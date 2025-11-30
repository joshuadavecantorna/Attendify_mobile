<?php

namespace App\Services;

use App\Services\OllamaService;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

class AIQueryService
{
    protected OllamaService $ollama;

    public function __construct(OllamaService $ollama)
    {
        $this->ollama = $ollama;
    }

    public function handleQuery(array $structuredQuery, array $userContext): array
    {
        if (empty($structuredQuery) || !isset($structuredQuery['query_category'])) {
            Log::error('AIQueryService: Invalid or empty structured query received.');
            return ['type' => 'unknown', 'error' => 'Could not understand the question.'];
        }

        $category = $structuredQuery['query_category'] ?? 'unknown';

        Log::info('AIQueryService: Handling structured query.', ['query' => $structuredQuery]);

        try {
            switch ($category) {
                case 'attendance':
                    return $this->executeAttendanceQuery($structuredQuery, $userContext);
                case 'classes':
                    return $this->executeClassQuery($structuredQuery, $userContext);
                case 'excuses':
                    return $this->executeExcuseQuery($structuredQuery, $userContext);
                default:
                    return ['type' => 'unknown', 'error' => 'This type of query is not supported yet.'];
            }
        } catch (\Exception $e) {
            Log::error('AIQueryService: Error executing query.', ['exception' => $e]);
            return ['type' => 'error', 'error' => 'An unexpected error occurred while processing the query.'];
        }
    }

    protected function executeAttendanceQuery(array $query, array $userContext): array
    {
        $queryType = $query['query_type'] ?? 'list';
        $entities = $query['entities'] ?? [];
        $timePeriod = $entities['time_period'] ?? 'this_month';

        [$startDate, $endDate] = $this->getDateRange($timePeriod);
        $studentIds = $this->getScopedStudentIds($userContext, $entities);
        $scope = $this->getScopeDescription($userContext, $entities);

        if (is_array($studentIds) && empty($studentIds)) {
            return match ($queryType) {
                'rate' => ['type' => 'rate', 'attendance_rate' => 0, 'scope' => $scope, 'period' => $timePeriod],
                'count_presents' => ['type' => 'count_presents', 'present_count' => 0, 'scope' => $scope, 'period' => $timePeriod],
                'count_absences' => ['type' => 'count_absences', 'absence_count' => 0, 'scope' => $scope, 'period' => $timePeriod],
                'count_lates' => ['type' => 'count_lates', 'late_count' => 0, 'scope' => $scope, 'period' => $timePeriod],
                'summary' => ['type' => 'attendance_summary', 'present_count' => 0, 'absent_count' => 0, 'late_count' => 0, 'scope' => $scope, 'period' => $timePeriod],
                default => ['type' => $queryType, 'records' => [], 'scope' => $scope, 'period' => $timePeriod],
            };
        }

        $dbQuery = DB::table('attendance_records');
        if ($studentIds !== null) {
            $dbQuery->whereIn('attendance_records.student_id', $studentIds);
        }

        if ($startDate && $endDate) {
            $dbQuery->whereBetween('attendance_records.created_at', [$startDate, $endDate]);
        }

        switch ($queryType) {
            case 'count_presents':
                return ['type' => 'count_presents', 'present_count' => (clone $dbQuery)->where('status', 'present')->count(), 'scope' => $scope, 'period' => $timePeriod];
            case 'count_absences':
                return ['type' => 'count_absences', 'absence_count' => (clone $dbQuery)->where('status', 'absent')->count(), 'scope' => $scope, 'period' => $timePeriod];
            case 'count_lates':
                return ['type' => 'count_lates', 'late_count' => (clone $dbQuery)->where('status', 'late')->count(), 'scope' => $scope, 'period' => $timePeriod];
            case 'list_absences':
            case 'list_records':
                $records = (clone $dbQuery)->when($queryType === 'list_absences', fn ($q) => $q->where('status', 'absent'))
                    ->join('students', 'attendance_records.student_id', '=', 'students.id')
                    ->select('attendance_records.created_at', 'attendance_records.status', 'students.name as student_name')
                    ->orderBy('attendance_records.created_at', 'desc')->limit(30)->get();
                return ['type' => $queryType, 'records' => $records, 'scope' => $scope, 'period' => $timePeriod];
            case 'rate':
                $total = (clone $dbQuery)->count();
                $present = (clone $dbQuery)->where('status', 'present')->count();
                $rate = $total > 0 ? round(($present / $total) * 100, 2) : 0;
                return ['type' => 'rate', 'attendance_rate' => $rate, 'scope' => $scope, 'period' => $timePeriod];
            case 'summary':
                return [
                    'type' => 'attendance_summary',
                    'present_count' => (clone $dbQuery)->where('status', 'present')->count(),
                    'absent_count' => (clone $dbQuery)->where('status', 'absent')->count(),
                    'late_count' => (clone $dbQuery)->where('status', 'late')->count(),
                    'scope' => $scope,
                    'period' => $timePeriod,
                ];
        }

        return ['type' => 'unknown', 'error' => 'Unsupported attendance query type.'];
    }

    protected function executeClassQuery(array $query, array $userContext): array
    {
        $queryType = $query['query_type'] ?? 'list';
        $entities = $query['entities'] ?? [];

        if ($queryType === 'rank_classes') {
            $metric = $entities['metric'] ?? 'attendance';
            $timePeriod = $entities['time_period'] ?? 'this_month';
            [$startDate, $endDate] = $this->getDateRange($timePeriod);

            $subQuery = DB::table('attendance_records')
                ->whereBetween('created_at', [$startDate, $endDate]);

            $dbQuery = DB::table('class_models')
                ->select('class_models.name')
                ->leftJoin('class_student', 'class_models.id', '=', 'class_student.class_model_id')
                ->leftJoinSub($subQuery, 'recs', 'recs.student_id', '=', 'class_student.student_id')
                ->groupBy('class_models.id', 'class_models.name');

            if ($metric === 'absences') {
                $dbQuery->selectRaw('COUNT(CASE WHEN recs.status = \'absent\' THEN 1 END) as metric_value')
                    ->orderBy('metric_value', 'desc');
            } else {
                $dbQuery->selectRaw('CAST(COUNT(CASE WHEN recs.status = \'present\' THEN 1 END) AS REAL) / NULLIF(COUNT(recs.id), 0) * 100 as metric_value')
                    ->orderBy('metric_value', 'desc');
            }
            return ['type' => 'rank_classes', 'metric' => $metric, 'period' => $timePeriod, 'classes' => $dbQuery->limit(5)->get()];
        }

        if ($queryType === 'list_all' || $queryType === 'list_details') {
            $dbQuery = DB::table('class_models');
            if ($userContext['role'] === 'student' && isset($userContext['student_id'])) {
                $pivotCol = Schema::hasColumn('class_student', 'class_id') ? 'class_id' : 'class_model_id';
                $dbQuery->join('class_student', 'class_models.id', '=', "class_student.{$pivotCol}")
                    ->where('class_student.student_id', $userContext['student_id']);
            } elseif ($userContext['role'] === 'teacher' && isset($userContext['teacher_id'])) {
                $dbQuery->where('teacher_id', $userContext['teacher_id']);
            }

            $columns = ($queryType === 'list_details')
                ? ['name', 'subject', 'schedule_time', 'schedule_days', 'room']
                : ['name', 'subject'];

            return ['type' => 'classes_list', 'classes' => $dbQuery->select($columns)->get()];
        }

        return ['type' => 'unknown', 'error' => 'Unsupported class query type.'];
    }

    protected function executeExcuseQuery(array $query, array $userContext): array
    {
        $queryType = $query['query_type'] ?? 'list';
        $entities = $query['entities'] ?? [];
        $status = $entities['excuse_status'] ?? null;

        $studentIds = $this->getScopedStudentIds($userContext, $entities);
        $scope = $this->getScopeDescription($userContext, $entities);

        if (is_array($studentIds) && empty($studentIds)) {
            return ['type' => 'excuse_status', 'status' => $status, 'count' => 0, 'records' => [], 'scope' => $scope];
        }

        $dbQuery = DB::table('excuse_requests')->join('students', 'excuse_requests.student_id', '=', 'students.id');
        if ($studentIds !== null) {
            $dbQuery->whereIn('excuse_requests.student_id', $studentIds);
        }
        if ($status) {
            $dbQuery->where('excuse_requests.status', $status);
        }

        $count = (clone $dbQuery)->count();
        $records = (clone $dbQuery)->select('students.name as student_name', 'excuse_requests.status', 'excuse_requests.created_at')
            ->orderBy('excuse_requests.created_at', 'desc')->limit(20)->get();

        return ['type' => 'excuse_status', 'status' => $status ?? 'all', 'count' => $count, 'records' => $records, 'scope' => $scope];
    }

    protected function getScopedStudentIds(array $userContext, array $entities): ?array
    {
        if (!empty($entities['student_name'])) {
            $student = DB::table('students')->where('name', 'ILIKE', $entities['student_name'])->first();
            return $student ? [$student->id] : [];
        }
        return match ($userContext['role'] ?? null) {
            'student' => isset($userContext['student_id']) ? [$userContext['student_id']] : [],
                'teacher' => isset($userContext['teacher_id']) ? DB::table('class_student')->join('class_models', 'class_student.class_model_id', '=', 'class_models.id')->where('class_models.teacher_id', $userContext['teacher_id'])->pluck('class_student.student_id')->unique()->all() : [],
            'admin' => null,
            default => [],
        };
    }

    protected function getScopeDescription(array $userContext, array $entities): string
    {
        if (!empty($entities['student_name'])) {
            return "for student \"{$entities['student_name']}\"";
        }
        return match ($userContext['role'] ?? null) {
            'student' => "for you",
            'teacher' => "for students in your classes",
            'admin' => "for all students",
            default => "",
        };
    }

    protected function getDateRange(string $period): array
    {
        $now = Carbon::now();
        return match (strtolower(str_replace(' ', '_', $period))) {
            'today' => [$now->copy()->startOfDay(), $now->copy()->endOfDay()],
            'this_week' => [$now->copy()->startOfWeek(), $now->copy()->endOfWeek()],
            'last_week' => [$now->copy()->subWeek()->startOfWeek(), $now->copy()->subWeek()->endOfWeek()],
            'this_month' => [$now->copy()->startOfMonth(), $now->copy()->endOfMonth()],
            'last_month' => [$now->copy()->subMonth()->startOfMonth(), $now->copy()->endOfMonth()],
            'this_year' => [$now->copy()->startOfYear(), $now->copy()->endOfYear()],
            default => [$now->copy()->startOfMonth(), $now->copy()->endOfMonth()],
        };
    }
}
<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Carbon\Carbon;
use App\Models\ClassModel;
use App\Models\AttendanceRecord;
use App\Models\AttendanceSession;

/**
 * RetrievalPlanner
 *
 * Responsibilities:
 * - Convert user question -> retrieval plan (tables, filters, role constraints)
 * - Execute queries safely using Query Builder / Eloquent
 * - Return fresh dynamic results
 *
 * Notes:
 * - Uses only real tables/columns present in migrations: attendance_records, attendance_sessions,
 *   class_models, class_student (pivot), students, teachers, excuse_requests
 */
class RetrievalPlanner
{
    /**
     * Plan and execute retrieval for a free-text question using the provided user context.
     *
     * @param string $question
     * @param array $userContext  Normalized user context from UserContextBuilder
     * @return array  ['intent' => string, 'plan' => array, 'results' => mixed]
     */
    public function planAndExecute(string $question, array $userContext): array
    {
        $q = Str::lower($question);

        // Basic intent detection via keywords
        $intent = $this->detectIntent($q);

        // Build a plan structure
        $plan = [
            'intent' => $intent,
            'tables' => [],
            'filters' => [],
            'role_constraints' => [],
        ];

        try {
            switch ($intent) {
                case 'attendance':
                    $plan['tables'][] = 'attendance_records';

                    // Time range detection
                    [$start, $end] = $this->extractDateRange($q);
                    if ($start && $end) {
                        $plan['filters']['date_range'] = [$start->toDateTimeString(), $end->toDateTimeString()];
                    }

                    // Role constraints
                    if (($userContext['role'] ?? null) === 'student' && isset($userContext['student_id'])) {
                        $plan['role_constraints']['student_id'] = $userContext['student_id'];
                        $results = DB::table('attendance_records')
                            ->where('student_id', $userContext['student_id'])
                            ->when(isset($plan['filters']['date_range']), function ($q) use ($plan) {
                                [$s, $e] = $plan['filters']['date_range'];
                                // prefer marked_at column
                                return $q->whereBetween('marked_at', [$s, $e]);
                            })
                            ->orderBy('marked_at', 'desc')
                            ->limit(100)
                            ->get();
                    } elseif (($userContext['role'] ?? null) === 'teacher' && isset($userContext['teacher'])) {
                        // teacher -> students in their classes
                        $teacherUserId = $userContext['teacher']['user_id'] ?? null;
                        $plan['role_constraints']['teacher_user_id'] = $teacherUserId;

                        // find student ids via pivot class_student joined to class_models by teacher
                        $studentIds = DB::table('class_student')
                            ->join('class_models', 'class_student.class_model_id', '=', 'class_models.id')
                            ->where('class_models.teacher_id', $teacherUserId)
                            ->where('class_student.status', 'enrolled')
                            ->pluck('class_student.student_id')
                            ->unique()
                            ->all();

                        $results = DB::table('attendance_records')
                            ->when(!empty($studentIds), fn($q) => $q->whereIn('student_id', $studentIds))
                            ->when(isset($plan['filters']['date_range']), function ($q) use ($plan) {
                                [$s, $e] = $plan['filters']['date_range'];
                                return $q->whereBetween('marked_at', [$s, $e]);
                            })
                            ->orderBy('marked_at', 'desc')
                            ->limit(200)
                            ->get();
                    } else {
                        // admin or unknown: return global attendance records within date range
                        $results = DB::table('attendance_records')
                            ->when(isset($plan['filters']['date_range']), function ($q) use ($plan) {
                                [$s, $e] = $plan['filters']['date_range'];
                                return $q->whereBetween('marked_at', [$s, $e]);
                            })
                            ->orderBy('marked_at', 'desc')
                            ->limit(200)
                            ->get();
                    }

                    $plan['executed_query'] = 'Query attendance_records with applied filters';
                    break;

                case 'schedule':
                    // We'll fetch from class_models schedule fields
                    $plan['tables'][] = 'class_models';

                    if (($userContext['role'] ?? null) === 'student' && isset($userContext['student_id'])) {
                        $studentId = $userContext['student_id'];

                        // Classes via pivot first (class_student)
                        $classes = DB::table('class_models')
                            ->join('class_student', 'class_models.id', '=', 'class_student.class_model_id')
                            ->where('class_student.student_id', $studentId)
                            ->where('class_student.status', 'enrolled')
                            ->select('class_models.id','class_models.name','class_models.class_code','class_models.subject','class_models.schedule_time','class_models.schedule_days','class_models.room')
                            ->orderBy('class_models.name')
                            ->get();

                        // fallback: student's direct class_id
                        if ($classes->isEmpty() && isset($userContext['student']['class_id'])) {
                            $classes = DB::table('class_models')
                                ->where('id', $userContext['student']['class_id'])
                                ->select('id','name','class_code','subject','schedule_time','schedule_days','room')
                                ->get();
                        }

                        $results = $classes;
                        $plan['role_constraints']['student_id'] = $studentId;
                    } elseif (($userContext['role'] ?? null) === 'teacher' && isset($userContext['teacher'])) {
                        $teacherUserId = $userContext['teacher']['user_id'] ?? null;
                        $plan['role_constraints']['teacher_user_id'] = $teacherUserId;

                        $classes = DB::table('class_models')
                            ->where('teacher_id', $teacherUserId)
                            ->select('id','name','class_code','subject','schedule_time','schedule_days','room')
                            ->orderBy('schedule_time')
                            ->get();

                        $results = $classes;
                    } else {
                        // admin: list active classes with schedules
                        $results = DB::table('class_models')
                            ->select('id','name','class_code','subject','schedule_time','schedule_days','room')
                            ->whereRaw('COALESCE(is_active, true) = true')
                            ->orderBy('name')
                            ->limit(200)
                            ->get();
                    }

                    $plan['executed_query'] = 'Select schedule fields from class_models (joined to class_student for students)';
                    break;

                case 'teacher':
                    $plan['tables'][] = 'teachers';

                    if (($userContext['role'] ?? null) === 'student' && isset($userContext['student_id'])) {
                        // find teacher(s) for student's classes
                        $studentId = $userContext['student_id'];

                        $teachers = DB::table('teachers')
                            ->join('class_models', 'teachers.user_id', '=', 'class_models.teacher_id')
                            ->join('class_student', 'class_models.id', '=', 'class_student.class_model_id')
                            ->where('class_student.student_id', $studentId)
                            ->where('class_student.status', 'enrolled')
                            ->select('teachers.*')
                            ->distinct()
                            ->get();

                        $results = $teachers;
                        $plan['role_constraints']['student_id'] = $studentId;
                    } elseif (($userContext['role'] ?? null) === 'teacher' && isset($userContext['teacher'])) {
                        // return their own teacher record
                        $teacherId = $userContext['teacher']['id'] ?? null;
                        $results = DB::table('teachers')->where('id', $teacherId)->get();
                        $plan['role_constraints']['teacher_id'] = $teacherId;
                    } else {
                        // admin: list all teachers
                        $results = DB::table('teachers')->select('id','teacher_id','first_name','last_name','email','department','position')->limit(200)->get();
                    }

                    $plan['executed_query'] = 'Query teachers table with joins for student->class->teacher mapping when needed';
                    break;

                case 'subjects':
                case 'classes':
                    $plan['tables'][] = 'class_models';
                    $plan['tables'][] = 'class_student';

                    if (($userContext['role'] ?? null) === 'student' && isset($userContext['student_id'])) {
                        $studentId = $userContext['student_id'];

                        $classes = DB::table('class_models')
                            ->join('class_student', 'class_models.id', '=', 'class_student.class_model_id')
                            ->where('class_student.student_id', $studentId)
                            ->where('class_student.status', 'enrolled')
                            ->select('class_models.id','class_models.name','class_models.subject','class_models.class_code','class_models.course','class_models.section')
                            ->orderBy('class_models.name')
                            ->get();

                        $results = $classes;
                        $plan['role_constraints']['student_id'] = $studentId;
                    } elseif (($userContext['role'] ?? null) === 'teacher' && isset($userContext['teacher'])) {
                        $teacherUserId = $userContext['teacher']['user_id'] ?? null;
                        $classes = DB::table('class_models')
                            ->where('teacher_id', $teacherUserId)
                            ->select('id','name','subject','class_code','course','section')
                            ->orderBy('name')
                            ->get();

                        $results = $classes;
                        $plan['role_constraints']['teacher_user_id'] = $teacherUserId;
                    } else {
                        $results = DB::table('class_models')
                            ->select('id','name','subject','class_code','course','section')
                            ->whereRaw('COALESCE(is_active, true) = true')
                            ->orderBy('name')
                            ->limit(200)
                            ->get();
                    }

                    $plan['executed_query'] = 'Query class_models joined to class_student for student enrollments';
                    break;

                default:
                    $plan['executed_query'] = null;
                    $results = ['error' => 'Could not map question to a supported retrieval intent.'];
                    break;
            }
        } catch (\Exception $e) {
            Log::error('RetrievalPlanner error', ['error' => $e->getMessage(), 'question' => $question, 'context' => $userContext]);
            return [
                'intent' => $intent,
                'plan' => $plan,
                'results' => ['error' => 'An error occurred while executing the retrieval.']
            ];
        }

        return [
            'intent' => $intent,
            'plan' => $plan,
            'results' => $results,
        ];
    }

    protected function detectIntent(string $q): string
    {
        if (Str::contains($q, ['attendance', 'absent', 'present', 'late', 'my attendance', 'attendance rate'])) {
            return 'attendance';
        }
        if (Str::contains($q, ['schedule', 'timetable', 'my schedule', 'class time', 'when is'])) {
            return 'schedule';
        }
        if (Str::contains($q, ['my teacher', 'teacher', 'who teaches', 'advisor', 'adviser'])) {
            return 'teacher';
        }
        if (Str::contains($q, ['subject', 'subjects', 'my subjects', 'enrolled', 'classes', 'my classes'])) {
            return 'subjects';
        }

        return 'unknown';
    }

    /**
     * Extract a simple date range from text: today, this week, this month, last week, last month
     * Returns [Carbon|null, Carbon|null]
     */
    protected function extractDateRange(string $q): array
    {
        $now = Carbon::now();
        if (Str::contains($q, 'today')) {
            return [$now->copy()->startOfDay(), $now->copy()->endOfDay()];
        }
        if (Str::contains($q, 'this week')) {
            return [$now->copy()->startOfWeek(), $now->copy()->endOfWeek()];
        }
        if (Str::contains($q, 'last week')) {
            return [$now->copy()->subWeek()->startOfWeek(), $now->copy()->subWeek()->endOfWeek()];
        }
        if (Str::contains($q, 'this month')) {
            return [$now->copy()->startOfMonth(), $now->copy()->endOfMonth()];
        }
        if (Str::contains($q, 'last month')) {
            return [$now->copy()->subMonth()->startOfMonth(), $now->copy()->subMonth()->endOfMonth()];
        }

        return [null, null];
    }
}

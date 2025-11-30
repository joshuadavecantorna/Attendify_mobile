<?php

namespace App\Services;

use App\Models\User;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\ClassModel;
use App\Models\AttendanceRecord;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class UserContextBuilder
{
    /**
     * Build a normalized user context and cache it for 5 minutes.
     *
     * @param int $userId
     * @return array
     */
    public function build(int $userId): array
    {
        $cacheKey = "context_{$userId}";

        // Use Cache::remember to ensure consistent caching behavior
        return Cache::remember($cacheKey, 300, function () use ($userId) {
            $user = User::find($userId);
            if (!$user) {
                return [];
            }

            // Determine role by presence in tables: teachers / students / admins
            $teacherRecord = Teacher::where('user_id', $userId)->first();
            $studentRecord = Student::where('user_id', $userId)->first();

            $adminRecord = null;
            if (Schema::hasTable('admins') && Schema::hasColumn('admins', 'user_id')) {
                $adminRecord = DB::table('admins')->where('user_id', $userId)->first();
            }

            if ($teacherRecord) {
                $role = 'teacher';
            } elseif ($studentRecord) {
                $role = 'student';
            } elseif ($adminRecord) {
                $role = 'admin';
            } else {
                $role = $user->role ?? 'admin';
            }

        // Base user info (only include columns that exist)
        $userInfo = [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $role,
        ];

        if (Schema::hasColumn('users', 'student_id')) {
            $userInfo['student_id'] = $user->student_id;
        }
        if (Schema::hasColumn('users', 'class_code')) {
            $userInfo['class_code'] = $user->class_code;
        }
        if (Schema::hasColumn('users', 'telegram_chat_id')) {
            $userInfo['telegram_chat_id'] = $user->telegram_chat_id;
            $userInfo['telegram_username'] = $user->telegram_username ?? null;
            $userInfo['notifications_enabled'] = $user->notifications_enabled ?? false;
        }

        $context = [
            'user' => $userInfo,
            'role' => $role,
        ];

        // Student-specific context
        if ($role === 'student' && $studentRecord) {
            $student = $studentRecord->toArray();

            // Only keep known keys from migrations / model fillable
            $studentContext = array_intersect_key($student, array_flip([
                'id','student_id','name','email','class_id','phone','year','course','section','avatar','qr_data','is_active'
            ]));

            // Load enrolled classes via pivot (limit to recent 6 for UI)
            // Qualify columns with the related table name to avoid ambiguous column errors
            $classes = $studentRecord->classes()->select([
                'class_models.id as id',
                'class_models.name',
                'class_models.class_code',
                'class_models.course',
                'class_models.section',
                'class_models.subject',
                'class_models.schedule_time',
                'class_models.schedule_days',
                'class_models.room',
                'class_models.academic_year',
                'class_models.semester',
                'class_models.teacher_id'
            ])->limit(6)->get();

            // Recent attendance records (limit 20)
            $attendance = AttendanceRecord::where('student_id', $studentRecord->id)
                ->select(['id','attendance_session_id','status','marked_at','marked_by','notes','created_at'])
                ->orderBy('marked_at', 'desc')
                ->limit(8)
                ->get();

            // Recent excuse requests for dashboard (limit 5)
            $recentRequests = [];
            try {
                if (class_exists(\App\Models\ExcuseRequest::class)) {
                    $recentRequests = \App\Models\ExcuseRequest::where('student_id', $studentRecord->id)
                        ->select(['id','attendance_session_id','reason','status','created_at'])
                        ->orderBy('created_at','desc')
                        ->limit(5)
                        ->get()
                        ->map(function($r){
                            return [
                                'id' => $r->id,
                                'status' => $r->status,
                                'reason' => is_string($r->reason) ? mb_substr($r->reason,0,200) : null,
                                'created_at' => $r->created_at,
                            ];
                        })->toArray();
                }
            } catch (\Exception $e) {
                Log::warning('Failed to load recent excuse requests for UI context: '.$e->getMessage());
            }

            // Normalize schedule_days (sometimes JSON string) and reduce fields
            $studentContext['classes'] = array_map(function($c){
                // If schedule_days is JSON string, try decode
                if (isset($c['schedule_days']) && is_string($c['schedule_days'])) {
                    $decoded = json_decode($c['schedule_days'], true);
                    $c['schedule_days'] = is_array($decoded) ? $decoded : [$c['schedule_days']];
                }
                // Keep only UI-relevant keys
                return [
                    'id' => $c['id'] ?? null,
                    'name' => $c['name'] ?? null,
                    'class_code' => $c['class_code'] ?? null,
                    'course' => $c['course'] ?? null,
                    'section' => $c['section'] ?? null,
                    'subject' => $c['subject'] ?? null,
                    'schedule_time' => $c['schedule_time'] ?? null,
                    'schedule_days' => $c['schedule_days'] ?? [],
                    'room' => $c['room'] ?? null,
                ];
            }, $classes->toArray());

            $studentContext['recent_attendance'] = array_map(function($r){
                return [
                    'id' => $r['id'] ?? null,
                    'attendance_session_id' => $r['attendance_session_id'] ?? null,
                    'status' => $r['status'] ?? null,
                    'marked_at' => $r['marked_at'] ?? $r['created_at'] ?? null,
                ];
            }, $attendance->toArray());
            $studentContext['recent_requests'] = $recentRequests;

            // Basic stats for UI (counts)
            $studentContext['stats'] = [
                'totalClasses' => count($studentContext['classes']),
                'recentAttendanceCount' => count($studentContext['recent_attendance']),
            ];

            $context['student'] = $studentContext;
            $context['student_id'] = $studentRecord->id;
        }

        // Teacher-specific context
        if ($role === 'teacher' && $teacherRecord) {
            $teacher = $teacherRecord->toArray();

            $teacherContext = array_intersect_key($teacher, array_flip([
                'id','user_id','teacher_id','first_name','last_name','middle_name','email','phone','department','position','salary','profile_picture','is_active'
            ]));


            // Classes taught by this teacher (class_models.teacher_id stores users.id)
            $classes = ClassModel::where('teacher_id', $teacherRecord->user_id)
                ->select(['id','name','class_code','course','section','subject','schedule_time','schedule_days','room','academic_year','semester','is_active'])
                ->limit(12)
                ->get();

            $teacherContext['classes'] = array_map(function($c){
                $arr = (array)$c;
                if (isset($arr['schedule_days']) && is_string($arr['schedule_days'])) {
                    $decoded = json_decode($arr['schedule_days'], true);
                    $arr['schedule_days'] = is_array($decoded) ? $decoded : [$arr['schedule_days']];
                }
                return [
                    'id' => $arr['id'] ?? null,
                    'name' => $arr['name'] ?? null,
                    'class_code' => $arr['class_code'] ?? null,
                    'course' => $arr['course'] ?? null,
                    'section' => $arr['section'] ?? null,
                    'subject' => $arr['subject'] ?? null,
                    'schedule_time' => $arr['schedule_time'] ?? null,
                    'schedule_days' => $arr['schedule_days'] ?? [],
                    'room' => $arr['room'] ?? null,
                ];
            }, $classes->toArray());

            // Teacher stats
            $teacherContext['stats'] = [
                'classesCount' => count($teacherContext['classes']),
            ];

            $context['teacher'] = $teacherContext;
            $context['teacher_id'] = $teacherRecord->id;
        }

        // Admins or fallback: include basic summary info
        if ($role === 'admin') {
            $context['admin'] = [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ];
        }

            return $context;
        });
    }
}

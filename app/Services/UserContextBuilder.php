<?php

namespace App\Services;

use App\Models\User;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\ClassModel;
use App\Models\AttendanceRecord;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class UserContextBuilder
{
    /**
     * Build and cache user context for 15 minutes
     * 
     * @param int $userId
     * @return array
     */
    public function build(int $userId): array
    {
        $cacheKey = "user_context:{$userId}";
        $cacheDuration = now()->addMinutes(15); // Extended from 5 to 15 minutes

        return Cache::remember($cacheKey, $cacheDuration, function () use ($userId) {
            return $this->buildFresh($userId);
        });
    }

    /**
     * Force rebuild context without cache
     * 
     * @param int $userId
     * @return array
     */
    public function rebuild(int $userId): array
    {
        $cacheKey = "user_context:{$userId}";
        Cache::forget($cacheKey);
        return $this->build($userId);
    }

    /**
     * Clear context cache for a user
     * 
     * @param int $userId
     * @return void
     */
    public function clearCache(int $userId): void
    {
        $cacheKey = "user_context:{$userId}";
        Cache::forget($cacheKey);
    }

    /**
     * Build fresh context from database
     * 
     * @param int $userId
     * @return array
     */
    private function buildFresh(int $userId): array
    {
        try {
            $user = User::findOrFail($userId);
            
            // Determine user role
            $role = $this->determineUserRole($user);

            // Base user info
            $context = [
                'user' => $this->buildUserInfo($user),
                'role' => $role,
            ];

            // Add role-specific context
            switch ($role) {
                case 'student':
                    $context = array_merge($context, $this->buildStudentContext($user));
                    break;
                    
                case 'teacher':
                    $context = array_merge($context, $this->buildTeacherContext($user));
                    break;
                    
                case 'admin':
                    $context = array_merge($context, $this->buildAdminContext($user));
                    break;
            }

            return $context;

        } catch (\Exception $e) {
            Log::error('UserContextBuilder::buildFresh error', [
                'user_id' => $userId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            // Return minimal fallback context
            return [
                'user' => ['id' => $userId, 'name' => 'User', 'role' => 'unknown'],
                'role' => 'unknown',
                'error' => 'Failed to load user context',
            ];
        }
    }

    /**
     * Determine user role from relationships
     * 
     * @param User $user
     * @return string
     */
    private function determineUserRole(User $user): string
    {
        // Check explicit relationships first
        if ($user->teacher()->exists()) {
            return 'teacher';
        }
        
        if ($user->student()->exists()) {
            return 'student';
        }
        
        // Check admin table if it exists
        if ($this->isAdmin($user)) {
            return 'admin';
        }
        
        // Fallback to user role column
        return $user->role ?? 'user';
    }

    /**
     * Check if user is admin
     * 
     * @param User $user
     * @return bool
     */
    private function isAdmin(User $user): bool
    {
        // Check user role column first
        if ($user->role === 'admin') {
            return true;
        }

        // Check admins table if it exists
        if (!Schema::hasTable('admins')) {
            return false;
        }

        return DB::table('admins')->where('user_id', $user->id)->exists();
    }

    /**
     * Build base user information
     * 
     * @param User $user
     * @return array
     */
    private function buildUserInfo(User $user): array
    {
        $info = [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
        ];

        // Optional fields (check if column exists before accessing)
        $optionalFields = [
            'student_id', 
            'class_code', 
            'telegram_chat_id', 
            'telegram_username', 
            'notifications_enabled'
        ];
        
        foreach ($optionalFields as $field) {
            if (Schema::hasColumn('users', $field) && isset($user->$field)) {
                $info[$field] = $user->$field;
            }
        }

        return $info;
    }

    /**
     * Build student-specific context
     * 
     * @param User $user
     * @return array
     */
    private function buildStudentContext(User $user): array
    {
        $studentRecord = Student::where('user_id', $user->id)->first();
        
        if (!$studentRecord) {
            return ['student' => null, 'student_id' => null];
        }

        // Eager load classes relationship with optimized query
        $studentRecord->load([
            'classes' => function ($query) {
                $query->select([
                    'class_models.id',
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
                ])
                ->where('class_student.status', 'enrolled')
                ->limit(10);
            }
        ]);

        // Recent attendance (last 10 records)
        $recentAttendance = AttendanceRecord::where('student_id', $studentRecord->id)
            ->select(['id', 'attendance_session_id', 'status', 'marked_at', 'notes', 'method'])
            ->orderBy('marked_at', 'desc')
            ->limit(10)
            ->get()
            ->map(fn($r) => [
                'id' => $r->id,
                'status' => $r->status,
                'marked_at' => $r->marked_at,
                'method' => $r->method ?? 'manual',
            ])
            ->toArray();

        // Recent excuse requests
        $recentRequests = $this->loadRecentExcuseRequests($studentRecord->id);

        // Format classes
        $classes = $studentRecord->classes->map(function ($c) {
            return [
                'id' => $c->id,
                'name' => $c->name,
                'class_code' => $c->class_code,
                'course' => $c->course,
                'section' => $c->section,
                'subject' => $c->subject,
                'schedule_time' => $c->schedule_time,
                'schedule_days' => $this->parseScheduleDays($c->schedule_days),
                'room' => $c->room,
                'academic_year' => $c->academic_year,
                'semester' => $c->semester,
            ];
        })->toArray();

        $studentContext = [
            'id' => $studentRecord->id,
            'name' => $studentRecord->name,
            'student_id' => $studentRecord->student_id,
            'email' => $studentRecord->email,
            'year' => $studentRecord->year,
            'course' => $studentRecord->course,
            'section' => $studentRecord->section,
            'phone' => $studentRecord->phone ?? null,
            'classes' => $classes,
            'recent_attendance' => $recentAttendance,
            'recent_requests' => $recentRequests,
            'stats' => [
                'total_classes' => count($classes),
                'recent_attendance_count' => count($recentAttendance),
                'pending_requests' => collect($recentRequests)->where('status', 'pending')->count(),
            ],
        ];

        return [
            'student' => $studentContext,
            'student_id' => $studentRecord->id,
        ];
    }

    /**
     * Build teacher-specific context
     * 
     * @param User $user
     * @return array
     */
    private function buildTeacherContext(User $user): array
    {
        $teacherRecord = Teacher::where('user_id', $user->id)->first();
        
        if (!$teacherRecord) {
            return ['teacher' => null, 'teacher_id' => null];
        }

        // Classes taught by this teacher (teacher_id in class_models references users.id)
        $classes = ClassModel::where('teacher_id', $teacherRecord->user_id)
            ->select([
                'id', 'name', 'class_code', 'course', 'section', 
                'subject', 'schedule_time', 'schedule_days', 'room',
                'academic_year', 'semester', 'is_active'
            ])
            ->where('is_active', true)
            ->orderBy('schedule_time')
            ->limit(15)
            ->get()
            ->map(fn($c) => [
                'id' => $c->id,
                'name' => $c->name,
                'class_code' => $c->class_code,
                'course' => $c->course,
                'section' => $c->section,
                'subject' => $c->subject,
                'schedule_time' => $c->schedule_time,
                'schedule_days' => $this->parseScheduleDays($c->schedule_days),
                'room' => $c->room,
                'academic_year' => $c->academic_year,
                'semester' => $c->semester,
            ])
            ->toArray();

        $teacherContext = [
            'id' => $teacherRecord->id,
            'user_id' => $teacherRecord->user_id,
            'teacher_id' => $teacherRecord->teacher_id,
            'first_name' => $teacherRecord->first_name,
            'last_name' => $teacherRecord->last_name,
            'email' => $teacherRecord->email,
            'phone' => $teacherRecord->phone,
            'department' => $teacherRecord->department,
            'position' => $teacherRecord->position,
            'classes' => $classes,
            'stats' => [
                'classes_count' => count($classes),
            ],
        ];

        return [
            'teacher' => $teacherContext,
            'teacher_id' => $teacherRecord->id,
        ];
    }

    /**
     * Build admin context
     * 
     * @param User $user
     * @return array
     */
    private function buildAdminContext(User $user): array
    {
        return [
            'admin' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
        ];
    }

    /**
     * Parse schedule_days (handles JSON string or array)
     * 
     * @param mixed $scheduleDays
     * @return array
     */
    private function parseScheduleDays($scheduleDays): array
    {
        if (is_array($scheduleDays)) {
            return $scheduleDays;
        }
        
        if (is_string($scheduleDays)) {
            $decoded = json_decode($scheduleDays, true);
            return is_array($decoded) ? $decoded : [$scheduleDays];
        }

        return [];
    }

    /**
     * Load recent excuse requests safely
     * ✅ CORRECTED: Uses excuse_requests table
     * 
     * @param int $studentId
     * @return array
     */
    private function loadRecentExcuseRequests(int $studentId): array
    {
        try {
            // Check if ExcuseRequest model exists
            if (!class_exists(\App\Models\ExcuseRequest::class)) {
                return [];
            }

            // Load from excuse_requests table
            return \App\Models\ExcuseRequest::where('student_id', $studentId)
                ->select(['id', 'status', 'reason', 'submitted_at', 'attendance_session_id', 'created_at'])
                ->orderBy('created_at', 'desc')
                ->limit(5)
                ->get()
                ->map(fn($r) => [
                    'id' => $r->id,
                    'status' => $r->status,
                    'reason' => is_string($r->reason) ? mb_substr($r->reason, 0, 100) : null,
                    'submitted_at' => $r->submitted_at ?? $r->created_at,
                    'attendance_session_id' => $r->attendance_session_id,
                ])
                ->toArray();

        } catch (\Exception $e) {
            Log::warning('Failed to load excuse requests: ' . $e->getMessage());
            return [];
        }
    }
}

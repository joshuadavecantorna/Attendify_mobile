import '../database/database_helper.dart';

class OfflineService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Cache classes
  Future<void> cacheClasses(List<Map<String, dynamic>> classes) async {
    await _db.clearTable('classes');
    for (final classData in classes) {
      await _db.insert('classes', {
        'id': classData['id'],
        'name': classData['name'],
        'code': classData['code'],
        'description': classData['description'],
        'schedule': classData['schedule'],
        'teacher_name': classData['teacher_name'],
        'synced': 1,
        'created_at': classData['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCachedClasses() async {
    return await _db.query('classes');
  }

  // Cache attendance records
  Future<void> cacheAttendanceRecords(List<Map<String, dynamic>> records) async {
    await _db.clearTable('attendance_records');
    for (final record in records) {
      await _db.insert('attendance_records', {
        'id': record['id'],
        'class_id': record['class_id'],
        'class_name': record['class_name'],
        'date': record['date'],
        'status': record['status'],
        'checked_in_at': record['checked_in_at'],
        'session_id': record['session_id'],
        'synced': 1,
        'created_at': record['created_at'] ?? DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCachedAttendanceRecords() async {
    return await _db.query('attendance_records');
  }

  // Cache attendance summary
  Future<void> cacheAttendanceSummary(Map<String, dynamic> summary) async {
    await _db.clearTable('attendance_summary');
    await _db.insert('attendance_summary', {
      'id': 1,
      'total_sessions': summary['total_sessions'] ?? 0,
      'present': summary['present'] ?? 0,
      'absent': summary['absent'] ?? 0,
      'late': summary['late'] ?? 0,
      'attendance_rate': summary['attendance_rate'] ?? 0.0,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getCachedAttendanceSummary() async {
    final results = await _db.query('attendance_summary');
    return results.isNotEmpty ? results.first : null;
  }

  // Cache excuse requests
  Future<void> cacheExcuseRequests(List<Map<String, dynamic>> excuses) async {
    await _db.clearTable('excuse_requests');
    for (final excuse in excuses) {
      await _db.insert('excuse_requests', {
        'id': excuse['id'],
        'class_id': excuse['class_id'],
        'class_name': excuse['class_name'],
        'date': excuse['date'],
        'type': excuse['type'],
        'reason': excuse['reason'],
        'status': excuse['status'],
        'response': excuse['response'],
        'attachment_url': excuse['attachment_url'],
        'synced': 1,
        'created_at': excuse['created_at'] ?? DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCachedExcuseRequests() async {
    return await _db.query('excuse_requests');
  }

  // Cache schedule
  Future<void> cacheSchedule(List<Map<String, dynamic>> schedule) async {
    await _db.clearTable('schedule');
    for (final item in schedule) {
      await _db.insert('schedule', {
        'id': item['id'],
        'class_id': item['class_id'],
        'class_name': item['class_name'],
        'time': item['time'],
        'room': item['room'],
        'day': item['day'] ?? DateTime.now().weekday.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCachedSchedule() async {
    return await _db.query('schedule');
  }

  // Queue operations for sync
  Future<void> queueForSync({
    required String table,
    required int recordId,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    await _db.insert('sync_queue', {
      'table_name': table,
      'record_id': recordId,
      'operation': operation,
      'data': data.toString(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    return await _db.query('sync_queue');
  }

  Future<void> clearSyncQueue() async {
    await _db.clearTable('sync_queue');
  }

  Future<void> removeSyncItem(int id) async {
    await _db.delete('sync_queue', 'id = ?', [id]);
  }

  // Cache chat messages
  Future<void> cacheChatMessage(Map<String, dynamic> message) async {
    await _db.insert('chat_messages', {
      'id': message['id'],
      'content': message['content'],
      'is_user': message['is_user'] ? 1 : 0,
      'timestamp': message['timestamp'],
      'session_id': message['session_id'],
      'synced': 1,
    });
  }

  Future<List<Map<String, dynamic>>> getCachedChatMessages({String? sessionId}) async {
    if (sessionId != null) {
      return await _db.queryWhere('chat_messages', 'session_id = ?', [sessionId]);
    }
    return await _db.query('chat_messages');
  }

  // Check if data is cached
  Future<bool> hasCache(String table) async {
    final results = await _db.query(table);
    return results.isNotEmpty;
  }

  // Teacher-specific caching
  Future<void> cacheTeacherClasses(List<Map<String, dynamic>> classes) async {
    await _db.clearTable('teacher_classes');
    for (final classData in classes) {
      await _db.insert('teacher_classes', {
        'id': classData['id'],
        'name': classData['name'],
        'code': classData['code'],
        'enrolled_count': classData['enrolled_count'] ?? 0,
        'schedule': classData['schedule'],
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCachedTeacherClasses() async {
    return await _db.query('teacher_classes');
  }

  Future<void> cacheAttendanceSessions(List<Map<String, dynamic>> sessions) async {
    await _db.clearTable('attendance_sessions');
    for (final session in sessions) {
      await _db.insert('attendance_sessions', {
        'id': session['id'],
        'class_id': session['class_id'],
        'class_name': session['class_name'] ?? '',
        'start_time': session['start_time'],
        'end_time': session['end_time'],
        'status': session['status'],
        'qr_code': session['qr_code'],
        'present_count': session['present_count'] ?? 0,
        'absent_count': session['absent_count'] ?? 0,
        'late_count': session['late_count'] ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCachedAttendanceSessions() async {
    return await _db.query('attendance_sessions');
  }

  Future<void> cacheClassStudents(int classId, List<Map<String, dynamic>> students) async {
    // Clear only students for this specific class
    await _db.delete('class_students', 'class_id = ?', [classId]);
    for (final student in students) {
      await _db.insert('class_students', {
        'id': student['id'],
        'class_id': classId,
        'name': student['name'],
        'email': student['email'],
        'student_id': student['student_id'],
        'attendance_rate': student['attendance_rate'] ?? 0.0,
        'present_count': student['present_count'] ?? 0,
        'absent_count': student['absent_count'] ?? 0,
        'late_count': student['late_count'] ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCachedClassStudents(int classId) async {
    return await _db.queryWhere('class_students', 'class_id = ?', [classId]);
  }

  // Admin-specific caching
  Future<void> cacheAdminUsers(List<Map<String, dynamic>> users) async {
    await _db.clearTable('admin_users');
    for (final user in users) {
      await _db.insert('admin_users', {
        'id': user['id'],
        'name': user['name'],
        'email': user['email'],
        'role': user['role'],
        'created_at': user['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCachedAdminUsers() async {
    return await _db.query('admin_users');
  }

  Future<void> cacheAdminClasses(List<Map<String, dynamic>> classes) async {
    await _db.clearTable('admin_classes');
    for (final classData in classes) {
      await _db.insert('admin_classes', {
        'id': classData['id'],
        'name': classData['name'],
        'code': classData['code'],
        'description': classData['description'],
        'teacher_name': classData['teacher_name'],
        'enrolled_count': classData['enrolled_count'] ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCachedAdminClasses() async {
    return await _db.query('admin_classes');
  }

  Future<void> cacheSystemStats(Map<String, dynamic> stats) async {
    await _db.clearTable('system_stats');
    await _db.insert('system_stats', {
      'id': 1,
      'total_users': stats['total_users'] ?? 0,
      'total_students': stats['total_students'] ?? 0,
      'total_teachers': stats['total_teachers'] ?? 0,
      'total_classes': stats['total_classes'] ?? 0,
      'total_sessions': stats['total_sessions'] ?? 0,
      'average_attendance': stats['average_attendance'] ?? 0.0,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getCachedSystemStats() async {
    final results = await _db.query('system_stats');
    return results.isNotEmpty ? results.first : null;
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    await _db.clearTable('classes');
    await _db.clearTable('attendance_records');
    await _db.clearTable('attendance_summary');
    await _db.clearTable('excuse_requests');
    await _db.clearTable('schedule');
    await _db.clearTable('chat_messages');
    await _db.clearTable('teacher_classes');
    await _db.clearTable('attendance_sessions');
    await _db.clearTable('class_students');
    await _db.clearTable('admin_users');
    await _db.clearTable('admin_classes');
    await _db.clearTable('system_stats');
  }
}

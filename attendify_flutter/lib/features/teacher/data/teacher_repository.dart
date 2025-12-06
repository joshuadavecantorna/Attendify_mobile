import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/offline_service.dart';
import '../../../core/services/connectivity_service.dart';
import 'models/teacher_models.dart';

class TeacherRepository {
  final DioClient _dioClient;
  final OfflineService _offlineService;
  final ConnectivityService _connectivityService;

  TeacherRepository({
    required DioClient dioClient,
    required OfflineService offlineService,
    required ConnectivityService connectivityService,
  })  : _dioClient = dioClient,
        _offlineService = offlineService,
        _connectivityService = connectivityService;

  /// Get teacher's classes
  Future<List<TeacherClass>> getTeacherClasses() async {
    try {
      if (!_connectivityService.isOnline) {
        final cached = await _offlineService.getCachedTeacherClasses();
        return cached.map((json) => TeacherClass.fromJson(json)).toList();
      }

      final response = await _dioClient.get('/teacher/classes');
      final List<dynamic> data = response.data['classes'] ?? response.data;
      
      // Cache the data
      await _offlineService.cacheTeacherClasses(
        data.cast<Map<String, dynamic>>(),
      );
      
      return data.map((json) => TeacherClass.fromJson(json)).toList();
    } on DioException catch (e) {
      if (await _offlineService.hasCache('teacher_classes')) {
        final cached = await _offlineService.getCachedTeacherClasses();
        return cached.map((json) => TeacherClass.fromJson(json)).toList();
      }
      throw _handleError(e);
    }
  }

  /// Get students in a class
  Future<List<ClassStudent>> getClassStudents(int classId) async {
    try {
      if (!_connectivityService.isOnline) {
        final cached = await _offlineService.getCachedClassStudents(classId);
        return cached.map((json) => ClassStudent.fromJson(json)).toList();
      }

      final response = await _dioClient.get('/teacher/classes/$classId/students');
      final List<dynamic> data = response.data['students'] ?? response.data;
      
      // Cache the data
      await _offlineService.cacheClassStudents(
        classId,
        data.cast<Map<String, dynamic>>(),
      );
      
      return data.map((json) => ClassStudent.fromJson(json)).toList();
    } on DioException catch (e) {
      final cached = await _offlineService.getCachedClassStudents(classId);
      if (cached.isNotEmpty) {
        return cached.map((json) => ClassStudent.fromJson(json)).toList();
      }
      throw _handleError(e);
    }
  }

  /// Create attendance session
  Future<AttendanceSession> createAttendanceSession({
    required int classId,
    required DateTime startTime,
    required DateTime endTime,
    bool generateQR = true,
  }) async {
    if (!_connectivityService.isOnline) {
      throw 'Cannot create attendance session while offline. Please connect to internet.';
    }

    try {
      final response = await _dioClient.post(
        '/teacher/attendance/sessions',
        data: {
          'class_id': classId,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'generate_qr': generateQR,
        },
      );
      return AttendanceSession.fromJson(
          response.data['session'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get attendance sessions for a class
  Future<List<AttendanceSession>> getAttendanceSessions({
    int? classId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!_connectivityService.isOnline) {
        final cached = await _offlineService.getCachedAttendanceSessions();
        return cached.map((json) => AttendanceSession.fromJson(json)).toList();
      }

      final queryParams = <String, dynamic>{};
      if (classId != null) queryParams['class_id'] = classId;
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final response = await _dioClient.get(
        '/teacher/attendance/sessions',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data['sessions'] ?? response.data;
      
      // Cache the data
      await _offlineService.cacheAttendanceSessions(
        data.cast<Map<String, dynamic>>(),
      );
      
      return data.map((json) => AttendanceSession.fromJson(json)).toList();
    } on DioException catch (e) {
      if (await _offlineService.hasCache('attendance_sessions')) {
        final cached = await _offlineService.getCachedAttendanceSessions();
        return cached.map((json) => AttendanceSession.fromJson(json)).toList();
      }
      throw _handleError(e);
    }
  }

  /// Mark student attendance manually
  Future<void> markAttendance({
    required int sessionId,
    required int studentId,
    required String status,
  }) async {
    try {
      await _dioClient.post(
        '/teacher/attendance/mark',
        data: {
          'session_id': sessionId,
          'student_id': studentId,
          'status': status,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// End attendance session
  Future<void> endAttendanceSession(int sessionId) async {
    try {
      await _dioClient.post('/teacher/attendance/sessions/$sessionId/end');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get pending excuse requests
  Future<List<TeacherExcuseRequest>> getPendingExcuses() async {
    try {
      final response = await _dioClient.get('/teacher/excuses/pending');
      final List<dynamic> data = response.data['excuses'] ?? response.data;
      return data.map((json) => TeacherExcuseRequest.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all excuse requests
  Future<List<TeacherExcuseRequest>> getAllExcuses() async {
    try {
      final response = await _dioClient.get('/teacher/excuses');
      final List<dynamic> data = response.data['excuses'] ?? response.data;
      return data.map((json) => TeacherExcuseRequest.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Approve or reject excuse request
  Future<void> reviewExcuseRequest({
    required int excuseId,
    required String status,
    String? response,
  }) async {
    try {
      await _dioClient.post(
        '/teacher/excuses/$excuseId/review',
        data: {
          'status': status,
          'teacher_response': response,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get teacher dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await _dioClient.get('/teacher/dashboard/summary');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get class attendance report
  Future<Map<String, dynamic>> getClassAttendanceReport(int classId) async {
    try {
      final response =
          await _dioClient.get('/teacher/classes/$classId/attendance/report');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      if (data is Map && data.containsKey('error')) {
        return data['error'];
      }
      return 'Server error: ${error.response!.statusCode}';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    return 'An unexpected error occurred: ${error.message}';
  }
}

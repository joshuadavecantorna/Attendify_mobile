import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/offline_service.dart';
import '../../../core/services/connectivity_service.dart';
import 'models/student_models.dart';

class StudentRepository {
  final DioClient _dioClient;
  final OfflineService _offlineService;
  final ConnectivityService _connectivityService;

  StudentRepository({
    required DioClient dioClient,
    required OfflineService offlineService,
    required ConnectivityService connectivityService,
  })  : _dioClient = dioClient,
        _offlineService = offlineService,
        _connectivityService = connectivityService;

  /// Get student's enrolled classes
  Future<List<ClassModel>> getStudentClasses() async {
    try {
      if (!_connectivityService.isOnline) {
        // Return cached data when offline
        final cached = await _offlineService.getCachedClasses();
        return cached.map((json) => ClassModel.fromJson(json)).toList();
      }

      final response = await _dioClient.get('/student/classes');
      final List<dynamic> data = response.data['classes'] ?? response.data;
      
      // Cache the data
      await _offlineService.cacheClasses(
        data.cast<Map<String, dynamic>>(),
      );
      
      return data.map((json) => ClassModel.fromJson(json)).toList();
    } on DioException catch (e) {
      // Try to return cached data on network error
      if (await _offlineService.hasCache('classes')) {
        final cached = await _offlineService.getCachedClasses();
        return cached.map((json) => ClassModel.fromJson(json)).toList();
      }
      throw _handleError(e);
    }
  }

  /// Get student's attendance records
  Future<List<AttendanceRecord>> getAttendanceRecords({
    int? classId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!_connectivityService.isOnline) {
        // Return cached data when offline
        final cached = await _offlineService.getCachedAttendanceRecords();
        return cached.map((json) => AttendanceRecord.fromJson(json)).toList();
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
        '/student/attendance',
        queryParameters: queryParams,
      );
      
      final List<dynamic> data = response.data['records'] ?? response.data;
      
      // Cache the data
      await _offlineService.cacheAttendanceRecords(
        data.cast<Map<String, dynamic>>(),
      );
      
      return data.map((json) => AttendanceRecord.fromJson(json)).toList();
    } on DioException catch (e) {
      // Try to return cached data on network error
      if (await _offlineService.hasCache('attendance_records')) {
        final cached = await _offlineService.getCachedAttendanceRecords();
        return cached.map((json) => AttendanceRecord.fromJson(json)).toList();
      }
      throw _handleError(e);
    }
  }

  /// Get attendance summary/statistics
  Future<Map<String, dynamic>> getAttendanceSummary() async {
    try {
      if (!_connectivityService.isOnline) {
        // Return cached data when offline
        final cached = await _offlineService.getCachedAttendanceSummary();
        return cached ?? {};
      }

      final response = await _dioClient.get('/student/attendance/summary');
      
      // Cache the summary
      await _offlineService.cacheAttendanceSummary(response.data);
      
      return response.data;
    } on DioException catch (e) {
      // Try to return cached data on network error
      final cached = await _offlineService.getCachedAttendanceSummary();
      if (cached != null) {
        return cached;
      }
      throw _handleError(e);
    }
  }

  /// Check in to attendance session via QR code
  Future<Map<String, dynamic>> checkInWithQR(String qrData) async {
    try {
      final response = await _dioClient.post(
        '/student/attendance/check-in',
        data: {'qr_data': qrData},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get excuse requests
  Future<List<ExcuseRequest>> getExcuseRequests() async {
    try {
      if (!_connectivityService.isOnline) {
        // Return cached data when offline
        final cached = await _offlineService.getCachedExcuseRequests();
        return cached.map((json) => ExcuseRequest.fromJson(json)).toList();
      }

      final response = await _dioClient.get('/student/excuses');
      final List<dynamic> data = response.data['excuses'] ?? response.data;
      
      // Cache excuse requests
      await _offlineService.cacheExcuseRequests(
        data.cast<Map<String, dynamic>>(),
      );
      
      return data.map((json) => ExcuseRequest.fromJson(json)).toList();
    } on DioException catch (e) {
      // Try to return cached data on network error
      if (await _offlineService.hasCache('excuse_requests')) {
        final cached = await _offlineService.getCachedExcuseRequests();
        return cached.map((json) => ExcuseRequest.fromJson(json)).toList();
      }
      throw _handleError(e);
    }
  }

  /// Submit excuse request
  Future<ExcuseRequest> submitExcuseRequest({
    required int attendanceSessionId,
    required String reason,
    String? attachmentPath,
  }) async {
    try {
      if (!_connectivityService.isOnline) {
        throw 'Cannot submit excuse request while offline. Please try again when connected.';
      }

      FormData formData = FormData.fromMap({
        'attendance_session_id': attendanceSessionId,
        'reason': reason,
        if (attachmentPath != null)
          'attachment': await MultipartFile.fromFile(attachmentPath),
      });

      final response = await _dioClient.post(
        '/student/excuses',
        data: formData,
      );
      
      return ExcuseRequest.fromJson(response.data['excuse'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get today's schedule
  Future<List<ClassModel>> getTodaySchedule() async {
    try {
      if (!_connectivityService.isOnline) {
        // Return cached schedule when offline
        final cached = await _offlineService.getCachedSchedule();
        return cached.map((json) => ClassModel.fromJson(json)).toList();
      }

      final response = await _dioClient.get('/student/schedule/today');
      final List<dynamic> data = response.data['classes'] ?? response.data;
      
      // Cache schedule
      await _offlineService.cacheSchedule(
        data.cast<Map<String, dynamic>>(),
      );
      
      return data.map((json) => ClassModel.fromJson(json)).toList();
    } on DioException catch (e) {
      // Try to return cached data on network error
      if (await _offlineService.hasCache('schedule')) {
        final cached = await _offlineService.getCachedSchedule();
        return cached.map((json) => ClassModel.fromJson(json)).toList();
      }
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

import '../../../core/network/dio_client.dart';
import '../../../core/services/offline_service.dart';
import '../../../core/services/connectivity_service.dart';
import 'models/admin_models.dart';

class AdminRepository {
  final DioClient _dioClient;
  final OfflineService _offlineService;
  final ConnectivityService _connectivityService;

  AdminRepository({
    required DioClient dioClient,
    required OfflineService offlineService,
    required ConnectivityService connectivityService,
  })  : _dioClient = dioClient,
        _offlineService = offlineService,
        _connectivityService = connectivityService;

  // Dashboard & Statistics
  Future<SystemStats> getSystemStats() async {
    try {
      if (!_connectivityService.isOnline) {
        final cached = await _offlineService.getCachedSystemStats();
        if (cached != null) {
          return SystemStats.fromJson(cached);
        }
        throw 'No cached statistics available. Please connect to internet.';
      }

      final response = await _dioClient.dio.get('/admin/dashboard/stats');
      
      // Cache the stats
      await _offlineService.cacheSystemStats(response.data['data']);
      
      return SystemStats.fromJson(response.data['data']);
    } catch (e) {
      final cached = await _offlineService.getCachedSystemStats();
      if (cached != null) {
        return SystemStats.fromJson(cached);
      }
      throw _handleError(e);
    }
  }

  Future<AttendanceReport> getAttendanceReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/admin/reports/attendance',
        queryParameters: {
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );
      return AttendanceReport.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // User Management
  Future<List<AdminUser>> getAllUsers({String? role}) async {
    try {
      if (!_connectivityService.isOnline) {
        final cached = await _offlineService.getCachedAdminUsers();
        var users = cached.map((json) => AdminUser.fromJson(json)).toList();
        if (role != null) {
          users = users.where((u) => u.role == role).toList();
        }
        return users;
      }

      final response = await _dioClient.dio.get(
        '/admin/users',
        queryParameters: {
          if (role != null) 'role': role,
        },
      );
      
      final users = (response.data['data'] as List)
          .map((json) => AdminUser.fromJson(json))
          .toList();
      
      // Cache all users
      await _offlineService.cacheAdminUsers(
        (response.data['data'] as List).cast<Map<String, dynamic>>(),
      );
      
      return users;
    } catch (e) {
      if (await _offlineService.hasCache('admin_users')) {
        final cached = await _offlineService.getCachedAdminUsers();
        var users = cached.map((json) => AdminUser.fromJson(json)).toList();
        if (role != null) {
          users = users.where((u) => u.role == role).toList();
        }
        return users;
      }
      throw _handleError(e);
    }
  }

  Future<AdminUser> getUserById(int userId) async {
    try {
      final response = await _dioClient.dio.get('/admin/users/$userId');
      return AdminUser.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AdminUser> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? studentId,
    String? teacherId,
  }) async {
    if (!_connectivityService.isOnline) {
      throw 'Cannot create user while offline. Please connect to internet.';
    }

    try {
      final response = await _dioClient.dio.post(
        '/admin/users',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          if (studentId != null) 'student_id': studentId,
          if (teacherId != null) 'teacher_id': teacherId,
        },
      );
      return AdminUser.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AdminUser> updateUser({
    required int userId,
    String? name,
    String? email,
    String? role,
    String? password,
  }) async {
    if (!_connectivityService.isOnline) {
      throw 'Cannot update user while offline. Please connect to internet.';
    }

    try {
      final response = await _dioClient.dio.put(
        '/admin/users/$userId',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (role != null) 'role': role,
          if (password != null) 'password': password,
        },
      );
      return AdminUser.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteUser(int userId) async {
    if (!_connectivityService.isOnline) {
      throw 'Cannot delete user while offline. Please connect to internet.';
    }

    try {
      await _dioClient.dio.delete('/admin/users/$userId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Class Management
  Future<List<AdminClass>> getAllClasses() async {
    try {
      if (!_connectivityService.isOnline) {
        final cached = await _offlineService.getCachedAdminClasses();
        return cached.map((json) => AdminClass.fromJson(json)).toList();
      }

      final response = await _dioClient.dio.get('/admin/classes');
      final classes = (response.data['data'] as List)
          .map((json) => AdminClass.fromJson(json))
          .toList();
      
      // Cache classes
      await _offlineService.cacheAdminClasses(
        (response.data['data'] as List).cast<Map<String, dynamic>>(),
      );
      
      return classes;
    } catch (e) {
      if (await _offlineService.hasCache('admin_classes')) {
        final cached = await _offlineService.getCachedAdminClasses();
        return cached.map((json) => AdminClass.fromJson(json)).toList();
      }
      throw _handleError(e);
    }
  }

  Future<AdminClass> getClassById(int classId) async {
    try {
      final response = await _dioClient.dio.get('/admin/classes/$classId');
      return AdminClass.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AdminClass> createClass({
    required String name,
    required String code,
    String? description,
    String? schedule,
    int? teacherId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/admin/classes',
        data: {
          'name': name,
          'code': code,
          if (description != null) 'description': description,
          if (schedule != null) 'schedule': schedule,
          if (teacherId != null) 'teacher_id': teacherId,
        },
      );
      return AdminClass.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AdminClass> updateClass({
    required int classId,
    String? name,
    String? code,
    String? description,
    String? schedule,
    int? teacherId,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        '/admin/classes/$classId',
        data: {
          if (name != null) 'name': name,
          if (code != null) 'code': code,
          if (description != null) 'description': description,
          if (schedule != null) 'schedule': schedule,
          if (teacherId != null) 'teacher_id': teacherId,
        },
      );
      return AdminClass.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteClass(int classId) async {
    try {
      await _dioClient.dio.delete('/admin/classes/$classId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Student Enrollment
  Future<List<StudentEnrollment>> getClassEnrollments(int classId) async {
    try {
      final response = await _dioClient.dio.get('/admin/classes/$classId/enrollments');
      final enrollments = (response.data['data'] as List)
          .map((json) => StudentEnrollment.fromJson(json))
          .toList();
      return enrollments;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> enrollStudent({
    required int classId,
    required int studentId,
  }) async {
    try {
      await _dioClient.dio.post(
        '/admin/classes/$classId/enroll',
        data: {'student_id': studentId},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unenrollStudent({
    required int classId,
    required int studentId,
  }) async {
    try {
      await _dioClient.dio.post(
        '/admin/classes/$classId/unenroll',
        data: {'student_id': studentId},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error.toString().contains('DioException')) {
      return 'Network error. Please check your connection.';
    }
    return 'An error occurred: ${error.toString()}';
  }
}

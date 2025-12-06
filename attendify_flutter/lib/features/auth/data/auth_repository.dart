import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/app_constants.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository({required DioClient dioClient}) : _dioClient = dioClient;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dioClient.post(
        AppConstants.loginEndpoint,
        data: {
          'email': email,
          'password': password,
          'role': role,
        },
      );

      return {
        'token': response.data['token'],
        'user': response.data['user'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) async {
    try {
      final response = await _dioClient.post(
        AppConstants.registerEndpoint,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'role': role,
        },
      );

      return {
        'token': response.data['token'],
        'user': response.data['user'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dioClient.post(AppConstants.logoutEndpoint);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dioClient.get(AppConstants.userEndpoint);
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

  Future<void> registerFCMToken(String fcmToken) async {
    try {
      await _dioClient.post(
        '/notifications/register-token',
        data: {'fcm_token': fcmToken},
      );
    } on DioException catch (e) {
      // Don't throw error - FCM registration failure shouldn't block login
      print('FCM token registration failed: ${_handleError(e)}');
    }
  }
}

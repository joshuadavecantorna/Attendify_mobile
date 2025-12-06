/// Core constants for Attendify Flutter app
class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:8000'; // Update for production
  static const String apiPrefix = '/api';
  
  // API Endpoints
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String logoutEndpoint = '/logout';
  static const String userEndpoint = '/user';
  static const String chatbotQueryEndpoint = '/chatbot/query';
  static const String chatbotStreamEndpoint = '/chatbot/stream';
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String userRoleKey = 'user_role';
  
  // App Settings
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int qrScanTimeout = 30;
  
  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayTimeFormat = 'hh:mm a';
  
  // Attendance Status
  static const String statusPresent = 'present';
  static const String statusAbsent = 'absent';
  static const String statusLate = 'late';
  static const String statusExcused = 'excused';
  
  // User Roles
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';
  static const String roleAdmin = 'admin';
}

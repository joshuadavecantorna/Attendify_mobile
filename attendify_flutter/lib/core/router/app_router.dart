import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/student/presentation/screens/student_dashboard.dart';
import '../../features/student/presentation/screens/qr_scanner_screen.dart';
import '../../features/student/presentation/screens/classes_screen.dart';
import '../../features/student/presentation/screens/attendance_screen.dart';
import '../../features/student/presentation/screens/excuses_screen.dart';
import '../../features/teacher/presentation/screens/teacher_dashboard.dart';
import '../../features/teacher/presentation/screens/teacher_classes_screen.dart';
import '../../features/teacher/presentation/screens/create_session_screen.dart';
import '../../features/teacher/presentation/screens/session_qr_screen.dart';
import '../../features/teacher/presentation/screens/teacher_excuses_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard.dart';
import '../../features/admin/presentation/screens/users_management_screen.dart';
import '../../features/admin/presentation/screens/classes_management_screen.dart';
import '../../features/chatbot/presentation/screens/chat_screen.dart';
import '../constants/app_constants.dart';

/// Listens to AuthBloc stream and notifies GoRouter to re-evaluate redirects
class _AuthNotifier extends ChangeNotifier {
  final AuthBloc _authBloc;
  late final StreamSubscription _sub;

  _AuthNotifier(this._authBloc) {
    _sub = _authBloc.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRouter {
  static GoRouter createRouter(AuthBloc authBloc) {
    final notifier = _AuthNotifier(authBloc);

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: notifier,
      redirect: (context, state) {
        final authState = authBloc.state;
        final loc = state.matchedLocation;

        // Still checking — stay on splash
        if (authState is AuthInitial || authState is AuthLoading) {
          return loc == '/splash' ? null : '/splash';
        }

        // Not authenticated — go to login
        if (authState is AuthUnauthenticated || authState is AuthError) {
          return loc == '/login' ? null : '/login';
        }

        // Authenticated — redirect away from splash/login to role home
        if (authState is AuthAuthenticated) {
          if (loc == '/splash' || loc == '/login') {
            final role = authState.user.role;
            if (role == AppConstants.roleStudent) return '/student/dashboard';
            if (role == AppConstants.roleTeacher) return '/teacher/dashboard';
            if (role == AppConstants.roleAdmin) return '/admin/dashboard';
          }
        }

        return null;
      },
      routes: [
        // Auth
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

        // Student
        GoRoute(
          path: '/student/dashboard',
          builder: (_, __) => const StudentDashboard(),
        ),
        GoRoute(
          path: '/student/qr',
          builder: (_, __) => const QRScannerScreen(),
        ),
        GoRoute(
          path: '/student/classes',
          builder: (_, __) => const ClassesScreen(),
        ),
        GoRoute(
          path: '/student/attendance',
          builder: (_, __) => const AttendanceScreen(),
        ),
        GoRoute(
          path: '/student/excuses',
          builder: (_, __) => const ExcusesScreen(),
        ),

        // Teacher
        GoRoute(
          path: '/teacher/dashboard',
          builder: (_, __) => const TeacherDashboard(),
        ),
        GoRoute(
          path: '/teacher/classes',
          builder: (_, __) => const TeacherClassesScreen(),
        ),
        GoRoute(
          path: '/teacher/create-session',
          builder: (_, state) {
            final classIdParam = state.uri.queryParameters['classId'];
            return CreateSessionScreen(
              classId: classIdParam != null ? int.tryParse(classIdParam) : null,
            );
          },
        ),
        GoRoute(
          path: '/teacher/session-qr/:sessionId',
          builder: (_, state) {
            final sessionId = int.parse(state.pathParameters['sessionId']!);
            return SessionQRScreen(sessionId: sessionId);
          },
        ),
        GoRoute(
          path: '/teacher/excuses',
          builder: (_, __) => const TeacherExcusesScreen(),
        ),

        // Admin
        GoRoute(
          path: '/admin/dashboard',
          builder: (_, __) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (_, __) => const UsersManagementScreen(),
        ),
        GoRoute(
          path: '/admin/classes',
          builder: (_, __) => const ClassesManagementScreen(),
        ),

        // Chatbot
        GoRoute(
          path: '/chat',
          builder: (_, __) => const ChatScreen(),
        ),
      ],
    );
  }
}

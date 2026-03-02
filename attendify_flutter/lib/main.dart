import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/network/dio_client.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/offline_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/data/auth_repository.dart';

import 'features/student/bloc/student_bloc.dart';
import 'features/student/data/student_repository.dart';

import 'features/teacher/bloc/teacher_bloc.dart';
import 'features/teacher/data/teacher_repository.dart';

import 'features/admin/bloc/admin_bloc.dart';
import 'features/admin/data/admin_repository.dart';

import 'features/chatbot/bloc/chat_bloc.dart';
import 'features/chatbot/data/chat_repository.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const AttendSynxApp());
}

class AttendSynxApp extends StatefulWidget {
  const AttendSynxApp({super.key});

  @override
  State<AttendSynxApp> createState() => _AttendSynxAppState();
}

class _AttendSynxAppState extends State<AttendSynxApp> {
  // ── Core services ────────────────────────────────────────────────────────────
  final DioClient _dioClient = DioClient();
  final ConnectivityService _connectivityService = ConnectivityService();
  final OfflineService _offlineService = OfflineService();

  // ── Repositories ─────────────────────────────────────────────────────────────
  late final AuthRepository _authRepository;
  late final StudentRepository _studentRepository;
  late final TeacherRepository _teacherRepository;
  late final AdminRepository _adminRepository;
  late final ChatRepository _chatRepository;

  // ── BLoCs ────────────────────────────────────────────────────────────────────
  late final AuthBloc _authBloc;
  late final StudentBloc _studentBloc;
  late final TeacherBloc _teacherBloc;
  late final AdminBloc _adminBloc;
  late final ChatBloc _chatBloc;

  // ── Router ───────────────────────────────────────────────────────────────────
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    // Repositories
    _authRepository = AuthRepository(dioClient: _dioClient);
    _studentRepository = StudentRepository(
      dioClient: _dioClient,
      offlineService: _offlineService,
      connectivityService: _connectivityService,
    );
    _teacherRepository = TeacherRepository(
      dioClient: _dioClient,
      offlineService: _offlineService,
      connectivityService: _connectivityService,
    );
    _adminRepository = AdminRepository(
      dioClient: _dioClient,
      offlineService: _offlineService,
      connectivityService: _connectivityService,
    );
    _chatRepository = ChatRepository(
      dioClient: _dioClient,
      connectivityService: _connectivityService,
    );

    // BLoCs
    _authBloc = AuthBloc(authRepository: _authRepository);
    _studentBloc = StudentBloc(repository: _studentRepository);
    _teacherBloc = TeacherBloc(teacherRepository: _teacherRepository);
    _adminBloc = AdminBloc(adminRepository: _adminRepository);
    _chatBloc = ChatBloc(chatRepository: _chatRepository);

    // Router (reads AuthBloc state to drive redirect logic)
    _router = AppRouter.createRouter(_authBloc);

    // Wire 401 responses → navigate to login
    DioClient.onUnauthorized = () => _router.go('/login');

    // Kick off auth session check; splash screen also dispatches this
    _authBloc.add(const AuthCheckRequested());
  }

  @override
  void dispose() {
    _authBloc.close();
    _studentBloc.close();
    _teacherBloc.close();
    _adminBloc.close();
    _chatBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _studentRepository),
        RepositoryProvider.value(value: _teacherRepository),
        RepositoryProvider.value(value: _adminRepository),
        RepositoryProvider.value(value: _chatRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider.value(value: _studentBloc),
          BlocProvider.value(value: _teacherBloc),
          BlocProvider.value(value: _adminBloc),
          BlocProvider.value(value: _chatBloc),
        ],
        child: MaterialApp.router(
          title: 'AttendSynx',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: _router,
        ),
      ),
    );
  }
}

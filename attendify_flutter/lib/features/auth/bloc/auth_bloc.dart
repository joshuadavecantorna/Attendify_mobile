import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'auth_event.dart';
import 'auth_state.dart';
import '../data/auth_repository.dart';
import '../../../core/models/user_model.dart';
import '../../../core/constants/app_constants.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await _authRepository.login(
        email: event.email,
        password: event.password,
        role: event.role,
      );

      // Store token and user data
      await _storage.write(
        key: AppConstants.authTokenKey,
        value: response['token'],
      );
      await _storage.write(
        key: AppConstants.userDataKey,
        value: jsonEncode(response['user']),
      );

      final user = User.fromJson(response['user']);
      
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await _authRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
        passwordConfirmation: event.passwordConfirmation,
        role: event.role,
      );

      await _storage.write(
        key: AppConstants.authTokenKey,
        value: response['token'],
      );
      await _storage.write(
        key: AppConstants.userDataKey,
        value: jsonEncode(response['user']),
      );

      final user = User.fromJson(response['user']);
      
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.logout();
      await _storage.delete(key: AppConstants.authTokenKey);
      await _storage.delete(key: AppConstants.userDataKey);
      emit(const AuthUnauthenticated());
    } catch (e) {
      // Even if logout fails on server, clear local data
      await _storage.delete(key: AppConstants.authTokenKey);
      await _storage.delete(key: AppConstants.userDataKey);
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final token = await _storage.read(key: AppConstants.authTokenKey);
      final userDataString = await _storage.read(key: AppConstants.userDataKey);

      if (token != null && userDataString != null) {
        final userData = jsonDecode(userDataString);
        final user = User.fromJson(userData);
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

}

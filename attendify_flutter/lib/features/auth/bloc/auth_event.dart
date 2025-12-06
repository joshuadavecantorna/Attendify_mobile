import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String role;

  const AuthLoginRequested({
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, role];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String role;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.role,
  });

  @override
  List<Object?> get props => [name, email, password, passwordConfirmation, role];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

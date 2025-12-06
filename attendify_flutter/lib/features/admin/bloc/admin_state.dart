import 'package:equatable/equatable.dart';
import '../data/models/admin_models.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

// Dashboard States
class SystemStatsLoaded extends AdminState {
  final SystemStats stats;

  const SystemStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class AttendanceReportLoaded extends AdminState {
  final AttendanceReport report;

  const AttendanceReportLoaded({required this.report});

  @override
  List<Object?> get props => [report];
}

// User Management States
class UsersLoaded extends AdminState {
  final List<AdminUser> users;

  const UsersLoaded({required this.users});

  @override
  List<Object?> get props => [users];
}

class UserLoaded extends AdminState {
  final AdminUser user;

  const UserLoaded({required this.user});

  @override
  List<Object?> get props => [user];
}

class UserCreated extends AdminState {
  final AdminUser user;

  const UserCreated({required this.user});

  @override
  List<Object?> get props => [user];
}

class UserUpdated extends AdminState {
  final AdminUser user;

  const UserUpdated({required this.user});

  @override
  List<Object?> get props => [user];
}

class UserDeleted extends AdminState {
  final String message;

  const UserDeleted({required this.message});

  @override
  List<Object?> get props => [message];
}

// Class Management States
class ClassesLoaded extends AdminState {
  final List<AdminClass> classes;

  const ClassesLoaded({required this.classes});

  @override
  List<Object?> get props => [classes];
}

class ClassLoaded extends AdminState {
  final AdminClass classData;

  const ClassLoaded({required this.classData});

  @override
  List<Object?> get props => [classData];
}

class ClassCreated extends AdminState {
  final AdminClass classData;

  const ClassCreated({required this.classData});

  @override
  List<Object?> get props => [classData];
}

class ClassUpdated extends AdminState {
  final AdminClass classData;

  const ClassUpdated({required this.classData});

  @override
  List<Object?> get props => [classData];
}

class ClassDeleted extends AdminState {
  final String message;

  const ClassDeleted({required this.message});

  @override
  List<Object?> get props => [message];
}

// Enrollment States
class EnrollmentsLoaded extends AdminState {
  final List<StudentEnrollment> enrollments;

  const EnrollmentsLoaded({required this.enrollments});

  @override
  List<Object?> get props => [enrollments];
}

class StudentEnrolled extends AdminState {
  final String message;

  const StudentEnrolled({required this.message});

  @override
  List<Object?> get props => [message];
}

class StudentUnenrolled extends AdminState {
  final String message;

  const StudentUnenrolled({required this.message});

  @override
  List<Object?> get props => [message];
}

class AdminError extends AdminState {
  final String message;

  const AdminError({required this.message});

  @override
  List<Object?> get props => [message];
}

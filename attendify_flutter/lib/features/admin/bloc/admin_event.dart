import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

// Dashboard Events
class LoadSystemStats extends AdminEvent {
  const LoadSystemStats();
}

class LoadAttendanceReport extends AdminEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadAttendanceReport({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

// User Management Events
class LoadAllUsers extends AdminEvent {
  final String? role;

  const LoadAllUsers({this.role});

  @override
  List<Object?> get props => [role];
}

class LoadUserById extends AdminEvent {
  final int userId;

  const LoadUserById({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class CreateUser extends AdminEvent {
  final String name;
  final String email;
  final String password;
  final String role;
  final String? studentId;
  final String? teacherId;

  const CreateUser({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.studentId,
    this.teacherId,
  });

  @override
  List<Object?> get props => [name, email, password, role, studentId, teacherId];
}

class UpdateUser extends AdminEvent {
  final int userId;
  final String? name;
  final String? email;
  final String? role;
  final String? password;

  const UpdateUser({
    required this.userId,
    this.name,
    this.email,
    this.role,
    this.password,
  });

  @override
  List<Object?> get props => [userId, name, email, role, password];
}

class DeleteUser extends AdminEvent {
  final int userId;

  const DeleteUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Class Management Events
class LoadAllClasses extends AdminEvent {
  const LoadAllClasses();
}

class LoadClassById extends AdminEvent {
  final int classId;

  const LoadClassById({required this.classId});

  @override
  List<Object?> get props => [classId];
}

class CreateClass extends AdminEvent {
  final String name;
  final String code;
  final String? description;
  final String? schedule;
  final int? teacherId;

  const CreateClass({
    required this.name,
    required this.code,
    this.description,
    this.schedule,
    this.teacherId,
  });

  @override
  List<Object?> get props => [name, code, description, schedule, teacherId];
}

class UpdateClass extends AdminEvent {
  final int classId;
  final String? name;
  final String? code;
  final String? description;
  final String? schedule;
  final int? teacherId;

  const UpdateClass({
    required this.classId,
    this.name,
    this.code,
    this.description,
    this.schedule,
    this.teacherId,
  });

  @override
  List<Object?> get props => [classId, name, code, description, schedule, teacherId];
}

class DeleteClass extends AdminEvent {
  final int classId;

  const DeleteClass({required this.classId});

  @override
  List<Object?> get props => [classId];
}

// Enrollment Events
class LoadClassEnrollments extends AdminEvent {
  final int classId;

  const LoadClassEnrollments({required this.classId});

  @override
  List<Object?> get props => [classId];
}

class EnrollStudent extends AdminEvent {
  final int classId;
  final int studentId;

  const EnrollStudent({
    required this.classId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [classId, studentId];
}

class UnenrollStudent extends AdminEvent {
  final int classId;
  final int studentId;

  const UnenrollStudent({
    required this.classId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [classId, studentId];
}

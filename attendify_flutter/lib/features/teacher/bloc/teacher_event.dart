import 'package:equatable/equatable.dart';

abstract class TeacherEvent extends Equatable {
  const TeacherEvent();

  @override
  List<Object?> get props => [];
}

class LoadTeacherDashboard extends TeacherEvent {
  const LoadTeacherDashboard();
}

class LoadTeacherClasses extends TeacherEvent {
  const LoadTeacherClasses();
}

class LoadClassStudents extends TeacherEvent {
  final int classId;

  const LoadClassStudents({required this.classId});

  @override
  List<Object?> get props => [classId];
}

class CreateAttendanceSession extends TeacherEvent {
  final int classId;
  final DateTime startTime;
  final DateTime endTime;
  final bool generateQR;

  const CreateAttendanceSession({
    required this.classId,
    required this.startTime,
    required this.endTime,
    this.generateQR = true,
  });

  @override
  List<Object?> get props => [classId, startTime, endTime, generateQR];
}

class LoadAttendanceSessions extends TeacherEvent {
  final int? classId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadAttendanceSessions({
    this.classId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [classId, startDate, endDate];
}

class MarkStudentAttendance extends TeacherEvent {
  final int sessionId;
  final int studentId;
  final String status;

  const MarkStudentAttendance({
    required this.sessionId,
    required this.studentId,
    required this.status,
  });

  @override
  List<Object?> get props => [sessionId, studentId, status];
}

class EndAttendanceSession extends TeacherEvent {
  final int sessionId;

  const EndAttendanceSession({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class LoadPendingExcuses extends TeacherEvent {
  const LoadPendingExcuses();
}

class LoadAllExcuses extends TeacherEvent {
  const LoadAllExcuses();
}

class ReviewExcuseRequest extends TeacherEvent {
  final int excuseId;
  final String status;
  final String? response;

  const ReviewExcuseRequest({
    required this.excuseId,
    required this.status,
    this.response,
  });

  @override
  List<Object?> get props => [excuseId, status, response];
}

class LoadClassAttendanceReport extends TeacherEvent {
  final int classId;

  const LoadClassAttendanceReport({required this.classId});

  @override
  List<Object?> get props => [classId];
}

import 'package:equatable/equatable.dart';
import '../data/models/teacher_models.dart';

abstract class TeacherState extends Equatable {
  const TeacherState();

  @override
  List<Object?> get props => [];
}

class TeacherInitial extends TeacherState {
  const TeacherInitial();
}

class TeacherLoading extends TeacherState {
  const TeacherLoading();
}

class TeacherDashboardLoaded extends TeacherState {
  final Map<String, dynamic> dashboardData;

  const TeacherDashboardLoaded({required this.dashboardData});

  @override
  List<Object?> get props => [dashboardData];
}

class TeacherClassesLoaded extends TeacherState {
  final List<TeacherClass> classes;

  const TeacherClassesLoaded({required this.classes});

  @override
  List<Object?> get props => [classes];
}

class ClassStudentsLoaded extends TeacherState {
  final List<ClassStudent> students;
  final int classId;

  const ClassStudentsLoaded({
    required this.students,
    required this.classId,
  });

  @override
  List<Object?> get props => [students, classId];
}

class AttendanceSessionCreated extends TeacherState {
  final AttendanceSession session;

  const AttendanceSessionCreated({required this.session});

  @override
  List<Object?> get props => [session];
}

class AttendanceSessionsLoaded extends TeacherState {
  final List<AttendanceSession> sessions;

  const AttendanceSessionsLoaded({required this.sessions});

  @override
  List<Object?> get props => [sessions];
}

class AttendanceMarked extends TeacherState {
  final String message;

  const AttendanceMarked({required this.message});

  @override
  List<Object?> get props => [message];
}

class AttendanceSessionEnded extends TeacherState {
  final String message;

  const AttendanceSessionEnded({required this.message});

  @override
  List<Object?> get props => [message];
}

class PendingExcusesLoaded extends TeacherState {
  final List<TeacherExcuseRequest> excuses;

  const PendingExcusesLoaded({required this.excuses});

  @override
  List<Object?> get props => [excuses];
}

class AllExcusesLoaded extends TeacherState {
  final List<TeacherExcuseRequest> excuses;

  const AllExcusesLoaded({required this.excuses});

  @override
  List<Object?> get props => [excuses];
}

class ExcuseRequestReviewed extends TeacherState {
  final String message;

  const ExcuseRequestReviewed({required this.message});

  @override
  List<Object?> get props => [message];
}

class ClassAttendanceReportLoaded extends TeacherState {
  final Map<String, dynamic> reportData;

  const ClassAttendanceReportLoaded({required this.reportData});

  @override
  List<Object?> get props => [reportData];
}

class TeacherError extends TeacherState {
  final String message;

  const TeacherError({required this.message});

  @override
  List<Object?> get props => [message];
}

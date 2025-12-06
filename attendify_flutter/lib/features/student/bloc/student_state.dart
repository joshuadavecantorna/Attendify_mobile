import 'package:equatable/equatable.dart';
import '../data/models/student_models.dart';

abstract class StudentState extends Equatable {
  const StudentState();

  @override
  List<Object?> get props => [];
}

class StudentInitial extends StudentState {
  const StudentInitial();
}

class StudentLoading extends StudentState {
  const StudentLoading();
}

class StudentDashboardLoaded extends StudentState {
  final List<ClassModel> classes;
  final Map<String, dynamic> attendanceSummary;
  final List<ClassModel> todaySchedule;

  const StudentDashboardLoaded({
    required this.classes,
    required this.attendanceSummary,
    required this.todaySchedule,
  });

  @override
  List<Object?> get props => [classes, attendanceSummary, todaySchedule];
}

class StudentClassesLoaded extends StudentState {
  final List<ClassModel> classes;

  const StudentClassesLoaded({required this.classes});

  @override
  List<Object?> get props => [classes];
}

class AttendanceRecordsLoaded extends StudentState {
  final List<AttendanceRecord> records;

  const AttendanceRecordsLoaded({required this.records});

  @override
  List<Object?> get props => [records];
}

class TodayScheduleLoaded extends StudentState {
  final List<ClassModel> schedule;

  const TodayScheduleLoaded({required this.schedule});

  @override
  List<Object?> get props => [schedule];
}

class CheckInSuccess extends StudentState {
  final String message;
  final Map<String, dynamic> data;

  const CheckInSuccess({
    required this.message,
    required this.data,
  });

  @override
  List<Object?> get props => [message, data];
}

class ExcuseRequestsLoaded extends StudentState {
  final List<ExcuseRequest> requests;

  const ExcuseRequestsLoaded({required this.requests});

  @override
  List<Object?> get props => [requests];
}

class ExcuseRequestSubmitted extends StudentState {
  final ExcuseRequest request;

  const ExcuseRequestSubmitted({required this.request});

  @override
  List<Object?> get props => [request];
}

class StudentError extends StudentState {
  final String message;

  const StudentError({required this.message});

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';

abstract class StudentEvent extends Equatable {
  const StudentEvent();

  @override
  List<Object?> get props => [];
}

class LoadStudentDashboard extends StudentEvent {
  const LoadStudentDashboard();
}

class LoadStudentClasses extends StudentEvent {
  const LoadStudentClasses();
}

class LoadAttendanceRecords extends StudentEvent {
  final int? classId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadAttendanceRecords({
    this.classId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [classId, startDate, endDate];
}

class LoadTodaySchedule extends StudentEvent {
  const LoadTodaySchedule();
}

class CheckInWithQR extends StudentEvent {
  final String qrData;

  const CheckInWithQR({required this.qrData});

  @override
  List<Object?> get props => [qrData];
}

class LoadExcuseRequests extends StudentEvent {
  const LoadExcuseRequests();
}

class SubmitExcuseRequest extends StudentEvent {
  final int attendanceSessionId;
  final String reason;
  final String? attachmentPath;

  const SubmitExcuseRequest({
    required this.attendanceSessionId,
    required this.reason,
    this.attachmentPath,
  });

  @override
  List<Object?> get props => [attendanceSessionId, reason, attachmentPath];
}

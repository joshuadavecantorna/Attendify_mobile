import 'package:equatable/equatable.dart';

/// Class model matching Laravel backend
class ClassModel extends Equatable {
  final int id;
  final String name;
  final String classCode;
  final String? subject;
  final String? scheduleTime;
  final String? scheduleDays;
  final String? room;
  final int? teacherId;
  final String? teacherName;

  const ClassModel({
    required this.id,
    required this.name,
    required this.classCode,
    this.subject,
    this.scheduleTime,
    this.scheduleDays,
    this.room,
    this.teacherId,
    this.teacherName,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as int,
      name: json['name'] as String,
      classCode: json['class_code'] as String,
      subject: json['subject'] as String?,
      scheduleTime: json['schedule_time'] as String?,
      scheduleDays: json['schedule_days'] as String?,
      room: json['room'] as String?,
      teacherId: json['teacher_id'] as int?,
      teacherName: json['teacher_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'class_code': classCode,
      'subject': subject,
      'schedule_time': scheduleTime,
      'schedule_days': scheduleDays,
      'room': room,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        classCode,
        subject,
        scheduleTime,
        scheduleDays,
        room,
        teacherId,
        teacherName,
      ];
}

/// Attendance record model
class AttendanceRecord extends Equatable {
  final int id;
  final int studentId;
  final int attendanceSessionId;
  final String status;
  final DateTime? checkedInAt;
  final String? sessionName;
  final String? className;
  final DateTime? createdAt;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.attendanceSessionId,
    required this.status,
    this.checkedInAt,
    this.sessionName,
    this.className,
    this.createdAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      attendanceSessionId: json['attendance_session_id'] as int,
      status: json['status'] as String,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'] as String)
          : null,
      sessionName: json['session_name'] as String?,
      className: json['class_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        attendanceSessionId,
        status,
        checkedInAt,
        sessionName,
        className,
        createdAt,
      ];
}

/// Excuse request model
class ExcuseRequest extends Equatable {
  final int id;
  final int studentId;
  final int attendanceSessionId;
  final String reason;
  final String status;
  final String? teacherResponse;
  final String? className;
  final DateTime? sessionDate;
  final DateTime createdAt;

  const ExcuseRequest({
    required this.id,
    required this.studentId,
    required this.attendanceSessionId,
    required this.reason,
    required this.status,
    this.teacherResponse,
    this.className,
    this.sessionDate,
    required this.createdAt,
  });

  factory ExcuseRequest.fromJson(Map<String, dynamic> json) {
    return ExcuseRequest(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      attendanceSessionId: json['attendance_session_id'] as int,
      reason: json['reason'] as String,
      status: json['status'] as String,
      teacherResponse: json['teacher_response'] as String?,
      className: json['class_name'] as String?,
      sessionDate: json['session_date'] != null
          ? DateTime.parse(json['session_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        attendanceSessionId,
        reason,
        status,
        teacherResponse,
        className,
        sessionDate,
        createdAt,
      ];
}

import 'package:equatable/equatable.dart';

/// Teacher's class with student enrollment info
class TeacherClass extends Equatable {
  final int id;
  final String name;
  final String classCode;
  final String? code;  // Add code property
  final String? schedule;  // Add schedule property
  final String? subject;
  final String? scheduleTime;
  final String? scheduleDays;
  final String? room;
  final int enrolledCount;

  const TeacherClass({
    required this.id,
    required this.name,
    required this.classCode,
    this.code,
    this.schedule,
    this.subject,
    this.scheduleTime,
    this.scheduleDays,
    this.room,
    required this.enrolledCount,
  });

  factory TeacherClass.fromJson(Map<String, dynamic> json) {
    return TeacherClass(
      id: json['id'] as int,
      name: json['name'] as String,
      classCode: json['class_code'] as String,
      code: json['code'] as String? ?? json['class_code'] as String?,
      schedule: json['schedule'] as String?,
      subject: json['subject'] as String?,
      scheduleTime: json['schedule_time'] as String?,
      scheduleDays: json['schedule_days'] as String?,
      room: json['room'] as String?,
      enrolledCount: json['enrolled_count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        classCode,
        code,
        schedule,
        subject,
        scheduleTime,
        scheduleDays,
        room,
        enrolledCount,
      ];
}

/// Attendance session
class AttendanceSession extends Equatable {
  final int id;
  final int classId;
  final String? className;
  final DateTime startTime;
  final DateTime endTime;
  final String? qrCode;
  final String status;
  final int presentCount;
  final int absentCount;
  final int lateCount;

  const AttendanceSession({
    required this.id,
    required this.classId,
    this.className,
    required this.startTime,
    required this.endTime,
    this.qrCode,
    required this.status,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'] as int,
      classId: json['class_id'] as int,
      className: json['class_name'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      qrCode: json['qr_code'] as String?,
      status: json['status'] as String,
      presentCount: json['present_count'] as int? ?? 0,
      absentCount: json['absent_count'] as int? ?? 0,
      lateCount: json['late_count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        classId,
        className,
        startTime,
        endTime,
        qrCode,
        status,
        presentCount,
        absentCount,
        lateCount,
      ];
}

/// Student in class
class ClassStudent extends Equatable {
  final int id;
  final String studentId;
  final String name;
  final String email;
  final String? avatar;
  final double attendanceRate;
  final int presentCount;
  final int absentCount;
  final int lateCount;

  const ClassStudent({
    required this.id,
    required this.studentId,
    required this.name,
    required this.email,
    this.avatar,
    required this.attendanceRate,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
  });

  factory ClassStudent.fromJson(Map<String, dynamic> json) {
    return ClassStudent(
      id: json['id'] as int,
      studentId: json['student_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0.0,
      presentCount: json['present_count'] as int? ?? 0,
      absentCount: json['absent_count'] as int? ?? 0,
      lateCount: json['late_count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        name,
        email,
        avatar,
        attendanceRate,
        presentCount,
        absentCount,
        lateCount,
      ];
}

/// Teacher excuse request (from student models but with additional info)
class TeacherExcuseRequest extends Equatable {
  final int id;
  final int studentId;
  final String studentName;
  final int attendanceSessionId;
  final String? className;
  final String reason;
  final String status;
  final String? teacherResponse;
  final String? response;  // Add response alias
  final DateTime? sessionDate;
  final DateTime? date;  // Add date alias
  final DateTime createdAt;
  final String? attachmentUrl;
  final String? type;  // Add type property

  const TeacherExcuseRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.attendanceSessionId,
    this.className,
    required this.reason,
    required this.status,
    this.teacherResponse,
    this.response,
    this.sessionDate,
    this.date,
    required this.createdAt,
    this.attachmentUrl,
    this.type,
  });

  factory TeacherExcuseRequest.fromJson(Map<String, dynamic> json) {
    final sessionDate = json['session_date'] != null
        ? DateTime.parse(json['session_date'] as String)
        : null;
    final teacherResponse = json['teacher_response'] as String?;
    
    return TeacherExcuseRequest(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      studentName: json['student_name'] as String,
      attendanceSessionId: json['attendance_session_id'] as int,
      className: json['class_name'] as String?,
      reason: json['reason'] as String,
      status: json['status'] as String,
      teacherResponse: teacherResponse,
      response: json['response'] as String? ?? teacherResponse,
      sessionDate: sessionDate,
      date: sessionDate,  // Use same value for date alias
      createdAt: DateTime.parse(json['created_at'] as String),
      attachmentUrl: json['attachment_url'] as String?,
      type: json['type'] as String? ?? 'excuse',
    );
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        studentName,
        attendanceSessionId,
        className,
        reason,
        status,
        teacherResponse,
        sessionDate,
        createdAt,
        attachmentUrl,
      ];
}

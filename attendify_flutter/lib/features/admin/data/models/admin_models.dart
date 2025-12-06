import 'package:equatable/equatable.dart';

class AdminUser extends Equatable {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? studentId;
  final String? teacherId;
  final DateTime createdAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.teacherId,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      studentId: json['student_id']?.toString(),
      teacherId: json['teacher_id']?.toString(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'student_id': studentId,
      'teacher_id': teacherId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, email, role, studentId, teacherId, createdAt];
}

class AdminClass extends Equatable {
  final int id;
  final String name;
  final String code;
  final String? description;
  final String? schedule;
  final int? teacherId;
  final String? teacherName;
  final int enrolledCount;
  final DateTime createdAt;

  const AdminClass({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.schedule,
    this.teacherId,
    this.teacherName,
    required this.enrolledCount,
    required this.createdAt,
  });

  factory AdminClass.fromJson(Map<String, dynamic> json) {
    return AdminClass(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      description: json['description'],
      schedule: json['schedule'],
      teacherId: json['teacher_id'],
      teacherName: json['teacher_name'],
      enrolledCount: json['enrolled_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'schedule': schedule,
      'teacher_id': teacherId,
      'enrolled_count': enrolledCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, code, description, schedule, teacherId, teacherName, enrolledCount, createdAt];
}

class SystemStats extends Equatable {
  final int totalUsers;
  final int totalStudents;
  final int totalTeachers;
  final int totalClasses;
  final int totalSessions;
  final int todaySessions;
  final double averageAttendance;
  final int pendingExcuses;

  const SystemStats({
    required this.totalUsers,
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalClasses,
    required this.totalSessions,
    required this.todaySessions,
    required this.averageAttendance,
    required this.pendingExcuses,
  });

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    return SystemStats(
      totalUsers: json['total_users'] ?? 0,
      totalStudents: json['total_students'] ?? 0,
      totalTeachers: json['total_teachers'] ?? 0,
      totalClasses: json['total_classes'] ?? 0,
      totalSessions: json['total_sessions'] ?? 0,
      todaySessions: json['today_sessions'] ?? 0,
      averageAttendance: (json['average_attendance'] ?? 0).toDouble(),
      pendingExcuses: json['pending_excuses'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        totalUsers,
        totalStudents,
        totalTeachers,
        totalClasses,
        totalSessions,
        todaySessions,
        averageAttendance,
        pendingExcuses,
      ];
}

class StudentEnrollment extends Equatable {
  final int id;
  final int studentId;
  final String studentName;
  final String studentEmail;
  final int classId;
  final String className;
  final DateTime enrolledAt;

  const StudentEnrollment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.classId,
    required this.className,
    required this.enrolledAt,
  });

  factory StudentEnrollment.fromJson(Map<String, dynamic> json) {
    return StudentEnrollment(
      id: json['id'],
      studentId: json['student_id'],
      studentName: json['student_name'],
      studentEmail: json['student_email'],
      classId: json['class_id'],
      className: json['class_name'],
      enrolledAt: DateTime.parse(json['enrolled_at']),
    );
  }

  @override
  List<Object?> get props => [id, studentId, studentName, studentEmail, classId, className, enrolledAt];
}

class AttendanceReport extends Equatable {
  final String period;
  final int totalSessions;
  final int totalPresent;
  final int totalAbsent;
  final int totalLate;
  final double attendanceRate;
  final List<Map<String, dynamic>> classBreakdown;

  const AttendanceReport({
    required this.period,
    required this.totalSessions,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalLate,
    required this.attendanceRate,
    required this.classBreakdown,
  });

  factory AttendanceReport.fromJson(Map<String, dynamic> json) {
    return AttendanceReport(
      period: json['period'],
      totalSessions: json['total_sessions'] ?? 0,
      totalPresent: json['total_present'] ?? 0,
      totalAbsent: json['total_absent'] ?? 0,
      totalLate: json['total_late'] ?? 0,
      attendanceRate: (json['attendance_rate'] ?? 0).toDouble(),
      classBreakdown: (json['class_breakdown'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }

  @override
  List<Object?> get props => [period, totalSessions, totalPresent, totalAbsent, totalLate, attendanceRate, classBreakdown];
}

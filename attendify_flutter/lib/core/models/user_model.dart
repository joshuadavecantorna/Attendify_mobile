import 'package:equatable/equatable.dart';

/// User model matching Laravel backend
class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? avatar;
  final int? studentId;
  final int? teacherId;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    this.studentId,
    this.teacherId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      avatar: json['avatar'] as String?,
      studentId: json['student_id'] as int?,
      teacherId: json['teacher_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar': avatar,
      'student_id': studentId,
      'teacher_id': teacherId,
    };
  }

  @override
  List<Object?> get props => [id, name, email, role, avatar, studentId, teacherId];
}

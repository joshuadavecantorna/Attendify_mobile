import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      content: json['content'] ?? json['message'] ?? '',
      isUser: json['is_user'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isStreaming: json['is_streaming'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'is_streaming': isStreaming,
    };
  }

  @override
  List<Object?> get props => [id, content, isUser, timestamp, isStreaming];
}

class ChatSession extends Equatable {
  final String id;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatSession({
    required this.id,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  ChatSession copyWith({
    String? id,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id']?.toString() ?? '',
      messages: (json['messages'] as List?)
              ?.map((m) => ChatMessage.fromJson(m))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messages': messages.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, messages, createdAt, updatedAt];
}

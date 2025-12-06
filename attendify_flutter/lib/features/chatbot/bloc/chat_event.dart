import 'package:equatable/equatable.dart';
import '../data/models/chat_models.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatHistory extends ChatEvent {
  final String? sessionId;

  const LoadChatHistory({this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class SendMessage extends ChatEvent {
  final String message;
  final String? sessionId;
  final bool useStreaming;

  const SendMessage({
    required this.message,
    this.sessionId,
    this.useStreaming = true,
  });

  @override
  List<Object?> get props => [message, sessionId, useStreaming];
}

class UpdateStreamingMessage extends ChatEvent {
  final String messageId;
  final String content;

  const UpdateStreamingMessage({
    required this.messageId,
    required this.content,
  });

  @override
  List<Object?> get props => [messageId, content];
}

class CompleteStreamingMessage extends ChatEvent {
  final String messageId;

  const CompleteStreamingMessage({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class CreateNewSession extends ChatEvent {
  const CreateNewSession();
}

class LoadSessions extends ChatEvent {
  const LoadSessions();
}

class DeleteSession extends ChatEvent {
  final String sessionId;

  const DeleteSession({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class ClearHistory extends ChatEvent {
  final String? sessionId;

  const ClearHistory({this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class AddUserMessage extends ChatEvent {
  final ChatMessage message;

  const AddUserMessage({required this.message});

  @override
  List<Object?> get props => [message];
}

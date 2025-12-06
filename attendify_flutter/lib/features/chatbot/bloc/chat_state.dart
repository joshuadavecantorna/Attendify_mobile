import 'package:equatable/equatable.dart';
import '../data/models/chat_models.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final String? currentSessionId;
  final bool isSending;

  const ChatLoaded({
    required this.messages,
    this.currentSessionId,
    this.isSending = false,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    String? currentSessionId,
    bool? isSending,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [messages, currentSessionId, isSending];
}

class SessionsLoaded extends ChatState {
  final List<ChatSession> sessions;

  const SessionsLoaded({required this.sessions});

  @override
  List<Object?> get props => [sessions];
}

class SessionCreated extends ChatState {
  final ChatSession session;

  const SessionCreated({required this.session});

  @override
  List<Object?> get props => [session];
}

class SessionDeleted extends ChatState {
  final String message;

  const SessionDeleted({required this.message});

  @override
  List<Object?> get props => [message];
}

class HistoryCleared extends ChatState {
  final String message;

  const HistoryCleared({required this.message});

  @override
  List<Object?> get props => [message];
}

class MessageSent extends ChatState {
  final ChatMessage message;

  const MessageSent({required this.message});

  @override
  List<Object?> get props => [message];
}

class StreamingInProgress extends ChatState {
  final String messageId;
  final String currentContent;

  const StreamingInProgress({
    required this.messageId,
    required this.currentContent,
  });

  @override
  List<Object?> get props => [messageId, currentContent];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}

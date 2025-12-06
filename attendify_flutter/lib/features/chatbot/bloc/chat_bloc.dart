import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/chat_repository.dart';
import '../data/models/chat_models.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _streamSubscription;

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatInitial()) {
    on<LoadChatHistory>(_onLoadChatHistory);
    on<SendMessage>(_onSendMessage);
    on<UpdateStreamingMessage>(_onUpdateStreamingMessage);
    on<CompleteStreamingMessage>(_onCompleteStreamingMessage);
    on<CreateNewSession>(_onCreateNewSession);
    on<LoadSessions>(_onLoadSessions);
    on<DeleteSession>(_onDeleteSession);
    on<ClearHistory>(_onClearHistory);
    on<AddUserMessage>(_onAddUserMessage);
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistory event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatLoading());
      final messages = await _chatRepository.getChatHistory(
        sessionId: event.sessionId,
      );
      emit(ChatLoaded(
        messages: messages,
        currentSessionId: event.sessionId,
      ));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // Add user message immediately
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: event.message,
        isUser: true,
        timestamp: DateTime.now(),
      );

      final currentMessages = state is ChatLoaded
          ? List<ChatMessage>.from((state as ChatLoaded).messages)
          : <ChatMessage>[];
      currentMessages.add(userMessage);

      emit(ChatLoaded(
        messages: currentMessages,
        currentSessionId: event.sessionId,
        isSending: true,
      ));

      if (event.useStreaming) {
        // Create placeholder for streaming message
        final streamingMessageId = 'streaming_${DateTime.now().millisecondsSinceEpoch}';
        final streamingMessage = ChatMessage(
          id: streamingMessageId,
          content: '',
          isUser: false,
          timestamp: DateTime.now(),
          isStreaming: true,
        );
        currentMessages.add(streamingMessage);

        emit(ChatLoaded(
          messages: currentMessages,
          currentSessionId: event.sessionId,
          isSending: true,
        ));

        // Listen to streaming response
        _streamSubscription?.cancel();
        _streamSubscription = _chatRepository
            .sendMessage(
          message: event.message,
          sessionId: event.sessionId,
        )
            .listen(
          (chunk) {
            add(UpdateStreamingMessage(
              messageId: streamingMessageId,
              content: chunk,
            ));
          },
          onDone: () {
            add(CompleteStreamingMessage(messageId: streamingMessageId));
          },
          onError: (error) {
            emit(ChatError(message: error.toString()));
          },
        );
      } else {
        // Non-streaming response
        final response = await _chatRepository.sendMessageSync(
          message: event.message,
          sessionId: event.sessionId,
        );
        currentMessages.add(response);

        emit(ChatLoaded(
          messages: currentMessages,
          currentSessionId: event.sessionId,
          isSending: false,
        ));
      }
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onUpdateStreamingMessage(
    UpdateStreamingMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final messages = List<ChatMessage>.from(currentState.messages);
      
      final index = messages.indexWhere((m) => m.id == event.messageId);
      if (index != -1) {
        final existingMessage = messages[index];
        messages[index] = existingMessage.copyWith(
          content: existingMessage.content + event.content,
        );
        
        emit(currentState.copyWith(messages: messages));
      }
    }
  }

  Future<void> _onCompleteStreamingMessage(
    CompleteStreamingMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final messages = List<ChatMessage>.from(currentState.messages);
      
      final index = messages.indexWhere((m) => m.id == event.messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(isStreaming: false);
        emit(currentState.copyWith(messages: messages, isSending: false));
      }
    }
  }

  Future<void> _onCreateNewSession(
    CreateNewSession event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatLoading());
      final session = await _chatRepository.createSession();
      emit(SessionCreated(session: session));
      // Load the new session
      add(LoadChatHistory(sessionId: session.id));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onLoadSessions(
    LoadSessions event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatLoading());
      final sessions = await _chatRepository.getSessions();
      emit(SessionsLoaded(sessions: sessions));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onDeleteSession(
    DeleteSession event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.deleteSession(event.sessionId);
      emit(const SessionDeleted(message: 'Session deleted successfully'));
      add(const LoadSessions());
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onClearHistory(
    ClearHistory event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.clearHistory(sessionId: event.sessionId);
      emit(const HistoryCleared(message: 'Chat history cleared'));
      add(LoadChatHistory(sessionId: event.sessionId));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onAddUserMessage(
    AddUserMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final messages = List<ChatMessage>.from(currentState.messages);
      messages.add(event.message);
      emit(currentState.copyWith(messages: messages));
    }
  }
}

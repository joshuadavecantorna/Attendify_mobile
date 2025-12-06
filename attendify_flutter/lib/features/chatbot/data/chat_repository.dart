import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/connectivity_service.dart';
import 'models/chat_models.dart';

class ChatRepository {
  final DioClient _dioClient;
  final ConnectivityService _connectivityService;

  ChatRepository({
    required DioClient dioClient,
    required ConnectivityService connectivityService,
  })  : _dioClient = dioClient,
        _connectivityService = connectivityService;

  // Send message and get streaming response
  Stream<String> sendMessage({
    required String message,
    String? sessionId,
  }) async* {
    // Check if online - Ollama requires internet connection
    if (!_connectivityService.isOnline) {
      throw 'AI chatbot is unavailable offline. Ollama requires an internet connection.';
    }

    try {
      final response = await _dioClient.dio.post(
        '/chatbot/message',
        data: {
          'message': message,
          if (sessionId != null) 'session_id': sessionId,
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream;
      final decoder = utf8.decoder;
      
      await for (final chunk in stream.transform(decoder)) {
        // Parse SSE (Server-Sent Events) format
        if (chunk.startsWith('data: ')) {
          final data = chunk.substring(6).trim();
          if (data == '[DONE]') {
            break;
          }
          try {
            final json = jsonDecode(data);
            if (json['content'] != null) {
              yield json['content'] as String;
            }
          } catch (e) {
            // If not JSON, yield raw data
            yield data;
          }
        } else if (chunk.trim().isNotEmpty) {
          yield chunk;
        }
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Send message (non-streaming)
  Future<ChatMessage> sendMessageSync({
    required String message,
    String? sessionId,
  }) async {
    // Check if online - Ollama requires internet connection
    if (!_connectivityService.isOnline) {
      throw 'AI chatbot is unavailable offline. Ollama requires an internet connection.';
    }

    try {
      final response = await _dioClient.dio.post(
        '/chatbot/message',
        data: {
          'message': message,
          if (sessionId != null) 'session_id': sessionId,
        },
      );

      return ChatMessage(
        id: response.data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        content: response.data['response'] ?? response.data['message'] ?? '',
        isUser: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get chat history
  Future<List<ChatMessage>> getChatHistory({String? sessionId}) async {
    try {
      final response = await _dioClient.dio.get(
        '/chatbot/history',
        queryParameters: {
          if (sessionId != null) 'session_id': sessionId,
        },
      );

      final messages = (response.data['data'] as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
      return messages;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Create new chat session
  Future<ChatSession> createSession() async {
    try {
      final response = await _dioClient.dio.post('/chatbot/session');
      return ChatSession.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get all chat sessions
  Future<List<ChatSession>> getSessions() async {
    try {
      final response = await _dioClient.dio.get('/chatbot/sessions');
      final sessions = (response.data['data'] as List)
          .map((json) => ChatSession.fromJson(json))
          .toList();
      return sessions;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Delete chat session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _dioClient.dio.delete('/chatbot/session/$sessionId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Clear chat history
  Future<void> clearHistory({String? sessionId}) async {
    try {
      await _dioClient.dio.delete(
        '/chatbot/history',
        queryParameters: {
          if (sessionId != null) 'session_id': sessionId,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error.toString().contains('DioException')) {
      return 'Network error. Please check your connection.';
    }
    return 'An error occurred: ${error.toString()}';
  }
}

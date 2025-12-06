import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../bloc/chat_bloc.dart';
import '../../bloc/chat_event.dart';
import '../../bloc/chat_state.dart';
import '../../data/models/chat_models.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(const LoadChatHistory());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              context.read<ChatBloc>().add(const LoadSessions());
              _showSessionsDialog();
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('Clear History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text('New Session'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'clear') {
                _showClearConfirmation();
              } else if (value == 'new') {
                context.read<ChatBloc>().add(const CreateNewSession());
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline indicator banner
          StreamBuilder<bool>(
            stream: ConnectivityService().connectivityStream,
            initialData: true,
            builder: (context, snapshot) {
              final isOnline = snapshot.data ?? true;
              if (!isOnline) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.orange.shade100,
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off, color: Colors.orange.shade900, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI chatbot unavailable offline - Ollama requires internet connection',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is ChatLoaded) {
                  _scrollToBottom();
                } else if (state is ChatError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is SessionCreated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New chat session created'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (state is HistoryCleared) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ChatLoaded) {
                  if (state.messages.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      return _buildMessageBubble(message);
                    },
                  );
                }

                return _buildEmptyState();
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to AI Assistant!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ask me anything about attendance,\nclasses, or schedules.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('Show my attendance'),
              _buildSuggestionChip('List my classes'),
              _buildSuggestionChip('Today\'s schedule'),
              _buildSuggestionChip('Submit excuse'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _messageController.text = text;
      },
      avatar: const Icon(Icons.lightbulb_outline, size: 18),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      if (message.isStreaming)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isUser ? Colors.white : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isSending = state is ChatLoaded && state.isSending;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  enabled: !isSending,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                onPressed: isSending ? null : _sendMessage,
                mini: true,
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final currentState = context.read<ChatBloc>().state;
    String? sessionId;
    if (currentState is ChatLoaded) {
      sessionId = currentState.currentSessionId;
    }

    context.read<ChatBloc>().add(
          SendMessage(
            message: message,
            sessionId: sessionId,
            useStreaming: true,
          ),
        );

    _messageController.clear();
    _scrollToBottom();
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to clear all messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final currentState = context.read<ChatBloc>().state;
              String? sessionId;
              if (currentState is ChatLoaded) {
                sessionId = currentState.currentSessionId;
              }
              context.read<ChatBloc>().add(ClearHistory(sessionId: sessionId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showSessionsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is SessionsLoaded) {
            return AlertDialog(
              title: const Text('Chat Sessions'),
              content: SizedBox(
                width: double.maxFinite,
                child: state.sessions.isEmpty
                    ? const Center(child: Text('No sessions found'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.sessions.length,
                        itemBuilder: (context, index) {
                          final session = state.sessions[index];
                          return ListTile(
                            leading: const Icon(Icons.chat_bubble_outline),
                            title: Text(
                              'Session ${session.id}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              DateFormat('MMM d, y HH:mm')
                                  .format(session.updatedAt),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                context.read<ChatBloc>().add(
                                      DeleteSession(sessionId: session.id),
                                    );
                              },
                            ),
                            onTap: () {
                              Navigator.pop(dialogContext);
                              context.read<ChatBloc>().add(
                                    LoadChatHistory(sessionId: session.id),
                                  );
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            );
          }
          return const AlertDialog(
            content: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/services/socket/socket_service.dart';
import '../../domain/entities/message_notification.dart';

class MessageThreadPage extends StatefulWidget {
  final MessageNotification message;

  const MessageThreadPage({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  State<MessageThreadPage> createState() => _MessageThreadPageState();
}

class _MessageThreadPageState extends State<MessageThreadPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  final ApiClient _apiClient = ApiClient();
  final SocketService _socketService = SocketService();
  bool _isLoading = false;
  String? _errorMessage;
  final List<_ChatMessage> _dummyMessages = const [
    _ChatMessage(text: 'Hi! Ready for today?', isMe: false, time: '09:00'),
    _ChatMessage(text: 'Yes, I am.', isMe: true, time: '09:01'),
    _ChatMessage(text: 'Great, let us start in 5 minutes.', isMe: false, time: '09:02'),
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initSocket();
  }

  @override
  void dispose() {
    _controller.dispose();
    _socketService.offMessageNew(_handleMessageNew);
    _socketService.leaveThread(widget.message.id);
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Please log in to send messages.';
      });
      return;
    }
    final threadId = widget.message.id;
    if (threadId.isEmpty) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.postJson(
        '/api/v1/threads/$threadId/messages',
        token: token,
        body: {
          'text': text,
        },
      );
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final message = _mapMessage(data);
        setState(() {
          _messages.add(message);
          _controller.clear();
        });
      }
    } on HttpException catch (err) {
      setState(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to send message.';
      });
    }
  }

  Future<void> _loadMessages() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = null;
        _messages
          ..clear()
          ..addAll(_dummyMessages);
      });
      return;
    }
    final threadId = widget.message.id;
    if (threadId.isEmpty) {
      setState(() {
        _errorMessage = null;
        _messages
          ..clear()
          ..addAll(_dummyMessages);
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getJson(
        '/api/v1/threads/$threadId/messages',
        token: token,
      );
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_mapMessage)
            .toList();
        setState(() {
          _messages
            ..clear()
            ..addAll(mapped);
        });
      }
    } on HttpException catch (err) {
      setState(() {
        _errorMessage = err.message;
        if (_messages.isEmpty) {
          _messages
            ..clear()
            ..addAll(_dummyMessages);
        }
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to load messages.';
        if (_messages.isEmpty) {
          _messages
            ..clear()
            ..addAll(_dummyMessages);
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initSocket() {
    _socketService.connect();
    _socketService.joinThread(widget.message.id);
    _socketService.onMessageNew(_handleMessageNew);
  }

  void _handleMessageNew(dynamic payload) {
    if (!mounted || payload is! Map) {
      return;
    }
    final threadId = payload['threadId']?.toString();
    final rawMessage = payload['message'];
    if (threadId != widget.message.id || rawMessage is! Map) {
      return;
    }
    final mapped = _mapMessage(Map<String, dynamic>.from(rawMessage));
    if (mapped.id != null &&
        _messages.any((message) => message.id == mapped.id)) {
      return;
    }
    setState(() {
      _messages.add(mapped);
    });
  }

  _ChatMessage _mapMessage(Map<String, dynamic> message) {
    final sender = message['sender'];
    final senderName =
        sender is Map<String, dynamic> ? sender['name']?.toString() : null;
    final currentName = HiveService.currentUserName ?? '';
    final isMe = senderName != null &&
        currentName.isNotEmpty &&
        senderName.toLowerCase() == currentName.toLowerCase();
    final createdAt = message['createdAt']?.toString();
    return _ChatMessage(
      id: message['_id']?.toString() ?? message['id']?.toString(),
      text: message['text']?.toString() ?? '',
      isMe: isMe,
      time: _formatTime(createdAt),
    );
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 'Just now';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return 'Just now';
    }
    final local = parsed.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.message.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'OpenSans',
          ),
        ),
        actions: [
          Icon(
            widget.message.isOnline ? Icons.circle : Icons.circle_outlined,
            color: widget.message.isOnline
                ? AppColors.primary
                : AppColors.textSecondary,
            size: 12,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.redAccent,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return Align(
                            alignment: message.isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              constraints: const BoxConstraints(maxWidth: 260),
                              decoration: BoxDecoration(
                                color: message.isMe
                                    ? AppColors.primary
                                    : AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: message.isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: message.isMe
                                          ? AppColors.buttonText
                                          : AppColors.textPrimary,
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message.time,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: message.isMe
                                          ? AppColors.buttonText.withOpacity(0.7)
                                          : AppColors.textSecondary,
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String? id;
  final String text;
  final bool isMe;
  final String time;

  const _ChatMessage({
    this.id,
    required this.text,
    required this.isMe,
    required this.time,
  });
}



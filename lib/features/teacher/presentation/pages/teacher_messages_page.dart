import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/services/socket/socket_service.dart';
import '../../../notifications/domain/entities/message_notification.dart';
import '../widgets/teacher_bottom_nav.dart';

class TeacherMessagesPage extends StatefulWidget {
  const TeacherMessagesPage({Key? key}) : super(key: key);

  @override
  State<TeacherMessagesPage> createState() => _TeacherMessagesPageState();
}

class _TeacherMessagesPageState extends State<TeacherMessagesPage> {
  int _currentNavIndex = 3;
  final ApiClient _apiClient = ApiClient();
  final SocketService _socketService = SocketService();
  bool _isLoading = false;
  bool _isRequestsLoading = false;
  String? _errorMessage;
  List<MessageNotification> _threads = [];
  List<_TeacherRequestItem> _requests = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _pollTimer;
  bool _hasLoadedOnce = false;
  final List<MessageNotification> _dummyThreads = const [
    MessageNotification(
      id: 't-thread-1',
      name: 'Aashish Basnet',
      isOnline: true,
      time: '10:05',
      message: 'Can we reschedule today?',
    ),
    MessageNotification(
      id: 't-thread-2',
      name: 'Sita Thapa',
      isOnline: false,
      time: 'Yesterday',
      message: 'Thank you for the notes.',
    ),
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherHome);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherCourses);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherSearch);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherAccount);
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadThreads();
    _loadRequests();
    _startPolling();
    _initSocket();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pollTimer?.cancel();
    _socketService.offThreadNew(_handleThreadNew);
    _socketService.offMessageNew(_handleMessageNew);
    super.dispose();
  }

  Future<void> _loadThreads() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = null;
        _threads = List<MessageNotification>.from(_dummyThreads);
        _hasLoadedOnce = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getJson(
        '/api/v1/threads',
        token: token,
      );
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_mapThread)
            .toList();
        _applyThreadUpdate(mapped);
      } else {
        setState(() {
          _errorMessage = 'Unexpected response format.';
        });
      }
    } on HttpException catch (err) {
      setState(() {
        _errorMessage = err.message;
        if (_threads.isEmpty) {
          _threads = List<MessageNotification>.from(_dummyThreads);
        }
        _hasLoadedOnce = true;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to load messages.';
        if (_threads.isEmpty) {
          _threads = List<MessageNotification>.from(_dummyThreads);
        }
        _hasLoadedOnce = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRequests() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return;
    }
    setState(() {
      _isRequestsLoading = true;
    });
    try {
      final response = await _apiClient.getJson(
        '/api/v1/teacher-requests',
        token: token,
      );
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_TeacherRequestItem.fromJson)
            .where((item) => item.status == 'pending')
            .toList();
        setState(() {
          _requests = mapped;
        });
      }
    } on HttpException {
      // Ignore request errors here to avoid blocking messages UI.
    } catch (_) {
      // Ignore request errors here to avoid blocking messages UI.
    } finally {
      if (mounted) {
        setState(() {
          _isRequestsLoading = false;
        });
      }
    }
  }

  Future<void> _updateRequestStatus(
    _TeacherRequestItem request,
    String status,
  ) async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      await _apiClient.putJson(
        '/api/v1/teacher-requests/${request.id}',
        token: token,
        body: {'status': status},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _requests = _requests.where((item) => item.id != request.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status.')),
      );
      if (status == 'accepted') {
        _loadThreads();
      }
    } on HttpException catch (err) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update request.')),
      );
    }
  }

  void _applyThreadUpdate(List<MessageNotification> incoming) {
    if (!mounted) {
      return;
    }
    if (_hasLoadedOnce) {
      final previous = {for (final thread in _threads) thread.id: thread};
      for (final thread in incoming) {
        final before = previous[thread.id];
        final hasNewMessage =
            before == null || before.message != thread.message;
        if (hasNewMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New message from ${thread.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
          break;
        }
      }
    }
    setState(() {
      _threads = incoming;
      _hasLoadedOnce = true;
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadThreads();
    });
  }

  void _initSocket() {
    _socketService.connect();
    _socketService.joinUser();
    _socketService.onThreadNew(_handleThreadNew);
    _socketService.onMessageNew(_handleMessageNew);
  }

  void _handleThreadNew(dynamic payload) {
    if (!mounted || payload is! Map) {
      return;
    }
    final rawThread = payload['thread'];
    if (rawThread is! Map) {
      return;
    }
    final thread = _mapThread(Map<String, dynamic>.from(rawThread));
    setState(() {
      final index = _threads.indexWhere((t) => t.id == thread.id);
      if (index >= 0) {
        _threads[index] = thread;
      } else {
        _threads.insert(0, thread);
      }
    });
  }

  void _handleMessageNew(dynamic payload) {
    if (!mounted || payload is! Map) {
      return;
    }
    final threadId = payload['threadId']?.toString();
    final rawMessage = payload['message'];
    if (threadId == null || rawMessage is! Map) {
      return;
    }
    final text = rawMessage['text']?.toString() ?? '';
    final time = _formatTime(rawMessage['createdAt']?.toString());
    final index = _threads.indexWhere((t) => t.id == threadId);
    if (index == -1) {
      _loadThreads();
      return;
    }
    final updated = MessageNotification(
      id: _threads[index].id,
      name: _threads[index].name,
      isOnline: _threads[index].isOnline,
      time: time,
      message: text,
      hasAttachment: _threads[index].hasAttachment,
    );
    setState(() {
      _threads.removeAt(index);
      _threads.insert(0, updated);
    });
  }

  List<MessageNotification> get _filteredThreads {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _threads;
    }
    return _threads.where((thread) {
      return thread.name.toLowerCase().contains(query);
    }).toList();
  }

  MessageNotification _mapThread(Map<String, dynamic> thread) {
    final participants = thread['participants'];
    final currentName = HiveService.currentUserName ?? '';
    String name = 'Conversation';
    if (participants is List) {
      for (final participant in participants) {
        final user = participant is Map<String, dynamic> ? participant : null;
        final userName = user?['name']?.toString();
        if (userName != null && userName.isNotEmpty) {
          if (currentName.isNotEmpty &&
              userName.toLowerCase() == currentName.toLowerCase()) {
            continue;
          }
          name = userName;
          break;
        }
      }
      if (name == 'Conversation' && participants.isNotEmpty) {
        final user = participants.first is Map<String, dynamic> ? participants.first : null;
        final userName = user?['name']?.toString();
        if (userName != null && userName.isNotEmpty) {
          name = userName;
        }
      }
    }

    final createdAt = thread['createdAt']?.toString();
    return MessageNotification(
      id: thread['_id']?.toString() ?? thread['id']?.toString() ?? '',
      name: name,
      isOnline: false,
      time: _formatTime(createdAt),
      message: thread['lastMessage']?.toString() ?? 'No messages yet.',
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
    final threads = _filteredThreads;
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.teacherHome,
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.teacherBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.teacherPrimaryDark),
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.teacherHome,
              (route) => false,
            ),
          ),
          title: const Text(
            'Messages',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.teacherPrimaryDark,
              fontFamily: 'Inter',
            ),
          ),
        ),
        body: Column(
          children: [
            if (_isRequestsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_requests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New requests',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._requests.map((request) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.teacherSurface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.teacherChip,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.teacherPrimaryDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.studentName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    request.courseTitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.teacherMuted,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _updateRequestStatus(request, 'rejected'),
                              child: const Text(
                                'Decline',
                                style: TextStyle(
                                  color: AppColors.teacherMuted,
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  _updateRequestStatus(request, 'accepted'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teacherPrimary,
                                foregroundColor: AppColors.buttonText,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Approve',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search student name',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.teacherSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
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
                              fontFamily: 'Inter',
                            ),
                          ),
                        )
                      : threads.isEmpty
                          ? const Center(
                              child: Text(
                                'No messages yet.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.teacherMuted,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                              children: threads.map((message) {
                                return ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.teacherChip,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.person,
                                        color: AppColors.teacherPrimaryDark),
                                  ),
                                  title: Text(
                                    message.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  subtitle: Text(
                                    message.message,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.teacherMuted,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  trailing: Text(
                                    message.time,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.teacherMuted,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.messageThread,
                                      arguments: message,
                                    );
                                  },
                                );
                              }).toList(),
                            ),
            ),
            TeacherBottomNav(
              currentIndex: _currentNavIndex,
              onTap: _onNavTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherRequestItem {
  final String id;
  final String studentName;
  final String courseTitle;
  final String status;

  const _TeacherRequestItem({
    required this.id,
    required this.studentName,
    required this.courseTitle,
    required this.status,
  });

  static _TeacherRequestItem fromJson(Map<String, dynamic> json) {
    final student = json['student'];
    final course = json['course'];
    return _TeacherRequestItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      studentName: student is Map<String, dynamic>
          ? student['name']?.toString() ?? 'Student'
          : 'Student',
      courseTitle: course is Map<String, dynamic>
          ? course['title']?.toString() ?? 'Course'
          : 'Course',
      status: json['status']?.toString() ?? 'pending',
    );
  }
}


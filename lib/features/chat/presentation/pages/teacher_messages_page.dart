
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/services/socket/socket_service.dart';
import '../../../../core/services/teacher/teacher_request_actions_service.dart';
import '../../../notifications/domain/entities/message_notification.dart';
import '../../../teacher_dashboard/presentation/widgets/teacher_bottom_nav.dart';

class TeacherMessagesPage extends StatefulWidget {
  const TeacherMessagesPage({super.key});

  @override
  State<TeacherMessagesPage> createState() => _TeacherMessagesPageState();
}

class _TeacherMessagesPageState extends State<TeacherMessagesPage> {
  int _currentNavIndex = 3;
  int _topTab = 0;
  int _messageTab = 0;

  final ApiClient _apiClient = ApiClient();
  final TeacherRequestActionsService _requestActions = TeacherRequestActionsService();
  final SocketService _socketService = SocketService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoadingThreads = false;
  bool _isLoadingRequests = false;
  bool _isLoadingNotifications = false;
  bool _isSearchingOrCreating = false;
  String? _errorMessage;

  final List<_ThreadItem> _threads = <_ThreadItem>[];
  final List<_TeacherRequestItem> _requests = <_TeacherRequestItem>[];
  final List<_StudentItem> _students = <_StudentItem>[];
  final List<NotificationItem> _notifications = <NotificationItem>[];

  String _searchQuery = '';
  Timer? _pollTimer;
  String get _screenTitle => _topTab == 0 ? 'Messages' : 'Notifications';

  @override
  void initState() {
    super.initState();
    _loadAll();
    _startPolling();
    _initSocket();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pollTimer?.cancel();
    _socketService.offThreadNew(_handleThreadNew);
    _socketService.offMessageNew(_handleMessageNew);
    _socketService.offNotificationNew(_handleNotificationNew);
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) {
      return;
    }
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

  Future<void> _loadAll() async {
    await Future.wait<void>([
      _loadThreads(),
      _loadRequests(),
      _loadStudents(),
      _loadNotifications(),
    ]);
  }

  Future<void> _loadThreads() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _threads.clear();
          _errorMessage = 'Please log in to view messages.';
        });
      }
      return;
    }

    setState(() {
      _isLoadingThreads = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getJson('/api/v1/threads', token: token);
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_mapThread)
            .where((thread) => thread.id.isNotEmpty)
            .toList();
        if (!mounted) {
          return;
        }
        setState(() {
          _threads
            ..clear()
            ..addAll(mapped);
        });
      }
    } on HttpException catch (err) {
      if (mounted) {
        setState(() {
          _errorMessage = err.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load messages.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingThreads = false;
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
      _isLoadingRequests = true;
    });

    try {
      final response = await _apiClient.getJson('/api/v1/teacher-requests', token: token);
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_TeacherRequestItem.fromJson)
            .where(
              (item) => item.status.toLowerCase() == 'pending' && !item.isDeleted,
            )
            .toList();
        if (!mounted) {
          return;
        }
        setState(() {
          _requests
            ..clear()
            ..addAll(mapped);
        });
      }
    } catch (_) {
      // Non-blocking by design.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRequests = false;
        });
      }
    }
  }

  Future<void> _loadStudents() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      final response = await _apiClient.getJson(
        '/api/v1/tutor-students?status=active',
        token: token,
      );
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_StudentItem.fromTutorStudentJson)
            .where((student) => student.id.isNotEmpty)
            .toList();
        if (!mounted) {
          return;
        }
        setState(() {
          _students
            ..clear()
            ..addAll(mapped);
        });
      }
    } catch (_) {
      await _loadStudentsFromEnrollments(token);
    }
  }

  Future<void> _loadStudentsFromEnrollments(String token) async {
    try {
      final response = await _apiClient.getJson('/api/v1/enrollments', token: token);
      final data = response['data'];
      if (data is! List) {
        return;
      }
      final results = <String, _StudentItem>{};
      for (final row in data.whereType<Map<String, dynamic>>()) {
        final student = row['student'];
        if (student is! Map<String, dynamic>) {
          continue;
        }
        final id = student['_id']?.toString() ?? student['id']?.toString() ?? '';
        final name = student['name']?.toString() ?? '';
        if (id.isEmpty || name.isEmpty) {
          continue;
        }
        results[id] = _StudentItem(id: id, name: name);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _students
          ..clear()
          ..addAll(results.values);
      });
    } catch (_) {
      // Non-blocking by design.
    }
  }

  Future<void> _loadNotifications() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final response = await _apiClient.getJson('/api/v1/notifications', token: token);
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_mapNotification)
            .toList();
        if (!mounted) {
          return;
        }
        setState(() {
          _notifications
            ..clear()
            ..addAll(mapped);
        });
      }
    } catch (_) {
      // Non-blocking by design.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadThreads();
      _loadNotifications();
    });
  }

  void _initSocket() {
    _socketService.connect();
    _socketService.joinUser();
    _socketService.onThreadNew(_handleThreadNew);
    _socketService.onMessageNew(_handleMessageNew);
    _socketService.onNotificationNew(_handleNotificationNew);
  }

  void _handleThreadNew(dynamic payload) {
    if (!mounted || payload is! Map) {
      return;
    }
    final rawThread = payload['thread'];
    if (rawThread is! Map) {
      return;
    }
    final mapped = _mapThread(Map<String, dynamic>.from(rawThread));
    if (mapped.id.isEmpty) {
      return;
    }
    setState(() {
      final index = _threads.indexWhere((thread) => thread.id == mapped.id);
      if (index >= 0) {
        _threads[index] = mapped;
      } else {
        _threads.insert(0, mapped);
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
    final index = _threads.indexWhere((thread) => thread.id == threadId);
    if (index == -1) {
      _loadThreads();
      return;
    }

    final current = _threads[index];
    final updated = current.copyWith(lastMessage: text, time: time);
    setState(() {
      _threads.removeAt(index);
      _threads.insert(0, updated);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New message from ${updated.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleNotificationNew(dynamic payload) {
    if (!mounted || payload is! Map) {
      return;
    }
    final rawNotification = payload['notification'];
    if (rawNotification is! Map) {
      return;
    }
    final mapped = _mapNotification(Map<String, dynamic>.from(rawNotification));
    setState(() {
      _notifications.insert(0, mapped);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mapped.title),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  Future<void> _searchAndOpenChat() async {
    final value = _searchController.text.trim();
    setState(() {
      _searchQuery = value.toLowerCase();
    });
    if (value.isEmpty) {
      return;
    }

    final existing = _threads.where((thread) {
      return thread.name.toLowerCase().contains(_searchQuery);
    }).toList();
    final exact = existing.where((t) => t.name.toLowerCase() == _searchQuery).toList();
    if (exact.isNotEmpty) {
      _openThread(exact.first);
      return;
    }
    if (existing.length == 1) {
      _openThread(existing.first);
      return;
    }

    var student = _students.cast<_StudentItem?>().firstWhere(
          (item) => item != null && item.name.toLowerCase().contains(_searchQuery),
          orElse: () => null,
        );
    student ??= await _searchStudentFromServer(_searchQuery);
    if (student == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No student found for this search.')),
        );
      }
      return;
    }

    await _createOrOpenThreadForStudent(student);
  }

  Future<_StudentItem?> _searchStudentFromServer(String query) async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty || query.trim().isEmpty) {
      return null;
    }

    final encoded = Uri.encodeComponent(query.trim());
    final paths = <String>[
      '/api/v1/tutor-students?status=active&search=$encoded',
      '/api/v1/teacher-requests?search=$encoded',
    ];

    for (final path in paths) {
      try {
        final response = await _apiClient.getJson(path, token: token);
        final data = response['data'];
        if (data is! List) {
          continue;
        }
        for (final item in data.whereType<Map<String, dynamic>>()) {
          final student = item['student'];
          if (student is! Map<String, dynamic>) {
            continue;
          }
          final id = student['_id']?.toString() ?? student['id']?.toString() ?? '';
          final name = student['name']?.toString() ?? '';
          if (id.isEmpty || name.isEmpty) {
            continue;
          }
          if (name.toLowerCase().contains(query.toLowerCase())) {
            return _StudentItem(id: id, name: name);
          }
        }
      } on HttpException catch (err) {
        if (err.statusCode == 404 || err.statusCode == 405) {
          continue;
        }
        break;
      } catch (_) {
        break;
      }
    }
    return null;
  }

  Future<void> _createOrOpenThreadForStudent(_StudentItem student) async {
    final existing = _threads.where((thread) {
      final sameId = thread.participantId != null && thread.participantId == student.id;
      final sameName = thread.name.toLowerCase() == student.name.toLowerCase();
      return sameId || sameName;
    }).toList();
    if (existing.isNotEmpty) {
      _openThread(existing.first);
      return;
    }

    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create chat thread.')),
      );
      return;
    }

    setState(() {
      _isSearchingOrCreating = true;
    });

    try {
      Map<String, dynamic>? createdData;

      Future<bool> tryCreate(String path, Map<String, dynamic> body) async {
        try {
          final response = await _apiClient.postJson(path, token: token, body: body);
          final data = response['data'];
          if (data is Map<String, dynamic>) {
            createdData = data;
            return true;
          }
          return false;
        } catch (_) {
          return false;
        }
      }

      final success = await tryCreate('/api/v1/threads', {'participant': student.id}) ||
          await tryCreate('/api/v1/threads', {'participants': <String>[student.id]}) ||
          await tryCreate('/api/v1/threads/create', {'participant': student.id});

      if (!success || createdData == null) {
        throw Exception('Unable to create thread.');
      }

      final mapped = _mapThread(createdData!);
      if (mapped.id.isEmpty) {
        throw Exception('Thread id missing.');
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _threads.insert(
          0,
          mapped.copyWith(
            name: mapped.name == 'Conversation' ? student.name : mapped.name,
          ),
        );
      });
      _openThread(_threads.first);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to start chat with this student.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingOrCreating = false;
        });
      }
    }
  }

  void _openThread(_ThreadItem thread) {
    Navigator.of(context).pushNamed(
      AppRoutes.messageThread,
      arguments: MessageNotification(
        id: thread.id,
        name: thread.name,
        isOnline: thread.isOnline,
        time: thread.time,
        message: thread.lastMessage,
      ),
    );
  }

  Future<void> _updateRequestStatus(_TeacherRequestItem request, String status) async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await _requestActions.updateStatus(
        requestId: request.id,
        status: status,
        token: token,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _requests.removeWhere((item) => item.id == request.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status.')),
      );

      if (status == 'accepted') {
        await _loadStudents();
        await _loadThreads();
      }
    } on HttpException catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update request.')),
        );
      }
    }
  }

  _ThreadItem _mapThread(Map<String, dynamic> thread) {
    final otherName = thread['otherParticipantName']?.toString();
    final otherId = thread['otherParticipantId']?.toString();
    if (otherName != null && otherName.trim().isNotEmpty) {
      return _ThreadItem(
        id: thread['_id']?.toString() ?? thread['id']?.toString() ?? '',
        participantId: otherId,
        name: otherName,
        lastMessage: thread['lastMessageText']?.toString() ??
            thread['lastMessage']?.toString() ??
            'No messages yet.',
        time: _formatTime(
          thread['lastMessageAt']?.toString() ??
              thread['updatedAt']?.toString() ??
              thread['createdAt']?.toString(),
        ),
        isOnline: false,
      );
    }

    final currentUserName = (HiveService.currentUserName ?? '').toLowerCase();
    final currentUserId = _currentUserId();

    String name = 'Conversation';
    String? participantId;

    final participants = thread['participants'];
    if (participants is List) {
      for (final participant in participants.whereType<Map<String, dynamic>>()) {
        final userName = participant['name']?.toString() ?? '';
        final userId = participant['_id']?.toString() ?? participant['id']?.toString() ?? '';
        final isSelfById = currentUserId != null && currentUserId.isNotEmpty && currentUserId == userId;
        final isSelfByName = currentUserName.isNotEmpty && userName.toLowerCase() == currentUserName;
        if (isSelfById || isSelfByName) {
          continue;
        }
        if (userName.isNotEmpty) {
          name = userName;
        }
        if (userId.isNotEmpty) {
          participantId = userId;
        }
        break;
      }
    }

    if (name == 'Conversation') {
      final fallback = thread['name']?.toString();
      if (fallback != null && fallback.trim().isNotEmpty) {
        name = fallback;
      }
    }

    return _ThreadItem(
      id: thread['_id']?.toString() ?? thread['id']?.toString() ?? '',
      participantId: participantId,
      name: name,
      lastMessage: thread['lastMessageText']?.toString() ??
          thread['lastMessage']?.toString() ??
          'No messages yet.',
      time: _formatTime(thread['updatedAt']?.toString() ?? thread['createdAt']?.toString()),
      isOnline: false,
    );
  }

  NotificationItem _mapNotification(Map<String, dynamic> notification) {
    final type = notification['type']?.toString() ?? 'system';
    final topic = notification['topic']?.toString();
    final title = notification['title']?.toString() ?? topic ?? 'Notification';
    final message = notification['message']?.toString();
    final time = _formatTime(notification['createdAt']?.toString());

    final icon = type == 'message'
        ? Icons.message
        : type == 'course'
            ? Icons.play_lesson
            : type == 'request'
                ? Icons.mark_chat_unread
                : Icons.notifications_active;

    final iconColor = type == 'message'
        ? AppColors.primary
        : type == 'course'
            ? AppColors.durationOrange
            : type == 'request'
                ? AppColors.teacherPrimary
                : AppColors.teacherMuted;

    return NotificationItem(
      id: notification['_id']?.toString() ?? notification['id']?.toString() ?? '',
      title: title,
      message: message,
      time: time,
      iconColor: iconColor,
      icon: icon,
      type: type,
      data: notification['data'] is Map<String, dynamic>
          ? notification['data'] as Map<String, dynamic>
          : null,
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
    final now = DateTime.now();
    if (now.difference(local).inDays == 0) {
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '${local.month}/${local.day}';
  }

  String? _currentUserId() {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return null;
    }
    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }
    try {
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      final decoded = jsonDecode(utf8.decode(payload));
      if (decoded is Map<String, dynamic>) {
        final id = decoded['id'] ?? decoded['_id'] ?? decoded['userId'];
        return id?.toString();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  List<_ThreadItem> get _filteredThreads {
    if (_searchQuery.trim().isEmpty) {
      return _threads;
    }
    return _threads
        .where((thread) => thread.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  List<_TeacherRequestItem> get _filteredRequests {
    if (_searchQuery.trim().isEmpty) {
      return _requests;
    }
    return _requests
        .where((request) => request.studentName.toLowerCase().contains(_searchQuery))
        .toList();
  }

  List<_StudentItem> get _searchMatchedStudents {
    if (_searchQuery.trim().isEmpty) {
      return <_StudentItem>[];
    }
    return _students
        .where((student) => student.name.toLowerCase().contains(_searchQuery))
        .toList();
  }
  Widget _buildHeaderTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TopTab(
          label: 'Message',
          selected: _topTab == 0,
          onTap: () {
            setState(() {
              _topTab = 0;
            });
          },
        ),
        const SizedBox(width: 24),
        _TopTab(
          label: 'Notification',
          selected: _topTab == 1,
          onTap: () {
            setState(() {
              _topTab = 1;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMessagePanel() {
    final threads = _filteredThreads;
    final requests = _filteredRequests;
    final matchedStudents = _searchMatchedStudents;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _SubTabChip(
                    label: 'Approved Chats',
                    selected: _messageTab == 0,
                    onTap: () {
                      setState(() {
                        _messageTab = 0;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _SubTabChip(
                    label: 'Message Requests',
                    selected: _messageTab == 1,
                    onTap: () {
                      setState(() {
                        _messageTab = 1;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search enrolled student name',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                      ),
                      onSubmitted: (_) => _searchAndOpenChat(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: _isSearchingOrCreating ? null : _searchAndOpenChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.buttonText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(_isSearchingOrCreating ? '...' : 'Search'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_messageTab == 0)
          if (_isLoadingThreads)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            )
          else if (threads.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No approved chats yet.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.teacherMuted,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  if (matchedStudents.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...matchedStudents.map(
                      (student) => _StudentSearchTile(
                        student: student,
                        onStartChat: () => _createOrOpenThreadForStudent(student),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            ...threads.map(
              (thread) => _ThreadTile(
                thread: thread,
                onTap: () => _openThread(thread),
              ),
            ),
        if (_messageTab == 1)
          if (_isLoadingRequests)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            )
          else if (requests.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'No message requests.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.teacherMuted,
                  fontFamily: 'OpenSans',
                ),
              ),
            )
          else
            ...requests.map(
              (request) => _RequestTile(
                request: request,
                onApprove: () => _updateRequestStatus(request, 'accepted'),
                onDecline: () => _updateRequestStatus(request, 'rejected'),
              ),
            ),
      ],
    );
  }

  Widget _buildNotificationPanel() {
    if (_isLoadingNotifications) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: CircularProgressIndicator(),
      );
    }
    if (_notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          'No notifications yet.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.teacherMuted,
            fontFamily: 'OpenSans',
          ),
        ),
      );
    }

    return Column(
      children: _notifications.map((notification) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notification.iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(notification.icon, color: notification.iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                    if ((notification.message ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.message!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.teacherMuted,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                notification.time,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.teacherMuted,
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text(
            _screenTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.teacherPrimaryDark,
              fontFamily: 'OpenSans',
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            _buildHeaderTabs(),
            const SizedBox(height: 14),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  if (_topTab == 0) _buildMessagePanel(),
                  if (_topTab == 1) _buildNotificationPanel(),
                ],
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
class _TopTab extends StatelessWidget {
  const _TopTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? AppColors.primary : AppColors.teacherMuted,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
    );
  }
}

class _SubTabChip extends StatelessWidget {
  const _SubTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFE9ECF3),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? AppColors.buttonText : AppColors.teacherPrimaryDark,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.onTap});

  final _ThreadItem thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.teacherChip,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  thread.name.isNotEmpty ? thread.name.substring(0, 1).toUpperCase() : 'S',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teacherPrimaryDark,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    thread.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.teacherMuted,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ],
              ),
            ),
            Text(
              thread.time,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.teacherMuted,
                fontFamily: 'OpenSans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.onApprove,
    required this.onDecline,
  });

  final _TeacherRequestItem request;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.teacherChip,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: AppColors.teacherPrimaryDark),
          ),
          const SizedBox(width: 10),
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
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  request.courseTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.teacherMuted,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onDecline, child: const Text('Decline')),
          ElevatedButton(
            onPressed: onApprove,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.buttonText,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}

class _StudentSearchTile extends StatelessWidget {
  const _StudentSearchTile({required this.student, required this.onStartChat});

  final _StudentItem student;
  final VoidCallback onStartChat;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onStartChat,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                student.name,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontFamily: 'OpenSans',
                ),
              ),
            ),
            TextButton(onPressed: onStartChat, child: const Text('Start chat')),
          ],
        ),
      ),
    );
  }
}

class _ThreadItem {
  const _ThreadItem({
    required this.id,
    required this.participantId,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.isOnline,
  });

  final String id;
  final String? participantId;
  final String name;
  final String lastMessage;
  final String time;
  final bool isOnline;

  _ThreadItem copyWith({
    String? id,
    String? participantId,
    String? name,
    String? lastMessage,
    String? time,
    bool? isOnline,
  }) {
    return _ThreadItem(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class _StudentItem {
  const _StudentItem({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  static _StudentItem fromTutorStudentJson(Map<String, dynamic> json) {
    final student = json['student'];
    final studentMap = student is Map<String, dynamic> ? student : <String, dynamic>{};
    return _StudentItem(
      id: studentMap['_id']?.toString() ?? studentMap['id']?.toString() ?? '',
      name: studentMap['name']?.toString() ?? 'Student',
    );
  }
}

class _TeacherRequestItem {
  const _TeacherRequestItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseTitle,
    required this.status,
    required this.isDeleted,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String courseTitle;
  final String status;
  final bool isDeleted;

  static _TeacherRequestItem fromJson(Map<String, dynamic> json) {
    final student = json['student'];
    final studentMap = student is Map<String, dynamic> ? student : <String, dynamic>{};
    final course = json['course'];
    final courseMap = course is Map<String, dynamic> ? course : <String, dynamic>{};

    return _TeacherRequestItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      studentId: studentMap['_id']?.toString() ?? studentMap['id']?.toString() ?? '',
      studentName: studentMap['name']?.toString() ?? 'Student',
      courseTitle: courseMap['title']?.toString() ?? 'Course',
      status: json['status']?.toString() ?? 'pending',
      isDeleted: json['isDeleted'] == true ||
          json['deleted'] == true ||
          (json['status']?.toString().toLowerCase() == 'deleted'),
    );
  }
}




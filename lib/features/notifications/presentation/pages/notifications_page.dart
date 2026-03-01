import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/socket/socket_service.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../domain/entities/message_notification.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/message_card.dart';
import '../widgets/notification_tile.dart';
import '../../../student_dashboard/presentation/widgets/bottom_nav.dart';
import '../../../student_courses/domain/entities/course.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _currentTab = 0;
  int _currentNavIndex = 3;
  final ApiClient _apiClient = ApiClient();
  final SocketService _socketService = SocketService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isSearchingOrCreating = false;
  String? _errorMessage;
  List<MessageNotification> _threads = [];
  List<NotificationItem> _notifications = [];
  List<_ParticipantCandidate> _searchCandidates = [];

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

  String get _screenTitle => _currentTab == 0 ? 'Messages' : 'Notifications';
  String get _searchQuery => _searchController.text.trim().toLowerCase();
  List<MessageNotification> get _filteredThreads {
    final q = _searchQuery;
    if (q.isEmpty) {
      return _threads;
    }
    return _threads.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  Future<bool> _handleBack() async {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    return false;
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
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.courses);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.searchResults);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.account);
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _initSocket();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _socketService.offThreadNew(_handleThreadNew);
    _socketService.offMessageNew(_handleMessageNew);
    _socketService.offNotificationNew(_handleNotificationNew);
    super.dispose();
  }

  Future<void> _loadData() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      _setStateIfMounted(() {
        _errorMessage = 'Please log in to view messages.';
        _threads = [];
      });
      return;
    }

    _setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final threadsResponse = await _apiClient.getJson(
        '/api/v1/threads',
        token: token,
      );
      final notificationsResponse = await _apiClient.getJson(
        '/api/v1/notifications',
        token: token,
      );

      final threadsData = threadsResponse['data'];
      final notificationsData = notificationsResponse['data'];

      if (threadsData is List) {
        _threads = threadsData
            .whereType<Map<String, dynamic>>()
            .map(_mapThread)
            .toList();
      }

      if (notificationsData is List) {
        _notifications = notificationsData
            .whereType<Map<String, dynamic>>()
            .map(_mapNotification)
            .toList();
      }

      await _ensureThreadsForApprovedTeachers(token);
    } on HttpException catch (err) {
      _setStateIfMounted(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      _setStateIfMounted(() {
        _errorMessage = 'Unable to load notifications.';
      });
    } finally {
      _setStateIfMounted(() {
        _isLoading = false;
      });
    }
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
      _loadData();
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
  }

  MessageNotification _mapThread(Map<String, dynamic> thread) {
    final otherName = thread['otherParticipantName']?.toString();
    final backendLastMessage = thread['lastMessageText']?.toString();
    if (otherName != null && otherName.trim().isNotEmpty) {
      return MessageNotification(
        id: thread['_id']?.toString() ?? thread['id']?.toString() ?? '',
        name: otherName,
        isOnline: false,
        time: _formatTime(
          thread['lastMessageAt']?.toString() ??
              thread['updatedAt']?.toString() ??
              thread['createdAt']?.toString(),
        ),
        message: (backendLastMessage != null && backendLastMessage.isNotEmpty)
            ? backendLastMessage
            : (thread['lastMessage']?.toString() ?? 'No messages yet.'),
      );
    }

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
        final user = participants.first is Map<String, dynamic>
            ? participants.first
            : null;
        final userName = user?['name']?.toString();
        if (userName != null && userName.isNotEmpty) {
          name = userName;
        }
      }
    }

    final createdAt = thread['createdAt']?.toString();
    final time = _formatTime(createdAt);
    return MessageNotification(
      id: thread['_id']?.toString() ?? thread['id']?.toString() ?? '',
      name: name,
      isOnline: false,
      time: time,
      message: thread['lastMessageText']?.toString() ??
          thread['lastMessage']?.toString() ??
          'No messages yet.',
    );
  }

  Future<void> _ensureThreadsForApprovedTeachers(String token) async {
    final teachers = await _searchTeachersOnServer('');
    if (teachers.isEmpty) {
      return;
    }

    var createdAny = false;
    for (final teacher in teachers) {
      final exists = _threads.any((thread) {
        final byId = thread.id == teacher.id;
        final byName = thread.name.toLowerCase() == teacher.name.toLowerCase();
        return byId || byName;
      });
      if (exists) {
        continue;
      }
      try {
        await _apiClient.postJson(
          '/api/v1/threads',
          token: token,
          body: {'participant': teacher.id},
        );
        createdAny = true;
      } catch (_) {
        // Non-blocking by design.
      }
    }

    if (createdAny) {
      final response = await _apiClient.getJson('/api/v1/threads', token: token);
      final data = response['data'];
      if (data is List) {
        _threads = data
            .whereType<Map<String, dynamic>>()
            .map(_mapThread)
            .toList();
      }
    }
  }

  NotificationItem _mapNotification(Map<String, dynamic> notification) {
    final type = notification['type']?.toString() ?? 'system';
    final createdAt = notification['createdAt']?.toString();
    final title = notification['title']?.toString() ?? 'Notification';
    final message = notification['message']?.toString();
    final time = _formatTime(createdAt);
    final iconData = type == 'message'
        ? Icons.message
        : type == 'purchase'
            ? Icons.shopping_bag
            : type == 'course'
                ? Icons.play_lesson
                : type == 'reminder'
                    ? Icons.notifications_active
                    : Icons.info;
    final color = type == 'message'
        ? AppColors.primary
        : type == 'purchase'
            ? AppColors.durationOrange
            : type == 'course'
                ? AppColors.categoryBlue
                : type == 'reminder'
                    ? AppColors.categoryPurple
                    : AppColors.backgroundLight;
    return NotificationItem(
      id: notification['_id']?.toString() ??
          notification['id']?.toString() ??
          '',
      title: title,
      message: message,
      time: time,
      iconColor: color,
      icon: iconData,
      type: type,
      data: notification['data'] is Map
          ? Map<String, dynamic>.from(notification['data'])
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

  Course _mapCourse(Map<String, dynamic> course) {
    final tutor = course['tutor'];
    final tutorName =
        tutor is Map<String, dynamic> ? tutor['name']?.toString() : null;
    final tutorId =
        tutor is Map<String, dynamic> ? tutor['_id']?.toString() : null;
    return Course(
      id: course['_id']?.toString() ?? course['id']?.toString() ?? 'course',
      title: course['title']?.toString() ?? 'Course',
      instructor:
          course['instructorName']?.toString() ?? tutorName ?? 'Instructor',
      tutorId: tutorId,
      price: (course['price'] as num?)?.toDouble() ?? 0,
      durationHours: (course['durationHours'] as num?)?.toInt() ?? 0,
      lessonCount: (course['lessonCount'] as num?)?.toInt() ?? 0,
      category: course['category']?.toString() ?? 'General',
      imageUrl: course['imageUrl']?.toString(),
      description: course['description']?.toString() ?? '',
      isBestseller: course['isBestseller'] == true,
      isPopular: course['isPopular'] == true,
      isNew: course['isNew'] == true,
      lessons: const [],
    );
  }

  Future<void> _openNotification(NotificationItem notif) async {
    if (notif.type != 'course') {
      return;
    }
    final courseId = notif.data?['courseId']?.toString();
    if (courseId == null || courseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course not found.')),
      );
      return;
    }
    try {
      final response = await _apiClient.getJson('/api/v1/courses/$courseId');
      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response');
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(
        AppRoutes.courseDetail,
        arguments: _mapCourse(data),
      );
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
        const SnackBar(content: Text('Unable to open course.')),
      );
    }
  }

  void _openThread(MessageNotification thread) {
    Navigator.of(context).pushNamed(
      AppRoutes.messageThread,
      arguments: thread,
    );
  }

  Future<void> _searchAndOpenThread() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _setStateIfMounted(() {
        _searchCandidates = [];
      });
      return;
    }

    final matches = _threads
        .where((thread) => thread.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final exact = matches.where((t) => t.name.toLowerCase() == query.toLowerCase()).toList();
    if (exact.isNotEmpty) {
      _openThread(exact.first);
      return;
    }
    if (matches.length == 1) {
      _openThread(matches.first);
      return;
    }

    final serverCandidates = await _searchTeachersOnServer(query);
    _setStateIfMounted(() {
      _searchCandidates = serverCandidates;
    });
    if (serverCandidates.length == 1) {
      await _createOrOpenThreadForParticipant(serverCandidates.first);
    }
  }

  Future<List<_ParticipantCandidate>> _searchTeachersOnServer(String query) async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return [];
    }
    final results = <String, _ParticipantCandidate>{};

    // Enrolled-teacher only search.
    try {
      final response = await _apiClient.getJson('/api/v1/enrollments', token: token);
      final data = response['data'];
      if (data is List) {
        for (final row in data.whereType<Map<String, dynamic>>()) {
          final status = row['status']?.toString().toLowerCase() ?? '';
          final allowed = status == 'approved' ||
              status == 'paid' ||
              status == 'completed' ||
              row['isApproved'] == true;
          if (!allowed) {
            continue;
          }
          final course = row['course'];
          if (course is! Map<String, dynamic>) {
            continue;
          }
          final tutor = course['tutor'];
          String id = '';
          String name = '';
          if (tutor is Map<String, dynamic>) {
            id = tutor['_id']?.toString() ?? tutor['id']?.toString() ?? '';
            name = tutor['name']?.toString() ?? '';
          }
          if (id.isEmpty) {
            id = course['tutorId']?.toString() ?? '';
          }
          if (name.isEmpty) {
            name = course['instructorName']?.toString() ?? '';
          }
          if (id.isNotEmpty &&
              name.isNotEmpty &&
              name.toLowerCase().contains(query.toLowerCase())) {
            results[id] = _ParticipantCandidate(id: id, name: name);
          }
        }
      }
    } catch (_) {
      // Non-blocking by design.
    }

    return results.values.toList();
  }

  Future<void> _createOrOpenThreadForParticipant(
    _ParticipantCandidate participant,
  ) async {
    final existing = _threads.where(
      (thread) => thread.name.toLowerCase() == participant.name.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      _openThread(existing.first);
      return;
    }

    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return;
    }

    _setStateIfMounted(() {
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

      final success =
          await tryCreate('/api/v1/threads', {'participant': participant.id}) ||
          await tryCreate('/api/v1/threads', {'participants': <String>[participant.id]}) ||
          await tryCreate('/api/v1/threads/create', {'participant': participant.id});

      if (!success || createdData == null) {
        throw Exception('Unable to create thread.');
      }

      final thread = _mapThread(createdData!);
      final corrected = thread.copyWith(
        name: thread.name == 'Conversation' ? participant.name : thread.name,
      );
      _setStateIfMounted(() {
        _threads.insert(0, corrected);
      });
      _openThread(corrected);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to start chat.')),
        );
      }
    } finally {
      _setStateIfMounted(() {
        _isSearchingOrCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            _screenTitle,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'OpenSans',
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            SegmentedTabs(
              selectedIndex: _currentTab,
              onTap: (index) {
                setState(() {
                  _currentTab = index;
                  if (index != 0) {
                    _searchCandidates = [];
                  }
                });
              },
              showNotificationDot: _currentTab == 0,
            ),
            const SizedBox(height: 24),
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
                      : _currentTab == 0
                          ? ListView(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          hintText: 'Search teacher name',
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: AppColors.divider,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: AppColors.divider,
                                            ),
                                          ),
                                        ),
                                        onSubmitted: (_) => _searchAndOpenThread(),
                                        onChanged: (_) => _setStateIfMounted(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      height: 36,
                                      child: ElevatedButton(
                                        onPressed: _isSearchingOrCreating
                                            ? null
                                            : _searchAndOpenThread,
                                        child: Text(
                                          _isSearchingOrCreating ? '...' : 'Search',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ..._filteredThreads.map((message) {
                                  return MessageCard(message: message);
                                }),
                                if (_filteredThreads.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Text(
                                      'No messages found.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontFamily: 'OpenSans',
                                      ),
                                    ),
                                  ),
                                if (_searchCandidates.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Teachers',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ..._searchCandidates.map((candidate) {
                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(candidate.name),
                                      trailing: TextButton(
                                        onPressed: _isSearchingOrCreating
                                            ? null
                                            : () => _createOrOpenThreadForParticipant(
                                                  candidate,
                                                ),
                                        child: const Text('Open'),
                                      ),
                                      onTap: _isSearchingOrCreating
                                          ? null
                                          : () => _createOrOpenThreadForParticipant(
                                                candidate,
                                              ),
                                    );
                                  }),
                                ],
                              ],
                            )
                          : ListView(
                              children: _notifications.map((notif) {
                                return NotificationTile(
                                  notification: notif,
                                  onTap: () => _openNotification(notif),
                                );
                              }).toList(),
                            ),
            ),
            BottomNav(
              currentIndex: _currentNavIndex,
              onTap: _onNavTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantCandidate {
  const _ParticipantCandidate({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}


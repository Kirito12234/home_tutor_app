import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/socket/socket_service.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../domain/entities/message_notification.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/message_card.dart';
import '../widgets/notification_tile.dart';
import '../../../dashboard/presentation/widgets/bottom_nav.dart';
import '../../../courses/domain/entities/course.dart';

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
  bool _isLoading = false;
  String? _errorMessage;
  List<MessageNotification> _threads = [];
  List<NotificationItem> _notifications = [];
  final List<MessageNotification> _dummyThreads = const [
    MessageNotification(
      id: 'thread-1',
      name: 'Sujan Karki',
      isOnline: true,
      time: '09:12',
      message: 'See you in the next session.',
    ),
    MessageNotification(
      id: 'thread-2',
      name: 'Anisha Rai',
      isOnline: false,
      time: 'Yesterday',
      message: 'Please review the assignment notes.',
    ),
    MessageNotification(
      id: 'thread-3',
      name: 'Prerna Thapa',
      isOnline: true,
      time: 'Mon',
      message: 'Class schedule updated.',
    ),
  ];

  Future<bool> _handleBack() async {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    return false;
  }

  void _onNavTap(int index) {
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
        Navigator.of(context).pushNamed(AppRoutes.searchResults);
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
    _socketService.offThreadNew(_handleThreadNew);
    _socketService.offMessageNew(_handleMessageNew);
    _socketService.offNotificationNew(_handleNotificationNew);
    super.dispose();
  }

  Future<void> _loadData() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = null;
        _threads = List<MessageNotification>.from(_dummyThreads);
      });
      return;
    }

    setState(() {
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
    } on HttpException catch (err) {
      setState(() {
        _errorMessage = err.message;
        if (_threads.isEmpty) {
          _threads = List<MessageNotification>.from(_dummyThreads);
        }
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to load notifications.';
        if (_threads.isEmpty) {
          _threads = List<MessageNotification>.from(_dummyThreads);
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
    final mapped =
        _mapNotification(Map<String, dynamic>.from(rawNotification));
    setState(() {
      _notifications.insert(0, mapped);
    });
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
    final time = _formatTime(createdAt);
    return MessageNotification(
      id: thread['_id']?.toString() ?? thread['id']?.toString() ?? '',
      name: name,
      isOnline: false,
      time: time,
      message: thread['lastMessage']?.toString() ?? 'No messages yet.',
    );
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
      id: notification['_id']?.toString() ?? notification['id']?.toString() ?? '',
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
    final tutorId = tutor is Map<String, dynamic> ? tutor['_id']?.toString() : null;
    return Course(
      id: course['_id']?.toString() ?? course['id']?.toString() ?? 'course',
      title: course['title']?.toString() ?? 'Course',
      instructor: course['instructorName']?.toString() ?? tutorName ?? 'Instructor',
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
          title: const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
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
                              fontFamily: 'Inter',
                            ),
                          ),
                        )
                      : _currentTab == 0
                          ? ListView(
                              children: _threads.map((message) {
                                return MessageCard(message: message);
                              }).toList(),
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


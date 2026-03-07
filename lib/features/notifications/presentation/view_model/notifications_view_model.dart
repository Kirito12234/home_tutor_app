import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/socket/socket_service.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/message_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsViewModel extends StateNotifier<NotificationsState> {
  NotificationsViewModel(
    this._repository, {
    SocketService? socketService,
  })  : _socketService = socketService ?? SocketService(),
        super(const NotificationsState());

  final NotificationsRepository _repository;
  final SocketService _socketService;

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

  Future<void> initialize() async {
    await load();
    _initSocket();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _repository.fetchThreads(),
        _repository.fetchNotifications(),
      ]);
      final threads = (results[0] as List<MessageNotification>);
      final notifications = (results[1] as List<NotificationItem>);
      state = state.copyWith(
        isLoading: false,
        threads: threads,
        notifications: notifications,
      );

      await _ensureThreadsForApprovedTeachers();
    } catch (err) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: err.toString(),
        threads: const <MessageNotification>[],
      );
    }
  }

  Future<void> _ensureThreadsForApprovedTeachers() async {
    try {
      final teachers = await _repository.searchTeachers(query: '');
      if (teachers.isEmpty) {
        return;
      }

      var createdAny = false;
      final existingNames = state.threads
          .map((t) => t.name.trim().toLowerCase())
          .where((t) => t.isNotEmpty)
          .toSet();

      for (final teacher in teachers) {
        if (existingNames.contains(teacher.name.trim().toLowerCase())) {
          continue;
        }
        try {
          await _repository.createThread(participantId: teacher.id);
          createdAny = true;
        } catch (_) {
          // Non-blocking by design.
        }
      }

      if (createdAny) {
        final threads = await _repository.fetchThreads();
        state = state.copyWith(threads: threads);
      }
    } catch (_) {
      // Non-blocking by design.
    }
  }

  Future<void> searchTeachers(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchCandidates: const <ParticipantCandidate>[]);
      return;
    }
    try {
      final candidates = await _repository.searchTeachers(query: query);
      state = state.copyWith(searchCandidates: candidates);
    } catch (_) {
      state = state.copyWith(searchCandidates: const <ParticipantCandidate>[]);
    }
  }

  void clearCandidates() {
    state = state.copyWith(searchCandidates: const <ParticipantCandidate>[]);
  }

  Future<MessageNotification?> createOrOpenThread(
    ParticipantCandidate participant,
  ) async {
    final existing = state.threads.where(
      (thread) => thread.name.toLowerCase() == participant.name.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    state = state.copyWith(isSearchingOrCreating: true);
    try {
      final thread = await _repository.createThread(participantId: participant.id);
      final corrected = thread.copyWith(
        name: thread.name == 'Conversation' ? participant.name : thread.name,
      );
      state = state.copyWith(
        isSearchingOrCreating: false,
        threads: <MessageNotification>[corrected, ...state.threads],
      );
      return corrected;
    } catch (_) {
      state = state.copyWith(isSearchingOrCreating: false);
      return null;
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
    if (payload is! Map) {
      return;
    }
    final rawThread = payload['thread'];
    if (rawThread is! Map) {
      return;
    }
    final mapped = _mapThread(Map<String, dynamic>.from(rawThread));
    final index = state.threads.indexWhere((t) => t.id == mapped.id);
    final next = [...state.threads];
    if (index >= 0) {
      next[index] = mapped;
    } else {
      next.insert(0, mapped);
    }
    state = state.copyWith(threads: next);
  }

  void _handleMessageNew(dynamic payload) {
    if (payload is! Map) {
      return;
    }
    final threadId = payload['threadId']?.toString();
    final rawMessage = payload['message'];
    if (threadId == null || rawMessage is! Map) {
      return;
    }
    final index = state.threads.indexWhere((t) => t.id == threadId);
    if (index == -1) {
      load();
      return;
    }
    final text = rawMessage['text']?.toString() ?? '';
    final time = _formatTime(rawMessage['createdAt']?.toString());
    final updated = state.threads[index].copyWith(
      message: text,
      time: time,
    );
    final next = [...state.threads]..removeAt(index);
    next.insert(0, updated);
    state = state.copyWith(threads: next);
  }

  void _handleNotificationNew(dynamic payload) {
    if (payload is! Map) {
      return;
    }
    final rawNotification = payload['notification'];
    if (rawNotification is! Map) {
      return;
    }
    final mapped = _mapNotification(Map<String, dynamic>.from(rawNotification));
    state = state.copyWith(
      notifications: <NotificationItem>[mapped, ...state.notifications],
    );
  }

  @override
  void dispose() {
    _socketService.offThreadNew(_handleThreadNew);
    _socketService.offMessageNew(_handleMessageNew);
    _socketService.offNotificationNew(_handleNotificationNew);
    super.dispose();
  }
}

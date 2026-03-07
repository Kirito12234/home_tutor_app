import 'package:flutter/material.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/message_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/local/notifications_local_datasource.dart';
import '../datasources/remote/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({
    required NotificationsRemoteDataSource remote,
    required NotificationsLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final NotificationsRemoteDataSource _remote;
  final NotificationsLocalDataSource _local;

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
    final currentName = _local.currentUserName;
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

  String _requireToken() {
    final token = _local.authToken;
    if (token == null || token.isEmpty) {
      throw AppException('Please log in to view messages.');
    }
    return token;
  }

  @override
  Future<List<MessageNotification>> fetchThreads() async {
    final token = _requireToken();
    final raw = await _remote.getThreads(token: token);
    return raw.map(_mapThread).toList();
  }

  @override
  Future<List<NotificationItem>> fetchNotifications() async {
    final token = _requireToken();
    final raw = await _remote.getNotifications(token: token);
    return raw.map(_mapNotification).toList();
  }

  @override
  Future<List<ParticipantCandidate>> searchTeachers({
    required String query,
  }) async {
    final token = _requireToken();
    final results = <String, ParticipantCandidate>{};
    final q = query.trim().toLowerCase();

    final rows = await _remote.getEnrollments(token: token);
    for (final row in rows) {
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
      if (id.isEmpty || name.isEmpty) {
        continue;
      }
      if (q.isNotEmpty && !name.toLowerCase().contains(q)) {
        continue;
      }
      results[id] = ParticipantCandidate(id: id, name: name);
    }

    return results.values.toList();
  }

  @override
  Future<MessageNotification> createThread({
    required String participantId,
  }) async {
    final token = _requireToken();
    final created = await _remote.postCreateThreadFallback(
      token: token,
      participantId: participantId,
    );
    if (created.isEmpty) {
      throw AppException('Unable to start chat.');
    }
    return _mapThread(created);
  }
}


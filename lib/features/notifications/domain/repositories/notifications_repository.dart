import '../entities/message_notification.dart';

abstract class NotificationsRepository {
  Future<List<MessageNotification>> fetchThreads();
  Future<List<NotificationItem>> fetchNotifications();

  Future<List<ParticipantCandidate>> searchTeachers({
    required String query,
  });

  Future<MessageNotification> createThread({
    required String participantId,
  });
}

class ParticipantCandidate {
  const ParticipantCandidate({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

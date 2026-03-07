import '../../domain/entities/message_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class NotificationsState {
  const NotificationsState({
    this.isLoading = false,
    this.isSearchingOrCreating = false,
    this.errorMessage,
    this.threads = const <MessageNotification>[],
    this.notifications = const <NotificationItem>[],
    this.searchCandidates = const <ParticipantCandidate>[],
  });

  final bool isLoading;
  final bool isSearchingOrCreating;
  final String? errorMessage;
  final List<MessageNotification> threads;
  final List<NotificationItem> notifications;
  final List<ParticipantCandidate> searchCandidates;

  NotificationsState copyWith({
    bool? isLoading,
    bool? isSearchingOrCreating,
    String? errorMessage,
    List<MessageNotification>? threads,
    List<NotificationItem>? notifications,
    List<ParticipantCandidate>? searchCandidates,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      isSearchingOrCreating: isSearchingOrCreating ?? this.isSearchingOrCreating,
      errorMessage: errorMessage,
      threads: threads ?? this.threads,
      notifications: notifications ?? this.notifications,
      searchCandidates: searchCandidates ?? this.searchCandidates,
    );
  }
}


import '../../../../../core/services/hive/hive_service.dart';

class NotificationsLocalDataSource {
  const NotificationsLocalDataSource();

  String? get authToken => HiveService.authToken;
  String get currentUserName => HiveService.currentUserName ?? '';
}


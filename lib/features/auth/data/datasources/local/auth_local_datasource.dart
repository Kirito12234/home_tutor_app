import '../../../../../core/services/hive/hive_service.dart';

class AuthLocalDataSource {
  const AuthLocalDataSource();

  String? get authToken => HiveService.authToken;
  String? get currentUserRole => HiveService.currentUserRole;

  Future<void> setAuthToken(String? token) => HiveService.setAuthToken(token);

  Future<void> setCurrentUserRole(String? role) =>
      HiveService.setCurrentUserRole(role);

  Future<void> setCurrentUserName(String? name) =>
      HiveService.setCurrentUserName(name);

  Map<String, dynamic>? getOfflineCredential(String identifier) =>
      HiveService.getOfflineCredential(identifier);

  Future<void> upsertOfflineCredential({
    required String identifier,
    required String passwordHash,
    required String name,
    required String role,
  }) {
    return HiveService.upsertOfflineCredential(
      identifier: identifier,
      passwordHash: passwordHash,
      name: name,
      role: role,
    );
  }

  String hashPassword(String password) => HiveService.hashPassword(password);
}


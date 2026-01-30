import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String settingsBoxName = 'settings';
  static const String onboardingDoneKey = 'onboarding_done';
  static const String authTokenKey = 'auth_token';
  static const String currentUserNameKey = 'current_user_name';
  static const String currentUserRoleKey = 'current_user_role';
  static const String currentUserAvatarUrlKey = 'current_user_avatar_url';
  static const String apiBaseUrlKey = 'api_base_url';
  static const String offlineCredentialsKey = 'offline_credentials';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(settingsBoxName);
  }
  
  static Box get settingsBox => Hive.box(settingsBoxName);
  
  static bool get isOnboardingDone {
    return settingsBox.get(onboardingDoneKey, defaultValue: false) as bool;
  }
  
  static Future<void> setOnboardingDone(bool value) async {
    await settingsBox.put(onboardingDoneKey, value);
  }

  static String? get authToken {
    return settingsBox.get(authTokenKey) as String?;
  }

  static Future<void> setAuthToken(String? token) async {
    if (token == null || token.isEmpty) {
      await settingsBox.delete(authTokenKey);
      return;
    }
    await settingsBox.put(authTokenKey, token);
  }

  static String? get currentUserName {
    final value = settingsBox.get(currentUserNameKey) as String?;
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value;
  }

  static Future<void> setCurrentUserName(String? name) async {
    if (name == null || name.trim().isEmpty) {
      await settingsBox.delete(currentUserNameKey);
      return;
    }
    await settingsBox.put(currentUserNameKey, name.trim());
  }

  static String? get currentUserRole {
    final value = settingsBox.get(currentUserRoleKey) as String?;
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value;
  }

  static Future<void> setCurrentUserRole(String? role) async {
    if (role == null || role.trim().isEmpty) {
      await settingsBox.delete(currentUserRoleKey);
      return;
    }
    await settingsBox.put(currentUserRoleKey, role.trim());
  }

  static String? get currentUserAvatarUrl {
    final value = settingsBox.get(currentUserAvatarUrlKey) as String?;
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  static Future<void> setCurrentUserAvatarUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await settingsBox.delete(currentUserAvatarUrlKey);
      return;
    }
    await settingsBox.put(currentUserAvatarUrlKey, url.trim());
  }

  static String? get apiBaseUrlOverride {
    final value = settingsBox.get(apiBaseUrlKey) as String?;
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  static Future<void> setApiBaseUrlOverride(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await settingsBox.delete(apiBaseUrlKey);
      return;
    }
    await settingsBox.put(apiBaseUrlKey, url.trim());
  }

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static Map<String, dynamic> _offlineCredentials() {
    final stored =
        settingsBox.get(offlineCredentialsKey, defaultValue: <String, dynamic>{});
    if (stored is Map) {
      return Map<String, dynamic>.from(stored);
    }
    return <String, dynamic>{};
  }

  static Future<void> upsertOfflineCredential({
    required String identifier,
    required String passwordHash,
    required String name,
    required String role,
  }) async {
    final key = identifier.trim().toLowerCase();
    if (key.isEmpty) {
      return;
    }
    final credentials = _offlineCredentials();
    credentials[key] = <String, dynamic>{
      'passwordHash': passwordHash,
      'name': name.trim(),
      'role': role.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await settingsBox.put(offlineCredentialsKey, credentials);
  }

  static Map<String, dynamic>? getOfflineCredential(String identifier) {
    final key = identifier.trim().toLowerCase();
    if (key.isEmpty) {
      return null;
    }
    final credentials = _offlineCredentials();
    final value = credentials[key];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
  
  static Future<void> clearAll() async {
    await settingsBox.clear();
  }
}


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
  static const String currentUserAvatarLocalPathKey =
      'current_user_avatar_local_path';
  static const String teacherPayoutProofCacheKey = 'teacher_payout_proof_cache';
  static const String teacherPayoutPendingQrCacheKey =
      'teacher_payout_pending_qr_cache';
  static const String apiBaseUrlKey = 'api_base_url';
  static const String offlineCredentialsKey = 'offline_credentials';
  static const String learnedTodayGoalMinutesKey = 'learned_today_goal_minutes';
  static const String teacherOfflineCourseDraftsKey =
      'teacher_offline_course_drafts';
  static const String teacherCourseMaterialsCacheKey =
      'teacher_course_materials_cache';
  
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

  static String? get currentUserAvatarLocalPath {
    final value = settingsBox.get(currentUserAvatarLocalPathKey) as String?;
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  static Future<void> setCurrentUserAvatarLocalPath(String? path) async {
    if (path == null || path.trim().isEmpty) {
      await settingsBox.delete(currentUserAvatarLocalPathKey);
      return;
    }
    await settingsBox.put(currentUserAvatarLocalPathKey, path.trim());
  }

  static String _currentUserCacheKeySuffix() {
    final name = currentUserName?.trim().toLowerCase();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final role = currentUserRole?.trim().toLowerCase();
    if (role != null && role.isNotEmpty) {
      return role;
    }
    return 'guest';
  }

  static Map<String, dynamic> getTeacherPayoutProofCache() {
    final all = settingsBox.get(
      teacherPayoutProofCacheKey,
      defaultValue: <String, dynamic>{},
    );
    if (all is! Map) {
      return <String, dynamic>{};
    }
    final typed = Map<String, dynamic>.from(all);
    final value = typed[_currentUserCacheKeySuffix()];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  static Future<void> setTeacherPayoutProofCache(
    Map<String, dynamic> proofMap,
  ) async {
    final all = settingsBox.get(
      teacherPayoutProofCacheKey,
      defaultValue: <String, dynamic>{},
    );
    final typedAll = all is Map
        ? Map<String, dynamic>.from(all)
        : <String, dynamic>{};
    typedAll[_currentUserCacheKeySuffix()] = proofMap;
    await settingsBox.put(teacherPayoutProofCacheKey, typedAll);
  }

  static Map<String, dynamic> getTeacherPayoutPendingQrCache() {
    final all = settingsBox.get(
      teacherPayoutPendingQrCacheKey,
      defaultValue: <String, dynamic>{},
    );
    if (all is! Map) {
      return <String, dynamic>{};
    }
    final typed = Map<String, dynamic>.from(all);
    final value = typed[_currentUserCacheKeySuffix()];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  static Future<void> setTeacherPayoutPendingQrCache(
    Map<String, dynamic> pendingMap,
  ) async {
    final all = settingsBox.get(
      teacherPayoutPendingQrCacheKey,
      defaultValue: <String, dynamic>{},
    );
    final typedAll = all is Map
        ? Map<String, dynamic>.from(all)
        : <String, dynamic>{};
    typedAll[_currentUserCacheKeySuffix()] = pendingMap;
    await settingsBox.put(teacherPayoutPendingQrCacheKey, typedAll);
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

  static int get learnedTodayGoalMinutes {
    final value = settingsBox.get(learnedTodayGoalMinutesKey, defaultValue: 60);
    if (value is int && value > 0) {
      return value;
    }
    if (value is num && value > 0) {
      return value.toInt();
    }
    return 60;
  }

  static Future<void> setLearnedTodayGoalMinutes(int minutes) async {
    final safeValue = minutes <= 0 ? 60 : minutes;
    await settingsBox.put(learnedTodayGoalMinutesKey, safeValue);
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

  static List<Map<String, dynamic>> getTeacherOfflineCourseDrafts() {
    final all = settingsBox.get(
      teacherOfflineCourseDraftsKey,
      defaultValue: <String, dynamic>{},
    );
    if (all is! Map) {
      return <Map<String, dynamic>>[];
    }
    final typedAll = Map<String, dynamic>.from(all);
    final key = _currentUserCacheKeySuffix();
    final raw = typedAll[key];
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> setTeacherOfflineCourseDrafts(
    List<Map<String, dynamic>> drafts,
  ) async {
    final all = settingsBox.get(
      teacherOfflineCourseDraftsKey,
      defaultValue: <String, dynamic>{},
    );
    final typedAll = all is Map
        ? Map<String, dynamic>.from(all)
        : <String, dynamic>{};
    final key = _currentUserCacheKeySuffix();
    typedAll[key] = drafts;
    await settingsBox.put(teacherOfflineCourseDraftsKey, typedAll);
  }

  static Future<void> upsertTeacherOfflineCourseDraft(
    Map<String, dynamic> draft,
  ) async {
    final localId = draft['localId']?.toString() ?? '';
    if (localId.isEmpty) {
      return;
    }
    final drafts = getTeacherOfflineCourseDrafts();
    final next = drafts.where((item) {
      return item['localId']?.toString() != localId;
    }).toList();
    next.insert(0, draft);
    await setTeacherOfflineCourseDrafts(next);
  }

  static Future<void> removeTeacherOfflineCourseDraft(String localId) async {
    if (localId.trim().isEmpty) {
      return;
    }
    final drafts = getTeacherOfflineCourseDrafts();
    final next = drafts.where((item) {
      return item['localId']?.toString() != localId;
    }).toList();
    await setTeacherOfflineCourseDrafts(next);
  }

  static Map<String, dynamic> _teacherCourseMaterialsCache() {
    final stored = settingsBox.get(
      teacherCourseMaterialsCacheKey,
      defaultValue: <String, dynamic>{},
    );
    if (stored is Map) {
      return Map<String, dynamic>.from(stored);
    }
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> getTeacherCourseMaterials(
    String courseKey,
  ) {
    final rawKey = courseKey.trim();
    if (rawKey.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    final key = '${_currentUserCacheKeySuffix()}::$rawKey';
    final all = _teacherCourseMaterialsCache();
    final raw = all[key];
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> upsertTeacherCourseMaterial(
    String courseKey,
    Map<String, dynamic> material,
  ) async {
    final rawKey = courseKey.trim();
    if (rawKey.isEmpty) {
      return;
    }
    final key = '${_currentUserCacheKeySuffix()}::$rawKey';
    final normalized = Map<String, dynamic>.from(material);
    final url = (normalized['url']?.toString() ?? '').trim();
    final type = (normalized['type']?.toString() ?? '').trim().toLowerCase();
    final lessonId = (normalized['lessonId']?.toString() ?? '').trim();
    if (url.isEmpty || type.isEmpty) {
      return;
    }

    final materialId = (normalized['materialId']?.toString() ?? '').trim();
    final uniqueKey = materialId.isNotEmpty
        ? 'id:$materialId'
        : 'u:$lessonId|$type|$url';

    final all = _teacherCourseMaterialsCache();
    final listRaw = all[key];
    final list = listRaw is List
        ? listRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    final next = <Map<String, dynamic>>[
      {
        ...normalized,
        '_key': uniqueKey,
        'url': url,
        'type': type,
        'lessonId': lessonId,
        'materialId': materialId,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      ...list.where((item) => item['_key']?.toString() != uniqueKey),
    ];

    all[key] = next;
    await settingsBox.put(teacherCourseMaterialsCacheKey, all);
  }

  static Future<void> removeTeacherCourseMaterial({
    required String courseKey,
    String? materialId,
    required String url,
    required String type,
    String? lessonId,
  }) async {
    final rawKey = courseKey.trim();
    if (rawKey.isEmpty) {
      return;
    }
    final key = '${_currentUserCacheKeySuffix()}::$rawKey';
    final all = _teacherCourseMaterialsCache();
    final listRaw = all[key];
    if (listRaw is! List) {
      return;
    }
    final id = (materialId ?? '').trim();
    final normalizedType = type.trim().toLowerCase();
    final normalizedUrl = url.trim();
    final normalizedLessonId = (lessonId ?? '').trim();

    final next = listRaw.whereType<Map>().where((item) {
      final itemId = item['materialId']?.toString() ?? '';
      if (id.isNotEmpty && itemId == id) {
        return false;
      }
      final itemType = (item['type']?.toString() ?? '').toLowerCase();
      final itemUrl = item['url']?.toString() ?? '';
      final itemLessonId = item['lessonId']?.toString() ?? '';
      return !(itemType == normalizedType &&
          itemUrl == normalizedUrl &&
          (normalizedLessonId.isEmpty || itemLessonId == normalizedLessonId));
    }).map((e) => Map<String, dynamic>.from(e)).toList();

    all[key] = next;
    await settingsBox.put(teacherCourseMaterialsCacheKey, all);
  }
  
  static Future<void> clearAll() async {
    await settingsBox.clear();
  }
}


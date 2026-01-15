import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String settingsBoxName = 'settings';
  static const String onboardingDoneKey = 'onboarding_done';
  static const String authTokenKey = 'auth_token';
  
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
  
  static Future<void> clearAll() async {
    await settingsBox.clear();
  }
}


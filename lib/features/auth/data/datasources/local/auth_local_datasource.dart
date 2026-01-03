import 'package:hive/hive.dart';
import '../../models/user_hive_model.dart';

class AuthLocalDataSource {
  AuthLocalDataSource();

  static const String userBoxName = 'users';
  static const String sessionBoxName = 'auth_session';
  static const String sessionKey = 'logged_in_email';

  Box<UserHiveModel> get _userBox => Hive.box<UserHiveModel>(userBoxName);
  Box<String> get _sessionBox => Hive.box<String>(sessionBoxName);

  Future<UserHiveModel?> getUserByEmail(String email) async {
    return _userBox.get(email.toLowerCase());
  }

  Future<void> saveUser(UserHiveModel user) async {
    await _userBox.put(user.email.toLowerCase(), user);
  }

  Future<void> saveSession(String email) async {
    await _sessionBox.put(sessionKey, email.toLowerCase());
  }

  Future<String?> getSessionEmail() async {
    return _sessionBox.get(sessionKey);
  }

  Future<void> clearSession() async {
    await _sessionBox.delete(sessionKey);
  }
}

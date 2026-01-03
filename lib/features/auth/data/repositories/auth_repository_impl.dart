import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../models/user_hive_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._localDataSource);

  final AuthLocalDataSource _localDataSource;

  @override
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.trim().isEmpty) {
      return 'Email and password are required.';
    }

    final existing = await _localDataSource.getUserByEmail(normalizedEmail);
    if (existing != null) {
      return 'Email already registered.';
    }

    final safeName = name.trim().isEmpty
        ? _deriveNameFromEmail(normalizedEmail)
        : name.trim();
    final hashedPassword = _hashPassword(password.trim());

    final user = UserHiveModel(
      name: safeName,
      email: normalizedEmail,
      passwordHash: hashedPassword,
    );

    await _localDataSource.saveUser(user);
    return null;
  }

  @override
  Future<String?> logIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.trim().isEmpty) {
      return 'Email and password are required.';
    }

    final user = await _localDataSource.getUserByEmail(normalizedEmail);
    if (user == null) {
      return 'Invalid email or password.';
    }

    final hashedPassword = _hashPassword(password.trim());
    if (user.passwordHash != hashedPassword) {
      return 'Invalid email or password.';
    }

    if (rememberMe) {
      await _localDataSource.saveSession(normalizedEmail);
    } else {
      await _localDataSource.clearSession();
    }
    return null;
  }

  @override
  Future<String?> getSessionEmail() {
    return _localDataSource.getSessionEmail();
  }

  @override
  Future<void> logOut() {
    return _localDataSource.clearSession();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  String _deriveNameFromEmail(String email) {
    final parts = email.split('@');
    return parts.isEmpty || parts.first.trim().isEmpty
        ? 'User'
        : parts.first.trim();
  }
}

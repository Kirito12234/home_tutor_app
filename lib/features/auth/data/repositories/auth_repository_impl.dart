import 'dart:io';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/services/connectivity/connectivity_service.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/auth_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    ConnectivityService? connectivityService,
  })  : _remote = remote,
        _local = local,
        _connectivityService = connectivityService ?? ConnectivityService();

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final ConnectivityService _connectivityService;

  static String? _extractDisplayName(Map<String, dynamic> response) {
    final user = response['user'];
    if (user is Map<String, dynamic>) {
      final name = user['name']?.toString();
      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }
    }
    final name = response['name']?.toString();
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    return null;
  }

  static String? _extractRole(Map<String, dynamic> response) {
    String? role;
    final user = response['user'];
    if (user is Map<String, dynamic>) {
      role = user['role']?.toString();
    }
    role ??= response['role']?.toString();
    if (role == null || role.trim().isEmpty) {
      return null;
    }
    final normalized = role.trim().toLowerCase();
    if (normalized == 'tutor') {
      return 'teacher';
    }
    return normalized;
  }

  AuthUser? _extractUser(Map<String, dynamic> response) {
    final rawUser = response['user'];
    if (rawUser is Map<String, dynamic>) {
      final model = AuthUserModel.fromJson(rawUser);
      if (model.id.isNotEmpty || model.name.isNotEmpty || model.role.isNotEmpty) {
        return AuthUser(id: model.id, name: model.name, role: model.role);
      }
    }
    return null;
  }

  Future<AuthSession> _loginOffline({
    required String identifier,
    required String password,
  }) async {
    final credential = _local.getOfflineCredential(identifier);
    if (credential == null) {
      throw AppException('No offline account found for this user.');
    }
    final storedHash = credential['passwordHash']?.toString();
    final inputHash = _local.hashPassword(password);
    if (storedHash == null || storedHash != inputHash) {
      throw AppException('Incorrect offline password.');
    }
    final name = credential['name']?.toString();
    final role = credential['role']?.toString();

    await _local.setAuthToken(null);
    await _local.setCurrentUserName(name ?? identifier);
    if (role != null && role.trim().isNotEmpty) {
      await _local.setCurrentUserRole(role);
    }

    return AuthSession(
      identifier: identifier,
      displayName: (name == null || name.trim().isEmpty) ? identifier : name,
      role: role,
      token: null,
      user: null,
    );
  }

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
    String? fallbackRole,
  }) async {
    final safeIdentifier = identifier.trim();
    if (safeIdentifier.isEmpty) {
      throw AppException('Email or phone is required.');
    }
    if (password.isEmpty) {
      throw AppException('Password is required.');
    }

    final online = await _connectivityService.isOnline();
    if (!online) {
      return _loginOffline(identifier: safeIdentifier, password: password);
    }

    try {
      final response = await _remote.login(
        identifier: safeIdentifier,
        password: password,
      );

      final token = response['token']?.toString();
      if (token != null && token.isNotEmpty) {
        await _local.setAuthToken(token);
      }

      final serverRole = _extractRole(response);
      if (serverRole != null) {
        await _local.setCurrentUserRole(serverRole);
      }

      final displayName = _extractDisplayName(response) ?? safeIdentifier;
      await _local.setCurrentUserName(displayName);

      await _local.upsertOfflineCredential(
        identifier: safeIdentifier,
        passwordHash: _local.hashPassword(password),
        name: displayName,
        role: (serverRole ?? fallbackRole ?? '').trim().toLowerCase(),
      );

      return AuthSession(
        identifier: safeIdentifier,
        displayName: displayName,
        role: serverRole ?? fallbackRole,
        token: token,
        user: _extractUser(response),
      );
    } on SocketException {
      return _loginOffline(identifier: safeIdentifier, password: password);
    }
  }
}

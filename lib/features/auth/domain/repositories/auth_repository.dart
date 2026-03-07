import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String identifier,
    required String password,
    String? fallbackRole,
  });
}


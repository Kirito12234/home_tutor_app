import 'auth_user.dart';

class AuthSession {
  const AuthSession({
    required this.identifier,
    required this.displayName,
    required this.role,
    required this.token,
    this.user,
  });

  final String identifier;
  final String displayName;
  final String? role;
  final String? token;
  final AuthUser? user;
}


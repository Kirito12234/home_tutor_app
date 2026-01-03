import '../../domain/repositories/auth_repository.dart';

class AuthProvider {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _repository.signUp(
      name: name,
      email: email,
      password: password,
    );
  }

  Future<String?> logIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) {
    return _repository.logIn(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
  }

  Future<String?> getSessionEmail() {
    return _repository.getSessionEmail();
  }

  Future<void> logOut() {
    return _repository.logOut();
  }
}

abstract class AuthRepository {
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<String?> logIn({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<String?> getSessionEmail();

  Future<void> logOut();
}

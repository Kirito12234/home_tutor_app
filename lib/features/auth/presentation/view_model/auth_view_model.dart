import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<AuthSession?> login({
    required String identifier,
    required String password,
    String? fallbackRole,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final session = await _repository.login(
        identifier: identifier,
        password: password,
        fallbackRole: fallbackRole,
      );
      state = state.copyWith(isLoading: false, errorMessage: null);
      return session;
    } catch (err) {
      final message = switch (err) {
        AppException() => err.message,
        HttpException() => err.message,
        _ => err.toString(),
      };
      state = state.copyWith(isLoading: false, errorMessage: message);
      return null;
    }
  }
}

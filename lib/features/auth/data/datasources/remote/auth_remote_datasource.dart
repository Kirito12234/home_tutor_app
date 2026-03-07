import '../../../../../core/api/api_client.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) {
    return _apiClient.postJson(
      '/api/v1/auth/login',
      body: {
        'emailOrPhone': identifier,
        'password': password,
      },
    );
  }
}


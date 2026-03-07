import '../../../../../core/api/api_client.dart';

class StudentCoursesRemoteDataSource {
  StudentCoursesRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getCourses({
    required bool approvedOnly,
    required String searchQuery,
  }) async {
    final params = <String>[];
    if (approvedOnly) {
      params.add('status=approved');
    }
    final q = searchQuery.trim();
    if (q.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(q)}');
    }
    final query = params.isEmpty ? '' : '?${params.join('&')}';

    final response = await _apiClient.getJson('/api/v1/courses$query');
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> getFavorites({
    required String token,
    required String path,
  }) async {
    return _apiClient.getJson(path, token: token);
  }

  Future<void> addFavorite({
    required String token,
    required String path,
    required Map<String, dynamic> body,
  }) async {
    await _apiClient.postJson(path, token: token, body: body);
  }

  Future<void> removeFavorite({
    required String token,
    required String path,
  }) async {
    await _apiClient.deleteJson(path, token: token);
  }

  bool isNotFound(HttpException err) =>
      err.statusCode == 404 || err.statusCode == 405;
}

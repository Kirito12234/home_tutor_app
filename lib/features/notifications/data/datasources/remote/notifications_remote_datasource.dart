import '../../../../../core/api/api_client.dart';

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getThreads({required String token}) async {
    final response = await _apiClient.getJson('/api/v1/threads', token: token);
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getNotifications({
    required String token,
  }) async {
    final response =
        await _apiClient.getJson('/api/v1/notifications', token: token);
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getEnrollments({
    required String token,
  }) async {
    final response =
        await _apiClient.getJson('/api/v1/enrollments', token: token);
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> postCreateThread({
    required String token,
    required String participantId,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/threads',
      token: token,
      body: {'participant': participantId},
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> postCreateThreadFallback({
    required String token,
    required String participantId,
  }) async {
    Future<Map<String, dynamic>> tryCreate(
      String path,
      Map<String, dynamic> body,
    ) async {
      final response = await _apiClient.postJson(path, token: token, body: body);
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return <String, dynamic>{};
    }

    final candidates = <Future<Map<String, dynamic>> Function()>[
      () => tryCreate('/api/v1/threads', {'participant': participantId}),
      () => tryCreate('/api/v1/threads', {'participants': <String>[participantId]}),
      () => tryCreate('/api/v1/threads/create', {'participant': participantId}),
    ];

    for (final candidate in candidates) {
      try {
        final created = await candidate();
        if (created.isNotEmpty) {
          return created;
        }
      } catch (_) {
        // Try next candidate.
      }
    }

    return <String, dynamic>{};
  }
}


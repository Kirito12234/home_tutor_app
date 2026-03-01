import '../../api/api_client.dart';

class TeacherRequestActionsService {
  TeacherRequestActionsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<void> updateStatus({
    required String requestId,
    required String status,
    required String token,
  }) async {
    final errors = <HttpException>[];

    Future<bool> tryCall(Future<void> Function() run) async {
      try {
        await run();
        return true;
      } on HttpException catch (err) {
        if (_isRouteUnavailable(err)) {
          errors.add(err);
          return false;
        }
        rethrow;
      }
    }

    if (await tryCall(() async {
      await _apiClient.patchJson(
        '/api/v1/teacher-requests/$requestId',
        token: token,
        body: {'status': status},
      );
    })) {
      return;
    }

    if (await tryCall(() async {
      await _apiClient.putJson(
        '/api/v1/teacher-requests/$requestId',
        token: token,
        body: {'status': status},
      );
    })) {
      return;
    }

    if (await tryCall(() async {
      await _apiClient.postJson(
        '/api/v1/teacher-requests/$requestId/status',
        token: token,
        body: {'status': status},
      );
    })) {
      return;
    }

    if (await tryCall(() async {
      await _apiClient.postJson(
        '/api/v1/teacher-requests/$requestId/respond',
        token: token,
        body: {'status': status},
      );
    })) {
      return;
    }

    if (await tryCall(() async {
      await _apiClient.postJson(
        '/api/v1/teacher-requests/respond',
        token: token,
        body: {
          'requestId': requestId,
          'status': status,
        },
      );
    })) {
      return;
    }

    final nonUnavailable = errors.where((e) => !_isRouteUnavailable(e)).toList();
    if (nonUnavailable.isNotEmpty) {
      throw nonUnavailable.first;
    }
    throw HttpException(
      404,
      'Request action route is not available on this server.',
    );
  }

  Future<void> deleteRequest({
    required String requestId,
    required String token,
  }) async {
    final errors = <HttpException>[];

    Future<bool> tryCall(Future<void> Function() run) async {
      try {
        await run();
        return true;
      } on HttpException catch (err) {
        if (_isRouteUnavailable(err)) {
          errors.add(err);
          return false;
        }
        rethrow;
      }
    }

    if (await tryCall(() async {
      await _apiClient.deleteJson(
        '/api/v1/teacher-requests/$requestId',
        token: token,
      );
    })) {
      return;
    }

    if (await tryCall(() async {
      await _apiClient.deleteJson(
        '/api/v1/teacher-requests/delete/$requestId',
        token: token,
      );
    })) {
      return;
    }

    if (await tryCall(() async {
      await _apiClient.deleteJson(
        '/api/v1/teacher-requests/remove/$requestId',
        token: token,
      );
    })) {
      return;
    }

    if (await tryCall(() async {
      await _apiClient.postJson(
        '/api/v1/teacher-requests/$requestId/delete',
        token: token,
      );
    })) {
      return;
    }

    if (await tryCall(() async {
      await _apiClient.postJson(
        '/api/v1/teacher-requests/$requestId/remove',
        token: token,
      );
    })) {
      return;
    }

    if (await tryCall(() async {
      await _apiClient.postJson(
        '/api/v1/teacher-requests/delete',
        token: token,
        body: {'requestId': requestId},
      );
    })) {
      return;
    }

    if (await tryCall(() async {
      await _apiClient.postJson(
        '/api/v1/teacher-requests/remove',
        token: token,
        body: {'requestId': requestId},
      );
    })) {
      return;
    }

    // Soft-delete fallback for servers that store deletion status in DB.
    if (await tryCall(() async {
      await _apiClient.patchJson(
        '/api/v1/teacher-requests/$requestId',
        token: token,
        body: {'status': 'deleted', 'isDeleted': true},
      );
    })) {
      return;
    }

    if (await tryCall(() async {
      await _apiClient.putJson(
        '/api/v1/teacher-requests/$requestId',
        token: token,
        body: {'status': 'deleted', 'isDeleted': true},
      );
    })) {
      return;
    }

    final nonUnavailable = errors.where((e) => !_isRouteUnavailable(e)).toList();
    if (nonUnavailable.isNotEmpty) {
      throw nonUnavailable.first;
    }
    throw HttpException(
      404,
      'Request delete route is not available on this server.',
    );
  }

  Future<void> clearAllRequests({
    required String token,
  }) async {
    final errors = <HttpException>[];

    Future<bool> tryCall(Future<void> Function() run) async {
      try {
        await run();
        return true;
      } on HttpException catch (err) {
        if (_isRouteUnavailable(err)) {
          errors.add(err);
          return false;
        }
        rethrow;
      }
    }

    if (await tryCall(() async {
      await _apiClient.deleteJson(
        '/api/v1/teacher-requests',
        token: token,
      );
    })) {
      return;
    }

    if (await tryCall(() async {
      await _apiClient.postJson(
        '/api/v1/teacher-requests/clear-all',
        token: token,
      );
    })) {
      return;
    }

    if (await tryCall(() async {
      await _apiClient.postJson(
        '/api/v1/teacher-requests/clear',
        token: token,
      );
    })) {
      return;
    }

    final nonUnavailable = errors.where((e) => !_isRouteUnavailable(e)).toList();
    if (nonUnavailable.isNotEmpty) {
      throw nonUnavailable.first;
    }
    throw HttpException(
      404,
      'Request clear route is not available on this server.',
    );
  }

  bool _isRouteUnavailable(HttpException err) {
    if (err.statusCode == 404 || err.statusCode == 405 || err.statusCode == 501) {
      return true;
    }
    if (err.statusCode == 400) {
      final msg = err.message.toLowerCase();
      if (msg.contains('route') ||
          msg.contains('endpoint') ||
          msg.contains('not found') ||
          msg.contains('not available') ||
          msg.contains('cannot')) {
        return true;
      }
    }
    return false;
  }
}


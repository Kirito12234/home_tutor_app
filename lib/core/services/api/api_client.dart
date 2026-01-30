import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) {
    final base = apiBaseUrl();
    final normalized = path.startsWith('/') ? path : '/$path';
    final baseHasApi = base.endsWith('/api/v1');
    final pathHasApi = normalized.startsWith('/api/v1/');
    final effectivePath = baseHasApi && pathHasApi
        ? normalized.substring('/api/v1'.length)
        : normalized;
    return Uri.parse('$base$effectivePath');
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
  }) async {
    final response = await _client.get(
      _uri(path),
      headers: _headers(token),
    );
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers(token),
      body: jsonEncode(body ?? const {}),
    );
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await _client.put(
      _uri(path),
      headers: _headers(token),
      body: jsonEncode(body ?? const {}),
    );
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    String? token,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    if (fields != null) {
      request.fields.addAll(fields);
    }
    if (files != null) {
      request.files.addAll(files);
    }
    request.headers.addAll(_headers(token));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    String? token,
  }) async {
    final response = await _client.delete(
      _uri(path),
      headers: _headers(token),
    );
    return _decodeJson(response);
  }

  Map<String, String> _headers(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    final payload = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (payload is Map<String, dynamic>) {
        return payload;
      }
      return {'data': payload};
    }

    final message = payload is Map<String, dynamic>
        ? payload['message']?.toString()
        : payload.toString();
    throw HttpException(
      response.statusCode,
      message ?? 'Request failed',
    );
  }
}

class HttpException implements Exception {
  HttpException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'HttpException($statusCode): $message';
}

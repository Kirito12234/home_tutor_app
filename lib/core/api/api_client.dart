import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_endpoints.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _requestTimeout = Duration(seconds: 20);

  String _serverLabel() {
    final base = apiBaseUrl();
    try {
      final uri = Uri.parse(base);
      if (uri.hasScheme && uri.host.isNotEmpty) {
        return uri.origin;
      }
      return base;
    } catch (_) {
      return base;
    }
  }

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
    final response = await _safeRequest(
      () => _client.get(
        _uri(path),
        headers: _headers(token),
      ),
    );
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await _safeRequest(
      () => _client.post(
        _uri(path),
        headers: _headers(token),
        body: jsonEncode(body ?? const {}),
      ),
    );
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await _safeRequest(
      () => _client.put(
        _uri(path),
        headers: _headers(token),
        body: jsonEncode(body ?? const {}),
      ),
    );
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await _safeRequest(
      () => _client.patch(
        _uri(path),
        headers: _headers(token),
        body: jsonEncode(body ?? const {}),
      ),
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
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final streamed = await _safeMultipartSend(request);
    final response = await http.Response.fromStream(streamed)
        .timeout(_requestTimeout);
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    String? token,
  }) async {
    final response = await _safeRequest(
      () => _client.delete(
        _uri(path),
        headers: _headers(token),
      ),
    );
    return _decodeJson(response);
  }

  Future<http.Response> _safeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_requestTimeout);
    } on SocketException {
      throw HttpException(0, 'Lost connection. Check internet/server and try again.');
    } on HandshakeException {
      throw HttpException(0, 'Secure connection failed. Please try again.');
    } on TimeoutException {
      throw HttpException(
        0,
        'Request timeout. Server: ${_serverLabel()}. If you are on a real device, set the API server to a LAN IP/domain reachable from your phone.',
      );
    } on http.ClientException catch (err) {
      throw HttpException(0, err.message);
    }
  }

  Future<http.StreamedResponse> _safeMultipartSend(
    http.MultipartRequest request,
  ) async {
    try {
      return await request.send().timeout(_requestTimeout);
    } on SocketException {
      throw HttpException(0, 'Lost connection. Check internet/server and try again.');
    } on HandshakeException {
      throw HttpException(0, 'Secure connection failed. Please try again.');
    } on TimeoutException {
      throw HttpException(
        0,
        'Upload timeout. Server: ${_serverLabel()}. Please try again.',
      );
    } on http.ClientException catch (err) {
      throw HttpException(0, err.message);
    }
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
    if (response.body.trim().isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const <String, dynamic>{};
      }
      throw HttpException(response.statusCode, 'Empty response from server');
    }
    dynamic payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return <String, dynamic>{'data': response.body};
      }
      throw HttpException(response.statusCode, 'Invalid server response');
    }
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


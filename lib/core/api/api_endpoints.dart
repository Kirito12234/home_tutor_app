import 'dart:io';

import 'package:flutter/foundation.dart';
import '../services/hive/hive_service.dart';

String apiBaseUrl() {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) {
    return _normalizeApiBaseUrl(override);
  }
  const lanHost = String.fromEnvironment('API_LAN_HOST');
  if (lanHost.isNotEmpty) {
    return _normalizeApiBaseUrl('http://$lanHost:5000/api/v1');
  }
  final storedOverride = HiveService.apiBaseUrlOverride;
  if (storedOverride != null && storedOverride.isNotEmpty) {
    return _normalizeApiBaseUrl(storedOverride);
  }

  if (kIsWeb) {
    return 'http://localhost:5000/api/v1';
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:5000/api/v1';
  }
  if (Platform.isIOS) {
    return 'http://localhost:5000/api/v1';
  }
  return 'http://localhost:5000/api/v1';
}

String _normalizeApiBaseUrl(String url) {
  var value = url.trim();
  if (value.isEmpty) {
    return value;
  }
  if (!kIsWeb && Platform.isAndroid) {
    value = value
        .replaceFirst('://localhost', '://10.0.2.2')
        .replaceFirst('://127.0.0.1', '://10.0.2.2');
  }
  value = value.replaceFirst('localhost:3000', 'localhost:5000');
  value = value.replaceFirst('10.0.2.2:3000', '10.0.2.2:5000');
  if (!kIsWeb && Platform.isAndroid) {
    value = value
        .replaceFirst('localhost:5000', '10.0.2.2:5000')
        .replaceFirst('127.0.0.1:5000', '10.0.2.2:5000');
  }
  if (!value.endsWith('/api/v1')) {
    value = value.endsWith('/') ? '${value}api/v1' : '$value/api/v1';
  }
  return value;
}

String socketBaseUrl() {
  final base = apiBaseUrl();
  const suffix = '/api/v1';
  if (base.endsWith(suffix)) {
    return base.substring(0, base.length - suffix.length);
  }
  return base;
}


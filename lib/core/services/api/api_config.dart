import 'dart:io';

import 'package:flutter/foundation.dart';
import '../hive/hive_service.dart';

const bool isPhysicalDevice = false;
const String compIpAddress = "192.168.1.1";

String apiBaseUrl() {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) {
    return override;
  }
  final storedOverride = HiveService.apiBaseUrlOverride;
  if (storedOverride != null && storedOverride.isNotEmpty) {
    return storedOverride;
  }

  if (isPhysicalDevice) {
    return 'http://$compIpAddress:3000/api/v1';
  }

  if (kIsWeb) {
    return 'http://localhost:3000/api/v1';
  } else if (Platform.isAndroid) {
    return 'http://10.0.2.2:3000/api/v1';
  } else if (Platform.isIOS) {
    return 'http://localhost:3000/api/v1';
  }
  return 'http://localhost:3000/api/v1';
}

String socketBaseUrl() {
  final base = apiBaseUrl();
  const suffix = '/api/v1';
  if (base.endsWith(suffix)) {
    return base.substring(0, base.length - suffix.length);
  }
  return base;
}

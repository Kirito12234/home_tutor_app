import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_tutor_app/core/api/api_endpoints.dart';
import 'package:home_tutor_app/core/services/hive/hive_service.dart';
import '../utils/hive_test_utils.dart';

void main() {
  setUpAll(() async {
    await HiveTestUtils.ensureInitialized();
  });

  tearDownAll(() async {
    await HiveTestUtils.dispose();
  });

  setUp(() async {
    await HiveTestUtils.clearBox();
  });

  group('apiConfig', () {
    test('base URL is not empty', () {
      final base = apiBaseUrl();
      expect(base, isNotEmpty);
      expect(base.startsWith('http'), isTrue);
    });

    test('endpoint URLs are correctly formed', () {
      final base = apiBaseUrl();
      expect(base.endsWith('/api/v1'), isTrue);
      final socketBase = socketBaseUrl();
      expect(socketBase.endsWith('/api/v1'), isFalse);
    });

    test('environment config loads correctly', () async {
      const override = 'http://example.com/api/v1';
      await HiveService.setApiBaseUrlOverride(override);
      expect(apiBaseUrl(), equals(override));
      expect(socketBaseUrl(), equals('http://example.com'));
    });
  });

  test('api base url uses localhost on non-android targets', () {
    if (Platform.isAndroid) {
      return;
    }
    expect(apiBaseUrl(), contains('localhost:5000'));
  });
}


import 'package:flutter_test/flutter_test.dart';
import 'package:home_tutor_app/core/api/api_endpoints.dart';
import 'package:home_tutor_app/core/services/hive/hive_service.dart';

import '../utils/hive_test_utils.dart';

void main() {
  setUpAll(HiveTestUtils.ensureInitialized);
  tearDownAll(HiveTestUtils.dispose);

  setUp(HiveTestUtils.clearBox);

  test('setCurrentUserAvatarUrl stores a trimmed value', () async {
    await HiveService.setCurrentUserAvatarUrl('  /uploads/avatar.png  ');
    expect(HiveService.currentUserAvatarUrl, '/uploads/avatar.png');
  });

  test('setCurrentUserAvatarUrl clears on null', () async {
    await HiveService.setCurrentUserAvatarUrl('/uploads/avatar.png');
    await HiveService.setCurrentUserAvatarUrl(null);
    expect(HiveService.currentUserAvatarUrl, isNull);
  });

  test('setAuthToken clears on empty string', () async {
    await HiveService.setAuthToken('token');
    await HiveService.setAuthToken('');
    expect(HiveService.authToken, isNull);
  });

  test('hashPassword is deterministic and not equal to raw input', () {
    const password = 'secret123';
    final hash1 = HiveService.hashPassword(password);
    final hash2 = HiveService.hashPassword(password);
    expect(hash1, hash2);
    expect(hash1, isNot(password));
  });

  test('socketBaseUrl strips /api/v1 from override', () async {
    await HiveService.setApiBaseUrlOverride('http://example.com/api/v1');
    expect(socketBaseUrl(), 'http://example.com');
    await HiveService.setApiBaseUrlOverride(null);
  });
}


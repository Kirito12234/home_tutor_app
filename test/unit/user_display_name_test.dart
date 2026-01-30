import 'package:flutter_test/flutter_test.dart';
import 'package:home_tutor_app/core/constants/user_display_name.dart';

void main() {
  group('displayNameFromUser', () {
    test('returns fallback value when name is null', () {
      expect(displayNameFromUser(null), equals('Student'));
    });

    test('trims whitespace correctly', () {
      expect(displayNameFromUser('  john  '), equals('john'));
    });

    test('handles empty string safely', () {
      expect(displayNameFromUser(''), equals('Student'));
      expect(displayNameFromUser('   '), equals('Student'));
    });
  });
}

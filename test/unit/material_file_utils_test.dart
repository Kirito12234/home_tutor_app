import 'package:flutter_test/flutter_test.dart';
import 'package:home_tutor_app/core/utils/material_file_utils.dart';

void main() {
  group('sanitizeFileName', () {
    test('returns fallback for empty string', () {
      expect(sanitizeFileName(''), equals('file'));
      expect(sanitizeFileName('   '), equals('file'));
    });

    test('trims whitespace', () {
      expect(sanitizeFileName('  report.pdf  '), equals('report.pdf'));
    });

    test('replaces illegal characters', () {
      expect(
        sanitizeFileName('a<>:"/\\\\|?*b\u0001c.pdf'),
        equals('a__________b_c.pdf'),
      );
    });

    test('truncates long names', () {
      final input = 'a' * 200;
      final out = sanitizeFileName(input, maxLength: 120);
      expect(out.length, equals(120));
      expect(out, equals('a' * 120));
    });
  });

  group('isLocalFilePath', () {
    test('detects unix absolute paths', () {
      expect(isLocalFilePath('/storage/emulated/0/Download/a.pdf'), isTrue);
    });

    test('detects file scheme', () {
      expect(isLocalFilePath('file:///tmp/a.pdf'), isTrue);
      expect(isLocalFilePath('FILE://C:\\\\tmp\\\\a.pdf'), isTrue);
    });

    test('detects windows drive paths', () {
      expect(isLocalFilePath('C:\\\\Users\\\\me\\\\a.pdf'), isTrue);
    });

    test('detects UNC paths', () {
      expect(isLocalFilePath('\\\\\\\\server\\\\share\\\\a.pdf'), isTrue);
    });

    test('does not match http urls', () {
      expect(isLocalFilePath('https://example.com/a.pdf'), isFalse);
    });
  });

  group('fileNameFromUrl', () {
    test('keeps existing extension from url', () {
      expect(
        fileNameFromUrl(
          url: 'https://example.com/files/report.final.pdf?x=1',
          title: 'Ignored',
          extension: 'pdf',
        ),
        equals('report.final.pdf'),
      );
    });

    test('appends extension when missing', () {
      expect(
        fileNameFromUrl(
          url: 'https://example.com/files/report',
          title: 'Ignored',
          extension: 'pdf',
        ),
        equals('report.pdf'),
      );
    });

    test('falls back to title when url has no filename', () {
      expect(
        fileNameFromUrl(
          url: 'https://example.com',
          title: 'My Notes',
          extension: 'pdf',
        ),
        equals('My Notes.pdf'),
      );
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:home_tutor_app/core/services/hive/hive_service.dart';

class HiveTestUtils {
  static Directory? _tempDir;

  static Future<void> ensureInitialized() async {
    if (_tempDir != null) {
      return;
    }
    TestWidgetsFlutterBinding.ensureInitialized();
    _tempDir = await Directory.systemTemp.createTemp('hometutor_test_');
    Hive.init(_tempDir!.path);
    await Hive.openBox(HiveService.settingsBoxName);
  }

  static Future<void> clearBox() async {
    if (Hive.isBoxOpen(HiveService.settingsBoxName)) {
      await Hive.box(HiveService.settingsBoxName).clear();
    }
  }

  static Future<void> dispose() async {
    await Hive.close();
    if (_tempDir != null) {
      await _tempDir!.delete(recursive: true);
      _tempDir = null;
    }
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'material_file_utils.dart';

Future<Directory> _bestBaseDir() async {
  if (Platform.isAndroid) {
    final external = await getExternalStorageDirectory();
    if (external != null) {
      return external;
    }
  }
  return getApplicationDocumentsDirectory();
}

Future<Directory> _downloadsDir() async {
  final base = await _bestBaseDir();
  final dir = Directory('${base.path}${Platform.pathSeparator}downloads');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<String?> writeBytesToLocalFileImpl({
  required Uint8List bytes,
  required String fileName,
}) async {
  final name = sanitizeFileName(fileName);
  final dir = await _downloadsDir();
  final file = File('${dir.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<String?> downloadToLocalFileImpl({
  required Uri uri,
  required String fileName,
  Map<String, String>? headers,
}) async {
  final response = await http.get(uri, headers: headers);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    return null;
  }
  return writeBytesToLocalFileImpl(
    bytes: response.bodyBytes,
    fileName: fileName,
  );
}

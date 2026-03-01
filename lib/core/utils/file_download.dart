import 'dart:typed_data';

import 'file_download_stub.dart'
    if (dart.library.io) 'file_download_io.dart';

Future<String?> writeBytesToLocalFile({
  required Uint8List bytes,
  required String fileName,
}) {
  return writeBytesToLocalFileImpl(bytes: bytes, fileName: fileName);
}

Future<String?> downloadToLocalFile({
  required Uri uri,
  required String fileName,
  Map<String, String>? headers,
}) {
  return downloadToLocalFileImpl(uri: uri, fileName: fileName, headers: headers);
}

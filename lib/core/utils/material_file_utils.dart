String sanitizeFileName(String name, {int maxLength = 120}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return 'file';
  }
  final replaced =
      trimmed.replaceAll(RegExp(r'[<>:"/\\|?*\u0000-\u001F]'), '_');
  if (replaced.length <= maxLength) {
    return replaced;
  }
  return replaced.substring(0, maxLength);
}

bool isLocalFilePath(String value) {
  final lower = value.toLowerCase();
  return value.startsWith('/') ||
      lower.startsWith('file://') ||
      lower.contains(':\\') ||
      lower.startsWith(r'\\');
}

String stripFileScheme(String value) {
  return value.replaceFirst(RegExp('^file://', caseSensitive: false), '');
}

String fileNameFromUrl({
  required String url,
  required String title,
  required String extension,
}) {
  final raw = stripFileScheme(url).trim();
  final uri = Uri.tryParse(raw);
  final String last;
  if (uri == null) {
    last = raw.split('/').last.split('\\').last;
  } else if (uri.hasAuthority &&
      (uri.path.isEmpty || uri.path == '/' || uri.pathSegments.isEmpty)) {
    last = '';
  } else if (uri.pathSegments.isNotEmpty) {
    last = uri.pathSegments.last;
  } else {
    last = raw.split('/').last.split('\\').last;
  }
  final base = last.trim().isEmpty ? title.trim() : last.trim();
  if (base.contains('.')) {
    return base;
  }
  final safeExt = extension.trim().isEmpty ? 'bin' : extension.trim();
  return '$base.$safeExt';
}

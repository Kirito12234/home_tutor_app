String displayNameFromUser(String? rawName) {
  final value = (rawName ?? '').trim();
  if (value.isEmpty) {
    return 'Student';
  }

  if (!value.contains('@')) {
    return value;
  }

  final namePart = value.split('@').first.trim();
  if (namePart.isEmpty) {
    return 'Student';
  }

  final cleaned = namePart.replaceAll(RegExp(r'[._-]+'), ' ').trim();
  if (cleaned.isEmpty) {
    return namePart;
  }

  final withoutNumbers = cleaned.replaceAll(RegExp(r'\d+'), ' ').trim();
  if (withoutNumbers.isEmpty) {
    return cleaned;
  }

  return withoutNumbers
      .split(RegExp(r'\s+'))
      .map((part) {
        if (part.isEmpty) {
          return part;
        }
        final first = part.substring(0, 1).toUpperCase();
        final rest = part.length > 1 ? part.substring(1) : '';
        return '$first$rest';
      })
      .join(' ');
}

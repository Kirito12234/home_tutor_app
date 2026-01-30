class Lesson {
  final String id;
  final String title;
  final int durationMinutes;
  final bool isCompleted;
  final bool isLocked;
  final int order;
  final String? imageUrl;
  final String? pdfUrl;

  Lesson({
    required this.id,
    required this.title,
    required this.durationMinutes,
    this.isCompleted = false,
    this.isLocked = false,
    required this.order,
    this.imageUrl,
    this.pdfUrl,
  });
}


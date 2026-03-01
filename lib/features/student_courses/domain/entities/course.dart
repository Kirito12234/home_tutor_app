import '../../../student_dashboard/domain/entities/lesson.dart';

class Course {
  final String id;
  final String title;
  final String instructor;
  final String? tutorId;
  final double price;
  final int durationHours;
  final int lessonCount;
  final String category;
  final String? imageUrl;
  final String description;
  final bool isBestseller;
  final bool isPopular;
  final bool isNew;
  final List<Lesson> lessons;

  Course({
    required this.id,
    required this.title,
    required this.instructor,
    this.tutorId,
    required this.price,
    required this.durationHours,
    required this.lessonCount,
    required this.category,
    this.imageUrl,
    required this.description,
    this.isBestseller = false,
    this.isPopular = false,
    this.isNew = false,
    required this.lessons,
  });
}



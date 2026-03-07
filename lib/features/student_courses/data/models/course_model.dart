import '../../domain/entities/course.dart';
import '../../../student_dashboard/domain/entities/lesson.dart';

class CourseModel {
  const CourseModel({
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
  });

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

  static double _readPrice(Object? raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      final normalized = raw.replaceAll(',', '').trim();
      return double.tryParse(normalized) ?? 0;
    }
    return 0;
  }

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final tutor = json['tutor'];
    final tutorMap = tutor is Map<String, dynamic> ? tutor : null;
    final tutorName = tutorMap?['name']?.toString();
    final instructorName = json['instructorName']?.toString();

    return CourseModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Course',
      instructor: (instructorName != null && instructorName.trim().isNotEmpty)
          ? instructorName
          : (tutorName != null && tutorName.trim().isNotEmpty)
              ? tutorName
              : 'Instructor',
      tutorId: tutorMap?['_id']?.toString() ??
          tutorMap?['id']?.toString() ??
          json['tutorId']?.toString(),
      price: _readPrice(json['price']),
      durationHours: (json['durationHours'] as num?)?.toInt() ?? 0,
      lessonCount: (json['lessonCount'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString() ?? 'General',
      imageUrl: json['imageUrl']?.toString(),
      description: json['description']?.toString() ?? '',
      isBestseller: json['isBestseller'] == true,
      isPopular: json['isPopular'] == true,
      isNew: json['isNew'] == true,
    );
  }

  Course toEntity({List<Lesson> lessons = const <Lesson>[]}) {
    return Course(
      id: id.isEmpty ? 'course' : id,
      title: title,
      instructor: instructor,
      tutorId: tutorId,
      price: price,
      durationHours: durationHours,
      lessonCount: lessonCount,
      category: category,
      imageUrl: imageUrl,
      description: description,
      isBestseller: isBestseller,
      isPopular: isPopular,
      isNew: isNew,
      lessons: lessons,
    );
  }
}


import 'package:flutter_test/flutter_test.dart';
import 'package:home_tutor_app/core/constants/learning_plan_courses.dart';

void main() {
  group('buildLearningPlanCourses', () {
    test('courses list is not empty', () {
      final courses = buildLearningPlanCourses();
      expect(courses, isNotEmpty);
    });

    test('each course has required fields', () {
      final courses = buildLearningPlanCourses();
      for (final course in courses) {
        expect(course.id.trim(), isNotEmpty);
        expect(course.title.trim(), isNotEmpty);
        expect(course.description.trim(), isNotEmpty);
        expect(course.level.trim(), isNotEmpty);
        expect(course.mentor.trim(), isNotEmpty);
        expect(course.total, greaterThan(0));
        expect(course.weeks, greaterThan(0));
        expect(course.modules, isNotEmpty);
        expect(course.completed, inInclusiveRange(1, course.total));
      }
    });

    test('known course ID exists', () {
      final courses = buildLearningPlanCourses();
      expect(courses.any((course) => course.id == 'ethical-hacking-0'), isTrue);
    });
  });
}

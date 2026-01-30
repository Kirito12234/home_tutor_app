import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../widgets/my_courses_header.dart';
import '../widgets/course_progress_tile.dart';
import '../../../dashboard/presentation/widgets/bottom_nav.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../dashboard/domain/entities/lesson.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({Key? key}) : super(key: key);

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  int _currentNavIndex = 0;
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getJson(
        '/api/v1/enrollments',
        token: HiveService.authToken,
      );
      final data = response['data'];
      if (data is List) {
        final colors = [
          AppColors.favoriteOrangeLight,
          AppColors.categoryBlue,
          AppColors.backgroundLight,
          AppColors.categoryBeige,
        ];
        final progressColors = [
          AppColors.durationOrange,
          AppColors.primary,
          AppColors.primary,
          AppColors.durationOrange,
        ];
        final mapped = <Map<String, dynamic>>[];
        for (var i = 0; i < data.length; i++) {
          final enrollment = data[i];
          if (enrollment is! Map<String, dynamic>) {
            continue;
          }
          final course = enrollment['course'];
          final courseMap = course is Map<String, dynamic> ? course : <String, dynamic>{};
          final lessonCount = courseMap['lessonCount'];
          final total = lessonCount is num && lessonCount > 0 ? lessonCount.toInt() : 1;
          final progressPercent = enrollment['progressPercent'];
          final progressValue = progressPercent is num ? progressPercent.toDouble() : 0.0;
          final completed = ((progressValue / 100) * total).round();
          final courseEntity = _mapCourse(courseMap);

          mapped.add({
            'title': courseEntity.title,
            'completed': completed,
            'total': total,
            'cardColor': colors[i % colors.length],
            'progressColor': progressColors[i % progressColors.length],
            'course': courseEntity,
          });
        }
        setState(() {
          _courses
            ..clear()
            ..addAll(mapped);
        });
      } else {
        setState(() {
          _errorMessage = 'Unexpected response format.';
        });
      }
    } on HttpException catch (err) {
      setState(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to load enrollments.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Course _mapCourse(Map<String, dynamic> course) {
    final tutor = course['tutor'];
    final tutorName =
        tutor is Map<String, dynamic> ? tutor['name']?.toString() : null;
    return Course(
      id: course['_id']?.toString() ?? course['id']?.toString() ?? 'course',
      title: course['title']?.toString() ?? 'Course',
      instructor: course['instructorName']?.toString() ?? tutorName ?? 'Instructor',
      price: (course['price'] as num?)?.toDouble() ?? 0,
      durationHours: (course['durationHours'] as num?)?.toInt() ?? 0,
      lessonCount: (course['lessonCount'] as num?)?.toInt() ?? 0,
      category: course['category']?.toString() ?? 'General',
      imageUrl: course['imageUrl']?.toString(),
      description: course['description']?.toString() ?? '',
      isBestseller: course['isBestseller'] == true,
      isPopular: course['isPopular'] == true,
      isNew: course['isNew'] == true,
      lessons: const <Lesson>[],
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.courses);
        break;
      case 2:
        Navigator.of(context).pushNamed(AppRoutes.searchResults);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.notifications);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.account);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My courses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: Column(
        children: [
          const MyCoursesHeader(),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.redAccent,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  return CourseProgressTile(
                    title: course['title'] as String,
                    completed: course['completed'] as int,
                    total: course['total'] as int,
                    cardColor: course['cardColor'] as Color,
                    progressColor: course['progressColor'] as Color,
                    onTap: () {
                      final matchingCourse = course['course'] as Course;
                      Navigator.of(context).pushNamed(
                        AppRoutes.courseDetail,
                        arguments: matchingCourse,
                      );
                    },
                  );
                },
              ),
            ),
          BottomNav(
            currentIndex: _currentNavIndex,
            onTap: _onNavTap,
          ),
        ],
      ),
    );
  }
}


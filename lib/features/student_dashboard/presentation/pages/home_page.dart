import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../student_courses/domain/entities/course.dart';
import '../../../student_courses/presentation/widgets/course_list_item.dart';
import '../../domain/entities/lesson.dart';
import '../widgets/header_greeting.dart';
import '../widgets/learned_today_card.dart';
import '../widgets/learn_banner_card.dart';
import '../widgets/bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;
  final ApiClient _apiClient = ApiClient();
  final List<Course> _courses = <Course>[];
  bool _isLoadingCourses = false;

  void _onNavTap(int index) {
    if (index == _currentNavIndex) {
      return;
    }
    setState(() {
      _currentNavIndex = index;
    });
    switch (index) {
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.courses);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.searchResults);
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
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoadingCourses = true;
    });
    try {
      final response = await _apiClient.getJson(
        '/api/v1/courses?status=approved',
        token: HiveService.authToken,
      );
      final data = response['data'];
      if (data is! List) {
        return;
      }
      final mapped = data
          .whereType<Map<String, dynamic>>()
          .map(_mapCourse)
          .toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _courses
          ..clear()
          ..addAll(mapped);
      });
    } catch (_) {
      // Keep home stable even if courses fail to load.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCourses = false;
        });
      }
    }
  }

  Course _mapCourse(Map<String, dynamic> course) {
    final tutor = course['tutor'];
    final tutorName =
        tutor is Map<String, dynamic> ? tutor['name']?.toString() : null;
    final tutorId =
        tutor is Map<String, dynamic> ? tutor['_id']?.toString() : null;
    return Course(
      id: course['_id']?.toString() ?? course['id']?.toString() ?? 'course',
      title: course['title']?.toString() ?? 'Course',
      instructor:
          course['instructorName']?.toString() ?? tutorName ?? 'Instructor',
      tutorId: tutorId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderGreeting(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const LearnedTodayCard(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          LearnBannerCard(
                            isLeft: true,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.learnToday);
                            },
                          ),
                          LearnBannerCard(
                            isLeft: false,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.learnToday);
                            },
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.meetup);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.categoryPurple,
                              AppColors.categoryPurple.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 40,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Meetup',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Join the community',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Courses (${_courses.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRoutes.courses),
                            child: const Text(
                              'View all',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isLoadingCourses)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (!_isLoadingCourses)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: _courses
                              .map(
                                (course) => CourseListItem(
                                  course: course,
                                  showOpenButton: true,
                                  onTap: () => Navigator.of(context).pushNamed(
                                    AppRoutes.courseDetail,
                                    arguments: course,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            BottomNav(
              currentIndex: _currentNavIndex,
              onTap: _onNavTap,
            ),
          ],
        ),
      ),
    );
  }
}


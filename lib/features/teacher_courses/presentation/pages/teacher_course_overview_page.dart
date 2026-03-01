import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/learning_plan_courses.dart';

class TeacherCourseOverviewPage extends StatelessWidget {
  const TeacherCourseOverviewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final planCourses = buildLearningPlanCourses().take(10).toList();
    final courses = List<Map<String, String>>.generate(planCourses.length, (index) {
      final course = planCourses[index];
      final status = course.completed >= course.total ? 'Completed' : 'Active';
      return {
        'title': course.title,
        'subtitle': course.description,
        'level': course.level,
        'mentor': course.mentor,
        'weeks': '${course.weeks} weeks',
        'progress': '${course.completed} / ${course.total}',
        'students': '${20 + (index * 2)} students',
        'status': status,
      };
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.teacherHome,
            (route) => false,
          ),
        ),
        title: const Text(
          'Courses',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: courses
            .map(
              (course) => GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.teacherCourseDetail,
                    arguments: course,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.categoryBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.menu_book, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course['title']!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              course['subtitle']!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${course['level']} - ${course['mentor']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${course['weeks']} - ${course['progress']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              course['students']!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          course['status']!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}



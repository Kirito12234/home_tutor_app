import 'package:flutter/material.dart';



import '../../../../app/theme/app_colors.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/constants/learning_plan_courses.dart';

class LearningPlanCard extends StatefulWidget {
  const LearningPlanCard({Key? key}) : super(key: key);

  @override
  State<LearningPlanCard> createState() => _LearningPlanCardState();
}

class _LearningPlanCardState extends State<LearningPlanCard> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  List<LearningPlanCourse> _courses = buildLearningPlanCourses();

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _errorMessage = null;
      _courses = buildLearningPlanCourses();
    });
  }

  LearningPlanCourse _mapPlanToCourse(Map<String, dynamic> plan) {
    final id = plan['_id']?.toString() ?? plan['id']?.toString() ?? 'plan';
    final title = plan['title']?.toString() ?? 'Learning Plan';
    final description = plan['description']?.toString() ?? '';
    return LearningPlanCourse(
      id: id,
      title: title,
      description: description,
      level: 'Beginner',
      mentor: 'Mentor',
      completed: 0,
      total: 1,
      weeks: 1,
      modules: const ['Session'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = _courses;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Learning Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'All courses available in Nepal',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          if (!_isLoading && _errorMessage == null && courses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No learning plans yet.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final course = courses[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.learningPlanDetail,
                    arguments: course,
                  );
                },
                child: _buildPlanItem(course.title, course.completed, course.total),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlanItem(String title, int completed, int total) {
    final progress = completed / total;
    return Row(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: AppColors.backgroundLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              Center(
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$completed / $total',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


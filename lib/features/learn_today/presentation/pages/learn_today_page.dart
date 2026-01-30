import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

class LearnTodayPage extends StatelessWidget {
  const LearnTodayPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final courses = [
      {
        'title': 'Ethical Hacking Fundamentals',
        'subtitle': 'Security labs, network scanning, CTF basics',
        'level': 'Beginner',
      },
      {
        'title': 'AI with Data Science',
        'subtitle': 'Python, ML workflows, data visualization',
        'level': 'Intermediate',
      },
      {
        'title': 'Flutter Mobile Apps',
        'subtitle': 'UI, state, and Firebase integration',
        'level': 'Intermediate',
      },
      {
        'title': 'Cloud & DevOps',
        'subtitle': 'Docker, CI/CD, and deployment skills',
        'level': 'Beginner',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Learn Today',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.categoryBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pick a focus for today',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'IT field courses available in Nepal',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Explore all courses',
                  height: 44,
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.courses);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recommended now',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          ...courses.map(
            (course) => _LearnTodayCourseCard(
              title: course['title']!,
              subtitle: course['subtitle']!,
              level: course['level']!,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnTodayCourseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String level;

  const _LearnTodayCourseCard({
    required this.title,
    required this.subtitle,
    required this.level,
  });

  void _showAction(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.categoryBeige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  level,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.durationOrange,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showAction(context, 'Added to learning plan'),
                child: const Text(
                  'Add to plan',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showAction(context, 'Starting $title'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.buttonText,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class LearnedTodayCard extends StatelessWidget {
  final int currentMinutes;
  final int totalMinutes;

  const LearnedTodayCard({
    Key? key,
    this.currentMinutes = 46,
    this.totalMinutes = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = currentMinutes / totalMinutes;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(AppRoutes.clockingIn);
      },
      child: Container(
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
              'Learned today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'OpenSans',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentMinutes min / $totalMinutes min',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'OpenSans',
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.durationOrange,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.backgroundLight,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.durationOrange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



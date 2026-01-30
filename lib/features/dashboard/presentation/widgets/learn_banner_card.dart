import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

class LearnBannerCard extends StatelessWidget {
  final bool isLeft;
  final VoidCallback? onTap;

  const LearnBannerCard({
    Key? key,
    this.isLeft = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLeft) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.categoryBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.school,
                    size: 40,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'What do you want to learn today?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Get Started',
                  onPressed: onTap,
                  height: 40,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.categoryBeige,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.workspace_premium,
                  size: 42,
                  color: AppColors.durationOrange,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Learn today',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Learn today',
                    onPressed: onTap,
                    height: 40,
                    borderRadius: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}


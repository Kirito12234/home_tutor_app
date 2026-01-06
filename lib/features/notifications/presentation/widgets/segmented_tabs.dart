import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class SegmentedTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool showNotificationDot;

  const SegmentedTabs({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
    this.showNotificationDot = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => onTap(0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selectedIndex == 0
                      ? AppColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              'message',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: selectedIndex == 0
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: () => onTap(1),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selectedIndex == 1
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'notification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selectedIndex == 1
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              if (showNotificationDot) ...[
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.durationOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}


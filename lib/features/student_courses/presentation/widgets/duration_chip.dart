import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class DurationChip extends StatelessWidget {
  final String duration;
  final bool isSelected;

  const DurationChip({
    Key? key,
    required this.duration,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        duration,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? AppColors.buttonText : AppColors.textSecondary,
          fontFamily: 'OpenSans',
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}



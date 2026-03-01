import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class PinDotsRow extends StatelessWidget {
  final int filledCount;
  final int totalCount;

  const PinDotsRow({
    Key? key,
    required this.filledCount,
    this.totalCount = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalCount,
        (index) => Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: index < filledCount
                  ? AppColors.textPrimary
                  : AppColors.inputBorder,
              width: 2,
            ),
            color: index < filledCount
                ? AppColors.textPrimary
                : Colors.transparent,
          ),
        ),
      ),
    );
  }
}


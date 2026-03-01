import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class WeekRecordDots extends StatelessWidget {
  final int activeDays;

  const WeekRecordDots({
    Key? key,
    this.activeDays = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dotSize = ((constraints.maxWidth - 48) / 7).clamp(28.0, 40.0);
        final fontSize = (dotSize * 0.4).clamp(12.0, 16.0);

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: List.generate(
            7,
            (index) => Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: index < activeDays
                    ? AppColors.primary
                    : AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: index < activeDays
                        ? AppColors.buttonText
                        : AppColors.textSecondary,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}



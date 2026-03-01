import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class PageDots extends StatelessWidget {
  final int currentIndex;
  final int totalPages;

  const PageDots({
    Key? key,
    required this.currentIndex,
    required this.totalPages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => Container(
          width: index == currentIndex ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index == currentIndex
                ? AppColors.dotActive
                : AppColors.dotInactive,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}


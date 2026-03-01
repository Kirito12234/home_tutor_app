import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class SocialButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback? onPressed;

  const SocialButton({
    Key? key,
    required this.iconPath,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.inputBorder),
          color: AppColors.background,
        ),
        child: Center(
          child: Image.asset(
            iconPath,
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                iconPath.contains('google') ? Icons.g_mobiledata : Icons.facebook,
                size: 24,
                color: AppColors.textPrimary,
              );
            },
          ),
        ),
      ),
    );
  }
}


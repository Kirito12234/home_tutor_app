import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageAsset;
  final String? primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final bool showBack;
  final Widget? customIllustration;

  const EmptyStateView({
    Key? key,
    required this.title,
    required this.subtitle,
    this.imageAsset,
    this.primaryButtonText,
    this.onPrimaryPressed,
    this.showBack = true,
    this.customIllustration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: showBack
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(
                  Icons.visibility_off_outlined,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Illustration
              if (customIllustration != null)
                customIllustration!
              else if (imageAsset != null)
                Image.asset(
                  imageAsset!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                )
              else
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 40),
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Subtitle
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              // Primary Button
              if (primaryButtonText != null && onPrimaryPressed != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: PrimaryButton(
                    text: primaryButtonText!,
                    onPressed: onPrimaryPressed,
                  ),
                ),
              ] else
                const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}


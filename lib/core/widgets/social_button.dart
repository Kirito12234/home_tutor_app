import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/theme/app_colors.dart';

class SocialButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  const SocialButton({
    Key? key,
    required this.iconPath,
    this.onPressed,
    this.semanticLabel,
  }) : super(key: key);

  Widget _buildIcon() {
    if (iconPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        semanticsLabel: semanticLabel,
        placeholderBuilder: (_) => _fallbackIcon(),
      );
    }

    return Image.asset(
      iconPath,
      width: 24,
      height: 24,
      errorBuilder: (_, __, ___) => _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Icon(
      iconPath.toLowerCase().contains('google')
          ? Icons.g_mobiledata
          : Icons.facebook,
      size: 24,
      color: AppColors.textPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkResponse(
          onTap: onPressed,
          radius: 32,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.inputBorder),
              color: AppColors.background,
            ),
            child: Center(child: _buildIcon()),
          ),
        ),
      ),
    );
  }
}


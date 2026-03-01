import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final String? initialValue;

  const AppTextField({
    Key? key,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.initialValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      initialValue: initialValue,
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        fontFamily: 'OpenSans',
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 16,
          color: AppColors.textSecondary,
          fontFamily: 'OpenSans',
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}



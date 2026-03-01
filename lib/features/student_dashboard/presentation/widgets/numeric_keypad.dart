import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onNumberTap;
  final VoidCallback? onBackspace;

  const NumericKeypad({
    Key? key,
    required this.onNumberTap,
    this.onBackspace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 80),
              _buildKeypadButton('0'),
              _buildKeypadButton(
                '',
                icon: Icons.backspace,
                onTap: onBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String text, {IconData? icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => onNumberTap(text),
      child: Container(
        width: 80,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: AppColors.textPrimary, size: 24)
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'OpenSans',
                  ),
                ),
        ),
      ),
    );
  }
}



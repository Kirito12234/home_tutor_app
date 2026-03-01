import 'package:flutter/material.dart';
import '../../../../../app/routes/app_routes.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/primary_button.dart';

class PhoneContinuePage extends StatefulWidget {
  const PhoneContinuePage({Key? key}) : super(key: key);

  @override
  State<PhoneContinuePage> createState() => _PhoneContinuePageState();
}

class _PhoneContinuePageState extends State<PhoneContinuePage> {
  String _phoneNumber = '';

  void _onNumberTap(String number) {
    setState(() {
      _phoneNumber += number;
    });
  }

  void _onBackspace() {
    if (_phoneNumber.isNotEmpty) {
      setState(() {
        _phoneNumber = _phoneNumber.substring(0, _phoneNumber.length - 1);
      });
    }
  }

  void _onContinue() {
    if (_phoneNumber.length >= 10) {
      Navigator.of(context).pushNamed(
        AppRoutes.phoneVerify,
        arguments: _phoneNumber,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    'Continue with Phone',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          border: Border.all(color: AppColors.inputBorder),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          '+977',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            border: Border.all(color: AppColors.inputBorder),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _phoneNumber.isEmpty ? 'Phone number' : _phoneNumber,
                            style: TextStyle(
                              fontSize: 16,
                              color: _phoneNumber.isEmpty
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: PrimaryButton(
                          text: 'Continue',
                          onPressed: _phoneNumber.length >= 10 ? _onContinue : null,
                          height: 56,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            _buildKeypad(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
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
              _buildKeypadButton('*'),
              _buildKeypadButton('0'),
              _buildKeypadButton('#'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 80),
              _buildKeypadButton('+'),
              _buildKeypadButton(
                '',
                icon: Icons.backspace,
                onTap: _onBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String text, {IconData? icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => _onNumberTap(text),
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



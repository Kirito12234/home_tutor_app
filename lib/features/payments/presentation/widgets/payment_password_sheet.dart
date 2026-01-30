import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import 'pin_dots_row.dart';
import 'numeric_keypad.dart';

class PaymentPasswordSheet extends StatefulWidget {
  const PaymentPasswordSheet({
    Key? key,
    this.returnRoute,
    this.returnArgs,
    this.courseId,
    this.amount,
  }) : super(key: key);

  final String? returnRoute;
  final Object? returnArgs;
  final String? courseId;
  final double? amount;

  @override
  State<PaymentPasswordSheet> createState() => _PaymentPasswordSheetState();
}

class _PaymentPasswordSheetState extends State<PaymentPasswordSheet> {
  final ApiClient _apiClient = ApiClient();
  String _pin = '';
  bool _isSubmitting = false;
  String? _errorMessage;

  void _onNumberTap(String number) {
    if (_isSubmitting) {
      return;
    }
    if (_pin.length < 6) {
      setState(() {
        _pin += number;
        _errorMessage = null;
      });
      if (_pin.length == 6) {
        _submitPayment();
      }
    }
  }

  void _onBackspace() {
    if (_isSubmitting) {
      return;
    }
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _submitPayment() async {
    if (widget.courseId == null || widget.courseId!.isEmpty) {
      setState(() {
        _errorMessage = 'Missing course information.';
      });
      return;
    }
    if (widget.amount == null || widget.amount! <= 0) {
      setState(() {
        _errorMessage = 'Invalid payment amount.';
      });
      return;
    }
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Please log in to continue.';
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final created = await _createPayment(token);
    if (!mounted) {
      return;
    }
    if (!created) {
      setState(() {
        _isSubmitting = false;
        _pin = '';
        _errorMessage = 'Unable to create payment. Try again.';
      });
      return;
    }
    final verified = await _verifyPaymentStub();
    if (!mounted) {
      return;
    }
    if (!verified) {
      setState(() {
        _isSubmitting = false;
        _pin = '';
        _errorMessage = 'Payment verification failed.';
      });
      return;
    }
    setState(() {
      _isSubmitting = false;
    });
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(
      AppRoutes.purchaseSuccess,
      arguments: {
        'returnRoute': widget.returnRoute,
        'returnArgs': widget.returnArgs,
      },
    );
  }

  Future<bool> _createPayment(String token) async {
    try {
      await _apiClient.postJson(
        '/api/v1/payments',
        token: token,
        body: {
          'course': widget.courseId,
          'amount': widget.amount,
        },
      );
      return true;
    } on HttpException catch (err) {
      setState(() {
        _errorMessage = err.message;
      });
      return false;
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to create payment.';
      });
      return false;
    }
  }

  Future<bool> _verifyPaymentStub() async {
    // TODO: Replace with real verify-payment API call.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Payment Password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please enter the payment password',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 32),
                PinDotsRow(filledCount: _pin.length),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          NumericKeypad(
            onNumberTap: _onNumberTap,
            onBackspace: _onBackspace,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}


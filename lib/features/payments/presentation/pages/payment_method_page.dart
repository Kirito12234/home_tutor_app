import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/page_dots.dart';
import '../widgets/payment_password_sheet.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({Key? key}) : super(key: key);

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  List<_PaymentMethodInfo> _methods = [];

  void _showPasswordSheet(
    BuildContext context, {
    String? returnRoute,
    Object? returnArgs,
    String? courseId,
    double? amount,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentPasswordSheet(
        returnRoute: returnRoute,
        returnArgs: returnArgs,
        courseId: courseId,
        amount: amount,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Please log in to view payment methods.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getJson(
        '/api/v1/payment-methods',
        token: token,
      );
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_mapMethod)
            .toList();
        setState(() {
          _methods = mapped;
        });
      } else {
        setState(() {
          _errorMessage = 'Unexpected response format.';
        });
      }
    } on HttpException catch (err) {
      setState(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to load payment methods.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  _PaymentMethodInfo _mapMethod(Map<String, dynamic> method) {
    final type = method['type']?.toString() ?? 'card';
    final brand = method['brand']?.toString();
    final last4 = method['last4']?.toString();
    final holder = method['holderName']?.toString();
    final titleParts = <String>[];
    if (brand != null && brand.isNotEmpty) {
      titleParts.add(brand);
    }
    if (last4 != null && last4.isNotEmpty) {
      titleParts.add('**** $last4');
    }
    final title = titleParts.isNotEmpty ? titleParts.join(' ') : type.toUpperCase();
    final subtitle = holder != null && holder.isNotEmpty ? holder : 'Saved $type method';
    final icon = type == 'mobile'
        ? Icons.account_balance_wallet
        : type == 'bank'
            ? Icons.account_balance
            : Icons.credit_card;
    return _PaymentMethodInfo(
      title: title,
      subtitle: subtitle,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final routeArgs = args is Map<String, dynamic> ? args : <String, dynamic>{};
    final returnRoute = routeArgs['returnRoute'] as String?;
    final returnArgs = routeArgs['returnArgs'];
    final courseIdValue = routeArgs['courseId'];
    final courseId = courseIdValue is String ? courseIdValue : courseIdValue?.toString();
    final amountValue = routeArgs['amount'];
    final amount = amountValue is num ? amountValue.toDouble() : null;

    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          return true;
        }
        if (returnRoute != null && returnRoute.isNotEmpty) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            returnRoute,
            (route) => false,
            arguments: returnArgs,
          );
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.home,
            (route) => false,
          );
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                if (returnRoute != null && returnRoute.isNotEmpty) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    returnRoute,
                    (route) => false,
                    arguments: returnArgs,
                  );
                } else {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.home,
                    (route) => false,
                  );
                }
              }
            },
          ),
        ),
        body: SafeArea(
          child: Column(
          children: [
            const SizedBox(height: 40),
            // Card Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                    AppColors.categoryPurple,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Decorative blobs
                  Positioned(
                    top: -20,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.categoryBlue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    right: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.headerPink.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Card content
                  Positioned(
                    bottom: 40,
                    left: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '**** **** **** 4829',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.buttonText,
                            fontFamily: 'Inter',
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Balance',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.buttonText,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Rs 19,000',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.buttonText,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'My card',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 24),
            const PageDots(currentIndex: 0, totalPages: 3),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment methods',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontFamily: 'Inter',
                        ),
                      ),
                    )
                  else if (_methods.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No payment methods yet.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    )
                  else
                    ..._methods.map(
                      (method) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MethodTile(
                          icon: method.icon,
                          title: method.title,
                          subtitle: method.subtitle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                text: 'Pay Now',
                onPressed: () => _showPasswordSheet(
                  context,
                  returnRoute: returnRoute,
                  returnArgs: returnArgs,
                  courseId: courseId,
                  amount: amount,
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textLight),
        ],
      ),
    );
  }
}

class _PaymentMethodInfo {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PaymentMethodInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}


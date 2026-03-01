import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

class PurchaseSuccessPage extends StatelessWidget {
  const PurchaseSuccessPage({Key? key}) : super(key: key);

  void _handleBack(
    BuildContext context, {
    String? returnRoute,
    Object? returnArgs,
  }) {
    if (returnRoute != null && returnRoute.isNotEmpty) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        returnRoute,
        (route) => false,
        arguments: returnArgs,
      );
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.myCourses,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final routeArgs = args is Map<String, dynamic> ? args : <String, dynamic>{};
    final returnRoute = routeArgs['returnRoute'] as String?;
    final returnArgs = routeArgs['returnArgs'];

    return WillPopScope(
      onWillPop: () async {
        _handleBack(
          context,
          returnRoute: returnRoute,
          returnArgs: returnArgs,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => _handleBack(
              context,
              returnRoute: returnRoute,
              returnArgs: returnArgs,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Confetti dots
                    Positioned(
                      top: -20,
                      left: 20,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.durationOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -10,
                      right: 30,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.favoriteOrangeLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -15,
                      left: 30,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.categoryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      right: 20,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.categoryPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      left: -10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.durationOrangeLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Main circle with check
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.buttonText,
                        size: 60,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Successful purchase!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PrimaryButton(
                    text: 'Start learning',
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(AppRoutes.myCourses);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



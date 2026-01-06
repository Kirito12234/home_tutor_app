import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../widgets/empty_state_view.dart';

class NoProductsPage extends StatelessWidget {
  const NoProductsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      title: 'No products',
      subtitle: 'You don\'t have any products yet!',
      showBack: true,
      customIllustration: _buildIllustration(),
    );
  }

  Widget _buildIllustration() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cloud shapes
          Positioned(
            top: 15,
            left: 20,
            child: Container(
              width: 45,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Positioned(
            bottom: 25,
            right: 10,
            child: Container(
              width: 40,
              height: 25,
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          // Box
          Positioned(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(
                  color: AppColors.inputBorder,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // Person in box
                  const Center(
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFF2196F3), // Blue shirt
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


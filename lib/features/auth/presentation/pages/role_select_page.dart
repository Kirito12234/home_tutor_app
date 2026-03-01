import 'package:flutter/material.dart';
import '../../../../../app/routes/app_routes.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/services/hive/hive_service.dart';
import '../../../../../core/widgets/primary_button.dart';

class RoleSelectPage extends StatefulWidget {
  final String? action;

  const RoleSelectPage({Key? key, this.action}) : super(key: key);

  @override
  State<RoleSelectPage> createState() => _RoleSelectPageState();
}

class _RoleSelectPageState extends State<RoleSelectPage> {
  String? _selectedRole;

  void _goNext() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Student or Teacher')),
      );
      return;
    }
    await HiveService.setCurrentUserRole(_selectedRole);
    if (!mounted) {
      return;
    }
    final action = widget.action ?? 'signup';
    if (action == 'login') {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.login,
        arguments: _selectedRole,
      );
    } else {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.signup,
        arguments: _selectedRole,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action == 'login' ? 'Log in' : 'Sign up';
    final isChoiceOnly = widget.action == 'choice';
    final roleLabel =
        (HiveService.currentUserRole?.toLowerCase() == 'teacher') ? 'Teacher' : 'Student';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(
                    Icons.school,
                    size: 96,
                    color: AppColors.primary.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isChoiceOnly ? 'Continue as $roleLabel' : 'Choose your role',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'OpenSans',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isChoiceOnly
                    ? 'Select an option to continue'
                    : 'Select Student or Teacher to continue',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'OpenSans',
                ),
              ),
              if (!isChoiceOnly) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _RoleOption(
                        title: 'Student',
                        icon: Icons.school,
                        isSelected: _selectedRole == 'student',
                        onTap: () {
                          setState(() {
                            _selectedRole = 'student';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleOption(
                        title: 'Teacher',
                        icon: Icons.person,
                        isSelected: _selectedRole == 'teacher',
                        onTap: () {
                          setState(() {
                            _selectedRole = 'teacher';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              if (isChoiceOnly) ...[
                PrimaryButton(
                  text: 'Sign up',
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ),
              ] else ...[
                PrimaryButton(
                  text: action,
                  onPressed: _goNext,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(
                      widget.action == 'login' ? AppRoutes.signup : AppRoutes.login,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: Text(
                    widget.action == 'login' ? 'Sign up' : 'Log in',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.buttonText : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.buttonText : AppColors.textPrimary,
                fontFamily: 'OpenSans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../../../../app/routes/app_routes.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/social_button.dart';
import '../../../../../core/services/api/api_client.dart';
import '../../../../../core/services/hive/hive_service.dart';

class LoginPage extends StatefulWidget {
  final String? role;

  const LoginPage({Key? key, this.role}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String _roleLabel = 'Student';

  Future<bool> _handleBack() async {
    if (Navigator.of(context).canPop()) {
      return true;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    return false;
  }

  String? _extractDisplayName(Map<String, dynamic> response) {
    final user = response['user'];
    if (user is Map<String, dynamic>) {
      final name = user['name']?.toString();
      if (name != null && name.trim().isNotEmpty) {
        return name;
      }
    }
    final name = response['name']?.toString();
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final resolvedRole = widget.role ?? HiveService.currentUserRole;
    if (resolvedRole != null) {
      HiveService.setCurrentUserRole(resolvedRole);
    }
    if (resolvedRole != null && resolvedRole.toLowerCase() == 'teacher') {
      _roleLabel = 'Teacher';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final identifier = _emailController.text.trim();
      final online = await _isOnline();
      if (!online) {
        await _attemptOfflineLogin(identifier);
        return;
      }

      final response = await _apiClient.postJson(
        '/api/v1/auth/login',
        body: {
          'emailOrPhone': identifier,
          'password': _passwordController.text,
        },
      );

      final token = response['token']?.toString();
      if (token != null && token.isNotEmpty) {
        await HiveService.setAuthToken(token);
      }
      final displayName =
          _extractDisplayName(response) ?? identifier;
      await HiveService.setCurrentUserName(displayName);
      await HiveService.upsertOfflineCredential(
        identifier: identifier,
        passwordHash: HiveService.hashPassword(_passwordController.text),
        name: displayName,
        role: (HiveService.currentUserRole ?? _roleLabel).toLowerCase(),
      );

      if (!mounted) {
        return;
      }
      final role = HiveService.currentUserRole;
      Navigator.of(context).pushReplacementNamed(
        role != null && role.toLowerCase() == 'teacher'
            ? AppRoutes.teacherHome
            : AppRoutes.home,
      );
    } on SocketException {
      await _attemptOfflineLogin(_emailController.text.trim());
    } on HttpException catch (err) {
      _showError(err.message);
    } catch (_) {
      _showError('Unable to log in. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> _attemptOfflineLogin(String identifier) async {
    final credential = HiveService.getOfflineCredential(identifier);
    if (credential == null) {
      _showError('No offline account found for this user.');
      return;
    }
    final storedHash = credential['passwordHash']?.toString();
    final inputHash = HiveService.hashPassword(_passwordController.text);
    if (storedHash == null || storedHash != inputHash) {
      _showError('Incorrect offline password.');
      return;
    }
    final name = credential['name']?.toString();
    final role = credential['role']?.toString();
    await HiveService.setAuthToken(null);
    await HiveService.setCurrentUserName(name ?? identifier);
    if (role != null && role.trim().isNotEmpty) {
      await HiveService.setCurrentUserRole(role);
    }
    if (!mounted) {
      return;
    }
    final resolvedRole = role ?? HiveService.currentUserRole;
    Navigator.of(context).pushReplacementNamed(
      resolvedRole != null && resolvedRole.toLowerCase() == 'teacher'
          ? AppRoutes.teacherHome
          : AppRoutes.home,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Offline login used.')),
    );
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () async {
              final canPop = await _handleBack();
              if (canPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    '$_roleLabel Log In',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 40),
                  AppTextField(
                    controller: _emailController,
                    hintText: 'Email or phone',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email or phone';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
                      },
                      child: const Text(
                        'Forget password?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Log In',
                    onPressed: _onLogin,
                    isLoading: _isLoading,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text(
                          'Or login with',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.divider)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SocialButton(
                        iconPath: 'assets/icons/google.svg',
                        onPressed: () {
                          // Handle Google login
                        },
                      ),
                      const SizedBox(width: 24),
                      SocialButton(
                        iconPath: 'assets/icons/facebook.svg',
                        onPressed: () {
                          // Handle Facebook login
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don\'t have an account?  ',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacementNamed(
                              AppRoutes.signup,
                              arguments: widget.role ?? HiveService.currentUserRole,
                            );
                          },
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

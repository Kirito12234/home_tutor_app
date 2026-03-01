import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../../../../app/routes/app_routes.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/services/hive/hive_service.dart';

class SignUpPage extends StatefulWidget {
  final String? role;

  const SignUpPage({Key? key, this.role}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  bool _obscurePassword = true;
  bool _agreeToTerms = false;
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_agreeToTerms) {
      _showError('Please agree to the Terms & Conditions.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final online = await _isOnline();
      if (!online) {
        await _saveOfflineSignup();
        return;
      }

      final response = await _apiClient.postJson(
        '/api/v1/auth/register',
        body: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          'password': _passwordController.text,
          'role': _roleLabel.toLowerCase(),
        },
      );

      final token = response['token']?.toString();
      if (token != null && token.isNotEmpty) {
        await HiveService.setAuthToken(token);
      }
      final name = _nameController.text.trim();
      await HiveService.setCurrentUserName(name);

      final passwordHash = HiveService.hashPassword(_passwordController.text);
      final role = _roleLabel.toLowerCase();
      await HiveService.upsertOfflineCredential(
        identifier: _emailController.text.trim(),
        passwordHash: passwordHash,
        name: name,
        role: role,
      );
      final phone = _phoneController.text.trim();
      if (phone.isNotEmpty) {
        await HiveService.upsertOfflineCredential(
          identifier: phone,
          passwordHash: passwordHash,
          name: name,
          role: role,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(AppRoutes.success);
    } on SocketException {
      await _saveOfflineSignup();
    } on HttpException catch (err) {
      _showError(err.message);
    } catch (_) {
      _showError('Unable to sign up. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((item) => item != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  Future<void> _saveOfflineSignup() async {
    final name = _nameController.text.trim();
    final passwordHash = HiveService.hashPassword(_passwordController.text);
    final role = _roleLabel.toLowerCase();
    await HiveService.setAuthToken(null);
    await HiveService.setCurrentUserName(name);
    await HiveService.upsertOfflineCredential(
      identifier: _emailController.text.trim(),
      passwordHash: passwordHash,
      name: name,
      role: role,
    );
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      await HiveService.upsertOfflineCredential(
        identifier: phone,
        passwordHash: passwordHash,
        name: name,
        role: role,
      );
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved locally. Connect to the internet to sync.'),
      ),
    );
    Navigator.of(context).pushNamed(AppRoutes.success);
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
                    '$_roleLabel Sign Up',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your details below & free sign up',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 40),
                  AppTextField(
                    controller: _nameController,
                    hintText: 'Full name',
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _phoneController,
                    hintText: 'Phone (optional)',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return null;
                      }
                      if (value.trim().length < 7) {
                        return 'Please enter a valid phone number';
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
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreeToTerms = !_agreeToTerms;
                            });
                          },
                          child: const Text(
                            'I agree to the Terms & Conditions',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Create account',
                    onPressed: _onSignUp,
                    isLoading: _isLoading,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account ?  ',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacementNamed(
                              AppRoutes.login,
                              arguments: widget.role ?? HiveService.currentUserRole,
                            );
                          },
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              fontFamily: 'OpenSans',
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




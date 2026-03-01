import 'package:flutter/material.dart';
import '../../../../../app/routes/app_routes.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/services/hive/hive_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.role});

  final String? role;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isRequestingToken = false;
  bool _isResettingPassword = false;
  bool _obscurePassword = true;
  _ForgotRole _selectedRole = _ForgotRole.student;
  String? _issuedToken;
  String? _errorMessage;
  String? _successMessage;

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    final role = (widget.role ?? HiveService.currentUserRole)?.toLowerCase();
    _selectedRole = role == 'teacher' ? _ForgotRole.teacher : _ForgotRole.student;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestResetToken() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _setStatus(error: 'Email is required');
      return;
    }
    if (!_isValidEmail(email)) {
      _setStatus(error: 'Enter a valid email address');
      return;
    }

    _setStateIfMounted(() {
      _isRequestingToken = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await _apiClient.postJson(
        '/api/v1/auth/forgot-password',
        body: {
          'emailOrPhone': email,
          'email': email,
          'role': _selectedRole.apiValue,
        },
        token: HiveService.authToken,
      );

      final data = response['data'];
      final serverToken = data is Map
          ? (data['resetToken']?.toString() ?? data['token']?.toString())
          : null;
      if (serverToken == null || serverToken.isEmpty) {
        if (!mounted) {
          return;
        }
        _setStateIfMounted(() {
          _issuedToken = null;
          _successMessage =
              'Request accepted. Check email for your 5-character token.';
        });
        return;
      }

      if (!mounted) {
        return;
      }
      _setStateIfMounted(() {
        _issuedToken =
            serverToken.length > 5 ? serverToken.substring(0, 5) : serverToken;
        _tokenController.text = _issuedToken!;
        _successMessage =
            'Reset token generated from database. Use the 5-character token.';
      });
    } on HttpException catch (err) {
      if (!mounted) {
        return;
      }
      _setStateIfMounted(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      _setStateIfMounted(() {
        _errorMessage = 'Unable to request reset token.';
      });
    } finally {
      _setStateIfMounted(() {
        _isRequestingToken = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _setStatus(error: 'Email is required');
      return;
    }
    if (!_isValidEmail(email)) {
      _setStatus(error: 'Enter a valid email address');
      return;
    }
    if (token.isEmpty) {
      _setStatus(error: 'Reset token is required');
      return;
    }
    if (token.length != 5) {
      _setStatus(error: 'Token must be exactly 5 characters');
      return;
    }
    if (_issuedToken != null && token != _issuedToken) {
      _setStatus(error: 'Invalid token');
      return;
    }
    if (password.length < 6) {
      _setStatus(error: 'Password must be at least 6 characters');
      return;
    }

    _setStateIfMounted(() {
      _isResettingPassword = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _apiClient.putJson(
        '/api/v1/auth/reset-password/$token',
        body: {
          'password': password,
          'emailOrPhone': email,
          'email': email,
          'role': _selectedRole.apiValue,
        },
        token: HiveService.authToken,
      );
      if (!mounted) {
        return;
      }
      _setStateIfMounted(() {
        _successMessage = 'Password reset successful. Redirecting to login...';
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.login,
        arguments: _selectedRole.apiValue,
      );
    } on HttpException catch (err) {
      if (!mounted) {
        return;
      }
      _setStateIfMounted(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      _setStateIfMounted(() {
        _errorMessage = 'Unable to reset password.';
      });
    } finally {
      _setStateIfMounted(() {
        _isResettingPassword = false;
      });
    }
  }

  void _setStatus({String? error, String? success}) {
    _setStateIfMounted(() {
      _errorMessage = error;
      _successMessage = success;
    });
  }

  bool _isValidEmail(String value) {
    final emailRegExp = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegExp.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E5EC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACCOUNT RECOVERY',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3351FF),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedRole == _ForgotRole.teacher
                      ? 'Teacher forgot password'
                      : 'Student forgot password',
                  style: const TextStyle(
                    fontSize: 32,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B1538),
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Request reset token and set a new password.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 16),
                _StepCard(
                  title: '1. Request reset token',
                  child: Column(
                    children: [
                      _InputField(
                        controller: _emailController,
                        hintText: 'Enter email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ActionButton(
                          text: 'Request token',
                          isLoading: _isRequestingToken,
                          onPressed: _isRequestingToken
                              ? null
                              : _requestResetToken,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _StepCard(
                  title: '2. Reset password',
                  child: Column(
                    children: [
                      _InputField(
                        controller: _tokenController,
                        hintText: 'Enter reset token',
                        keyboardType: TextInputType.text,
                        maxLength: 5,
                      ),
                      const SizedBox(height: 10),
                      _InputField(
                        controller: _passwordController,
                        hintText: 'Enter new password',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ActionButton(
                          text: 'Reset password',
                          isLoading: _isResettingPassword,
                          onPressed:
                              _isResettingPassword ? null : _resetPassword,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontFamily: 'Roboto',
                    ),
                  ),
                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(
                        color: Color(0xFF0B9B56),
                        fontSize: 14,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text(
                      'Back to ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacementNamed(
                        AppRoutes.login,
                        arguments: _selectedRole.apiValue,
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3351FF),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ForgotRole {
  student('student'),
  teacher('teacher');

  const _ForgotRole(this.apiValue);
  final String apiValue;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1D7E5)),
        color: const Color(0xFFF3F4F6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2B47),
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      decoration: InputDecoration(
        counterText: '',
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontFamily: 'Roboto',
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF1F3F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD3DAE8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD3DAE8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF627BFF)),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4762F5),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
            ),
    );
  }
}



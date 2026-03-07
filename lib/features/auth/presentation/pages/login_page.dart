import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../app/routes/app_routes.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/social_button.dart';
import '../../../../../core/services/hive/hive_service.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String? role;

  const LoginPage({Key? key, this.role}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  ProviderSubscription<dynamic>? _authListener;
  bool _obscurePassword = true;
  String _roleLabel = 'Student';
  String get _effectiveApiBaseUrl => apiBaseUrl();

  Future<void> _onGoogleLogin() async {
    await _startSocialLogin('google');
  }

  Future<void> _onFacebookLogin() async {
    await _startSocialLogin('facebook');
  }

  Future<void> _startSocialLogin(String provider) async {
    final base = socketBaseUrl();
    final candidates = <Uri>[
      Uri.parse('$base/auth/$provider'),
      Uri.parse('$base/api/v1/auth/$provider'),
    ];

    bool launched = false;
    for (final uri in candidates) {
      try {
        final didLaunch = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (didLaunch) {
          launched = true;
          break;
        }
      } catch (_) {
        // Try next candidate.
      }
    }

    if (!context.mounted) {
      return;
    }

    if (!launched) {
      _showError(
        'Social login is not configured for this server (${socketBaseUrl()}). '
        'Ask your backend to provide an OAuth route like /auth/$provider (or /api/v1/auth/$provider).',
      );
      return;
    }

    final dialogContext = context;
    showDialog<void>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: Text('Continue with ${provider[0].toUpperCase()}${provider.substring(1)}'),
        content: const Text(
          'Your browser opened to finish sign-in. After you complete it, return to the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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
    _authListener = ref.listenManual(authViewModelProvider, (previous, next) {
      final message = next.errorMessage;
      if (message == null ||
          message.trim().isEmpty ||
          message == previous?.errorMessage) {
        return;
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
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
    _authListener?.close();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final identifier = _emailController.text.trim();
    final fallbackRole =
        (widget.role ?? HiveService.currentUserRole ?? _roleLabel).toLowerCase();

    final session = await ref.read(authViewModelProvider.notifier).login(
          identifier: identifier,
          password: _passwordController.text,
          fallbackRole: fallbackRole,
        );

    if (!mounted || session == null) {
      return;
    }

    final resolvedRole =
        (session.role ?? HiveService.currentUserRole)?.toLowerCase();
    Navigator.of(context).pushReplacementNamed(
      resolvedRole != null && resolvedRole.toLowerCase() == 'teacher'
          ? AppRoutes.teacherHome
          : AppRoutes.home,
    );
    if (session.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline login used.')),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showApiServerDialog() async {
    final controller = TextEditingController(
      text: HiveService.apiBaseUrlOverride ?? '',
    );
    final current = _effectiveApiBaseUrl;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('API server'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current: $current',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Override (optional)',
                  hintText: 'http://192.168.1.10:5000',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 10),
              const Text(
                'Tip: 10.0.2.2 works only on Android emulator. For a real phone, use your PC/server LAN IP or a public domain.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await HiveService.setApiBaseUrlOverride(null);
                if (context.mounted) {
                  navigator.pop();
                }
              },
              child: const Text('Use default'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final next = controller.text.trim();
                final navigator = Navigator.of(context);
                await HiveService.setApiBaseUrlOverride(next.isEmpty ? null : next);
                if (!context.mounted) {
                  return;
                }
                navigator.pop();
                setState(() {});
                _showSnack('API server updated: ${apiBaseUrl()}');
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
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
              final navigator = Navigator.of(context);
              final canPop = await _handleBack();
              if (canPop && context.mounted) {
                navigator.pop();
              }
            },
          ),
          actions: [
            IconButton(
              tooltip: 'API server',
              icon: const Icon(Icons.cloud_outlined, color: AppColors.textPrimary),
              onPressed: _showApiServerDialog,
            ),
          ],
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
                      fontFamily: 'OpenSans',
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
                        Navigator.of(context).pushNamed(
                          AppRoutes.forgotPassword,
                          arguments:
                              (widget.role ?? HiveService.currentUserRole)
                                  ?.toLowerCase(),
                        );
                      },
                      child: const Text(
                        'Forget password?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Log In',
                    onPressed: _onLogin,
                    isLoading: authState.isLoading,
                  ),
                  if (authState.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      authState.errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontFamily: 'OpenSans',
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
                            fontFamily: 'OpenSans',
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
                        semanticLabel: 'Continue with Google',
                        onPressed: () {
                          _onGoogleLogin();
                        },
                      ),
                      const SizedBox(width: 24),
                      SocialButton(
                        iconPath: 'assets/icons/facebook.svg',
                        semanticLabel: 'Continue with Facebook',
                        onPressed: () {
                          _onFacebookLogin();
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
                            fontFamily: 'OpenSans',
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



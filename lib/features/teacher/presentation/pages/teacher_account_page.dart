import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../widgets/teacher_bottom_nav.dart';

class TeacherAccountPage extends StatefulWidget {
  const TeacherAccountPage({Key? key}) : super(key: key);

  @override
  State<TeacherAccountPage> createState() => _TeacherAccountPageState();
}

class _TeacherAccountPageState extends State<TeacherAccountPage> {
  int _currentNavIndex = 4;
  final ApiClient _apiClient = ApiClient();
  bool _isLoadingEarnings = false;
  String? _earningsError;
  String _monthlyEarnings = 'Rs 0';
  String _pendingEarnings = 'Rs 0';
  String _lastMonthEarnings = 'Rs 0';

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherHome);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherCourses);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherSearch);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherMessages);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherAccount);
        break;
    }
  }

  Future<void> _logout() async {
    await HiveService.setAuthToken(null);
    await HiveService.setCurrentUserName(null);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  void _showAction(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _showEditProfileDialog() async {
    final controller = TextEditingController(
      text: HiveService.currentUserName ?? '',
    );
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Full name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (newName != null && newName.isNotEmpty) {
      await HiveService.setCurrentUserName(newName);
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadEarnings() async {
    setState(() {
      _isLoadingEarnings = true;
      _earningsError = null;
    });

    try {
      final token = HiveService.authToken;
      if (token == null || token.isEmpty) {
        setState(() {
          _monthlyEarnings = 'Rs 0';
          _pendingEarnings = 'Rs 0';
          _lastMonthEarnings = 'Rs 0';
        });
        return;
      }
      final response = await _apiClient.getJson(
        '/api/v1/payments/summary',
        token: token,
      );
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final thisMonth = data['thisMonth'];
        final pending = data['pending'];
        final lastMonth = data['lastMonth'];
        final thisMonthValue = thisMonth is num ? thisMonth.toDouble() : 0.0;
        final pendingValue = pending is num ? pending.toDouble() : 0.0;
        final lastMonthValue = lastMonth is num ? lastMonth.toDouble() : 0.0;
        setState(() {
          _monthlyEarnings = _formatCurrency(thisMonthValue);
          _pendingEarnings = _formatCurrency(pendingValue);
          _lastMonthEarnings = _formatCurrency(lastMonthValue);
        });
      }
    } on HttpException catch (err) {
      setState(() {
        _earningsError = err.message;
      });
    } catch (_) {
      setState(() {
        _earningsError = 'Unable to load earnings.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEarnings = false;
        });
      }
    }
  }

  String _formatCurrency(double value) {
    final rounded = value.round().toString();
    final formatted = rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'Rs $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = HiveService.currentUserName ?? 'Teacher';
    final items = [
      {'title': 'Edit Profile', 'icon': Icons.edit},
      {'title': 'Earnings', 'icon': Icons.payments},
      {'title': 'Payouts', 'icon': Icons.account_balance_wallet},
      {'title': 'Settings and Privacy', 'icon': Icons.settings},
      {'title': 'Help', 'icon': Icons.help_outline},
      {'title': 'Logout', 'icon': Icons.logout},
    ];

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.teacherHome,
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.teacherBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.teacherPrimaryDark),
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.teacherHome,
              (route) => false,
            ),
          ),
          title: const Text(
            'Account',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.teacherPrimaryDark,
              fontFamily: 'Inter',
            ),
          ),
        ),
        body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.teacherChip,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: AppColors.teacherPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Professional Teacher',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.teacherMuted,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ...items.map((item) {
                  final title = item['title'] as String;
                  String? subtitle;
                  if (title == 'Earnings') {
                    subtitle = _isLoadingEarnings
                        ? 'Loading...'
                        : _earningsError ??
                            'This month $_monthlyEarnings · Pending $_pendingEarnings';
                  }
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(item['icon'] as IconData, color: AppColors.teacherPrimary),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    subtitle: subtitle == null
                        ? null
                        : Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.teacherMuted,
                              fontFamily: 'Inter',
                            ),
                          ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.teacherMuted,
                    ),
                    onTap: () {
                      switch (title) {
                        case 'Edit Profile':
                          _showEditProfileDialog();
                          break;
                        case 'Earnings':
                          _showAction(
                            'This month $_monthlyEarnings · Pending $_pendingEarnings · Last month $_lastMonthEarnings',
                          );
                          break;
                        case 'Payouts':
                          Navigator.of(context).pushNamed(AppRoutes.teacherPayoutSettings);
                          break;
                        case 'Settings and Privacy':
                          Navigator.of(context).pushNamed(AppRoutes.settingsPrivacy);
                          break;
                        case 'Help':
                          Navigator.of(context).pushNamed(AppRoutes.help);
                          break;
                        case 'Logout':
                          _logout();
                          break;
                        default:
                          _showAction('$title tapped');
                      }
                    },
                  );
                }).toList(),
              ],
            ),
          ),
          TeacherBottomNav(
            currentIndex: _currentNavIndex,
            onTap: _onNavTap,
          ),
        ],
      ),
      ),
    );
  }
}


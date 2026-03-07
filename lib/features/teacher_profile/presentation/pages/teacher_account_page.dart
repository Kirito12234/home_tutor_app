import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/services/profile/user_profile_service.dart';
import '../../../../core/widgets/file_picker_screen.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../teacher_dashboard/presentation/widgets/teacher_bottom_nav.dart';

class TeacherAccountPage extends StatefulWidget {
  const TeacherAccountPage({super.key});

  @override
  State<TeacherAccountPage> createState() => _TeacherAccountPageState();
}

class _TeacherAccountPageState extends State<TeacherAccountPage> {
  int _currentNavIndex = 4;
  final ApiClient _apiClient = ApiClient();
  final UserProfileService _profileService = UserProfileService();

  bool _isLoadingEarnings = false;
  bool _isUploadingAvatar = false;
  Uint8List? _pendingAvatarBytes;
  String? _earningsError;
  String _monthlyEarnings = 'Rs 0';
  String _pendingEarnings = 'Rs 0';
  String _lastMonthEarnings = 'Rs 0';
  Timer? _profileSyncTimer;

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _loadEarnings();
    _refreshProfileFromServer();
    _profileSyncTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshProfileFromServer(),
    );
  }

  @override
  void dispose() {
    _profileSyncTimer?.cancel();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) {
      return;
    }
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

  Future<void> _refreshProfileFromServer() async {
    try {
      await _profileService.refreshUserCache();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    _profileSyncTimer?.cancel();
    await HiveService.setAuthToken(null);
    await HiveService.setCurrentUserName(null);
    await HiveService.setCurrentUserRole('teacher');
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.login,
      arguments: 'teacher',
    );
  }

  void _showAction(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showAvatarOptions() async {
    final hasAvatar = HiveService.currentUserAvatarUrl != null ||
        HiveService.currentUserAvatarLocalPath != null;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Change photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickAndUploadAvatar();
                  },
                ),
                if (hasAvatar)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Remove photo'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _removeAvatar();
                    },
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final selected = await Navigator.of(context).push<SelectedFile>(
      MaterialPageRoute(
        builder: (_) => const FilePickerScreen(
          title: 'Select a photo',
          allowPdf: false,
          allowAny: false,
          allowImages: true,
          allowCamera: true,
        ),
      ),
    );
    if (selected == null) {
      return;
    }
    if (!_isImageFile(selected)) {
      _showAction('Please select an image file.');
      return;
    }
    _setStateIfMounted(() {
      _pendingAvatarBytes = selected.bytes;
    });
    await HiveService.setCurrentUserAvatarLocalPath(selected.path);
    await _uploadAvatar(selected);
  }

  bool _isImageFile(SelectedFile file) {
    final name = file.name.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp') ||
        name.endsWith('.gif');
  }

  Future<void> _uploadAvatar(SelectedFile file) async {
    setState(() {
      _isUploadingAvatar = true;
      _pendingAvatarBytes = file.bytes ?? _pendingAvatarBytes;
    });
    try {
      await _profileService.uploadAvatar(file);
      await _profileService.refreshUserCache();
      if (mounted) {
        _showAction('Profile photo updated.');
      }
    } on HttpException catch (err) {
      _showAction(err.message);
    } catch (_) {
      _showAction('Unable to update profile photo.');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Widget _buildAvatar() {
    if (_pendingAvatarBytes != null && _pendingAvatarBytes!.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          _pendingAvatarBytes!,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        ),
      );
    }
    return ProfileAvatar(
      size: 90,
      backgroundColor: AppColors.teacherChip,
      iconColor: AppColors.teacherPrimaryDark,
      onTap: _isUploadingAvatar ? null : _showAvatarOptions,
    );
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _isUploadingAvatar = true;
      _pendingAvatarBytes = null;
    });
    try {
      await _profileService.deleteAvatar();
      await HiveService.setCurrentUserAvatarLocalPath(null);
      if (mounted) {
        _showAction('Profile photo removed.');
      }
    } on HttpException catch (err) {
      _showAction(err.message);
    } catch (_) {
      _showAction('Unable to remove profile photo.');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
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
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
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
    _setStateIfMounted(() {
      _isLoadingEarnings = true;
      _earningsError = null;
    });

    try {
      final token = HiveService.authToken;
      if (token == null || token.isEmpty) {
        _setStateIfMounted(() {
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
        _setStateIfMounted(() {
          _monthlyEarnings = _formatCurrency(thisMonthValue);
          _pendingEarnings = _formatCurrency(pendingValue);
          _lastMonthEarnings = _formatCurrency(lastMonthValue);
        });
      }
    } on HttpException catch (err) {
      _setStateIfMounted(() {
        _earningsError = err.message;
      });
    } catch (_) {
      _setStateIfMounted(() {
        _earningsError = 'Unable to load earnings.';
      });
    } finally {
      _setStateIfMounted(() {
        _isLoadingEarnings = false;
      });
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
            icon: const Icon(Icons.arrow_back,
                color: AppColors.teacherPrimaryDark),
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
              fontFamily: 'OpenSans',
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshProfileFromServer,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              _buildAvatar(),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _isUploadingAvatar
                                      ? const Padding(
                                          padding: EdgeInsets.all(7),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppColors.buttonText,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          color: AppColors.buttonText,
                                          size: 14,
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed:
                                _isUploadingAvatar ? null : _showAvatarOptions,
                            child: const Text(
                              'Change photo',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Professional Teacher',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.teacherMuted,
                              fontFamily: 'OpenSans',
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
                                'This month $_monthlyEarnings  -  Pending $_pendingEarnings';
                      }
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(item['icon'] as IconData,
                            color: AppColors.teacherPrimary),
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                        subtitle: subtitle == null
                            ? null
                            : Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.teacherMuted,
                                  fontFamily: 'OpenSans',
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
                                'This month $_monthlyEarnings  -  Pending $_pendingEarnings  -  Last month $_lastMonthEarnings',
                              );
                              break;
                            case 'Payouts':
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.teacherPayoutSettings);
                              break;
                            case 'Settings and Privacy':
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.settingsPrivacy);
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
                    }),
                  ],
                ),
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


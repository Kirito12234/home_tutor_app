import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/api/api_config.dart';
import '../../../../core/services/hive/hive_service.dart';

class SettingsPrivacyPage extends StatefulWidget {
  const SettingsPrivacyPage({Key? key}) : super(key: key);

  @override
  State<SettingsPrivacyPage> createState() => _SettingsPrivacyPageState();
}

class _SettingsPrivacyPageState extends State<SettingsPrivacyPage> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  bool _isSavingProfile = false;
  String? _errorMessage;
  String _displayName = '';
  String _email = '';
  String _phone = '';
  String _avatarUrl = '';
  bool _pushNotifications = true;
  bool _emailUpdates = true;
  bool _showProfile = true;
  bool _twoFactor = false;
  bool _downloadWifiOnly = true;
  String? _updatingSettingKey;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getJson(
        '/api/v1/users/me',
        token: HiveService.authToken,
      );
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        await _applyUserPayload(data);
      }
    } on HttpException catch (err) {
      _errorMessage = err.message;
    } catch (_) {
      _errorMessage = 'Unable to load settings.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyUserPayload(Map<String, dynamic> data) async {
    final settings = data['settings'];
    _displayName = data['name']?.toString() ?? _displayName;
    _email = data['email']?.toString() ?? _email;
    _phone = data['phone']?.toString() ?? _phone;
    if (data.containsKey('avatarUrl')) {
      _avatarUrl = data['avatarUrl']?.toString() ?? '';
    }
    if (settings is Map) {
      _pushNotifications =
          settings['pushNotifications'] is bool ? settings['pushNotifications'] as bool : _pushNotifications;
      _emailUpdates =
          settings['emailUpdates'] is bool ? settings['emailUpdates'] as bool : _emailUpdates;
      _showProfile =
          settings['showProfile'] is bool ? settings['showProfile'] as bool : _showProfile;
      _twoFactor =
          settings['twoFactorEnabled'] is bool ? settings['twoFactorEnabled'] as bool : _twoFactor;
      _downloadWifiOnly = settings['downloadWifiOnly'] is bool
          ? settings['downloadWifiOnly'] as bool
          : _downloadWifiOnly;
    }
    await HiveService.setCurrentUserName(_displayName);
    await HiveService.setCurrentUserAvatarUrl(_avatarUrl);
  }

  Future<void> _updateProfile({
    required String name,
    required String email,
    required String phone,
    required String avatarUrl,
  }) async {
    setState(() {
      _isSavingProfile = true;
    });
    try {
      final body = <String, dynamic>{};
      if (name.trim().isNotEmpty) {
        body['name'] = name.trim();
      }
      if (email.trim().isNotEmpty) {
        body['email'] = email.trim();
      }
      if (phone.trim().isNotEmpty) {
        body['phone'] = phone.trim();
      }
      if (avatarUrl.trim().isNotEmpty) {
        body['avatarUrl'] = avatarUrl.trim();
      }

      final response = await _apiClient.putJson(
        '/api/v1/users/me',
        token: HiveService.authToken,
        body: body,
      );
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        await _applyUserPayload(data);
      }
      _showSnack('Profile updated.');
    } on HttpException catch (err) {
      _showSnack(err.message);
    } catch (_) {
      _showSnack('Unable to update profile.');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _displayName);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);
    final avatarController = TextEditingController(text: _avatarUrl);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profile'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: avatarController,
                  decoration: const InputDecoration(labelText: 'Photo URL'),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSavingProfile
                ? null
                : () async {
                    if (formKey.currentState?.validate() != true) {
                      return;
                    }
                    Navigator.of(context).pop();
                    await _updateProfile(
                      name: nameController.text,
                      email: emailController.text,
                      phone: phoneController.text,
                      avatarUrl: avatarController.text,
                    );
                  },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentController,
                  decoration: const InputDecoration(labelText: 'Current password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter current password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newController,
                  decoration: const InputDecoration(labelText: 'New password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  decoration: const InputDecoration(labelText: 'Confirm password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim() != newController.text.trim()) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) {
                return;
              }
              Navigator.of(context).pop();
              await _changePassword(
                current: currentController.text.trim(),
                next: newController.text.trim(),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword({
    required String current,
    required String next,
  }) async {
    try {
      await _apiClient.putJson(
        '/api/v1/users/me/password',
        token: HiveService.authToken,
        body: {
          'currentPassword': current,
          'newPassword': next,
        },
      );
      _showSnack('Password updated.');
    } on HttpException catch (err) {
      _showSnack(err.message);
    } catch (_) {
      _showSnack('Unable to change password.');
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final previous = _settingValue(key);
    setState(() {
      _updatingSettingKey = key;
      _setSettingValue(key, value);
    });

    try {
      await _apiClient.putJson(
        '/api/v1/users/me/settings',
        token: HiveService.authToken,
        body: {key: value},
      );
    } on HttpException catch (err) {
      _showSnack(err.message);
      setState(() {
        _setSettingValue(key, previous);
      });
    } catch (_) {
      _showSnack('Unable to update setting.');
      setState(() {
        _setSettingValue(key, previous);
      });
    } finally {
      if (mounted) {
        setState(() {
          _updatingSettingKey = null;
        });
      }
    }
  }

  bool _settingValue(String key) {
    switch (key) {
      case 'pushNotifications':
        return _pushNotifications;
      case 'emailUpdates':
        return _emailUpdates;
      case 'showProfile':
        return _showProfile;
      case 'twoFactorEnabled':
        return _twoFactor;
      case 'downloadWifiOnly':
        return _downloadWifiOnly;
      default:
        return false;
    }
  }

  void _setSettingValue(String key, bool value) {
    switch (key) {
      case 'pushNotifications':
        _pushNotifications = value;
        break;
      case 'emailUpdates':
        _emailUpdates = value;
        break;
      case 'showProfile':
        _showProfile = value;
        break;
      case 'twoFactorEnabled':
        _twoFactor = value;
        break;
      case 'downloadWifiOnly':
        _downloadWifiOnly = value;
        break;
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cache?'),
        content: const Text('This removes temporary files and cached images.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.buttonText,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      await _deleteDirectoryContents(tempDir);
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      _showSnack('Cache cleared.');
    } catch (_) {
      _showSnack('Unable to clear cache.');
    }
  }

  Future<void> _deleteDirectoryContents(Directory directory) async {
    if (!await directory.exists()) {
      return;
    }
    final entries = directory.listSync();
    for (final entry in entries) {
      try {
        await entry.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<void> _showApiBaseUrlDialog() async {
    final controller = TextEditingController(
      text: HiveService.apiBaseUrlOverride ?? apiBaseUrl(),
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API server URL'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'http://192.168.1.10:3000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await HiveService.setApiBaseUrlOverride(null);
              if (!mounted) {
                return;
              }
              Navigator.of(context).pop();
              setState(() {});
              _showSnack('API URL cleared.');
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isEmpty) {
                await HiveService.setApiBaseUrlOverride(null);
              } else if (!value.startsWith('http://') &&
                  !value.startsWith('https://')) {
                _showSnack('URL must start with http:// or https://');
                return;
              } else {
                await HiveService.setApiBaseUrlOverride(value);
              }
              if (!mounted) {
                return;
              }
              Navigator.of(context).pop();
              setState(() {});
              _showSnack('API URL updated.');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiOverride = HiveService.apiBaseUrlOverride;
    final apiLabel = apiOverride ?? apiBaseUrl();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Settings & Privacy',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const _SectionTitle(title: 'Account'),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_errorMessage != null)
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
            ),
          _SettingsTile(
            title: 'Edit profile',
            subtitle: 'Update name and photo',
            icon: Icons.edit,
            onTap: _showEditProfileDialog,
          ),
          _SettingsTile(
            title: 'Change password',
            subtitle: 'Update your account password',
            icon: Icons.lock_outline,
            onTap: _showChangePasswordDialog,
          ),
          const SizedBox(height: 12),
          const _SectionTitle(title: 'Notifications'),
          _SwitchTile(
            title: 'Push notifications',
            subtitle: 'Reminders and class updates',
            value: _pushNotifications,
            isBusy: _updatingSettingKey == 'pushNotifications',
            onChanged: (value) => _updateSetting('pushNotifications', value),
          ),
          _SwitchTile(
            title: 'Email updates',
            subtitle: 'Course news and newsletters',
            value: _emailUpdates,
            isBusy: _updatingSettingKey == 'emailUpdates',
            onChanged: (value) => _updateSetting('emailUpdates', value),
          ),
          const SizedBox(height: 12),
          const _SectionTitle(title: 'Privacy'),
          _SwitchTile(
            title: 'Show my profile',
            subtitle: 'Allow mentors to view your profile',
            value: _showProfile,
            isBusy: _updatingSettingKey == 'showProfile',
            onChanged: (value) => _updateSetting('showProfile', value),
          ),
          _SwitchTile(
            title: 'Two-factor authentication',
            subtitle: 'Extra security when signing in',
            value: _twoFactor,
            isBusy: _updatingSettingKey == 'twoFactorEnabled',
            onChanged: (value) => _updateSetting('twoFactorEnabled', value),
          ),
          const SizedBox(height: 12),
          const _SectionTitle(title: 'Downloads'),
          _SwitchTile(
            title: 'Wi-Fi only',
            subtitle: 'Download lessons over Wi-Fi',
            value: _downloadWifiOnly,
            isBusy: _updatingSettingKey == 'downloadWifiOnly',
            onChanged: (value) => _updateSetting('downloadWifiOnly', value),
          ),
          _SettingsTile(
            title: 'Clear cache',
            subtitle: 'Free up storage space',
            icon: Icons.delete_outline,
            onTap: _clearCache,
          ),
          const SizedBox(height: 12),
          const _SectionTitle(title: 'Developer'),
          _SettingsTile(
            title: 'API server',
            subtitle: apiLabel,
            icon: Icons.cloud_outlined,
            onTap: _showApiBaseUrlDialog,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isBusy;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: isBusy ? null : onChanged,
        activeColor: AppColors.primary,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

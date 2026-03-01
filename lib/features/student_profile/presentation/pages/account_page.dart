import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/user_display_name.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/services/profile/user_profile_service.dart';
import '../../../../core/widgets/file_picker_screen.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../student_dashboard/presentation/widgets/bottom_nav.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _currentNavIndex = 4;
  final UserProfileService _profileService = UserProfileService();
  bool _isUploadingAvatar = false;
  Uint8List? _pendingAvatarBytes;

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Edit Profile', 'icon': Icons.edit},
    {'title': 'Favourite', 'icon': Icons.favorite_border},
    {'title': 'Settings and Privacy', 'icon': Icons.settings},
    {'title': 'Help', 'icon': Icons.help_outline},
    {'title': 'Logout', 'icon': Icons.logout},
  ];

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
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
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.courses);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.searchResults);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.notifications);
        break;
    }
  }

  Future<bool> _handleBack() async {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    return false;
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

  Future<void> _logout() async {
    await HiveService.setAuthToken(null);
    await HiveService.setCurrentUserName(null);
    await HiveService.setCurrentUserAvatarUrl(null);
    await HiveService.setCurrentUserAvatarLocalPath(null);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshProfileFromServer();
  }

  Future<void> _refreshProfileFromServer() async {
    try {
      await _profileService.refreshUserCache();
      _setStateIfMounted(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final displayName = displayNameFromUser(HiveService.currentUserName);
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Stack(
                        children: [
                          _buildAvatar(),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingAvatar ? null : _showAvatarOptions,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: _isUploadingAvatar
                                    ? const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            AppColors.buttonText,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        color: AppColors.buttonText,
                                        size: 16,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ..._menuItems.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item['title']!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                          trailing: Icon(
                            item['icon'] as IconData,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onTap: () {
                            switch (item['title']) {
                              case 'Edit Profile':
                                _showEditProfileDialog();
                                break;
                              case 'Favourite':
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.favourites);
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item['title']} tapped'),
                                  ),
                                );
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            BottomNav(
              currentIndex: _currentNavIndex,
              onTap: _onNavTap,
            ),
          ],
        ),
      ),
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
                const SizedBox(height: 6),
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
      _showSnack('Please select an image file.');
      return;
    }
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
    _setStateIfMounted(() {
      _isUploadingAvatar = true;
      _pendingAvatarBytes = file.bytes;
    });
    try {
      await _profileService.uploadAvatar(file);
      await _profileService.refreshUserCache();
      if (mounted) {
        _setStateIfMounted(() {
          _pendingAvatarBytes = null;
        });
        _showSnack('Profile photo updated.');
      }
    } on HttpException catch (err) {
      _setStateIfMounted(() {
        _pendingAvatarBytes = null;
      });
      _showSnack(err.message);
    } catch (_) {
      _setStateIfMounted(() {
        _pendingAvatarBytes = null;
      });
      _showSnack('Unable to update profile photo.');
    } finally {
      _setStateIfMounted(() {
        _isUploadingAvatar = false;
      });
    }
  }

  Widget _buildAvatar() {
    if (_pendingAvatarBytes != null && _pendingAvatarBytes!.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          _pendingAvatarBytes!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    }
    return ProfileAvatar(
      size: 100,
      onTap: _isUploadingAvatar ? null : _showAvatarOptions,
    );
  }

  Future<void> _removeAvatar() async {
    _setStateIfMounted(() {
      _isUploadingAvatar = true;
    });
    try {
      await _profileService.deleteAvatar();
      await HiveService.setCurrentUserAvatarLocalPath(null);
      if (mounted) {
        _showSnack('Profile photo removed.');
      }
    } on HttpException catch (err) {
      _showSnack(err.message);
    } catch (_) {
      _showSnack('Unable to remove profile photo.');
    } finally {
      _setStateIfMounted(() {
        _isUploadingAvatar = false;
      });
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}


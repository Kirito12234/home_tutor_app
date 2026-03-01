import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../api/api_endpoints.dart';
import '../services/hive/hive_service.dart';

class ProfileAvatar extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;
  final Widget? overlay;

  const ProfileAvatar({
    Key? key,
    this.size = 50,
    this.backgroundColor = AppColors.categoryBlue,
    this.iconColor = AppColors.primary,
    this.onTap,
    this.overlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: HiveService.settingsBox.watch(),
      builder: (context, snapshot) {
        final localAvatarPath = HiveService.currentUserAvatarLocalPath;
        final localAvatarFilePath = localAvatarPath ?? '';
        final hasLocalAvatar = localAvatarPath != null &&
            localAvatarPath.trim().isNotEmpty &&
            File(localAvatarPath).existsSync();
        final avatarUrl = _resolveAvatarUrl(HiveService.currentUserAvatarUrl);
        final content = (hasLocalAvatar || avatarUrl.isNotEmpty)
            ? ClipOval(
                child: hasLocalAvatar
                    ? Image.file(
                        File(localAvatarFilePath),
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _fallbackAvatar();
                        },
                      )
                    : Image.network(
                        avatarUrl,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _fallbackAvatar();
                        },
                      ),
              )
            : _fallbackAvatar();

        final childWidget = overlay == null
            ? content
            : Stack(
                children: [
                  content,
                  Positioned.fill(child: overlay!),
                ],
              );

        if (onTap == null) {
          return childWidget;
        }
        return GestureDetector(
          onTap: onTap,
          child: childWidget,
        );
      },
    );
  }

  String _resolveAvatarUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return '';
    }
    final normalized = path.trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    final base = socketBaseUrl();
    if (normalized.startsWith('/')) {
      return '$base$normalized';
    }
    return '$base/$normalized';
  }

  Widget _fallbackAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: iconColor,
      ),
    );
  }
}


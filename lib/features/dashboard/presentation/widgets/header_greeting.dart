import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/user_display_name.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/services/profile/user_profile_service.dart';
import '../../../../core/widgets/profile_avatar.dart';

class HeaderGreeting extends StatefulWidget {
  const HeaderGreeting({Key? key}) : super(key: key);

  @override
  State<HeaderGreeting> createState() => _HeaderGreetingState();
}

class _HeaderGreetingState extends State<HeaderGreeting> {
  final UserProfileService _profileService = UserProfileService();
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }
    _didLoad = true;
    _profileService.refreshUserCache();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = displayNameFromUser(HiveService.currentUserName);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $displayName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.buttonText,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Let\'s start learning',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.buttonText,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          ProfileAvatar(
            size: 50,
            backgroundColor: AppColors.buttonText,
            iconColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}


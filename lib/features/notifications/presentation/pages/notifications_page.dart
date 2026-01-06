import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/dummy/dummy_notifications.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/message_card.dart';
import '../widgets/notification_tile.dart';
import '../../../dashboard/presentation/widgets/bottom_nav.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _currentTab = 0;
  int _currentNavIndex = 3;

  void _onNavTap(int index) {
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
        Navigator.of(context).pushNamed(AppRoutes.searchResults);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.account);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SegmentedTabs(
            selectedIndex: _currentTab,
            onTap: (index) {
              setState(() {
                _currentTab = index;
              });
            },
            showNotificationDot: _currentTab == 0,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _currentTab == 0
                ? ListView(
                    children: DummyNotifications.getMessages().map((message) {
                      return MessageCard(message: message);
                    }).toList(),
                  )
                : ListView(
                    children: DummyNotifications.getNotifications().map((notif) {
                      return NotificationTile(notification: notif);
                    }).toList(),
                  ),
          ),
          BottomNav(
            currentIndex: _currentNavIndex,
            onTap: _onNavTap,
          ),
        ],
      ),
    );
  }
}


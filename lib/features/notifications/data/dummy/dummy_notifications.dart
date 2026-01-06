import '../../domain/entities/message_notification.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class DummyNotifications {
  static List<MessageNotification> getMessages() {
    return [
      MessageNotification(
        id: '1',
        name: 'Albert Marjan',
        isOnline: true,
        time: '04:32 pm',
        message: 'Congratulations on completing the first lesson, keep up the good work!',
      ),
      MessageNotification(
        id: '2',
        name: 'Sagar shrestha',
        isOnline: true,
        time: '04:32 pm',
        message: 'Your course has been updated, you can check the new course in your study course.',
        hasAttachment: true,
      ),
      MessageNotification(
        id: '3',
        name: 'Bishikha satgiya',
        isOnline: false,
        time: '12:00 am',
        message: 'Congratulations, you have completed your...',
      ),
    ];
  }

  static List<NotificationItem> getNotifications() {
    return [
      NotificationItem(
        id: '1',
        title: 'Successful purchase!',
        time: 'Just now',
        iconColor: AppColors.durationOrange,
        icon: Icons.receipt,
      ),
      NotificationItem(
        id: '2',
        title: 'Congratulations on completing the ...',
        time: 'Just now',
        iconColor: AppColors.categoryPurple,
        icon: Icons.message,
      ),
      NotificationItem(
        id: '3',
        title: 'Your course has been updated, you ...',
        time: 'Just now',
        iconColor: AppColors.categoryPurple,
        icon: Icons.message,
      ),
      NotificationItem(
        id: '4',
        title: 'Congratulations, you have...',
        time: 'Just now',
        iconColor: AppColors.categoryPurple,
        icon: Icons.message,
      ),
    ];
  }
}


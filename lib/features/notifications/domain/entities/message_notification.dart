import 'package:flutter/material.dart';

class MessageNotification {
  final String id;
  final String name;
  final bool isOnline;
  final String time;
  final String message;
  final bool hasAttachment;

  MessageNotification({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.time,
    required this.message,
    this.hasAttachment = false,
  });
}

class NotificationItem {
  final String id;
  final String title;
  final String time;
  final Color iconColor;
  final IconData icon;

  NotificationItem({
    required this.id,
    required this.title,
    required this.time,
    required this.iconColor,
    required this.icon,
  });
}


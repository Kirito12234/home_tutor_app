import 'package:flutter/material.dart';

class MessageNotification {
  final String id;
  final String name;
  final bool isOnline;
  final String time;
  final String message;
  final bool hasAttachment;

  const MessageNotification({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.time,
    required this.message,
    this.hasAttachment = false,
  });

  factory MessageNotification.fromJson(Map<String, dynamic> json) {
    return MessageNotification(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isOnline: json['isOnline'] == true,
      time: json['time']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      hasAttachment: json['hasAttachment'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isOnline': isOnline,
      'time': time,
      'message': message,
      'hasAttachment': hasAttachment,
    };
  }

  MessageNotification copyWith({
    String? id,
    String? name,
    bool? isOnline,
    String? time,
    String? message,
    bool? hasAttachment,
  }) {
    return MessageNotification(
      id: id ?? this.id,
      name: name ?? this.name,
      isOnline: isOnline ?? this.isOnline,
      time: time ?? this.time,
      message: message ?? this.message,
      hasAttachment: hasAttachment ?? this.hasAttachment,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MessageNotification &&
        other.id == id &&
        other.name == name &&
        other.isOnline == isOnline &&
        other.time == time &&
        other.message == message &&
        other.hasAttachment == hasAttachment;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, isOnline, time, message, hasAttachment);
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String? message;
  final String time;
  final Color iconColor;
  final IconData icon;
  final String type;
  final Map<String, dynamic>? data;

  const NotificationItem({
    required this.id,
    required this.title,
    this.message,
    required this.time,
    required this.iconColor,
    required this.icon,
    this.type = 'system',
    this.data,
  });
}


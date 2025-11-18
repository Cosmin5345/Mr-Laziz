import 'package:flutter/material.dart';

class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String
  type; // task_assigned, task_status_changed, task_created, task_deleted
  final String? taskId;
  final String? groupId;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.taskId,
    this.groupId,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      taskId: json['task_id'] as String?,
      groupId: json['group_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'task_id': taskId,
      'group_id': groupId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? taskId,
    String? groupId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      taskId: taskId ?? this.taskId,
      groupId: groupId ?? this.groupId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  IconData get icon {
    switch (type) {
      case 'task_assigned':
        return Icons.person_add_outlined;
      case 'task_status_changed':
        return Icons.sync_alt;
      case 'task_created':
        return Icons.add_circle_outline;
      case 'task_deleted':
        return Icons.delete_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get color {
    switch (type) {
      case 'task_assigned':
        return const Color(0xFF06B6D4); // cyan
      case 'task_status_changed':
        return const Color(0xFF8B5CF6); // purple
      case 'task_created':
        return const Color(0xFF10B981); // green
      case 'task_deleted':
        return const Color(0xFFEF4444); // red
      default:
        return const Color(0xFF6B7280); // gray
    }
  }
}

// Alias pentru compatibilitate cu UI vechi
typedef AppNotification = Notification;

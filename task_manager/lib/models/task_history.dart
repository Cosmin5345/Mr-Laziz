import 'package:flutter/material.dart';

class TaskHistory {
  final String id;
  final String taskId;
  final String taskTitle;
  final String action; // created, updated, completed, assigned, etc.
  final String? oldValue;
  final String? newValue;
  final String? changedBy;
  final String? changedByUsername;
  final DateTime? timestamp;

  TaskHistory({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.action,
    this.oldValue,
    this.newValue,
    this.changedBy,
    this.changedByUsername,
    this.timestamp,
  });

  factory TaskHistory.fromJson(Map<String, dynamic> json) {
    return TaskHistory(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      taskTitle: json['task_title'] as String? ?? 'Unknown Task',
      action: json['action'] as String,
      oldValue: json['old_value'] as String?,
      newValue: json['new_value'] as String?,
      changedBy: json['changed_by'] as String?,
      changedByUsername: json['changed_by_username'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'task_title': taskTitle,
      'action': action,
      'old_value': oldValue,
      'new_value': newValue,
      'changed_by': changedBy,
      'changed_by_username': changedByUsername,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  String get description {
    switch (action) {
      case 'created':
        return 'Task created';
      case 'completed':
        return 'Marked as complete';
      case 'reopened':
        return 'Reopened task';
      case 'status_changed':
        return 'Status: $oldValue → $newValue';
      case 'assigned':
        return 'Assigned to $newValue';
      case 'deadline_changed':
        return 'Deadline updated';
      case 'priority_changed':
        return 'Priority: $oldValue → $newValue';
      case 'updated':
        return 'Task updated';
      default:
        return action;
    }
  }

  IconData get icon {
    switch (action) {
      case 'created':
        return Icons.add_circle_outline;
      case 'completed':
        return Icons.check_circle_outline;
      case 'reopened':
        return Icons.refresh;
      case 'status_changed':
        return Icons.swap_horiz;
      case 'assigned':
        return Icons.person_add_outlined;
      case 'deadline_changed':
        return Icons.calendar_today;
      case 'priority_changed':
        return Icons.flag_outlined;
      case 'updated':
        return Icons.edit_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}

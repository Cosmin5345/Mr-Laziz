import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    this.onTap,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case 'high':
        return AppColors.red500;
      case 'medium':
        return AppColors.orange500;
      case 'low':
        return AppColors.gray400;
      default:
        return AppColors.gray400;
    }
  }

  String _getPriorityLabel() {
    final priority = task.priority ?? 'low';
    return '${priority[0].toUpperCase()}${priority.substring(1)} priority';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.white.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    gradient: task.completed
                        ? const LinearGradient(
                            colors: [AppColors.cyan400, AppColors.blue500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: task.completed
                        ? null
                        : Border.all(color: AppColors.gray300, width: 2),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    boxShadow: task.completed
                        ? [
                            BoxShadow(
                              color: AppColors.cyan400.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: task.completed
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w400,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: AppColors.gray400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${task.dueDate ?? 'No deadline'} • ${_getPriorityLabel()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getPriorityColor(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.more_vert, size: 20, color: AppColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeadlineHelper {
  /// Calculează timpul rămas până la deadline
  static String getTimeRemaining(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      final overdue = now.difference(deadline);
      if (overdue.inDays > 0) {
        return 'Overdue by ${overdue.inDays} day${overdue.inDays > 1 ? 's' : ''}';
      } else if (overdue.inHours > 0) {
        return 'Overdue by ${overdue.inHours} hour${overdue.inHours > 1 ? 's' : ''}';
      } else {
        return 'Overdue by ${overdue.inMinutes} minute${overdue.inMinutes > 1 ? 's' : ''}';
      }
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} left';
    } else {
      return 'Less than a minute left';
    }
  }

  /// Returnează culoarea bazată pe urgența deadline-ului
  static Color getDeadlineColor(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return Colors.red; // Overdue
    } else if (difference.inDays == 0) {
      return Colors.orange; // Due today
    } else if (difference.inDays <= 3) {
      return Colors.amber; // Due soon (next 3 days)
    } else {
      return Colors.green; // Plenty of time
    }
  }

  /// Formatează data pentru afișare
  static String formatDeadline(DateTime deadline) {
    return DateFormat('MMM dd, yyyy - HH:mm').format(deadline);
  }

  /// Widget pentru afișarea deadline-ului
  static Widget buildDeadlineChip(
    DateTime? deadline, {
    bool showTimeRemaining = true,
  }) {
    if (deadline == null) return const SizedBox.shrink();

    final color = getDeadlineColor(deadline);
    final timeRemaining = getTimeRemaining(deadline);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            showTimeRemaining ? timeRemaining : formatDeadline(deadline),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

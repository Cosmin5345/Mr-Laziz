import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/user.dart' as models;
import '../config/supabase_config.dart';

class ApiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Task>> getTasksByGroup(String groupId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.tasksTable)
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  Future<List<Task>> getTasks() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.tasksTable)
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  Future<Task> createTask(
    String title,
    String? description,
    String groupId, {
    DateTime? deadline,
    String? priority,
  }) async {
    try {
      final response = await _supabase.rpc(
        'create_task',
        params: {
          'p_group_id': groupId,
          'p_title': title,
          'p_description': description,
        },
      );

      final task = Task.fromJson(response[0]);

      if (deadline != null || priority != null) {
        final updateData = <String, dynamic>{};
        if (deadline != null) {
          updateData['deadline'] = deadline.toIso8601String();
        }
        if (priority != null) {
          updateData['priority'] = priority;
        }

        await _supabase
            .from(SupabaseConfig.tasksTable)
            .update(updateData)
            .eq('id', task.id);

        // Returnează task cu datele actualizate
        final updatedData = <String, dynamic>{...response[0]};
        if (deadline != null) {
          updatedData['deadline'] = deadline.toIso8601String();
        }
        if (priority != null) {
          updatedData['priority'] = priority;
        }
        return Task.fromJson(updatedData);
      }

      return task;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  Future<void> updateTaskDeadline(String taskId, DateTime? deadline) async {
    try {
      await _supabase
          .from(SupabaseConfig.tasksTable)
          .update({'deadline': deadline?.toIso8601String()})
          .eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to update task deadline: $e');
    }
  }

  Future<void> updateTaskPriority(String taskId, String priority) async {
    try {
      await _supabase
          .from(SupabaseConfig.tasksTable)
          .update({'priority': priority})
          .eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to update task priority: $e');
    }
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _supabase
          .from(SupabaseConfig.tasksTable)
          .update({'status': newStatus})
          .eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to update task status: $e');
    }
  }

  Future<void> assignTask(String taskId, String? userId) async {
    try {
      await _supabase
          .from(SupabaseConfig.tasksTable)
          .update({'assigned_to': userId})
          .eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to assign task: $e');
    }
  }

  Future<void> updateTask(
    String taskId,
    String title,
    String? description,
  ) async {
    try {
      await _supabase
          .from(SupabaseConfig.tasksTable)
          .update({'title': title, 'description': description ?? ''})
          .eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from(SupabaseConfig.tasksTable).delete().eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<List<models.User>> getUsers() async {
    try {
      final response = await _supabase.from(SupabaseConfig.usersTable).select();

      return (response as List)
          .map((json) => models.User.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  RealtimeChannel subscribeToTasks(Function(List<Task>) onTasksChanged) {
    return _supabase
        .channel('tasks_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.tasksTable,
          callback: (payload) async {
            final tasks = await getTasks();
            onTasksChanged(tasks);
          },
        )
        .subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/user.dart' as models;
import '../config/supabase_config.dart';

class ApiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===== TASK OPERATIONS =====

  /// Obține task-urile pentru un grup specific
  Future<List<Task>> getTasksByGroup(String groupId) async {
    try {
      print('=== GET TASKS BY GROUP DEBUG ===');
      print('Group ID: $groupId');
      print('User ID: ${_supabase.auth.currentUser?.id}');

      final response = await _supabase
          .from(SupabaseConfig.tasksTable)
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

      print('Tasks response: $response');
      print('Tasks count: ${(response as List).length}');

      return (response as List).map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      print('Error loading tasks: $e');
      throw Exception('Failed to load tasks: $e');
    }
  }

  /// Obține toate task-urile (pentru backward compatibility)
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
    String groupId,
  ) async {
    try {
      print('=== CREATE TASK DEBUG ===');
      print('Group ID: $groupId');
      print('Title: $title');
      print('Description: $description');

      // Folosește funcția database create_task
      final response = await _supabase.rpc(
        'create_task',
        params: {
          'p_group_id': groupId,
          'p_title': title,
          'p_description': description,
        },
      );

      print('Task created successfully');
      print('Response: $response');

      return Task.fromJson(response[0]);
    } catch (e) {
      print('Error creating task: $e');
      throw Exception('Failed to create task: $e');
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

  // ===== USER OPERATIONS =====

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

  // ===== REAL-TIME SUBSCRIPTIONS =====

  /// Ascultă modificări în real-time pentru task-uri
  RealtimeChannel subscribeToTasks(Function(List<Task>) onTasksChanged) {
    return _supabase
        .channel('tasks_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.tasksTable,
          callback: (payload) async {
            // Reîncarcă toate task-urile când apare o schimbare
            final tasks = await getTasks();
            onTasksChanged(tasks);
          },
        )
        .subscribe();
  }

  /// Oprește ascultarea modificărilor în real-time
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}

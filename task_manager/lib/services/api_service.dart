import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/task.dart';
import '../models/user.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000'; // Windows/iOS
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Task>> getTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Task> createTask(String title, String? description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'title': title,
          'description': description ?? '',
        }),
      );

      if (response.statusCode == 201) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create task');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> updateTaskStatus(int taskId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId/status'),
        headers: await _getHeaders(),
        body: jsonEncode({'newStatus': newStatus}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update task status');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> assignTask(int taskId, int? userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId/assign'),
        headers: await _getHeaders(),
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to assign task');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> updateTask(int taskId, String title, String? description) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'title': title,
          'description': description ?? '',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update task');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<User>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

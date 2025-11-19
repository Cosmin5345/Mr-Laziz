import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/group_service.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Task task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final ApiService _apiService = ApiService();
  final GroupService _groupService = GroupService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _currentStatus;
  late String _currentPriority; // Add priority state
  String? _assignedUserId; // Changed from int? to String?
  List<User> _users = [];
  bool _isLoading = false;
  bool _isLoadingUsers = true;
  bool _isLeader = false;
  bool _isCheckingLeader = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );
    _currentStatus = widget.task.status;
    _assignedUserId = widget.task.assignedTo; // Changed from assignedToUserId
    _currentPriority = widget.task.priority ?? 'low'; // Default to low if null
    _loadUsers();
    _checkIfLeader();
  }

  Future<void> _checkIfLeader() async {
    if (widget.task.groupId == null) {
      setState(() => _isCheckingLeader = false);
      return;
    }

    try {
      final isLeader = await _groupService.isGroupLeader(widget.task.groupId!);
      setState(() {
        _isLeader = isLeader;
        _isCheckingLeader = false;
      });
    } catch (e) {
      setState(() => _isCheckingLeader = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (widget.task.groupId == null) {
      setState(() => _isLoadingUsers = false);
      return;
    }

    try {
      final users = await _groupService.getGroupMembersForAssignment(
        widget.task.groupId!,
      );
      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
    }
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.updateTask(
        widget.task.id,
        _titleController.text.trim(),
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task updated successfully')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _apiService.updateTaskStatus(widget.task.id, newStatus);
      setState(() => _currentStatus = newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updatePriority(String newPriority) async {
    try {
      await _apiService.updateTaskPriority(widget.task.id, newPriority);
      setState(() => _currentPriority = newPriority);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Priority updated to $newPriority')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _assignTask(String? userId) async {
    try {
      await _apiService.assignTask(widget.task.id, userId);
      setState(() => _assignedUserId = userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userId == null ? 'Task unassigned' : 'Task assigned successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            const Text(
              'Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Todo', label: Text('To Do')),
                ButtonSegment(value: 'InProgress', label: Text('In Progress')),
                ButtonSegment(value: 'Done', label: Text('Done')),
              ],
              selected: {_currentStatus},
              onSelectionChanged: (Set<String> newSelection) {
                _updateStatus(newSelection.first);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Priority',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _currentPriority,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'high',
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Color(0xFFEF4444), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'HIGH',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'medium',
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Color(0xFFF97316), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'MEDIUM',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'low',
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Color(0xFF059669), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'LOW',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _updatePriority(value);
                }
              },
            ),
            const SizedBox(height: 24),
            // Afișează secțiunea de assign doar pentru lideri
            if (_isLeader) ...[
              const Text(
                'Assign to',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _isLoadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String?>(
                      initialValue: _users.any((u) => u.id == _assignedUserId)
                          ? _assignedUserId
                          : null, // Dacă user-ul asignat nu e în listă, setează null
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select user',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Unassigned'),
                        ),
                        // Adaugă toți userii din listă
                        ..._users.map((user) {
                          return DropdownMenuItem<String?>(
                            value: user.id,
                            child: Text(user.username),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        _assignTask(value);
                      },
                    ),
              const SizedBox(height: 24),
            ] else if (!_isCheckingLeader) ...[
              // Mesaj pentru membrii care nu sunt lideri
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Only group leaders can assign tasks',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            ElevatedButton(
              onPressed: _isLoading ? null : _updateTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/group.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../ui/theme/app_colors.dart';
import '../ui/widgets/task_card.dart';
import '../ui/widgets/profile_drawer.dart';
import 'auth_screen.dart';
import 'create_task_screen.dart';
import 'task_details_screen.dart';
import 'notifications_screen.dart';

class TaskBoardScreen extends StatefulWidget {
  final Group group;

  const TaskBoardScreen({super.key, required this.group});

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  List<Task> _allTasks = [];
  bool _isLoading = true;
  String? _error;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await _apiService.getTasksByGroup(widget.group.id);
      setState(() {
        _allTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Task> _getTasksByStatus(String status) {
    return _allTasks.where((task) => task.status == status).toList();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      setState(() => _unreadCount = count);
    } catch (e) {
      // Ignore error
    }
  }

  void _navigateToNotifications() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    // Reîncarcă contorul după ce utilizatorul revine
    _loadUnreadCount();
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  void _navigateToCreateTask() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateTaskScreen(groupId: widget.group.id),
      ),
    );
    if (result == true) {
      _loadTasks();
    }
  }

  void _navigateToTaskDetails(Task task) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)));
    if (result == true) {
      _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks = _allTasks.where((t) => t.completed).length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGradientStart,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.group.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.gray900),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          tooltip: 'Profile',
        ),
        actions: [
          // Notification badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.gray900,
                ),
                onPressed: _navigateToNotifications,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.red500,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: AppColors.gray900),
            onPressed: _loadTasks,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.indigo600,
          unselectedLabelColor: AppColors.gray500,
          indicatorColor: AppColors.indigo600,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'To Do'),
            Tab(text: 'In Progress'),
            Tab(text: 'Done'),
          ],
        ),
      ),
      drawer: ProfileDrawer(
        totalTasks: _allTasks.length,
        completedTasks: completedTasks,
        onSignOut: _logout,
        userName: widget.group.name,
        userEmail: null,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientMid,
              AppColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadTasks,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList(_getTasksByStatus('Todo')),
                  _buildTaskList(_getTasksByStatus('InProgress')),
                  _buildTaskList(_getTasksByStatus('Done')),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateTask,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
        backgroundColor: AppColors.indigo600,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              'No tasks in this category',
              style: TextStyle(fontSize: 16, color: AppColors.gray500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TaskCard(
              task: task,
              onToggle: () => _toggleTaskComplete(task),
              onTap: () => _navigateToTaskDetails(task),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleTaskComplete(Task task) async {
    try {
      final newStatus = task.completed ? 'Todo' : 'Done';
      await _apiService.updateTaskStatus(task.id, newStatus);
      _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

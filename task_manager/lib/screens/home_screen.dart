import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/group.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../ui/theme/app_colors.dart';
import '../ui/widgets/profile_drawer_modern.dart';
import 'auth_screen.dart';
import 'create_task_screen.dart';
import 'task_details_screen.dart';
import 'projects_screen.dart';
import 'schedule_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  final Group group;

  const HomeScreen({super.key, required this.group});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final PreferencesService _preferencesService = PreferencesService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _supabase = Supabase.instance.client;

  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _searchOpen = false;
  String _searchQuery = '';
  String _filterPriority = 'Medium priority';
  bool _showFilter = false;

  String _userName = '';
  String _userInitials = 'U';

  @override
  void initState() {
    super.initState();
    _saveCurrentGroup();
    _loadTasks();
    _loadUserInfo();
  }

  Future<void> _saveCurrentGroup() async {
    await _preferencesService.saveLastGroup(widget.group.id, widget.group.name);
  }

  Future<void> _loadUserInfo() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser != null) {
      final firstName = authUser.userMetadata?['first_name'] as String? ?? '';
      final lastName = authUser.userMetadata?['last_name'] as String? ?? '';

      setState(() {
        _userName = '$firstName $lastName'.trim();
        if (_userName.isEmpty)
          _userName = authUser.email?.split('@')[0] ?? 'User';

        if (firstName.isNotEmpty && lastName.isNotEmpty) {
          _userInitials = '${firstName[0]}${lastName[0]}'.toUpperCase();
        } else if (firstName.isNotEmpty) {
          _userInitials = firstName[0].toUpperCase();
        } else if (_userName.isNotEmpty) {
          _userInitials = _userName[0].toUpperCase();
        }
      });
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _apiService.getTasksByGroup(widget.group.id);
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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

  Future<void> _showPriorityDialog(Task task) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Set Priority',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPriorityOption(
                'high',
                'HIGH',
                AppColors.red600,
                const Color(0xFFEF4444),
                task.priority == 'high',
              ),
              const SizedBox(height: 12),
              _buildPriorityOption(
                'medium',
                'MEDIUM',
                AppColors.orange600,
                const Color(0xFFF97316),
                task.priority == 'medium',
              ),
              const SizedBox(height: 12),
              _buildPriorityOption(
                'low',
                'LOW',
                const Color(0xFF059669),
                const Color(0xFF059669),
                task.priority == 'low',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.gray600),
              ),
            ),
          ],
        );
      },
    );

    if (result != null && result != task.priority) {
      try {
        await _apiService.updateTaskPriority(task.id, result);
        _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Priority updated to ${result.toUpperCase()}'),
              backgroundColor: AppColors.green600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating priority: $e'),
              backgroundColor: AppColors.red600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildPriorityOption(
    String value,
    String label,
    Color textColor,
    Color iconColor,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.indigo50 : AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.indigo600 : AppColors.gray200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.flag, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: textColor,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.indigo600,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    // Șterge toate preferințele salvate
    await _preferencesService.clearAll();
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  void _navigateToNewTask() async {
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

  void _deleteTask(String taskId) async {
    setState(() {
      _tasks.removeWhere((t) => t.id == taskId);
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task deleted')));
    }
  }

  List<Task> get _filteredTasks {
    var filtered = _tasks.where((t) => !t.completed).toList();

    if (_showFilter && _filterPriority.isNotEmpty) {
      filtered = filtered.where((t) => t.priority == _filterPriority).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Sortare după prioritate: high > medium > low
    filtered.sort((a, b) {
      const priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      final aPriority = priorityOrder[a.priority?.toLowerCase()] ?? 3;
      final bPriority = priorityOrder[b.priority?.toLowerCase()] ?? 3;
      return aPriority.compareTo(bPriority);
    });

    return filtered;
  }

  int get _completedCount => _tasks.where((t) => t.completed).length;
  int get _totalCount => _tasks.length;
  double get _progressPercent =>
      _totalCount > 0 ? (_completedCount / _totalCount) : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      drawer: ProfileDrawerModern(
        totalTasks: _totalCount,
        completedTasks: _completedCount,
        onSignOut: _logout,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_searchOpen) _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGreeting(),
                            const SizedBox(height: 24),
                            _buildProgressCard(),
                            const SizedBox(height: 24),
                            _buildQuickActions(),
                            const SizedBox(height: 24),
                            _buildTasksList(),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.indigo500, AppColors.blue500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.indigo500.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _userInitials,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Your productivity companion',
                  style: TextStyle(fontSize: 12, color: AppColors.gray500),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _searchOpen = !_searchOpen),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _searchOpen ? Icons.close : Icons.search,
                  size: 20,
                  color: AppColors.gray600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.gray50,
      child: TextField(
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.white,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.gray500,
              fontFamily: 'Outfit',
            ),
            children: [
              const TextSpan(text: "Working on "),
              TextSpan(
                text: widget.group.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.indigo600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.cyan400, AppColors.blue500, AppColors.indigo600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo500.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Progress",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_completedCount of $_totalCount tasks completed',
            style: const TextStyle(fontSize: 14, color: AppColors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressPercent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${(_progressPercent * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildQuickActionItem(
              icon: Icons.edit_outlined,
              label: 'New',
              color: AppColors.indigo100,
              iconColor: AppColors.indigo600,
              onTap: _navigateToNewTask,
            ),
            _buildQuickActionItem(
              icon: Icons.folder_outlined,
              label: 'Projects',
              color: AppColors.orange100,
              iconColor: AppColors.orange600,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProjectsScreen(currentGroup: widget.group),
                  ),
                );
              },
            ),
            _buildQuickActionItem(
              icon: Icons.calendar_today_outlined,
              label: 'Schedule',
              color: AppColors.cyan100,
              iconColor: AppColors.cyan600,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ScheduleScreen(group: widget.group),
                  ),
                );
              },
            ),
            _buildQuickActionItem(
              icon: Icons.bar_chart_outlined,
              label: 'Analytics',
              color: AppColors.pink100,
              iconColor: AppColors.pink600,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AnalyticsScreen(group: widget.group),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.gray900),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Tasks",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.indigo50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.filter_list,
                  size: 20,
                  color: AppColors.indigo600,
                ),
              ),
              onSelected: (value) {
                setState(() {
                  if (value == 'all') {
                    _showFilter = false;
                    _filterPriority = '';
                  } else {
                    _showFilter = true;
                    _filterPriority = value;
                  }
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, size: 16, color: AppColors.gray600),
                      SizedBox(width: 8),
                      Text('All Tasks'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'low',
                  child: Row(
                    children: [
                      Icon(Icons.flag, size: 16, color: Color(0xFF16A34A)),
                      SizedBox(width: 8),
                      Text('Low Priority'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'medium',
                  child: Row(
                    children: [
                      Icon(Icons.flag, size: 16, color: AppColors.orange500),
                      SizedBox(width: 8),
                      Text('Medium Priority'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'high',
                  child: Row(
                    children: [
                      Icon(Icons.flag, size: 16, color: AppColors.red500),
                      SizedBox(width: 8),
                      Text('High Priority'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_showFilter) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.indigo50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtering: ${_filterPriority.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.indigo900,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showFilter = false),
                  child: const Text(
                    '×',
                    style: TextStyle(fontSize: 20, color: AppColors.indigo600),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_filteredTasks.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No tasks found',
                style: TextStyle(fontSize: 16, color: AppColors.gray400),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredTasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final task = _filteredTasks[index];
              return _buildTaskCard(task);
            },
          ),
      ],
    );
  }

  Widget _buildTaskCard(Task task) {
    return GestureDetector(
      onTap: () => _navigateToTaskDetails(task),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.gray200, width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.dueDate ?? 'No deadline',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: task.priority == 'high'
                              ? AppColors.pink100
                              : task.priority == 'medium'
                              ? AppColors.orange100
                              : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag,
                              size: 12,
                              color: task.priority == 'high'
                                  ? AppColors.red600
                                  : task.priority == 'medium'
                                  ? AppColors.orange600
                                  : const Color(0xFF059669),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.priority?.toUpperCase() ?? 'LOW',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: task.priority == 'high'
                                    ? AppColors.red600
                                    : task.priority == 'medium'
                                    ? AppColors.orange600
                                    : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: AppColors.gray600,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              offset: const Offset(-20, 0),
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteTask(task.id.toString());
                } else if (value == 'complete') {
                  _toggleTaskComplete(task);
                } else if (value == 'priority') {
                  _showPriorityDialog(task);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(
                        task.completed
                            ? Icons.close
                            : Icons.check_circle_outline,
                        size: 20,
                        color: AppColors.cyan600,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        task.completed
                            ? 'Mark as incomplete'
                            : 'Mark as complete',
                        style: const TextStyle(
                          color: AppColors.cyan600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'priority',
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 20,
                        color: AppColors.indigo600,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Change Priority',
                        style: TextStyle(
                          color: AppColors.indigo600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.red500,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Delete task',
                        style: TextStyle(color: AppColors.red600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: _navigateToNewTask,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.indigo500, AppColors.indigo700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.indigo500.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, size: 24, color: AppColors.white),
      ),
    );
  }
}

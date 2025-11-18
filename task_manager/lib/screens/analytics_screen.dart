import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/group.dart';
import '../models/task_history.dart';
import '../services/api_service.dart';
import '../ui/theme/app_colors.dart';

class AnalyticsScreen extends StatefulWidget {
  final Group group;

  const AnalyticsScreen({super.key, required this.group});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  List<Task> _allTasks = [];
  List<TaskHistory> _taskHistory = [];
  bool _isLoading = true;

  // Statistics
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _inProgressTasks = 0;
  int _overdueTasks = 0;

  // Priority breakdown
  int _highPriorityTasks = 0;
  int _mediumPriorityTasks = 0;
  int _lowPriorityTasks = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load all tasks for the group
      final tasks = await _apiService.getTasksByGroup(widget.group.id);

      // Load task history (we'll simulate this for now since we don't have a history table yet)
      final history = await _generateTaskHistory(tasks);

      setState(() {
        _allTasks = tasks;
        _taskHistory = history;
        _calculateStatistics();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<TaskHistory>> _generateTaskHistory(List<Task> tasks) async {
    // For now, generate history from task data
    // In the future, this should come from a task_history table in Supabase
    List<TaskHistory> history = [];

    for (var task in tasks) {
      // Add creation event
      history.add(
        TaskHistory(
          id: '${task.id}_created',
          taskId: task.id,
          taskTitle: task.title,
          action: 'created',
          changedBy: task.createdBy,
          changedByUsername: task.createdByUsername ?? 'Unknown',
          timestamp: task.createdAt,
        ),
      );

      // Add assignment event if assigned
      if (task.assignedTo != null) {
        history.add(
          TaskHistory(
            id: '${task.id}_assigned',
            taskId: task.id,
            taskTitle: task.title,
            action: 'assigned',
            newValue: task.assignedToUsername ?? 'Unknown',
            changedBy: task.createdBy,
            changedByUsername: task.createdByUsername ?? 'Unknown',
            timestamp: task.createdAt,
          ),
        );
      }

      // Add completion event if completed
      if (task.completed) {
        history.add(
          TaskHistory(
            id: '${task.id}_completed',
            taskId: task.id,
            taskTitle: task.title,
            action: 'completed',
            changedBy: task.assignedTo ?? task.createdBy,
            changedByUsername:
                task.assignedToUsername ?? task.createdByUsername ?? 'Unknown',
            timestamp: task.updatedAt,
          ),
        );
      }

      // Add update event if updated
      if (task.updatedAt != null &&
          task.createdAt != null &&
          task.updatedAt!.isAfter(task.createdAt!)) {
        history.add(
          TaskHistory(
            id: '${task.id}_updated',
            taskId: task.id,
            taskTitle: task.title,
            action: 'updated',
            changedBy: task.assignedTo ?? task.createdBy,
            changedByUsername:
                task.assignedToUsername ?? task.createdByUsername ?? 'Unknown',
            timestamp: task.updatedAt,
          ),
        );
      }
    }

    // Sort by timestamp descending (newest first)
    history.sort((a, b) {
      if (a.timestamp == null) return 1;
      if (b.timestamp == null) return -1;
      return b.timestamp!.compareTo(a.timestamp!);
    });

    return history;
  }

  void _calculateStatistics() {
    _totalTasks = _allTasks.length;
    _completedTasks = _allTasks.where((t) => t.completed).length;
    _inProgressTasks = _allTasks.where((t) => t.status == 'InProgress').length;

    // Calculate overdue tasks
    final now = DateTime.now();
    _overdueTasks = _allTasks.where((t) {
      if (t.completed || t.deadline == null) return false;
      return t.deadline!.isBefore(now);
    }).length;

    // Calculate priority breakdown
    _highPriorityTasks = _allTasks.where((t) => t.priority == 'high').length;
    _mediumPriorityTasks = _allTasks
        .where((t) => t.priority == 'medium')
        .length;
    _lowPriorityTasks = _allTasks.where((t) => t.priority == 'low').length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.gray200),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    _buildTabSection(),
                    const SizedBox(height: 24),
                    _buildHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _StatData(
        'Total Tasks',
        _totalTasks.toString(),
        Icons.list_alt,
        AppColors.indigo600,
        AppColors.indigo100,
      ),
      _StatData(
        'Completed',
        _completedTasks.toString(),
        Icons.check_circle,
        AppColors.green600,
        AppColors.green100,
      ),
      _StatData(
        'In Progress',
        _inProgressTasks.toString(),
        Icons.access_time,
        AppColors.cyan600,
        AppColors.cyan100,
      ),
      _StatData(
        'Overdue',
        _overdueTasks.toString(),
        Icons.error_outline,
        AppColors.red600,
        AppColors.red100,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray900.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stat.title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: stat.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(stat.icon, color: stat.iconColor, size: 18),
                  ),
                ],
              ),
              Text(
                stat.value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.indigo600,
            unselectedLabelColor: AppColors.gray500,
            indicatorColor: AppColors.indigo600,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Priority'),
              Tab(text: 'Timeline'),
            ],
          ),
          SizedBox(
            height: 350,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPriorityTab(),
                _buildTimelineTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Completion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _totalTasks > 0
                      ? PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: [
                              PieChartSectionData(
                                value: _completedTasks.toDouble(),
                                color: AppColors.green600,
                                title:
                                    '${((_completedTasks / _totalTasks) * 100).toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              PieChartSectionData(
                                value: (_totalTasks - _completedTasks)
                                    .toDouble(),
                                color: AppColors.gray300,
                                title:
                                    '${(((_totalTasks - _completedTasks) / _totalTasks) * 100).toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  color: AppColors.gray700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Center(child: Text('No tasks yet')),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      'Completed',
                      _completedTasks,
                      AppColors.green600,
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      'Pending',
                      _totalTasks - _completedTasks,
                      AppColors.gray300,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tasks by Priority',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPriorityBar(
                  'High Priority',
                  _highPriorityTasks,
                  _totalTasks,
                  AppColors.red600,
                ),
                const SizedBox(height: 16),
                _buildPriorityBar(
                  'Medium Priority',
                  _mediumPriorityTasks,
                  _totalTasks,
                  AppColors.orange600,
                ),
                const SizedBox(height: 16),
                _buildPriorityBar(
                  'Low Priority',
                  _lowPriorityTasks,
                  _totalTasks,
                  AppColors.green600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    // Group tasks by week for the last 4 weeks
    final now = DateTime.now();
    final weeklyData = <int, Map<String, int>>{};

    for (int i = 0; i < 4; i++) {
      weeklyData[i] = {'created': 0, 'completed': 0};
    }

    for (var task in _allTasks) {
      if (task.createdAt != null) {
        final weekAgo = now.difference(task.createdAt!).inDays ~/ 7;
        if (weekAgo >= 0 && weekAgo < 4) {
          weeklyData[weekAgo]!['created'] =
              (weeklyData[weekAgo]!['created'] ?? 0) + 1;
        }
      }

      if (task.completed && task.updatedAt != null) {
        final weekAgo = now.difference(task.updatedAt!).inDays ~/ 7;
        if (weekAgo >= 0 && weekAgo < 4) {
          weeklyData[weekAgo]!['completed'] =
              (weeklyData[weekAgo]!['completed'] ?? 0) + 1;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    (weeklyData.values
                                .map(
                                  (e) =>
                                      e.values.reduce((a, b) => a > b ? a : b),
                                )
                                .reduce((a, b) => a > b ? a : b) +
                            5)
                        .toDouble(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = [
                          'This Week',
                          '1 Week Ago',
                          '2 Weeks Ago',
                          '3 Weeks Ago',
                        ];
                        final index = 3 - value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[index],
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(4, (index) {
                  final weekIndex = 3 - index;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (weeklyData[weekIndex]!['created'] ?? 0)
                            .toDouble(),
                        color: AppColors.indigo600,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: (weeklyData[weekIndex]!['completed'] ?? 0)
                            .toDouble(),
                        color: AppColors.green600,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegend('Created', AppColors.indigo600),
              const SizedBox(width: 20),
              _buildChartLegend('Completed', AppColors.green600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppColors.indigo600, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _taskHistory.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: AppColors.gray400),
                        SizedBox(height: 12),
                        Text(
                          'No activity yet',
                          style: TextStyle(color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _taskHistory.length > 20
                      ? 20
                      : _taskHistory.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final history = _taskHistory[index];
                    return _buildHistoryItem(history);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(TaskHistory history) {
    final timeAgo = _getTimeAgo(history.timestamp);

    Color actionColor;
    switch (history.action) {
      case 'created':
        actionColor = AppColors.indigo600;
        break;
      case 'completed':
        actionColor = AppColors.green600;
        break;
      case 'assigned':
        actionColor = AppColors.cyan600;
        break;
      case 'updated':
        actionColor = AppColors.orange600;
        break;
      default:
        actionColor = AppColors.gray600;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: actionColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(history.icon, color: actionColor, size: 20),
      ),
      title: Text(
        history.taskTitle,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(history.description, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            '${history.changedByUsername} • $timeAgo',
            style: const TextStyle(fontSize: 12, color: AppColors.gray500),
          ),
        ],
      ),
      trailing: history.timestamp != null
          ? Text(
              DateFormat('HH:mm').format(history.timestamp!),
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
            )
          : null,
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.gray600),
            ),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray700,
                  ),
                ),
              ],
            ),
            Text(
              '$value tasks',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.gray200,
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.gray700),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  _StatData(this.title, this.value, this.icon, this.iconColor, this.bgColor);
}

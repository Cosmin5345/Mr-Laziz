import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/group.dart';
import '../services/api_service.dart';
import '../ui/theme/app_colors.dart';
import 'create_task_screen.dart';
import 'task_details_screen.dart';

class ScheduleScreen extends StatefulWidget {
  final Group group;

  const ScheduleScreen({super.key, required this.group});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ApiService _apiService = ApiService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Task>> _tasksByDate = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _apiService.getTasksByGroup(widget.group.id);

      // Grupează task-urile după dată
      final tasksByDate = <DateTime, List<Task>>{};
      for (final task in tasks) {
        if (task.deadline != null) {
          final date = DateTime(
            task.deadline!.year,
            task.deadline!.month,
            task.deadline!.day,
          );
          tasksByDate[date] = [...(tasksByDate[date] ?? []), task];
        }
      }

      setState(() {
        _tasksByDate = tasksByDate;
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

  List<Task> _getTasksForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _tasksByDate[date] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  void _createTaskForSelectedDay() async {
    if (_selectedDay == null) return;

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
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Schedule',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: AppColors.indigo600),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendar(),
                const Divider(height: 1),
                Expanded(child: _buildTasksList()),
              ],
            ),
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton.extended(
              onPressed: _createTaskForSelectedDay,
              backgroundColor: AppColors.indigo600,
              icon: const Icon(Icons.add),
              label: Text(
                'Add Task for ${DateFormat('MMM d').format(_selectedDay!)}',
              ),
            )
          : null,
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar<Task>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _getTasksForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: AppColors.cyan400.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.indigo500, AppColors.blue500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.orange500,
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.indigo600,
            fontWeight: FontWeight.w600,
          ),
          selectedTextStyle: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
          weekendTextStyle: const TextStyle(color: AppColors.red500),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
          leftChevronIcon: const Icon(
            Icons.chevron_left,
            color: AppColors.gray600,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right,
            color: AppColors.gray600,
          ),
        ),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() => _calendarFormat = format);
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildTasksList() {
    if (_selectedDay == null) {
      return const Center(
        child: Text(
          'Select a day to view tasks',
          style: TextStyle(fontSize: 16, color: AppColors.gray400),
        ),
      );
    }

    final tasksForDay = _getTasksForDay(_selectedDay!);
    final dateStr = DateFormat('EEEE, MMMM d, y').format(_selectedDay!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${tasksForDay.length} ${tasksForDay.length == 1 ? 'task' : 'tasks'}',
                style: const TextStyle(fontSize: 14, color: AppColors.gray500),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasksForDay.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.indigo50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.event_available,
                          size: 40,
                          color: AppColors.indigo600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No tasks for this day',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the button below to add a task',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: tasksForDay.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = tasksForDay[index];
                    return _buildTaskCard(task);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Task task) {
    return GestureDetector(
      onTap: () => _navigateToTaskDetails(task),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(
            color: task.completed ? AppColors.cyan200 : AppColors.gray200,
            width: 1.5,
          ),
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
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: task.completed
                    ? AppColors.cyan400
                    : task.priority == 'high'
                    ? AppColors.red500
                    : task.priority == 'medium'
                    ? AppColors.orange500
                    : AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppColors.gray400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (task.priority != null) ...[
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
                                : AppColors.gray100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.priority!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: task.priority == 'high'
                                  ? AppColors.red600
                                  : task.priority == 'medium'
                                  ? AppColors.orange600
                                  : AppColors.gray600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (task.completed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cyan100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: AppColors.cyan600,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cyan600,
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
            const Icon(Icons.chevron_right, color: AppColors.gray400, size: 20),
          ],
        ),
      ),
    );
  }
}

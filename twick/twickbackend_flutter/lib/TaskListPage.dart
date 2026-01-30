import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'models/Task.dart';
import 'models/TaskList.dart';
import 'models/Category.dart';
import 'models/CategoryList.dart';
import 'services/NotificationService.dart';
import 'services/ServerSyncService.dart';

enum TaskFilterType {
  today,
  scheduled,
  overdue,
  all,
  recurring,
}

class TaskListPage extends StatelessWidget {
  final TaskFilterType filterType;
  final String? categoryId; // Optional category filter

  const TaskListPage({
    super.key,
    required this.filterType,
    this.categoryId,
  });

  String get _pageTitle {
    if (categoryId != null) {
      final category = getCategoryById(categoryId);
      return category?.name ?? 'Category Tasks';
    }
    switch (filterType) {
      case TaskFilterType.today:
        return "Today's Tasks";
      case TaskFilterType.scheduled:
        return 'Scheduled Tasks';
      case TaskFilterType.overdue:
        return 'Overdue Tasks';
      case TaskFilterType.all:
        return 'All Tasks';
      case TaskFilterType.recurring:
        return 'Recurring Tasks';
    }
  }

  List<Task> _getFilteredTasks() {
    List<Task> tasks;
    switch (filterType) {
      case TaskFilterType.today:
        tasks = TaskFilters.getTodayTasks();
        break;
      case TaskFilterType.scheduled:
        tasks = TaskFilters.getScheduledTasks();
        break;
      case TaskFilterType.overdue:
        tasks = TaskFilters.getOverdueTasks();
        break;
      case TaskFilterType.all:
        // Exclude recurring tasks from "all" view
        tasks = allTasks.where((task) => !task.isRecurring).toList();
        break;
      case TaskFilterType.recurring:
        // Show all recurring tasks (no date filtering)
        tasks = TaskFilters.getRecurringTasks();
        break;
    }

    // Apply category filter if specified
    if (categoryId != null) {
      tasks = tasks.where((task) => task.categoryId == categoryId).toList();
    }

    return tasks;
  }

  void _showEditCategoryBottomSheet(BuildContext context) {
    if (categoryId == null) return;
    final category = getCategoryById(categoryId);
    if (category == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => _EditCategoryBottomSheet(category: category),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    if (categoryId == null) return;
    final category = getCategoryById(categoryId);
    if (category == null) return;

    final isDefault = ['work', 'personal', 'health', 'finance', 'general'].contains(category.id);
    
    if (isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default categories cannot be deleted'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final taskCount = TaskFilters.getTaskCountByCategoryId(category.id);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _DeleteCategoryDialog(category: category, taskCount: taskCount),
    );
  }

  bool _isDefaultCategory(String? categoryId) {
    if (categoryId == null) return false;
    const defaultIds = ['work', 'personal', 'health', 'finance', 'general'];
    return defaultIds.contains(categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[900]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _pageTitle,
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: categoryId != null
            ? [
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[900]),
                  color: Colors.white,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditCategoryBottomSheet(context);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue[600], size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Edit Category',
                            style: TextStyle(color: Colors.grey[900]),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      enabled: !_isDefaultCategory(categoryId),
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red[600], size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Delete Category',
                            style: TextStyle(
                              color: _isDefaultCategory(categoryId) 
                                  ? Colors.grey[400] 
                                  : Colors.grey[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: Obx(
        () {
          final tasks = _getFilteredTasks();

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          // For recurring tasks, show simple list without date grouping
          if (filterType == TaskFilterType.recurring) {
            // Sort tasks by priority first, then by time
            final sortedTasks = List<Task>.from(tasks);
            sortedTasks.sort(_compareTasks);

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: sortedTasks.length,
              itemBuilder: (context, index) {
                final task = sortedTasks[index];
                return _TaskListTile(task: task);
              },
            );
          }

          // For other filter types, group tasks by date
          final groupedTasks = _groupTasksByDate(tasks);

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: groupedTasks.length,
            itemBuilder: (context, index) {
              final dateGroup = groupedTasks[index];
              return _DateGroupSection(
                date: dateGroup['date'] as DateTime,
                tasks: dateGroup['tasks'] as List<Task>,
              );
            },
          );
        },
      ),
    );
  }

  // Helper function to get priority weight for sorting
  int _getPriorityWeight(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 3;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.low:
        return 1;
    }
  }

  // Sort tasks by priority first, then by time
  int _compareTasks(Task a, Task b) {
    // First compare by priority (higher priority first)
    final priorityDiff = _getPriorityWeight(b.priority) - _getPriorityWeight(a.priority);
    if (priorityDiff != 0) {
      return priorityDiff;
    }
    // If same priority, sort by time (earlier first)
    return a.scheduledTime.compareTo(b.scheduledTime);
  }

  List<Map<String, dynamic>> _groupTasksByDate(List<Task> tasks) {
    final Map<String, List<Task>> grouped = {};

    for (final task in tasks) {
      final dateKey = DateFormat('yyyy-MM-dd').format(task.scheduledTime);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(task);
    }

    // Sort tasks within each date group by priority first, then time
    for (final key in grouped.keys) {
      grouped[key]!.sort(_compareTasks);
    }

    // Convert to list and sort by date
    final result = grouped.entries.map((entry) {
      return {
        'date': DateTime.parse(entry.key),
        'tasks': entry.value,
      };
    }).toList();

    // Sort: Yesterday, Today, Tomorrow, then rest chronologically
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    result.sort((a, b) {
      final dateA = (a['date'] as DateTime);
      final dateB = (b['date'] as DateTime);
      
      final dateAOnly = DateTime(dateA.year, dateA.month, dateA.day);
      final dateBOnly = DateTime(dateB.year, dateB.month, dateB.day);
      
      // Helper function to get sort order
      int getSortOrder(DateTime date) {
        if (date == yesterday) return 1;
        if (date == today) return 2;
        if (date == tomorrow) return 3;
        return 4; // Rest
      }
      
      final orderA = getSortOrder(dateAOnly);
      final orderB = getSortOrder(dateBOnly);
      
      // If both are special dates (yesterday, today, tomorrow), sort by their order
      if (orderA < 4 && orderB < 4) {
        return orderA.compareTo(orderB);
      }
      
      // If one is special and other is not, special comes first
      if (orderA < 4 && orderB == 4) return -1;
      if (orderA == 4 && orderB < 4) return 1;
      
      // Both are regular dates, sort chronologically (earliest first)
      return dateAOnly.compareTo(dateBOnly);
    });

    return result;
  }
}

class _DateGroupSection extends StatelessWidget {
  final DateTime date;
  final List<Task> tasks;

  const _DateGroupSection({
    required this.date,
    required this.tasks,
  });

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM dd').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatDateHeader(date),
                style: TextStyle(
                  color: Colors.grey[900],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('yyyy').format(date) != DateFormat('yyyy').format(DateTime.now())
                    ? DateFormat('yyyy').format(date)
                    : '',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        ...tasks.map((task) => _TaskListTile(task: task)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _TaskListTile extends StatelessWidget {
  final Task task;

  const _TaskListTile({required this.task});

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }


  String _formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  String _formatTimeShort(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')}$period';
  }

  String _formatRecurringTime(Task task, DateTime dateTime) {
    if (!task.isRecurring || task.recurringIntervalType == null) {
      return _formatTime(dateTime);
    }

    final now = DateTime.now();
    final timeStr = _formatTimeShort(dateTime);

    switch (task.recurringIntervalType!) {
      case RecurringIntervalType.daily:
        // Check if it's tomorrow
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        final dateTimeDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
        if (dateTimeDay.year == tomorrow.year &&
            dateTimeDay.month == tomorrow.month &&
            dateTimeDay.day == tomorrow.day) {
          return 'Tomorrow, $timeStr';
        }
        // Otherwise show the date
        return '${DateFormat('MMM d').format(dateTime)}, $timeStr';
        
      case RecurringIntervalType.weekly:
        // Show short form like "Jan 24"
        return DateFormat('MMM d').format(dateTime);
        
      case RecurringIntervalType.minutes:
      case RecurringIntervalType.hours:
        // For minutes/hours, just show time
        return timeStr;
    }
  }

  String _getRecurringLabel(Task task) {
    if (!task.isRecurring || task.recurringIntervalType == null) {
      return 'DAILY';
    }
    
    final duration = task.recurringDuration;
    final type = task.recurringIntervalType!;
    
    switch (type) {
      case RecurringIntervalType.minutes:
        return duration == 1 ? 'EVERY MIN' : 'EVERY ${duration}M';
      case RecurringIntervalType.hours:
        return duration == 1 ? 'EVERY HR' : 'EVERY ${duration}H';
      case RecurringIntervalType.daily:
        return duration == 1 ? 'DAILY' : 'EVERY ${duration}D';
      case RecurringIntervalType.weekly:
        return duration == 1 ? 'WEEKLY' : 'EVERY ${duration}W';
    }
  }

  void _showTaskActionsDialog(BuildContext context, Task task) {
    String? selectedCategoryId = task.categoryId ?? getGeneralCategory().id;
    TaskPriority selectedPriority = task.priority;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
              child: Container(
            padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
              color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[900],
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                if (!task.isRecurring)
                    Text(
                    'PRIORITY: ${task.priority.displayName}',
                      style: TextStyle(
                        color: _getPriorityColorForDialog(task.priority),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 16),
                // Priority Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRIORITY',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      child: DropdownButtonFormField<TaskPriority>(
                        value: selectedPriority,
                        dropdownColor: Colors.white,
                        style: TextStyle(color: Colors.grey[900]),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        items: TaskPriority.values.map((priority) {
                          Color priorityColor;
                          switch (priority) {
                            case TaskPriority.low:
                              priorityColor = Colors.green;
                              break;
                            case TaskPriority.medium:
                              priorityColor = Colors.orange;
                              break;
                            case TaskPriority.high:
                              priorityColor = Colors.red;
                              break;
                          }
                          return DropdownMenuItem<TaskPriority>(
                            value: priority,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: priorityColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  priority.displayName,
                                  style: TextStyle(
                                    color: Colors.grey[900],
                        fontWeight: FontWeight.w500,
                                    fontSize: 14,
                      ),
                    ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedPriority = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                    const SizedBox(height: 16),
                    // Category Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CATEGORY',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedCategoryId,
                          dropdownColor: Colors.white,
                          style: TextStyle(color: Colors.grey[900]),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          items: allCategories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category.id,
                              child: Row(
                                children: [
                                  Icon(
                                    category.icon,
                                    color: category.color,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      color: Colors.grey[900],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedCategoryId = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                        final taskIndex = allTasks.indexWhere((t) => t.id == task.id);
                        if (taskIndex != -1) {
                        allTasks[taskIndex] = task.copyWith(
                          priority: selectedPriority,
                          categoryId: selectedCategoryId,
                        );
                          allTasks.refresh();
                        }
                        Navigator.pop(context);
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 19, 38, 61),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                    ),
                    const SizedBox(height: 12),
                // Mark Complete/Incomplete Button (hidden for recurring tasks)
                if (!task.isRecurring) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        task.isCompleted = !task.isCompleted;
                        if (task.isCompleted) {
                          await NotificationService.cancelTaskNotification(task);
                          // Play swoosh sound when task is marked complete
                          final audioPlayer = AudioPlayer();
                          audioPlayer.play(AssetSource('swoosh.mp3')).catchError((e) {
                            debugPrint('Error playing swoosh sound: $e');
                          });
                        } else {
                          await NotificationService.scheduleTaskNotification(task);
                        }
                        allTasks.refresh();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green[700],
                        side: BorderSide(color: Colors.green[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                task.isCompleted ? Icons.undo : Icons.check_circle_outline,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                task.isCompleted ? 'Mark Incomplete' : 'Mark Complete',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ),
                    const SizedBox(height: 12),
                    ],
                    // Delete and Cancel buttons in a row
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              // Show confirmation dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Text(
                                    'Delete Task?',
                                    style: TextStyle(color: Colors.grey[900]),
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        // Cancel all notifications for this task
                        await NotificationService.cancelTaskNotification(task);
                        final taskId = task.id;
                        allTasks.remove(task);
                                        // Delete from server (non-blocking)
                                        ServerSyncService.deleteTaskFromServer(taskId).catchError((e) {
                                          debugPrint('Error deleting task from server: $e');
                                        });
                                        Navigator.pop(context); // Close confirmation
                                        Navigator.pop(context); // Close task actions dialog
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                      onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                      child: const Text(
                        'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                      ),
                    ),
                ),
              ),
                      ],
            ),
                  ],
          ),
        ),
      ),
          ),
        
      
    );
  }

  Color _getPriorityColorForDialog(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(task.priority);
    final category = getCategoryById(task.categoryId) ?? getGeneralCategory();
    final categoryIcon = category.icon;
    final categoryColor = category.color;

    // Check if task is overdue
    final isOverdue = !task.isCompleted && 
        !task.isRecurring && 
        task.scheduledTime.isBefore(DateTime.now());

    return GestureDetector(
      onTap: () => _showTaskActionsDialog(context, task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
          children: [
            Container(
                  height: 48,
                  width: 48,
              decoration: BoxDecoration(
                color: task.isCompleted
                        ? Colors.grey[200]
                        : categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                categoryIcon,
                    color: task.isCompleted ? Colors.grey[600] : categoryColor,
                    size: 24,
                  ),
                ),
                // Completed tick icon overlay
                if (task.isCompleted)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
              ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: task.isCompleted ? Colors.grey[600] : Colors.grey[900],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                          decorationColor: Colors.grey
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // For recurring tasks, only show recurring tag, no priority
                      if (task.isRecurring && !task.isCompleted) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(29, 158, 158, 158),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.repeat,
                                size: 12,
                                color: Colors.blue[600],
                              ),
                              const SizedBox(width: 4),
                      Text(
                                _getRecurringLabel(task),
                        style: TextStyle(
                                  color: Colors.blue[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                        ),
                      ] else if (!task.isCompleted) ...[
                        // For non-recurring tasks, show priority
                        Text(
                          "${task.priority.displayName} PRIORITY",
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            // letterSpacing: 0.3,
                          ),
                        ),
                      ] else ...[
                        // Completed tasks
                        Container(
                          // padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          // decoration: BoxDecoration(
                          //   color: Colors.green[50],
                          //   borderRadius: BorderRadius.circular(12),
                          // ),
                          child: Text(
                            "COMPLETED",
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              // letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // For recurring tasks, show "NEXT" tag and next trigger time
                // For non-recurring tasks, show schedule time
                if (task.isRecurring) ...[
                Text(
                    'NEXT',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatRecurringTime(task, task.getNextReminderTime() ?? task.scheduledTime),
                    style: TextStyle(
                      color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                ] else ...[
                  Text(
                    _formatTime(task.scheduledTime),
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                // Show status tag (PENDING, OVERDUE, or COMPLETED)
                if (!task.isRecurring) ...[
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      gradient: task.isCompleted
                          ? LinearGradient(
                              colors: [Colors.green[600]!, const Color.fromARGB(255, 30, 90, 33)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : isOverdue
                              ? LinearGradient(
                                  colors: [Colors.red[600]!, Colors.black87],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    Color(0xFF3B82F6), // Blue
                                    Color(0xFF1E40AF), // Dark Blue
                                    Color(0xFF000000), // Black
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                      borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                      task.isCompleted
                          ? 'COMPLETED'
                          : isOverdue
                              ? 'OVERDUE'
                              : 'PENDING',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────── EDIT CATEGORY BOTTOM SHEET ─────────────────
class _EditCategoryBottomSheet extends StatefulWidget {
  final TaskCategory category;

  const _EditCategoryBottomSheet({required this.category});

  @override
  State<_EditCategoryBottomSheet> createState() => _EditCategoryBottomSheetState();
}

class _EditCategoryBottomSheetState extends State<_EditCategoryBottomSheet> {
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late Color _selectedColor;
  final _formKey = GlobalKey<FormState>();

  final List<IconData> _availableIcons = [
    Icons.folder,
    Icons.work,
    Icons.person,
    Icons.fitness_center,
    Icons.account_balance_wallet,
    Icons.school,
    Icons.home,
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.music_note,
    Icons.movie,
    Icons.sports_soccer,
    Icons.book,
    Icons.car_repair,
    Icons.pets,
    Icons.favorite,
  ];

  final List<Color> _availableColors = [
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.tealAccent,
    Colors.cyanAccent,
    Colors.amberAccent,
    Colors.indigoAccent,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _selectedIcon = widget.category.icon;
    _selectedColor = widget.category.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateCategory() {
    if (_formKey.currentState!.validate()) {
      final index = allCategories.indexWhere((cat) => cat.id == widget.category.id);
      if (index != -1) {
        allCategories[index] = TaskCategory(
          id: widget.category.id,
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          color: _selectedColor,
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
              color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      Text(
                          'Edit Category',
                          style: TextStyle(
                          color: Colors.grey[900],
                          fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Name Input
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: Colors.grey[900]),
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                        hintText: 'Enter category name',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.blue[600]!,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a category name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Icon Selection
                    Text(
                      'Select Icon',
                      style: TextStyle(
                        color: Colors.grey[900],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableIcons.length,
                        itemBuilder: (context, index) {
                          final icon = _availableIcons[index];
                          final isSelected = icon == _selectedIcon;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIcon = icon;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[50],
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blueAccent
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? Colors.blueAccent : Colors.grey[600],
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Color Selection
                    Text(
                      'Select Color',
                      style: TextStyle(
                        color: Colors.grey[900],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableColors.length,
                        itemBuilder: (context, index) {
                          final color = _availableColors[index];
                          final isSelected = color == _selectedColor;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF3B82F6), // Blue
                                    Color(0xFF1E40AF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      child: ElevatedButton(
                        onPressed: _updateCategory,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Update Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      
    );
  }
}

// ───────────────── DELETE CATEGORY DIALOG ─────────────────
class _DeleteCategoryDialog extends StatelessWidget {
  final TaskCategory category;
  final int taskCount;

  const _DeleteCategoryDialog({
    required this.category,
    required this.taskCount,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
          color: Colors.white,
              borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            Text(
                  'Delete Category',
                  style: TextStyle(
                color: Colors.grey[900],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  taskCount > 0
                      ? 'This category has $taskCount ${taskCount == 1 ? 'task' : 'tasks'}. Deleting it will remove the category from all tasks.'
                      : 'Are you sure you want to delete "${category.name}"?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Text(
                          'Cancel',
                      style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red[600]!, Colors.red[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                      child: ElevatedButton(
                        onPressed: () {
                          final categoryId = category.id;
                          allCategories.removeWhere((cat) => cat.id == category.id);
                          // Delete from server (non-blocking)
                          ServerSyncService.deleteCategoryFromServer(categoryId).catchError((e) {
                            debugPrint('Error deleting category from server: $e');
                          });
                          Navigator.pop(context);
                          Navigator.pop(context); // Go back to categories page
                        },
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                    ),
                ),
            ),
          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

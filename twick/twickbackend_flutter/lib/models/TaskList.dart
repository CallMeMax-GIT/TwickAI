import 'package:get/get.dart';
import 'Task.dart';

// Single task list for the entire app
// Will be loaded from Hive storage on app start
final RxList<Task> allTasks = <Task>[].obs;

// Helper functions to filter tasks
class TaskFilters {
  // Get tasks scheduled for today (excluding recurring tasks)
  static List<Task> getTodayTasks() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return allTasks.where((task) {
      return !task.isRecurring && 
          task.scheduledTime.isAfter(startOfDay) &&
          task.scheduledTime.isBefore(endOfDay);
    }).toList();
  }

  // Get scheduled tasks (future tasks, not today, excluding recurring tasks)
  static List<Task> getScheduledTasks() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));

    return allTasks.where((task) {
      return !task.isRecurring && 
          task.scheduledTime.isAfter(endOfDay);
    }).toList();
  }

  // Get overdue tasks (past tasks that are not completed, excluding recurring tasks)
  static List<Task> getOverdueTasks() {
    final now = DateTime.now();

    return allTasks.where((task) {
      return !task.isRecurring && 
          task.scheduledTime.isBefore(now) && !task.isCompleted;
    }).toList();
  }

  // Get all incomplete tasks
  static List<Task> getIncompleteTasks() {
    return allTasks.where((task) => !task.isCompleted).toList();
  }

  // Get all completed tasks
  static List<Task> getCompletedTasks() {
    return allTasks.where((task) => task.isCompleted).toList();
  }

  // Get tasks by category ID
  static List<Task> getTasksByCategoryId(String categoryId) {
    return allTasks.where((task) => task.categoryId == categoryId).toList();
  }

  // Get task count by category ID
  static int getTaskCountByCategoryId(String categoryId) {
    return allTasks.where((task) => task.categoryId == categoryId).length;
  }

  // Get completed task count by category ID
  static int getCompletedCountByCategoryId(String categoryId) {
    return allTasks
        .where((task) => task.categoryId == categoryId && task.isCompleted)
        .length;
  }

  // Get all recurring tasks (including completed - they should still show and trigger)
  static List<Task> getRecurringTasks() {
    return allTasks.where((task) => task.isRecurring).toList();
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Task.dart';
import '../models/TaskList.dart';

/// Service to sync task data to App Group for iOS widgets
class WidgetDataService {
  static const MethodChannel _channel = MethodChannel('com.twick.app/widget');
  static const String _appGroupId = 'group.com.twick.app'; // Update with your App Group ID

  /// Sync all tasks to App Group UserDefaults
  static Future<void> syncTasksToWidget() async {
    try {
      // Get today's tasks
      final todayTasks = TaskFilters.getTodayTasks();
      debugPrint('WidgetDataService: Found ${todayTasks.length} today tasks out of ${allTasks.length} total tasks');
      
      // Convert tasks to JSON
      final tasksJson = allTasks.map((task) => task.toJson()).toList();
      final todayTasksJson = todayTasks.map((task) => task.toJson()).toList();
      
      debugPrint('WidgetDataService: Converting to JSON - ${todayTasksJson.length} today tasks');
      
      // Debug: Log first task's scheduled time
      if (todayTasksJson.isNotEmpty) {
        final firstTask = todayTasksJson.first;
        debugPrint('WidgetDataService: First task - title: ${firstTask['title']}, scheduledTime: ${firstTask['scheduledTime']}, scheduledTimeEpoch: ${firstTask['scheduledTimeEpoch']}');
        // Also log the actual DateTime object
        final firstTaskObj = todayTasks.first;
        debugPrint('WidgetDataService: First task DateTime - local: ${firstTaskObj.scheduledTime}, UTC: ${firstTaskObj.scheduledTime.toUtc()}');
      }
      
      // Save to App Group via method channel
      final result = await _channel.invokeMethod('syncTasksToWidget', {
        'tasks': tasksJson,
        'todayTasks': todayTasksJson,
        'appGroupId': _appGroupId,
      });
      
      debugPrint('WidgetDataService: Synced ${todayTasks.length} today tasks to widget - result: $result');
    } catch (e, stackTrace) {
      debugPrint('WidgetDataService: Error syncing tasks to widget: $e');
      debugPrint('WidgetDataService: Stack trace: $stackTrace');
      
      // Fallback: Try using SharedPreferences if method channel fails
      try {
        final todayTasks = TaskFilters.getTodayTasks();
        final tasksJson = allTasks.map((task) => task.toJson()).toList();
        final todayTasksJson = todayTasks.map((task) => task.toJson()).toList();
        await _syncToSharedPreferences(tasksJson, todayTasksJson);
      } catch (fallbackError) {
        debugPrint('WidgetDataService: Fallback also failed: $fallbackError');
      }
    }
  }

  /// Fallback method using SharedPreferences
  static Future<void> _syncToSharedPreferences(
    List<Map<String, dynamic>> tasksJson,
    List<Map<String, dynamic>> todayTasksJson,
  ) async {
    try {
      // This won't work for widgets, but helps with debugging
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_tasks', jsonEncode(tasksJson));
      await prefs.setString('widget_today_tasks', jsonEncode(todayTasksJson));
    } catch (e) {
      debugPrint('Error syncing to SharedPreferences: $e');
    }
  }

  /// Get today's tasks count
  static int getTodayTasksCount() {
    return TaskFilters.getTodayTasks().length;
  }

  /// Get today's completed tasks count
  static int getTodayCompletedCount() {
    final todayTasks = TaskFilters.getTodayTasks();
    return todayTasks.where((task) => task.isCompleted).length;
  }

  /// Get today's tasks progress (0.0 to 1.0)
  static double getTodayProgress() {
    final todayTasks = TaskFilters.getTodayTasks();
    if (todayTasks.isEmpty) return 0.0;
    final completed = todayTasks.where((task) => task.isCompleted).length;
    return completed / todayTasks.length;
  }
}

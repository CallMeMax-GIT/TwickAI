import 'package:flutter/material.dart';
import 'package:twickbackend_client/twickbackend_client.dart';
import 'package:twickbackend_flutter/main.dart' show client;
import 'package:twickbackend_flutter/models/Task.dart' as FlutterTask;
import 'package:twickbackend_flutter/models/Category.dart' as FlutterCategory;
import 'package:twickbackend_flutter/models/TaskList.dart' show allTasks;
import 'package:twickbackend_flutter/models/CategoryList.dart' show allCategories;
import 'package:twickbackend_flutter/models/NotificationState.dart';
import 'package:twickbackend_flutter/models/AuthState.dart';
import 'package:twickbackend_flutter/models/ConnectivityState.dart';
import 'package:twickbackend_flutter/services/NotificationService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serverpod_client/serverpod_client.dart' as serverpod;

/// Service for syncing data with the Serverpod server
class ServerSyncService {
  // Flag to prevent sync loops when syncing from server
  static bool _isSyncingFromServer = false;

  /// Check if user has existing data on the server (account exists)
  static Future<bool> hasExistingAccountData() async {
    if (!AuthState.isLoggedIn.value) {
      debugPrint('User not logged in, cannot check existing account data');
      return false;
    }
    
    try {
      // First verify we have a valid session by checking user profile
      try {
        final userProfile = await client.modules.serverpod_auth_core.userProfileInfo.get();
        debugPrint('Session verified for user: ${userProfile.email ?? userProfile.userName}');
      } catch (e) {
        debugPrint('Session verification failed: $e');
        return false;
      }
      
      // Check if user has any tasks, categories, or settings on the server
      final tasks = await client.task.getTasks();
      final categories = await client.category.getCategories();
      final settings = await client.userSettings.getSettings();
      
      debugPrint('Server data check - Tasks: ${tasks.length}, Categories: ${categories.length}, Settings: ${settings != null}');
      
      // If user has any data, account exists
      final hasData = tasks.isNotEmpty || categories.isNotEmpty || settings != null;
      debugPrint('Account has existing data: $hasData');
      return hasData;
    } catch (e) {
      // If error, assume account doesn't exist (new user)
      debugPrint('Error checking existing account data: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Sync all local data to server (for new users)
  static Future<void> syncAllToServer() async {
    if (!AuthState.isLoggedIn.value) {
      debugPrint('User not logged in, skipping sync to server');
      return;
    }

    // Check connectivity before syncing
    if (!ConnectivityState.isOnline.value) {
      debugPrint('No internet connection, skipping sync to server');
      return;
    }

    // Ensure we're not syncing from server (which would block syncing to server)
    final wasSyncingFromServer = _isSyncingFromServer;
    _isSyncingFromServer = false; // Allow syncing to server
    
    try {
      // Ensure default categories exist before syncing
      initializeDefaultCategories();
      
      await Future.wait([
        syncTasksToServer(),
        syncCategoriesToServer(), // This will only sync user-created categories
        syncSettingsToServer(),
      ]);
      debugPrint('Successfully synced all local data to server');
    } catch (e) {
      debugPrint('Error syncing local data to server: $e');
      // Don't throw - allow app to continue
    } finally {
      // Restore the flag if it was set
      _isSyncingFromServer = wasSyncingFromServer;
    }
  }

  /// Sync all data from server (tasks, categories, settings)
  static Future<void> syncAllFromServer() async {
    if (!AuthState.isLoggedIn.value) {
      debugPrint('User not logged in, skipping server sync');
      return;
    }

    // Check connectivity before syncing
    if (!ConnectivityState.isOnline.value) {
      debugPrint('No internet connection, skipping sync from server');
      return;
    }

    if (_isSyncingFromServer) {
      debugPrint('Already syncing from server, skipping');
      return;
    }

    _isSyncingFromServer = true;
    try {
      await Future.wait([
        syncTasksFromServer(),
        syncCategoriesFromServer(),
        syncSettingsFromServer(),
      ]);
      debugPrint('Successfully synced all data from server');
    } catch (e) {
      debugPrint('Error syncing data from server: $e');
      // Don't throw - allow app to continue with local data
    } finally {
      _isSyncingFromServer = false;
    }
  }

  /// Sync tasks from server
  static Future<void> syncTasksFromServer() async {
    // Note: Flag is managed by syncAllFromServer, so we don't set it here
    try {
      final serverTasks = await client.task.getTasks();
      
      // Convert server tasks to Flutter tasks
      final flutterTasks = serverTasks.map((serverTask) {
        return _serverTaskToFlutter(serverTask);
      }).toList();

      // Cancel all existing notifications before updating tasks
      await NotificationService.cancelAllNotifications();
      
      // Temporarily disable watch to prevent sync loop
      // Update local task list - this will trigger Obx rebuilds
      allTasks.clear();
      allTasks.addAll(flutterTasks);
      
      // Force a small delay to ensure reactive updates propagate
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Reschedule notifications for all synced tasks
      // This ensures notifications work on the new device
      if (NotificationState.notificationsEnabled.value) {
        await NotificationService.rescheduleAllNotifications();
        debugPrint('Rescheduled notifications for ${flutterTasks.length} synced tasks');
      }
      
      debugPrint('Synced ${flutterTasks.length} tasks from server');
    } catch (e) {
      debugPrint('Error syncing tasks from server: $e');
      rethrow;
    }
  }

  /// Sync categories from server
  static Future<void> syncCategoriesFromServer() async {
    // Note: Flag is managed by syncAllFromServer, so we don't set it here
    try {
      final serverCategories = await client.category.getCategories();
      
      // Convert server categories to Flutter categories
      final flutterCategories = serverCategories.map((serverCategory) {
        return _serverCategoryToFlutter(serverCategory);
      }).toList();

      // Always ensure default categories exist first
        initializeDefaultCategories();
      
      // Get default category IDs
      final defaultCategoryIds = ['work', 'personal', 'health', 'finance', 'general'];
      
      // Add user-created categories from server (exclude defaults)
      for (var serverCategory in flutterCategories) {
        // Only add if it's not a default category
        if (!defaultCategoryIds.contains(serverCategory.id)) {
          // Check if category already exists (avoid duplicates)
          final exists = allCategories.any((cat) => cat.id == serverCategory.id);
          if (!exists) {
            allCategories.add(serverCategory);
          }
        }
      }
      
      debugPrint('Synced ${flutterCategories.length} categories from server (${allCategories.length} total including defaults)');
    } catch (e) {
      debugPrint('Error syncing categories from server: $e');
      // If error, at least ensure defaults exist
      initializeDefaultCategories();
      rethrow;
    }
  }

  /// Sync settings from server
  static Future<void> syncSettingsFromServer() async {
    try {
      final serverSettings = await client.userSettings.getSettings();
      
      if (serverSettings != null) {
        // Update local notification state
        // Note: toggleNotifications and setSleepMode will automatically reschedule notifications
        // But we need to update them without triggering the sync back to server
        NotificationState.notificationsEnabled.value = serverSettings.notificationsEnabled;
        NotificationState.sleepModeEnabled.value = serverSettings.sleepModeEnabled;
        NotificationState.sleepModeFromTime.value = TimeOfDay(
          hour: serverSettings.sleepModeFromHour,
          minute: serverSettings.sleepModeFromMinute,
        );
        NotificationState.sleepModeToTime.value = TimeOfDay(
          hour: serverSettings.sleepModeToHour,
          minute: serverSettings.sleepModeToMinute,
        );
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_enabled', serverSettings.notificationsEnabled);
        await prefs.setBool('sleep_mode_enabled', serverSettings.sleepModeEnabled);
        await prefs.setInt('sleep_mode_from_hour', serverSettings.sleepModeFromHour);
        await prefs.setInt('sleep_mode_from_minute', serverSettings.sleepModeFromMinute);
        await prefs.setInt('sleep_mode_to_hour', serverSettings.sleepModeToHour);
        await prefs.setInt('sleep_mode_to_minute', serverSettings.sleepModeToMinute);
        
        // Reschedule all notifications based on synced settings
        if (serverSettings.notificationsEnabled) {
          await NotificationService.rescheduleAllNotifications();
          debugPrint('Rescheduled notifications after syncing settings');
        } else {
          await NotificationService.cancelAllNotifications();
          debugPrint('Cancelled notifications (disabled in synced settings)');
        }
        
        debugPrint('Synced settings from server');
      }
    } catch (e) {
      debugPrint('Error syncing settings from server: $e');
      rethrow;
    }
  }

  /// Sync all tasks to server
  static Future<void> syncTasksToServer() async {
    if (!AuthState.isLoggedIn.value) {
      debugPrint('User not logged in, skipping task sync to server');
      return;
    }

    // Don't sync to server if we're currently syncing from server
    if (_isSyncingFromServer) {
      debugPrint('Currently syncing from server, skipping sync to server');
      return;
    }

    try {
      // Convert Flutter tasks to server tasks
      final serverTasks = allTasks.map((flutterTask) {
        return _flutterTaskToServer(flutterTask);
      }).toList();

      if (serverTasks.isNotEmpty) {
        await client.task.saveTasks(serverTasks);
        debugPrint('Synced ${serverTasks.length} tasks to server');
      }
    } catch (e) {
      debugPrint('Error syncing tasks to server: $e');
      // Don't throw - allow app to continue
    }
  }

  /// Sync all categories to server
  static Future<void> syncCategoriesToServer() async {
    if (!AuthState.isLoggedIn.value) {
      debugPrint('User not logged in, skipping category sync to server');
      return;
    }

    // Don't sync to server if we're currently syncing from server
    if (_isSyncingFromServer) {
      debugPrint('Currently syncing from server, skipping sync to server');
      return;
    }

    try {
      // Default category IDs that should not be synced to server
      final defaultCategoryIds = ['work', 'personal', 'health', 'finance', 'general'];
      
      // Only sync user-created categories (exclude defaults)
      final userCreatedCategories = allCategories.where((cat) => 
        !defaultCategoryIds.contains(cat.id)
      ).toList();
      
      if (userCreatedCategories.isNotEmpty) {
        // Convert Flutter categories to server categories
        final serverCategories = userCreatedCategories.map((flutterCategory) {
          return _flutterCategoryToServer(flutterCategory);
        }).toList();

        await client.category.saveCategories(serverCategories);
        debugPrint('Synced ${serverCategories.length} user-created categories to server');
      } else {
        debugPrint('No user-created categories to sync (only defaults present)');
      }
    } catch (e) {
      debugPrint('Error syncing categories to server: $e');
      // Don't throw - allow app to continue
    }
  }

  /// Sync settings to server
  static Future<void> syncSettingsToServer() async {
    if (!AuthState.isLoggedIn.value) {
      debugPrint('User not logged in, skipping settings sync to server');
      return;
    }

    try {
      final now = DateTime.now();
      final serverSettings = UserSettings(
        authUserId: serverpod.UuidValue.fromString('00000000-0000-0000-0000-000000000000'), // Will be set by server
        notificationsEnabled: NotificationState.notificationsEnabled.value,
        sleepModeEnabled: NotificationState.sleepModeEnabled.value,
        sleepModeFromHour: NotificationState.sleepModeFromTime.value.hour,
        sleepModeFromMinute: NotificationState.sleepModeFromTime.value.minute,
        sleepModeToHour: NotificationState.sleepModeToTime.value.hour,
        sleepModeToMinute: NotificationState.sleepModeToTime.value.minute,
        createdAt: now,
        updatedAt: now,
      );

      await client.userSettings.saveSettings(serverSettings);
      debugPrint('Synced settings to server');
    } catch (e) {
      debugPrint('Error syncing settings to server: $e');
      // Don't throw - allow app to continue
    }
  }

  /// Save a single task to server
  static Future<void> saveTaskToServer(FlutterTask.Task task) async {
    if (!AuthState.isLoggedIn.value) return;

    try {
      final serverTask = _flutterTaskToServer(task);
      await client.task.saveTask(serverTask);
      debugPrint('Saved task to server: ${task.title}');
    } catch (e) {
      debugPrint('Error saving task to server: $e');
    }
  }

  /// Save a single category to server
  static Future<void> saveCategoryToServer(FlutterCategory.TaskCategory category) async {
    if (!AuthState.isLoggedIn.value) return;

    try {
      final serverCategory = _flutterCategoryToServer(category);
      await client.category.saveCategory(serverCategory);
      debugPrint('Saved category to server: ${category.name}');
    } catch (e) {
      debugPrint('Error saving category to server: $e');
    }
  }

  /// Delete a task from server
  static Future<void> deleteTaskFromServer(String taskId) async {
    if (!AuthState.isLoggedIn.value) return;

    try {
      await client.task.deleteTask(taskId);
      debugPrint('Deleted task from server: $taskId');
    } catch (e) {
      debugPrint('Error deleting task from server: $e');
    }
  }

  /// Delete a category from server
  static Future<void> deleteCategoryFromServer(String categoryId) async {
    if (!AuthState.isLoggedIn.value) return;

    try {
      await client.category.deleteCategory(categoryId);
      debugPrint('Deleted category from server: $categoryId');
    } catch (e) {
      debugPrint('Error deleting category from server: $e');
    }
  }

  // Conversion helpers

  static FlutterTask.Task _serverTaskToFlutter(Task serverTask) {
    // Server stores DateTime in UTC, convert to local time for Flutter app
    final localScheduledTime = serverTask.scheduledTime.isUtc
        ? serverTask.scheduledTime.toLocal()
        : serverTask.scheduledTime;
    
    return FlutterTask.Task(
      id: serverTask.clientId,
      title: serverTask.title,
      scheduledTime: localScheduledTime,
      isCompleted: serverTask.isCompleted,
      priority: FlutterTask.TaskPriority.fromString(serverTask.priority),
      categoryId: serverTask.categoryId,
      playSound: serverTask.playSound,
      isRecurring: serverTask.isRecurring,
      recurringIntervalType: serverTask.recurringIntervalType != null
          ? FlutterTask.RecurringIntervalType.fromString(serverTask.recurringIntervalType!)
          : null,
      recurringDuration: serverTask.recurringDuration,
    );
  }

  static Task _flutterTaskToServer(FlutterTask.Task flutterTask) {
    final now = DateTime.now().toUtc();
    // Flutter app uses local time, convert to UTC for server storage
    final utcScheduledTime = flutterTask.scheduledTime.isUtc
        ? flutterTask.scheduledTime
        : flutterTask.scheduledTime.toUtc();
    
    return Task(
      clientId: flutterTask.id,
      authUserId: serverpod.UuidValue.fromString('00000000-0000-0000-0000-000000000000'), // Will be set by server
      title: flutterTask.title,
      scheduledTime: utcScheduledTime,
      isCompleted: flutterTask.isCompleted,
      priority: flutterTask.priority.name,
      categoryId: flutterTask.categoryId,
      playSound: flutterTask.playSound,
      isRecurring: flutterTask.isRecurring,
      recurringIntervalType: flutterTask.recurringIntervalType?.name,
      recurringDuration: flutterTask.recurringDuration,
      createdAt: now,
      updatedAt: now,
    );
  }

  static FlutterCategory.TaskCategory _serverCategoryToFlutter(TaskCategory serverCategory) {
    return FlutterCategory.TaskCategory(
      id: serverCategory.clientId,
      name: serverCategory.name,
      icon: IconData(serverCategory.iconCodePoint, fontFamily: 'MaterialIcons'),
      color: Color(serverCategory.colorValue),
    );
  }

  static TaskCategory _flutterCategoryToServer(FlutterCategory.TaskCategory flutterCategory) {
    final now = DateTime.now();
    return TaskCategory(
      clientId: flutterCategory.id,
      authUserId: serverpod.UuidValue.fromString('00000000-0000-0000-0000-000000000000'), // Will be set by server
      name: flutterCategory.name,
      iconCodePoint: flutterCategory.icon.codePoint,
      colorValue: flutterCategory.color.value,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Initialize default categories (work, personal, health, finance, general)
  /// These categories are always present for every user
  static void initializeDefaultCategories() {
    // Check which defaults are missing
    final existingIds = allCategories.map((cat) => cat.id).toSet();
    
    // Add missing default categories
    if (!existingIds.contains('work')) {
      allCategories.add(FlutterCategory.TaskCategory(
        id: 'work',
        name: 'Work',
        icon: Icons.code,
        color: Colors.blueAccent,
      ));
    }
    if (!existingIds.contains('personal')) {
      allCategories.add(FlutterCategory.TaskCategory(
        id: 'personal',
        name: 'Personal',
        icon: Icons.person,
        color: Colors.purpleAccent,
      ));
    }
    if (!existingIds.contains('health')) {
      allCategories.add(FlutterCategory.TaskCategory(
        id: 'health',
        name: 'Health',
        icon: Icons.trending_up,
        color: const Color.fromARGB(255, 56, 106, 82),
      ));
    }
    if (!existingIds.contains('finance')) {
      allCategories.add(FlutterCategory.TaskCategory(
        id: 'finance',
        name: 'Finance',
        icon: Icons.account_balance_wallet,
        color: Colors.orangeAccent,
      ));
    }
    if (!existingIds.contains('general')) {
      allCategories.add(FlutterCategory.TaskCategory(
        id: 'general',
        name: 'General',
        icon: Icons.folder,
        color: Colors.blueAccent,
      ));
    }
  }
}

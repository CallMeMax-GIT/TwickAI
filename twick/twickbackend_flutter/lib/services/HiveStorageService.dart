import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/Task.dart';
import '../models/Category.dart';
import '../models/TaskList.dart';
import '../models/CategoryList.dart';
import '../models/AuthState.dart';
import 'ServerSyncService.dart';
import 'WidgetDataService.dart';

class HiveStorageService {
  static const String _tasksBoxName = 'tasks';
  static const String _categoriesBoxName = 'categories';
  static Box? _tasksBox;
  static Box? _categoriesBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Open boxes
    _tasksBox = await Hive.openBox(_tasksBoxName);
    _categoriesBox = await Hive.openBox(_categoriesBoxName);
    
    // Load data
    await loadTasks();
    await loadCategories();
    
    // Watch for changes and auto-save
    watchTasks();
    watchCategories();
  }

  // Tasks
  static Future<void> loadTasks() async {
    final tasksJsonString = _tasksBox?.get('tasks', defaultValue: '[]') as String;
    final tasksJson = jsonDecode(tasksJsonString) as List;
    
    allTasks.clear();
    if (tasksJson.isNotEmpty) {
      allTasks.addAll(
        tasksJson.map((json) => Task.fromJson(Map<String, dynamic>.from(json))).toList(),
      );
    }
    
    // Sync to widget after loading tasks
    WidgetDataService.syncTasksToWidget();
  }

  static Future<void> saveTasks() async {
    // Save to local storage (always - for both guest and logged-in users)
    final tasksJson = allTasks.map((task) => task.toJson()).toList();
    final tasksJsonString = jsonEncode(tasksJson);
    await _tasksBox?.put('tasks', tasksJsonString);
    
    // Also sync to server ONLY if user is logged in (non-blocking, only if not currently syncing from server)
    if (AuthState.isLoggedIn.value) {
      ServerSyncService.syncTasksToServer().catchError((e) {
        debugPrint('Error syncing tasks to server: $e');
      });
    }
  }

  // Categories
  static Future<void> loadCategories() async {
    final categoriesJsonString = _categoriesBox?.get('categories', defaultValue: '[]') as String;
    final categoriesJson = jsonDecode(categoriesJsonString) as List;
    
    allCategories.clear();
    if (categoriesJson.isEmpty) {
      // Initialize with default categories if empty
      _initializeDefaultCategories();
      await saveCategories();
    } else {
      allCategories.addAll(
        categoriesJson.map((json) => TaskCategory.fromJson(Map<String, dynamic>.from(json))).toList(),
      );
    }
  }

  static void _initializeDefaultCategories() {
    allCategories.addAll([
      TaskCategory(
        id: 'work',
        name: 'Work',
        icon: Icons.code,
        color: Colors.blueAccent,
      ),
      TaskCategory(
        id: 'personal',
        name: 'Personal',
        icon: Icons.person,
        color: Colors.purpleAccent,
      ),
      TaskCategory(
        id: 'health',
        name: 'Health',
        icon: Icons.trending_up,
        color: const Color.fromARGB(255, 56, 106, 82),
      ),
      TaskCategory(
        id: 'finance',
        name: 'Finance',
        icon: Icons.account_balance_wallet,
        color: Colors.orangeAccent,
      ),
      TaskCategory(
        id: 'general',
        name: 'General',
        icon: Icons.folder,
        color: Colors.blueAccent,
      ),
    ]);
  }

  static Future<void> saveCategories() async {
    // Save to local storage (always - for both guest and logged-in users)
    final categoriesJson = allCategories.map((cat) => cat.toJson()).toList();
    final categoriesJsonString = jsonEncode(categoriesJson);
    await _categoriesBox?.put('categories', categoriesJsonString);
    
    // Also sync to server ONLY if user is logged in (non-blocking)
    if (AuthState.isLoggedIn.value) {
      ServerSyncService.syncCategoriesToServer().catchError((e) {
        debugPrint('Error syncing categories to server: $e');
      });
    }
  }

  // Helper method to save tasks whenever they change
  static void watchTasks() {
    ever(allTasks, (_) {
      saveTasks();
      // Sync to widget whenever tasks change
      WidgetDataService.syncTasksToWidget();
    });
  }

  // Helper method to save categories whenever they change
  static void watchCategories() {
    ever(allCategories, (_) => saveCategories());
  }

  /// Clear all data from Hive storage (for logout)
  /// Note: Default categories are preserved and will be re-initialized
  static Future<void> clearAllData() async {
    try {
      // Clear task list
      allTasks.clear();
      
      // Clear only user-created categories (preserve defaults)
      final defaultCategoryIds = ['work', 'personal', 'health', 'finance', 'general'];
      allCategories.removeWhere((cat) => !defaultCategoryIds.contains(cat.id));
      
      // Clear Hive boxes
      await _tasksBox?.clear();
      await _categoriesBox?.clear();
      
      // Re-initialize default categories after clearing
      ServerSyncService.initializeDefaultCategories();
      
      // Save defaults to Hive
      await saveCategories();
      
      debugPrint('Cleared all Hive storage data, preserved default categories');
    } catch (e) {
      debugPrint('Error clearing Hive data: $e');
    }
  }
}

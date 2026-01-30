import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'Category.dart';

// Categories list - will be loaded from Hive storage on app start
final RxList<TaskCategory> allCategories = <TaskCategory>[].obs;

TaskCategory getGeneralCategory() {
  // First try to find 'general' category
  try {
    return allCategories.firstWhere((cat) => cat.id == 'general');
  } catch (e) {
    // If 'general' not found, try to get first category
    if (allCategories.isNotEmpty) {
      return allCategories.first;
    }
    // If no categories exist, return a fallback category
    // This should not happen if defaults are initialized properly
    return TaskCategory(
      id: 'general',
      name: 'General',
      icon: Icons.folder,
      color: Colors.blueAccent,
  );
  }
}

TaskCategory? getCategoryById(String? categoryId) {
  if (categoryId == null) return null;
  try {
    return allCategories.firstWhere((cat) => cat.id == categoryId);
  } catch (e) {
    return null;
  }
}

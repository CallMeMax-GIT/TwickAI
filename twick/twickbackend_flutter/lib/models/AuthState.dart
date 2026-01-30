import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twickbackend_flutter/main.dart' show client;
import 'package:twickbackend_flutter/services/NotificationService.dart';
import 'package:twickbackend_flutter/services/HiveStorageService.dart';
import 'package:twickbackend_flutter/services/ServerSyncService.dart';
import 'package:twickbackend_flutter/models/TaskList.dart' show allTasks;
import 'package:twickbackend_flutter/models/CategoryList.dart' show allCategories;
import 'package:twickbackend_flutter/models/NotificationState.dart';

class AuthState {
  static final RxBool isLoggedIn = false.obs;
  static final RxString userName = 'Kevin'.obs;
  static final RxString userEmail = ''.obs;
  static final RxString profileImageUrl = ''.obs;

  static void login(String name, String email, String imageUrl) {
    debugPrint('AuthState.login called: name=$name, email=$email, isLoggedIn=${isLoggedIn.value}');
    userName.value = name;
    userEmail.value = email;
    // Only set image URL if it's not empty and is a valid URL
    profileImageUrl.value = (imageUrl.isNotEmpty && 
                             (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')))
        ? imageUrl 
        : '';
    isLoggedIn.value = true;
    
    // Cache user info to SharedPreferences for offline access
    _cacheUserInfo(name, email, imageUrl);
    
    debugPrint('AuthState.login completed: userName=${userName.value}, userEmail=${userEmail.value}, isLoggedIn=${isLoggedIn.value}');
  }
  
  /// Cache user info to SharedPreferences
  static Future<void> _cacheUserInfo(String name, String email, String imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_name', name);
      await prefs.setString('cached_user_email', email);
      await prefs.setString('cached_profile_image_url', imageUrl);
      await prefs.setBool('is_logged_in', true);
      debugPrint('Cached user info: name=$name, email=$email');
    } catch (e) {
      debugPrint('Error caching user info: $e');
    }
  }
  
  /// Load cached user info from SharedPreferences
  static Future<bool> loadCachedUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (!wasLoggedIn) {
        return false;
      }
      
      final cachedName = prefs.getString('cached_user_name');
      final cachedEmail = prefs.getString('cached_user_email');
      final cachedImageUrl = prefs.getString('cached_profile_image_url') ?? '';
      
      if (cachedName != null && cachedName.isNotEmpty) {
        userName.value = cachedName;
        userEmail.value = cachedEmail ?? '';
        profileImageUrl.value = cachedImageUrl;
        isLoggedIn.value = true;
        debugPrint('Loaded cached user info: name=$cachedName, email=$cachedEmail');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error loading cached user info: $e');
      return false;
    }
  }
  
  /// Force refresh AuthState to trigger UI rebuilds
  static void refresh() {
    if (isLoggedIn.value) {
      final currentName = userName.value;
      final currentEmail = userEmail.value;
      final currentImage = profileImageUrl.value;
      // Trigger rebuild by updating values
      userName.value = currentName;
      userEmail.value = currentEmail;
      profileImageUrl.value = currentImage;
      isLoggedIn.value = true;
      debugPrint('AuthState refreshed: userName=$currentName, userEmail=$currentEmail');
    }
  }
  
  /// Returns true if we should show a placeholder icon instead of loading an image
  static bool shouldShowPlaceholder() {
    final url = profileImageUrl.value;
    return url.isEmpty || 
           (!url.startsWith('http://') && !url.startsWith('https://'));
  }

  static Future<void> logout() async {
    try {
      // Cancel all notifications before logging out
      await NotificationService.cancelAllNotifications();
      debugPrint('Cancelled all notifications on logout');
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
    
    try {
      // Sign out from Serverpod - sign out from current device
      await client.modules.serverpod_auth_core.status.signOutDevice();
    } catch (e) {
      // Ignore errors if already signed out
      debugPrint('Error signing out: $e');
    }
    
    // Clear all local data
    try {
      // Clear all tasks from memory
      allTasks.clear();
      
      // Clear all categories except defaults
      // Remove only user-created categories, keep defaults
      final defaultCategoryIds = ['work', 'personal', 'health', 'finance', 'general'];
      allCategories.removeWhere((cat) => !defaultCategoryIds.contains(cat.id));
      
      // Clear all Hive storage (but defaults will be re-initialized)
      await HiveStorageService.clearAllData();
      
      // Re-initialize default categories after clearing
      ServerSyncService.initializeDefaultCategories();
      debugPrint('Cleared all Hive storage, preserved default categories');
    } catch (e) {
      debugPrint('Error clearing Hive storage: $e');
    }
    
    // Reset notification state
    try {
      NotificationState.notificationsEnabled.value = false;
      NotificationState.sleepModeEnabled.value = false;
      NotificationState.sleepModeFromTime.value = const TimeOfDay(hour: 22, minute: 0);
      NotificationState.sleepModeToTime.value = const TimeOfDay(hour: 7, minute: 0);
    } catch (e) {
      debugPrint('Error resetting notification state: $e');
    }
    
    // Clear SharedPreferences data (but preserve has_skipped_intro and has_skipped_login)
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSkippedIntro = prefs.getBool('has_skipped_intro') ?? false;
      final hasSkippedLogin = prefs.getBool('has_skipped_login') ?? false;
      final wasPreviouslyLoggedIn = prefs.getBool('was_previously_logged_in') ?? false;
      
      // Clear all preferences
      await prefs.clear();
      
      // Restore flags so intro/login are never shown again if user skipped them
      if (hasSkippedIntro) {
        await prefs.setBool('has_skipped_intro', true);
      }
      if (hasSkippedLogin) {
        await prefs.setBool('has_skipped_login', true);
      }
      // Preserve was_previously_logged_in flag so dialog doesn't show when switching accounts
      if (wasPreviouslyLoggedIn) {
        await prefs.setBool('was_previously_logged_in', true);
      }
      
      // Clear login flag
      await prefs.setBool('is_logged_in', false);
      
      debugPrint('Cleared SharedPreferences data (preserved has_skipped_intro: $hasSkippedIntro, has_skipped_login: $hasSkippedLogin)');
    } catch (e) {
      debugPrint('Error clearing SharedPreferences: $e');
    }
    
    // Clear local auth state
    isLoggedIn.value = false;
    userName.value = 'Kevin';
    userEmail.value = '';
    profileImageUrl.value = '';
    
    // Clear cached user info from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user_name');
      await prefs.remove('cached_user_email');
      await prefs.remove('cached_profile_image_url');
      debugPrint('Cleared cached user info from SharedPreferences');
    } catch (e) {
      debugPrint('Error clearing cached user info: $e');
    }
    
    debugPrint('Logout complete - app reset to fresh state');
  }
}

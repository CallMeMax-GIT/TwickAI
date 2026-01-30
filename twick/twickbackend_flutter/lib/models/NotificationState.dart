import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/NotificationService.dart';
import '../services/ServerSyncService.dart';
import 'AuthState.dart';

class NotificationState {
  static final RxBool notificationsEnabled = false.obs;
  static final RxBool sleepModeEnabled = false.obs;
  static final Rx<TimeOfDay> sleepModeFromTime = const TimeOfDay(hour: 22, minute: 0).obs; // 10:00 PM default
  static final Rx<TimeOfDay> sleepModeToTime = const TimeOfDay(hour: 7, minute: 0).obs; // 7:00 AM default
  
  static const String _prefKey = 'notifications_enabled';
  static const String _sleepModeEnabledKey = 'sleep_mode_enabled';
  static const String _sleepModeFromHourKey = 'sleep_mode_from_hour';
  static const String _sleepModeFromMinuteKey = 'sleep_mode_from_minute';
  static const String _sleepModeToHourKey = 'sleep_mode_to_hour';
  static const String _sleepModeToMinuteKey = 'sleep_mode_to_minute';

  static Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled.value = prefs.getBool(_prefKey) ?? false;
    
    // Load sleep mode settings
    sleepModeEnabled.value = prefs.getBool(_sleepModeEnabledKey) ?? false;
    final fromHour = prefs.getInt(_sleepModeFromHourKey) ?? 22;
    final fromMinute = prefs.getInt(_sleepModeFromMinuteKey) ?? 0;
    final toHour = prefs.getInt(_sleepModeToHourKey) ?? 7;
    final toMinute = prefs.getInt(_sleepModeToMinuteKey) ?? 0;
    
    sleepModeFromTime.value = TimeOfDay(hour: fromHour, minute: fromMinute);
    sleepModeToTime.value = TimeOfDay(hour: toHour, minute: toMinute);
    
    // If notifications are enabled, reschedule all notifications
    if (notificationsEnabled.value) {
      await NotificationService.rescheduleAllNotifications();
    }
  }

  static Future<void> toggleNotifications(bool enabled) async {
    notificationsEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
    
    // If enabling, reschedule all notifications
    // If disabling, cancel all notifications
    if (enabled) {
      await NotificationService.rescheduleAllNotifications();
    } else {
      await NotificationService.cancelAllNotifications();
    }
    
    // Sync to server ONLY if user is logged in (non-blocking)
    if (AuthState.isLoggedIn.value) {
      ServerSyncService.syncSettingsToServer().catchError((e) {
        debugPrint('Error syncing settings to server: $e');
      });
    }
  }

  static Future<void> setSleepMode({
    required bool enabled,
    required TimeOfDay fromTime,
    required TimeOfDay toTime,
  }) async {
    sleepModeEnabled.value = enabled;
    sleepModeFromTime.value = fromTime;
    sleepModeToTime.value = toTime;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sleepModeEnabledKey, enabled);
    await prefs.setInt(_sleepModeFromHourKey, fromTime.hour);
    await prefs.setInt(_sleepModeFromMinuteKey, fromTime.minute);
    await prefs.setInt(_sleepModeToHourKey, toTime.hour);
    await prefs.setInt(_sleepModeToMinuteKey, toTime.minute);
    
    // Reschedule all notifications to respect sleep mode
    if (notificationsEnabled.value) {
      await NotificationService.rescheduleAllNotifications();
    }
    
    // Sync to server ONLY if user is logged in (non-blocking)
    if (AuthState.isLoggedIn.value) {
      ServerSyncService.syncSettingsToServer().catchError((e) {
        debugPrint('Error syncing settings to server: $e');
      });
    }
  }

  // Check if current time is within sleep mode hours
  static bool isInSleepMode() {
    if (!sleepModeEnabled.value) return false;
    
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    
    final fromTime = sleepModeFromTime.value;
    final toTime = sleepModeToTime.value;
    
    // Convert to minutes for easier comparison
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final fromMinutes = fromTime.hour * 60 + fromTime.minute;
    final toMinutes = toTime.hour * 60 + toTime.minute;
    
    // Handle case where sleep mode spans midnight (e.g., 10 PM to 7 AM)
    if (fromMinutes > toMinutes) {
      // Sleep mode spans midnight
      return currentMinutes >= fromMinutes || currentMinutes < toMinutes;
    } else {
      // Sleep mode is within the same day
      return currentMinutes >= fromMinutes && currentMinutes < toMinutes;
    }
  }
}

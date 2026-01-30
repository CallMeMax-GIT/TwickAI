import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import 'package:twickbackend_flutter/models/NotificationState.dart';
import 'package:twickbackend_flutter/models/Task.dart';
import 'package:twickbackend_flutter/models/TaskList.dart';
import '../main.dart' show flutterLocalNotificationsPlugin;

class NotificationService {
  static bool _channelCreated = false;
  static final AudioPlayer _alarmPlayer = AudioPlayer();
  static const String snoozeActionId = 'snooze_action';
  static const String dismissActionId = 'dismiss_action';

  // Convert task ID to a safe 32-bit integer for notification ID
  static int _getNotificationId(String taskId) {
    // Use hashCode and ensure it's positive and within 32-bit range
    // Max 32-bit signed int is 2,147,483,647
    final hash = taskId.hashCode;
    // Make it positive and within safe range
    return (hash.abs() % 2147483647);
  }

  // Generate a unique notification ID for future occurrences
  static int _getFutureNotificationId(String taskId, int occurrenceIndex) {
    // Combine task ID with occurrence index to create unique ID
    final combinedId = '${taskId}_future_$occurrenceIndex';
    final hash = combinedId.hashCode;
    return (hash.abs() % 2147483647);
  }

  // Create notification channel (required for Android)
  static Future<void> _createNotificationChannel() async {
    if (_channelCreated) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Notifications for task reminders',
      importance: Importance.max, // Use max importance for alarm
      playSound: true,
      enableVibration: true,
      showBadge: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _channelCreated = true;
  }

  // Play alarm sound from assets (fallback method)
  static Future<void> playAlarm() async {
    try {
      debugPrint('Playing alarm sound from assets');
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop); // Loop the alarm
      await _alarmPlayer.play(AssetSource('alarm.mp3'));
    } catch (e) {
      debugPrint('Could not play alarm sound: $e');
      // Fallback: try to play notification sound
      try {
        await _alarmPlayer.play(AssetSource('alarm.mp3'));
      } catch (e2) {
        debugPrint('Could not play fallback sound: $e2');
      }
    }
  }

  // Stop alarm sound
  static Future<void> stopAlarm() async {
    try {
      await _alarmPlayer.stop();
    } catch (e) {
      debugPrint('Could not stop alarm sound: $e');
    }
  }

  // Check if notifications are permitted (iOS)
  static Future<bool> _checkPermissions() async {
    final iOSImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iOSImplementation != null) {
      final result = await iOSImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('iOS notification permission result: $result');
      return result ?? false;
    }
    return true; // Android doesn't need this check
  }

  static Future<void> scheduleTaskNotification(Task task) async {
    // Only schedule if notifications are enabled
    if (!NotificationState.notificationsEnabled.value) {
      debugPrint('Notifications are disabled, skipping scheduling for task: ${task.title}');
      return;
    }

    // Check if sleep mode is enabled and the scheduled time falls within sleep hours
    if (NotificationState.sleepModeEnabled.value) {
      final scheduledTime = task.scheduledTime;
      final scheduledTimeOfDay = TimeOfDay.fromDateTime(scheduledTime);
      final fromTime = NotificationState.sleepModeFromTime.value;
      final toTime = NotificationState.sleepModeToTime.value;
      
      // Convert to minutes for comparison
      final scheduledMinutes = scheduledTimeOfDay.hour * 60 + scheduledTimeOfDay.minute;
      final fromMinutes = fromTime.hour * 60 + fromTime.minute;
      final toMinutes = toTime.hour * 60 + toTime.minute;
      
      bool isInSleepWindow = false;
      if (fromMinutes > toMinutes) {
        // Sleep mode spans midnight (e.g., 10 PM to 7 AM)
        isInSleepWindow = scheduledMinutes >= fromMinutes || scheduledMinutes < toMinutes;
      } else {
        // Sleep mode is within the same day
        isInSleepWindow = scheduledMinutes >= fromMinutes && scheduledMinutes < toMinutes;
      }
      
      if (isInSleepWindow) {
        debugPrint('Task scheduled time is during sleep mode, skipping notification: ${task.title}');
        return;
      }
    }

    // Check permissions before scheduling
    final hasPermission = await _checkPermissions();
    if (!hasPermission) {
      debugPrint('Notification permissions not granted, skipping scheduling for task: ${task.title}');
      return;
    }

    // For recurring tasks, always schedule (even if completed)
    // For non-recurring tasks, skip if completed
    if (task.isCompleted && !task.isRecurring) {
      debugPrint('Task is completed and not recurring, skipping notification: ${task.title}');
      return;
    }

    if (task.scheduledTime.isBefore(DateTime.now())) {
      debugPrint('Task is in the past, skipping notification: ${task.title}');
      return;
    }

    try {
      // Create notification channel (Android requirement)
      await _createNotificationChannel();

      final now = tz.TZDateTime.now(tz.local);
      final scheduledDate = tz.TZDateTime.from(
        task.scheduledTime,
        tz.local,
      );

      // Calculate time difference
      final timeDifference = scheduledDate.difference(now);

      // If task is in the past, don't schedule
      if (timeDifference.isNegative) {
        print('Task time difference is negative, skipping: ${task.title}');
        return;
      }

      final notificationId = _getNotificationId(task.id);
      debugPrint('Scheduling notification for task: ${task.title}, in ${timeDifference.inSeconds} seconds');

      // For recurring tasks with very short intervals (like 1 minute), schedule immediately
      // For other tasks less than 5 minutes away, schedule for the exact task time
      if (task.isRecurring && timeDifference.inSeconds < 60) {
        // For very short recurring intervals, use exact scheduling
        debugPrint('Scheduling recurring task with very short interval (${timeDifference.inSeconds}s): ${task.title}');
      await _scheduleNotification(
          id: notificationId,
          title: 'Task Reminder',
        body: task.title,
        scheduledDate: scheduledDate,
          useExact: true, // Use exact for recurring tasks
        taskId: task.id,
          playSound: task.playSound,
      );

        // For very short intervals (1-5 minutes), schedule multiple future occurrences in advance
        // This ensures continuous notifications even if user doesn't interact
        if (task.recurringIntervalType == RecurringIntervalType.minutes && task.recurringDuration <= 5) {
          await _scheduleNextRecurringOccurrence(task, scheduledDate);
        } else if (task.isRecurring) {
          // For other recurring tasks, also schedule the next occurrence
          await _scheduleNextRecurringOccurrence(task, scheduledDate);
        }
        return;
      }

      if (timeDifference.inMinutes < 5) {
        debugPrint('Scheduling notification for exact time (short interval): ${task.title}');
        await _scheduleNotification(
          id: notificationId,
          title: 'Task Reminder',
          body: task.title,
          scheduledDate: scheduledDate,
          useExact: false, // Use inexact for short intervals on Android
          taskId: task.id,
          playSound: task.playSound, // Use task's playSound setting
        );
        
        // For recurring tasks, also schedule future occurrences
        if (task.isRecurring) {
          await _scheduleNextRecurringOccurrence(task, scheduledDate);
        }
        return;
      }

      // For tasks more than 5 minutes away, schedule 5 minutes before
      final notificationTime = scheduledDate.subtract(const Duration(minutes: 5));
      debugPrint('Scheduling notification 5 minutes before: ${task.title}');
      await _scheduleNotification(
        id: notificationId,
        title: 'Task Reminder',
        body: task.title,
        scheduledDate: notificationTime,
        useExact: true,
        taskId: task.id,
        playSound: task.playSound, // Use task's playSound setting
      );
      
      // For recurring tasks, also schedule future occurrences
      if (task.isRecurring) {
        await _scheduleNextRecurringOccurrence(task, scheduledDate);
      }
    } catch (e, stackTrace) {
      debugPrint('Error scheduling notification for task ${task.title}: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    bool useExact = true,
    required String taskId,
    bool playSound = true, // Whether to play sound for this notification
  }) async {
    // For Android, use inexact scheduling for short intervals
    // Exact scheduling requires special permissions and has restrictions
    final androidScheduleMode = useExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

      debugPrint('Scheduling notification with mode: $androidScheduleMode, at: $scheduledDate');
      debugPrint('Current time: ${tz.TZDateTime.now(tz.local)}');
      debugPrint('Scheduled time: $scheduledDate');
      debugPrint('Time difference: ${scheduledDate.difference(tz.TZDateTime.now(tz.local)).inSeconds} seconds');

    try {
      // Create action buttons for snooze and dismiss
      // Note: Actions are visible when notification is expanded
      const AndroidNotificationAction snoozeAction = AndroidNotificationAction(
        snoozeActionId,
        'Snooze',
        titleColor: Color(0xFF2196F3),
      );

      const AndroidNotificationAction dismissAction = AndroidNotificationAction(
        dismissActionId,
        'Dismiss',
        titleColor: Color(0xFFF44336),
      );

      // Schedule the notification with snooze/dismiss actions
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.max, // Max importance for alarm
            priority: Priority.max, // Max priority
            enableVibration: true,
            playSound: playSound, // Use task's playSound setting
            sound: playSound ? const RawResourceAndroidNotificationSound('alarm') : null,
            actions: [snoozeAction, dismissAction],
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: true, // Show as full screen on Android
            autoCancel: false, // Don't auto-cancel so actions are visible
            ongoing: false,
            styleInformation: BigTextStyleInformation(body),
            enableLights: true,
            ledColor: const Color(0xFFFF0000), // Red LED for alarm
            ledOnMs: 1000,
            ledOffMs: 500,
            showWhen: true,
            when: scheduledDate.millisecondsSinceEpoch,
            // Ensure actions are always visible
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            sound: playSound ? 'alarm.caf' : null, // Only set sound if playSound is true
            presentAlert: true,
            presentBadge: true,
            presentSound: playSound, // Use task's playSound setting
            // For iOS: Custom sound will play automatically when notification triggers
            // Sound file must be added to iOS bundle (see setup instructions below)
            // If custom sound not found, iOS will use default notification sound
            interruptionLevel: InterruptionLevel.critical,
            categoryIdentifier: 'TASK_REMINDER',
            threadIdentifier: 'task_reminders',
          ),
        ),
        androidScheduleMode: androidScheduleMode,
        // For very short intervals, don't use matchDateTimeComponents as it might interfere
        // For longer intervals, use dateAndTime matching
        matchDateTimeComponents: (scheduledDate.difference(tz.TZDateTime.now(tz.local)).inMinutes < 60)
            ? null
            : DateTimeComponents.dateAndTime,
        payload: taskId, // Store task ID in payload for action handling
      );

      debugPrint('Notification scheduled successfully with ID: $id');
      
      // Verify the notification was scheduled (optional check, don't throw if not found on Android)
      try {
      final pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
        debugPrint('Total pending notifications: ${pendingNotifications.length}');
      final scheduledNotification = pendingNotifications.firstWhere(
        (n) => n.id == id,
      );
        debugPrint('Scheduled notification verified: ID=${scheduledNotification.id}, Title=${scheduledNotification.title}');
      } catch (e) {
        // On Android, notifications might not appear in pending list immediately
        debugPrint('Could not verify notification in pending list (this is normal on Android): $e');
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _scheduleNotification: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> cancelTaskNotification(Task task) async {
    try {
      final notificationId = _getNotificationId(task.id);
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      debugPrint('Cancelled main notification for task: ${task.title} (ID: $notificationId)');
      
      // Also cancel any future scheduled notifications for this task
      // All notifications for this task use the same task.id in their payload
      final pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      int cancelledCount = 0;
      for (final notification in pendingNotifications) {
        if (notification.payload != null && notification.payload == task.id) {
          await flutterLocalNotificationsPlugin.cancel(notification.id);
          cancelledCount++;
        }
      }
      if (cancelledCount > 0) {
        debugPrint('Cancelled $cancelledCount future notification(s) for task: ${task.title}');
      }
      debugPrint('Total notifications cancelled for task "${task.title}": ${cancelledCount + 1}');
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  static Future<void> rescheduleAllNotifications() async {
    // Only reschedule if notifications are enabled
    if (!NotificationState.notificationsEnabled.value) {
      return;
    }

    // Cancel all existing notifications
    await cancelAllNotifications();

    // Reschedule all tasks with future scheduled times
    // Include recurring tasks even if completed, and non-recurring tasks only if not completed
    for (final task in allTasks) {
      // For recurring tasks, always reschedule (they might have passed their scheduled time)
      if (task.isRecurring) {
        // For recurring tasks, calculate the next occurrence from now
        await rescheduleRecurringTask(task);
      } else if (!task.isCompleted && task.scheduledTime.isAfter(DateTime.now())) {
        // For non-recurring tasks, only schedule if in the future
        await scheduleTaskNotification(task);
      }
    }
  }

  // Snooze notification - reschedule for 10 minutes later
  static Future<void> snoozeNotification(String taskId) async {
    try {
      // Find the task
      final task = allTasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () => throw Exception('Task not found: $taskId'),
      );

      final notificationId = _getNotificationId(task.id);
      
      // Stop any playing alarm
      await stopAlarm();

      // Cancel current notification
      await cancelTaskNotification(task);

      // Reschedule for 10 minutes from now
      final snoozeTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));

      await _scheduleNotification(
        id: notificationId,
        title: 'Task Reminder (Snoozed)',
        body: task.title,
        scheduledDate: snoozeTime,
        useExact: false,
        taskId: task.id,
        playSound: task.playSound, // Preserve original sound setting
      );

      debugPrint('Notification snoozed for task: ${task.title}, rescheduled for 10 minutes');
    } catch (e) {
      debugPrint('Error snoozing notification: $e');
    }
  }

  // Dismiss notification
  static Future<void> dismissNotification(String taskId) async {
    try {
      // Stop any playing alarm
      await stopAlarm();

      // Cancel the notification
      final task = allTasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () => throw Exception('Task not found: $taskId'),
      );
      await cancelTaskNotification(task);

      // If task is recurring, always reschedule (even if completed)
      if (task.isRecurring) {
        await rescheduleRecurringTask(task);
      }

      debugPrint('Notification dismissed for task: ${task.title}');
    } catch (e) {
      debugPrint('Error dismissing notification: $e');
    }
  }

  // Schedule the next occurrence for a recurring task (used for very short intervals)
  static Future<void> _scheduleNextRecurringOccurrence(Task task, tz.TZDateTime currentScheduledDate) async {
    try {
      if (!task.isRecurring || task.recurringIntervalType == null) {
        return;
      }

      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime nextDate;

      switch (task.recurringIntervalType!) {
        case RecurringIntervalType.minutes:
          nextDate = currentScheduledDate.add(Duration(minutes: task.recurringDuration));
          break;
        case RecurringIntervalType.hours:
          nextDate = currentScheduledDate.add(Duration(hours: task.recurringDuration));
          break;
        case RecurringIntervalType.daily:
          nextDate = currentScheduledDate.add(Duration(days: task.recurringDuration));
          break;
        case RecurringIntervalType.weekly:
          nextDate = currentScheduledDate.add(Duration(days: 7 * task.recurringDuration));
          break;
      }

      // Only schedule if it's in the future
      if (nextDate.isAfter(now)) {
        // Use a unique notification ID for the next occurrence
        final nextNotificationId = _getFutureNotificationId(task.id, 1);
        
        debugPrint('Scheduling next occurrence for recurring task "${task.title}" at ${nextDate} (ID: $nextNotificationId)');
        
        await _scheduleNotification(
          id: nextNotificationId,
          title: 'Task Reminder',
          body: task.title,
          scheduledDate: nextDate,
          useExact: true,
          taskId: task.id,
          playSound: task.playSound,
        );
        
        // For very short intervals (1 minute), schedule multiple occurrences ahead
        if (task.recurringIntervalType == RecurringIntervalType.minutes && task.recurringDuration == 1) {
          // Schedule the next 30 occurrences in advance to ensure continuous notifications
          debugPrint('Pre-scheduling 30 future occurrences for 1-minute recurring task');
          int scheduledCount = 0;
          for (int i = 2; i <= 30; i++) {
            final futureDate = currentScheduledDate.add(Duration(minutes: i));
            if (futureDate.isAfter(now)) {
              final futureNotificationId = _getFutureNotificationId(task.id, i);
              try {
                await _scheduleNotification(
                  id: futureNotificationId,
                  title: 'Task Reminder',
                  body: task.title,
                  scheduledDate: futureDate,
                  useExact: true,
                  taskId: task.id,
                  playSound: task.playSound,
                );
                scheduledCount++;
                if (i <= 5 || i % 5 == 0) {
                  debugPrint('Pre-scheduled occurrence $i for ${task.title} at $futureDate (ID: $futureNotificationId)');
                }
              } catch (e) {
                debugPrint('Error pre-scheduling occurrence $i: $e');
              }
            }
          }
          debugPrint('Successfully pre-scheduled $scheduledCount future occurrences for 1-minute recurring task');
        } else if (task.recurringIntervalType == RecurringIntervalType.minutes && task.recurringDuration <= 5) {
          // For 2-5 minute intervals, schedule 15 occurrences ahead
          debugPrint('Pre-scheduling 15 future occurrences for ${task.recurringDuration}-minute recurring task');
          int scheduledCount = 0;
          for (int i = 2; i <= 15; i++) {
            final futureDate = currentScheduledDate.add(Duration(minutes: task.recurringDuration * i));
            if (futureDate.isAfter(now)) {
              final futureNotificationId = _getFutureNotificationId(task.id, i);
              try {
                await _scheduleNotification(
                  id: futureNotificationId,
                  title: 'Task Reminder',
                  body: task.title,
                  scheduledDate: futureDate,
                  useExact: true,
                  taskId: task.id,
                  playSound: task.playSound,
                );
                scheduledCount++;
                debugPrint('Pre-scheduled occurrence $i for ${task.title} at $futureDate (ID: $futureNotificationId)');
              } catch (e) {
                debugPrint('Error pre-scheduling occurrence $i: $e');
              }
            }
          }
          debugPrint('Successfully pre-scheduled $scheduledCount future occurrences for ${task.recurringDuration}-minute recurring task');
        }
      }
    } catch (e) {
      debugPrint('Error scheduling next recurring occurrence: $e');
    }
  }

  // Check and reschedule missed recurring notifications
  static Future<void> checkAndRescheduleRecurringTasks() async {
    if (!NotificationState.notificationsEnabled.value) {
      return;
    }

    final now = DateTime.now();
    for (final task in allTasks) {
      if (task.isRecurring && task.recurringIntervalType != null) {
        // Check if the task's scheduled time has passed
        if (task.scheduledTime.isBefore(now)) {
          debugPrint('Recurring task "${task.title}" scheduled time has passed, rescheduling...');
          await rescheduleRecurringTask(task);
        }
      }
    }
  }

  // Reschedule a recurring task based on its interval type and duration
  static Future<void> rescheduleRecurringTask(Task task) async {
    try {
      if (!task.isRecurring || task.recurringIntervalType == null) {
        debugPrint('Task is not recurring or missing interval type');
        return;
      }

      // Cancel all existing notifications for this task (including future ones)
      await cancelTaskNotification(task);

      final now = tz.TZDateTime.now(tz.local);
      final originalTime = tz.TZDateTime.from(task.scheduledTime, tz.local);
      
      // Get the time components (hour, minute, second)
      final hour = originalTime.hour;
      final minute = originalTime.minute;
      final second = originalTime.second;
      
      // Calculate next occurrence based on interval type
      tz.TZDateTime nextDate;
      Duration intervalDuration;
      
      switch (task.recurringIntervalType!) {
        case RecurringIntervalType.minutes:
          intervalDuration = Duration(minutes: task.recurringDuration);
          nextDate = now.add(intervalDuration);
          break;
          
        case RecurringIntervalType.hours:
          intervalDuration = Duration(hours: task.recurringDuration);
          nextDate = now.add(intervalDuration);
          break;
          
        case RecurringIntervalType.daily:
          // Next day at the same time
          nextDate = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            hour,
            minute,
            second,
          ).add(Duration(days: task.recurringDuration));
          
          // If the time has already passed today, schedule for the next interval
          if (nextDate.isBefore(now)) {
            nextDate = nextDate.add(Duration(days: task.recurringDuration));
          }
          break;
          
        case RecurringIntervalType.weekly:
          // Next week at the same time
          nextDate = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            hour,
            minute,
            second,
          ).add(Duration(days: 7 * task.recurringDuration));
          
          // If the time has already passed this week, schedule for next week
          if (nextDate.isBefore(now)) {
            nextDate = nextDate.add(Duration(days: 7 * task.recurringDuration));
          }
          break;
      }

      debugPrint('Rescheduling recurring task "${task.title}" (${task.recurringIntervalType!.displayName}, ${task.recurringDuration}) for ${nextDate}');

      // Update task's scheduled time to next occurrence
      final taskIndex = allTasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        allTasks[taskIndex] = task.copyWith(
          scheduledTime: nextDate.toLocal(),
        );
        
        // Schedule notification for the next occurrence
        // This will automatically pre-schedule future occurrences for short intervals
        await scheduleTaskNotification(allTasks[taskIndex]);
        
        // Also explicitly pre-schedule future occurrences for very short intervals
        if (task.recurringIntervalType == RecurringIntervalType.minutes && task.recurringDuration <= 5) {
          final nextTzDate = tz.TZDateTime.from(nextDate.toLocal(), tz.local);
          await _scheduleNextRecurringOccurrence(allTasks[taskIndex], nextTzDate);
        }
      }
    } catch (e) {
      debugPrint('Error rescheduling recurring task: $e');
    }
  }
}

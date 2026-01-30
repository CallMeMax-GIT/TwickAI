enum TaskPriority {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'LOW';
      case TaskPriority.medium:
        return 'MEDIUM';
      case TaskPriority.high:
        return 'HIGH';
    }
  }

  static TaskPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      default:
        return TaskPriority.medium;
    }
  }
}

enum RecurringIntervalType {
  minutes,
  hours,
  daily,
  weekly;

  String get displayName {
    switch (this) {
      case RecurringIntervalType.minutes:
        return 'Minutes';
      case RecurringIntervalType.hours:
        return 'Hours';
      case RecurringIntervalType.daily:
        return 'Daily';
      case RecurringIntervalType.weekly:
        return 'Weekly';
    }
  }

  static RecurringIntervalType? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'minutes':
      case 'minute':
      case 'min':
        return RecurringIntervalType.minutes;
      case 'hours':
      case 'hour':
      case 'hr':
        return RecurringIntervalType.hours;
      case 'daily':
      case 'day':
      case 'days':
        return RecurringIntervalType.daily;
      case 'weekly':
      case 'week':
      case 'weeks':
        return RecurringIntervalType.weekly;
      default:
        return null;
    }
  }
}

class Task {
  final String id;
  final String title;
  final DateTime scheduledTime; // Required - using DateTime (best format for Dart)
  bool isCompleted;
  TaskPriority priority;
  String? categoryId; // Category ID reference
  bool playSound; // Whether to play sound when notification triggers
  bool isRecurring; // Whether this task repeats
  RecurringIntervalType? recurringIntervalType; // Type of recurring interval (minutes, hours, daily, weekly)
  int recurringDuration; // Duration for the interval (e.g., 2 for "every 2 hours")

  Task({
    required this.id,
    required this.title,
    required this.scheduledTime,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.categoryId,
    this.playSound = true, // Default to true (play sound)
    this.isRecurring = false, // Default to false (not recurring)
    this.recurringIntervalType,
    this.recurringDuration = 1, // Default to 1
  });

  // Convert to epoch milliseconds (for storage if needed)
  int get scheduledTimeEpoch => scheduledTime.millisecondsSinceEpoch;

  // Create from epoch milliseconds
  factory Task.fromEpoch({
    required String id,
    required String title,
    required int scheduledTimeEpoch,
    bool isCompleted = false,
    TaskPriority priority = TaskPriority.medium,
    String? categoryId,
    bool playSound = true,
    bool isRecurring = false,
    RecurringIntervalType? recurringIntervalType,
    int recurringDuration = 1,
  }) {
    return Task(
      id: id,
      title: title,
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(scheduledTimeEpoch),
      isCompleted: isCompleted,
      priority: priority,
      categoryId: categoryId,
      playSound: playSound,
      isRecurring: isRecurring,
      recurringIntervalType: recurringIntervalType,
      recurringDuration: recurringDuration,
    );
  }

  // CopyWith method for easier updates
  Task copyWith({
    String? id,
    String? title,
    DateTime? scheduledTime,
    bool? isCompleted,
    TaskPriority? priority,
    String? categoryId,
    bool? playSound,
    bool? isRecurring,
    RecurringIntervalType? recurringIntervalType,
    int? recurringDuration,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      playSound: playSound ?? this.playSound,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringIntervalType: recurringIntervalType ?? this.recurringIntervalType,
      recurringDuration: recurringDuration ?? this.recurringDuration,
    );
  }

  // Convert to/from JSON for storage
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'])
          : DateTime.fromMillisecondsSinceEpoch(json['scheduledTimeEpoch'] ?? 0),
      isCompleted: json['isCompleted'] ?? false,
      priority: json['priority'] != null
          ? TaskPriority.fromString(json['priority'])
          : TaskPriority.medium,
      categoryId: json['categoryId'],
      playSound: json['playSound'] != null && json['playSound'] is bool 
          ? json['playSound'] as bool 
          : true, // Default to true for backward compatibility
      isRecurring: json['isRecurring'] != null && json['isRecurring'] is bool 
          ? json['isRecurring'] as bool 
          : false, // Default to false for backward compatibility
      recurringIntervalType: json['recurringIntervalType'] != null
          ? RecurringIntervalType.fromString(json['recurringIntervalType'] as String)
          : null,
      recurringDuration: json['recurringDuration'] != null && json['recurringDuration'] is int
          ? json['recurringDuration'] as int
          : 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'scheduledTime': scheduledTime.toIso8601String(),
        'scheduledTimeEpoch': scheduledTimeEpoch,
        'isCompleted': isCompleted,
        'priority': priority.name,
        'categoryId': categoryId,
        'playSound': playSound,
        'isRecurring': isRecurring,
        'recurringIntervalType': recurringIntervalType?.name,
        'recurringDuration': recurringDuration,
      };

  // Calculate the next reminder time based on recurring interval
  // Returns null if task is not recurring
  DateTime? getNextReminderTime() {
    if (!isRecurring || recurringIntervalType == null) {
      return null;
    }

    final now = DateTime.now();
    DateTime nextReminder = scheduledTime;

    // If scheduledTime is in the past, calculate the next occurrence
    if (scheduledTime.isBefore(now)) {
      switch (recurringIntervalType!) {
        case RecurringIntervalType.minutes:
          // Calculate how many intervals have passed
          final minutesPassed = now.difference(scheduledTime).inMinutes;
          final intervalsPassed = (minutesPassed / recurringDuration).ceil();
          nextReminder = scheduledTime.add(Duration(minutes: intervalsPassed * recurringDuration));
          // Ensure it's in the future
          while (nextReminder.isBefore(now) || nextReminder.isAtSameMomentAs(now)) {
            nextReminder = nextReminder.add(Duration(minutes: recurringDuration));
          }
          break;
        case RecurringIntervalType.hours:
          // Calculate how many intervals have passed
          final hoursPassed = now.difference(scheduledTime).inHours;
          final intervalsPassed = (hoursPassed / recurringDuration).ceil();
          nextReminder = scheduledTime.add(Duration(hours: intervalsPassed * recurringDuration));
          // Ensure it's in the future
          while (nextReminder.isBefore(now) || nextReminder.isAtSameMomentAs(now)) {
            nextReminder = nextReminder.add(Duration(hours: recurringDuration));
          }
          break;
        case RecurringIntervalType.daily:
          // For daily, keep the same time of day
          nextReminder = DateTime(
            now.year,
            now.month,
            now.day,
            scheduledTime.hour,
            scheduledTime.minute,
            scheduledTime.second,
          );
          // If today's time has passed, move to next day
          if (nextReminder.isBefore(now) || nextReminder.isAtSameMomentAs(now)) {
            nextReminder = nextReminder.add(Duration(days: recurringDuration));
          }
          break;
        case RecurringIntervalType.weekly:
          // For weekly, keep the same day of week and time
          final daysToAdd = (now.difference(scheduledTime).inDays / (7 * recurringDuration)).ceil() * (7 * recurringDuration);
          nextReminder = scheduledTime.add(Duration(days: daysToAdd));
          // Ensure it's in the future
          while (nextReminder.isBefore(now) || nextReminder.isAtSameMomentAs(now)) {
            nextReminder = nextReminder.add(Duration(days: 7 * recurringDuration));
          }
          break;
      }
    } else {
      // scheduledTime is in the future, so it's the next reminder
      nextReminder = scheduledTime;
    }

    return nextReminder;
  }
}

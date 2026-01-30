/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class Task implements _i1.SerializableModel {
  Task._({
    this.id,
    required this.clientId,
    required this.authUserId,
    required this.title,
    required this.scheduledTime,
    required this.isCompleted,
    required this.priority,
    this.categoryId,
    required this.playSound,
    required this.isRecurring,
    this.recurringIntervalType,
    required this.recurringDuration,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task({
    int? id,
    required String clientId,
    required _i1.UuidValue authUserId,
    required String title,
    required DateTime scheduledTime,
    required bool isCompleted,
    required String priority,
    String? categoryId,
    required bool playSound,
    required bool isRecurring,
    String? recurringIntervalType,
    required int recurringDuration,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TaskImpl;

  factory Task.fromJson(Map<String, dynamic> jsonSerialization) {
    return Task(
      id: jsonSerialization['id'] as int?,
      clientId: jsonSerialization['clientId'] as String,
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      title: jsonSerialization['title'] as String,
      scheduledTime: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['scheduledTime'],
      ),
      isCompleted: jsonSerialization['isCompleted'] as bool,
      priority: jsonSerialization['priority'] as String,
      categoryId: jsonSerialization['categoryId'] as String?,
      playSound: jsonSerialization['playSound'] as bool,
      isRecurring: jsonSerialization['isRecurring'] as bool,
      recurringIntervalType:
          jsonSerialization['recurringIntervalType'] as String?,
      recurringDuration: jsonSerialization['recurringDuration'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The unique identifier for the task (using client-side ID as string)
  String clientId;

  /// The authenticated user who owns this task
  _i1.UuidValue authUserId;

  /// The title of the task
  String title;

  /// When the task is scheduled
  DateTime scheduledTime;

  /// Whether the task is completed
  bool isCompleted;

  /// The priority level (low, medium, high)
  String priority;

  /// The category ID this task belongs to
  String? categoryId;

  /// Whether to play sound when notification triggers
  bool playSound;

  /// Whether this task repeats
  bool isRecurring;

  /// Type of recurring interval (minutes, hours, daily, weekly)
  String? recurringIntervalType;

  /// Duration for the recurring interval
  int recurringDuration;

  /// When the task was created
  DateTime createdAt;

  /// When the task was last updated
  DateTime updatedAt;

  /// Returns a shallow copy of this [Task]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Task copyWith({
    int? id,
    String? clientId,
    _i1.UuidValue? authUserId,
    String? title,
    DateTime? scheduledTime,
    bool? isCompleted,
    String? priority,
    String? categoryId,
    bool? playSound,
    bool? isRecurring,
    String? recurringIntervalType,
    int? recurringDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Task',
      if (id != null) 'id': id,
      'clientId': clientId,
      'authUserId': authUserId.toJson(),
      'title': title,
      'scheduledTime': scheduledTime.toJson(),
      'isCompleted': isCompleted,
      'priority': priority,
      if (categoryId != null) 'categoryId': categoryId,
      'playSound': playSound,
      'isRecurring': isRecurring,
      if (recurringIntervalType != null)
        'recurringIntervalType': recurringIntervalType,
      'recurringDuration': recurringDuration,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaskImpl extends Task {
  _TaskImpl({
    int? id,
    required String clientId,
    required _i1.UuidValue authUserId,
    required String title,
    required DateTime scheduledTime,
    required bool isCompleted,
    required String priority,
    String? categoryId,
    required bool playSound,
    required bool isRecurring,
    String? recurringIntervalType,
    required int recurringDuration,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         clientId: clientId,
         authUserId: authUserId,
         title: title,
         scheduledTime: scheduledTime,
         isCompleted: isCompleted,
         priority: priority,
         categoryId: categoryId,
         playSound: playSound,
         isRecurring: isRecurring,
         recurringIntervalType: recurringIntervalType,
         recurringDuration: recurringDuration,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Task]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Task copyWith({
    Object? id = _Undefined,
    String? clientId,
    _i1.UuidValue? authUserId,
    String? title,
    DateTime? scheduledTime,
    bool? isCompleted,
    String? priority,
    Object? categoryId = _Undefined,
    bool? playSound,
    bool? isRecurring,
    Object? recurringIntervalType = _Undefined,
    int? recurringDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id is int? ? id : this.id,
      clientId: clientId ?? this.clientId,
      authUserId: authUserId ?? this.authUserId,
      title: title ?? this.title,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      categoryId: categoryId is String? ? categoryId : this.categoryId,
      playSound: playSound ?? this.playSound,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringIntervalType: recurringIntervalType is String?
          ? recurringIntervalType
          : this.recurringIntervalType,
      recurringDuration: recurringDuration ?? this.recurringDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

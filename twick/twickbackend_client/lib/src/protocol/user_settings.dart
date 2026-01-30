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

abstract class UserSettings implements _i1.SerializableModel {
  UserSettings._({
    this.id,
    required this.authUserId,
    required this.notificationsEnabled,
    required this.sleepModeEnabled,
    required this.sleepModeFromHour,
    required this.sleepModeFromMinute,
    required this.sleepModeToHour,
    required this.sleepModeToMinute,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSettings({
    int? id,
    required _i1.UuidValue authUserId,
    required bool notificationsEnabled,
    required bool sleepModeEnabled,
    required int sleepModeFromHour,
    required int sleepModeFromMinute,
    required int sleepModeToHour,
    required int sleepModeToMinute,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserSettingsImpl;

  factory UserSettings.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserSettings(
      id: jsonSerialization['id'] as int?,
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      notificationsEnabled: jsonSerialization['notificationsEnabled'] as bool,
      sleepModeEnabled: jsonSerialization['sleepModeEnabled'] as bool,
      sleepModeFromHour: jsonSerialization['sleepModeFromHour'] as int,
      sleepModeFromMinute: jsonSerialization['sleepModeFromMinute'] as int,
      sleepModeToHour: jsonSerialization['sleepModeToHour'] as int,
      sleepModeToMinute: jsonSerialization['sleepModeToMinute'] as int,
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

  /// The authenticated user these settings belong to
  _i1.UuidValue authUserId;

  /// Whether notifications are enabled
  bool notificationsEnabled;

  /// Whether sleep mode is enabled
  bool sleepModeEnabled;

  /// Sleep mode start hour (0-23)
  int sleepModeFromHour;

  /// Sleep mode start minute (0-59)
  int sleepModeFromMinute;

  /// Sleep mode end hour (0-23)
  int sleepModeToHour;

  /// Sleep mode end minute (0-59)
  int sleepModeToMinute;

  /// When the settings were created
  DateTime createdAt;

  /// When the settings were last updated
  DateTime updatedAt;

  /// Returns a shallow copy of this [UserSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserSettings copyWith({
    int? id,
    _i1.UuidValue? authUserId,
    bool? notificationsEnabled,
    bool? sleepModeEnabled,
    int? sleepModeFromHour,
    int? sleepModeFromMinute,
    int? sleepModeToHour,
    int? sleepModeToMinute,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserSettings',
      if (id != null) 'id': id,
      'authUserId': authUserId.toJson(),
      'notificationsEnabled': notificationsEnabled,
      'sleepModeEnabled': sleepModeEnabled,
      'sleepModeFromHour': sleepModeFromHour,
      'sleepModeFromMinute': sleepModeFromMinute,
      'sleepModeToHour': sleepModeToHour,
      'sleepModeToMinute': sleepModeToMinute,
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

class _UserSettingsImpl extends UserSettings {
  _UserSettingsImpl({
    int? id,
    required _i1.UuidValue authUserId,
    required bool notificationsEnabled,
    required bool sleepModeEnabled,
    required int sleepModeFromHour,
    required int sleepModeFromMinute,
    required int sleepModeToHour,
    required int sleepModeToMinute,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         notificationsEnabled: notificationsEnabled,
         sleepModeEnabled: sleepModeEnabled,
         sleepModeFromHour: sleepModeFromHour,
         sleepModeFromMinute: sleepModeFromMinute,
         sleepModeToHour: sleepModeToHour,
         sleepModeToMinute: sleepModeToMinute,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [UserSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserSettings copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? authUserId,
    bool? notificationsEnabled,
    bool? sleepModeEnabled,
    int? sleepModeFromHour,
    int? sleepModeFromMinute,
    int? sleepModeToHour,
    int? sleepModeToMinute,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id is int? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      sleepModeEnabled: sleepModeEnabled ?? this.sleepModeEnabled,
      sleepModeFromHour: sleepModeFromHour ?? this.sleepModeFromHour,
      sleepModeFromMinute: sleepModeFromMinute ?? this.sleepModeFromMinute,
      sleepModeToHour: sleepModeToHour ?? this.sleepModeToHour,
      sleepModeToMinute: sleepModeToMinute ?? this.sleepModeToMinute,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

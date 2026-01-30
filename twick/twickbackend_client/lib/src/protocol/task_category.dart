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

abstract class TaskCategory implements _i1.SerializableModel {
  TaskCategory._({
    this.id,
    required this.clientId,
    required this.authUserId,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskCategory({
    int? id,
    required String clientId,
    required _i1.UuidValue authUserId,
    required String name,
    required int iconCodePoint,
    required int colorValue,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TaskCategoryImpl;

  factory TaskCategory.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaskCategory(
      id: jsonSerialization['id'] as int?,
      clientId: jsonSerialization['clientId'] as String,
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      name: jsonSerialization['name'] as String,
      iconCodePoint: jsonSerialization['iconCodePoint'] as int,
      colorValue: jsonSerialization['colorValue'] as int,
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

  /// The unique identifier for the category (using client-side ID as string)
  String clientId;

  /// The authenticated user who owns this category
  _i1.UuidValue authUserId;

  /// The name of the category
  String name;

  /// The icon code point (MaterialIcons)
  int iconCodePoint;

  /// The color value (ARGB)
  int colorValue;

  /// When the category was created
  DateTime createdAt;

  /// When the category was last updated
  DateTime updatedAt;

  /// Returns a shallow copy of this [TaskCategory]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TaskCategory copyWith({
    int? id,
    String? clientId,
    _i1.UuidValue? authUserId,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TaskCategory',
      if (id != null) 'id': id,
      'clientId': clientId,
      'authUserId': authUserId.toJson(),
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
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

class _TaskCategoryImpl extends TaskCategory {
  _TaskCategoryImpl({
    int? id,
    required String clientId,
    required _i1.UuidValue authUserId,
    required String name,
    required int iconCodePoint,
    required int colorValue,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         clientId: clientId,
         authUserId: authUserId,
         name: name,
         iconCodePoint: iconCodePoint,
         colorValue: colorValue,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [TaskCategory]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TaskCategory copyWith({
    Object? id = _Undefined,
    String? clientId,
    _i1.UuidValue? authUserId,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskCategory(
      id: id is int? ? id : this.id,
      clientId: clientId ?? this.clientId,
      authUserId: authUserId ?? this.authUserId,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

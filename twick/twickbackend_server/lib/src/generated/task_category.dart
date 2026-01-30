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
import 'package:serverpod/serverpod.dart' as _i1;

abstract class TaskCategory
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = TaskCategoryTable();

  static const db = TaskCategoryRepository._();

  @override
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

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static TaskCategoryInclude include() {
    return TaskCategoryInclude._();
  }

  static TaskCategoryIncludeList includeList({
    _i1.WhereExpressionBuilder<TaskCategoryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TaskCategoryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TaskCategoryTable>? orderByList,
    TaskCategoryInclude? include,
  }) {
    return TaskCategoryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaskCategory.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TaskCategory.t),
      include: include,
    );
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

class TaskCategoryUpdateTable extends _i1.UpdateTable<TaskCategoryTable> {
  TaskCategoryUpdateTable(super.table);

  _i1.ColumnValue<String, String> clientId(String value) => _i1.ColumnValue(
    table.clientId,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> authUserId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.authUserId,
    value,
  );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<int, int> iconCodePoint(int value) => _i1.ColumnValue(
    table.iconCodePoint,
    value,
  );

  _i1.ColumnValue<int, int> colorValue(int value) => _i1.ColumnValue(
    table.colorValue,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class TaskCategoryTable extends _i1.Table<int?> {
  TaskCategoryTable({super.tableRelation}) : super(tableName: 'task_category') {
    updateTable = TaskCategoryUpdateTable(this);
    clientId = _i1.ColumnString(
      'clientId',
      this,
    );
    authUserId = _i1.ColumnUuid(
      'authUserId',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    iconCodePoint = _i1.ColumnInt(
      'iconCodePoint',
      this,
    );
    colorValue = _i1.ColumnInt(
      'colorValue',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final TaskCategoryUpdateTable updateTable;

  /// The unique identifier for the category (using client-side ID as string)
  late final _i1.ColumnString clientId;

  /// The authenticated user who owns this category
  late final _i1.ColumnUuid authUserId;

  /// The name of the category
  late final _i1.ColumnString name;

  /// The icon code point (MaterialIcons)
  late final _i1.ColumnInt iconCodePoint;

  /// The color value (ARGB)
  late final _i1.ColumnInt colorValue;

  /// When the category was created
  late final _i1.ColumnDateTime createdAt;

  /// When the category was last updated
  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    clientId,
    authUserId,
    name,
    iconCodePoint,
    colorValue,
    createdAt,
    updatedAt,
  ];
}

class TaskCategoryInclude extends _i1.IncludeObject {
  TaskCategoryInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => TaskCategory.t;
}

class TaskCategoryIncludeList extends _i1.IncludeList {
  TaskCategoryIncludeList._({
    _i1.WhereExpressionBuilder<TaskCategoryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaskCategory.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => TaskCategory.t;
}

class TaskCategoryRepository {
  const TaskCategoryRepository._();

  /// Returns a list of [TaskCategory]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<TaskCategory>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TaskCategoryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TaskCategoryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TaskCategoryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<TaskCategory>(
      where: where?.call(TaskCategory.t),
      orderBy: orderBy?.call(TaskCategory.t),
      orderByList: orderByList?.call(TaskCategory.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [TaskCategory] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<TaskCategory?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TaskCategoryTable>? where,
    int? offset,
    _i1.OrderByBuilder<TaskCategoryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TaskCategoryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<TaskCategory>(
      where: where?.call(TaskCategory.t),
      orderBy: orderBy?.call(TaskCategory.t),
      orderByList: orderByList?.call(TaskCategory.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [TaskCategory] by its [id] or null if no such row exists.
  Future<TaskCategory?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<TaskCategory>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [TaskCategory]s in the list and returns the inserted rows.
  ///
  /// The returned [TaskCategory]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<TaskCategory>> insert(
    _i1.Session session,
    List<TaskCategory> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<TaskCategory>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [TaskCategory] and returns the inserted row.
  ///
  /// The returned [TaskCategory] will have its `id` field set.
  Future<TaskCategory> insertRow(
    _i1.Session session,
    TaskCategory row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaskCategory>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TaskCategory]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TaskCategory>> update(
    _i1.Session session,
    List<TaskCategory> rows, {
    _i1.ColumnSelections<TaskCategoryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TaskCategory>(
      rows,
      columns: columns?.call(TaskCategory.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaskCategory]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaskCategory> updateRow(
    _i1.Session session,
    TaskCategory row, {
    _i1.ColumnSelections<TaskCategoryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaskCategory>(
      row,
      columns: columns?.call(TaskCategory.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaskCategory] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaskCategory?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<TaskCategoryUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<TaskCategory>(
      id,
      columnValues: columnValues(TaskCategory.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaskCategory]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<TaskCategory>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<TaskCategoryUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TaskCategoryTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TaskCategoryTable>? orderBy,
    _i1.OrderByListBuilder<TaskCategoryTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<TaskCategory>(
      columnValues: columnValues(TaskCategory.t.updateTable),
      where: where(TaskCategory.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaskCategory.t),
      orderByList: orderByList?.call(TaskCategory.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [TaskCategory]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TaskCategory>> delete(
    _i1.Session session,
    List<TaskCategory> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TaskCategory>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TaskCategory].
  Future<TaskCategory> deleteRow(
    _i1.Session session,
    TaskCategory row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaskCategory>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TaskCategory>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TaskCategoryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TaskCategory>(
      where: where(TaskCategory.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TaskCategoryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TaskCategory>(
      where: where?.call(TaskCategory.t),
      limit: limit,
      transaction: transaction,
    );
  }
}

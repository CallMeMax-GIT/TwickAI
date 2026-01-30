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

abstract class Task implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = TaskTable();

  static const db = TaskRepository._();

  @override
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

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static TaskInclude include() {
    return TaskInclude._();
  }

  static TaskIncludeList includeList({
    _i1.WhereExpressionBuilder<TaskTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TaskTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TaskTable>? orderByList,
    TaskInclude? include,
  }) {
    return TaskIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Task.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Task.t),
      include: include,
    );
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

class TaskUpdateTable extends _i1.UpdateTable<TaskTable> {
  TaskUpdateTable(super.table);

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

  _i1.ColumnValue<String, String> title(String value) => _i1.ColumnValue(
    table.title,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> scheduledTime(DateTime value) =>
      _i1.ColumnValue(
        table.scheduledTime,
        value,
      );

  _i1.ColumnValue<bool, bool> isCompleted(bool value) => _i1.ColumnValue(
    table.isCompleted,
    value,
  );

  _i1.ColumnValue<String, String> priority(String value) => _i1.ColumnValue(
    table.priority,
    value,
  );

  _i1.ColumnValue<String, String> categoryId(String? value) => _i1.ColumnValue(
    table.categoryId,
    value,
  );

  _i1.ColumnValue<bool, bool> playSound(bool value) => _i1.ColumnValue(
    table.playSound,
    value,
  );

  _i1.ColumnValue<bool, bool> isRecurring(bool value) => _i1.ColumnValue(
    table.isRecurring,
    value,
  );

  _i1.ColumnValue<String, String> recurringIntervalType(String? value) =>
      _i1.ColumnValue(
        table.recurringIntervalType,
        value,
      );

  _i1.ColumnValue<int, int> recurringDuration(int value) => _i1.ColumnValue(
    table.recurringDuration,
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

class TaskTable extends _i1.Table<int?> {
  TaskTable({super.tableRelation}) : super(tableName: 'task') {
    updateTable = TaskUpdateTable(this);
    clientId = _i1.ColumnString(
      'clientId',
      this,
    );
    authUserId = _i1.ColumnUuid(
      'authUserId',
      this,
    );
    title = _i1.ColumnString(
      'title',
      this,
    );
    scheduledTime = _i1.ColumnDateTime(
      'scheduledTime',
      this,
    );
    isCompleted = _i1.ColumnBool(
      'isCompleted',
      this,
    );
    priority = _i1.ColumnString(
      'priority',
      this,
    );
    categoryId = _i1.ColumnString(
      'categoryId',
      this,
    );
    playSound = _i1.ColumnBool(
      'playSound',
      this,
    );
    isRecurring = _i1.ColumnBool(
      'isRecurring',
      this,
    );
    recurringIntervalType = _i1.ColumnString(
      'recurringIntervalType',
      this,
    );
    recurringDuration = _i1.ColumnInt(
      'recurringDuration',
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

  late final TaskUpdateTable updateTable;

  /// The unique identifier for the task (using client-side ID as string)
  late final _i1.ColumnString clientId;

  /// The authenticated user who owns this task
  late final _i1.ColumnUuid authUserId;

  /// The title of the task
  late final _i1.ColumnString title;

  /// When the task is scheduled
  late final _i1.ColumnDateTime scheduledTime;

  /// Whether the task is completed
  late final _i1.ColumnBool isCompleted;

  /// The priority level (low, medium, high)
  late final _i1.ColumnString priority;

  /// The category ID this task belongs to
  late final _i1.ColumnString categoryId;

  /// Whether to play sound when notification triggers
  late final _i1.ColumnBool playSound;

  /// Whether this task repeats
  late final _i1.ColumnBool isRecurring;

  /// Type of recurring interval (minutes, hours, daily, weekly)
  late final _i1.ColumnString recurringIntervalType;

  /// Duration for the recurring interval
  late final _i1.ColumnInt recurringDuration;

  /// When the task was created
  late final _i1.ColumnDateTime createdAt;

  /// When the task was last updated
  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    clientId,
    authUserId,
    title,
    scheduledTime,
    isCompleted,
    priority,
    categoryId,
    playSound,
    isRecurring,
    recurringIntervalType,
    recurringDuration,
    createdAt,
    updatedAt,
  ];
}

class TaskInclude extends _i1.IncludeObject {
  TaskInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Task.t;
}

class TaskIncludeList extends _i1.IncludeList {
  TaskIncludeList._({
    _i1.WhereExpressionBuilder<TaskTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Task.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Task.t;
}

class TaskRepository {
  const TaskRepository._();

  /// Returns a list of [Task]s matching the given query parameters.
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
  Future<List<Task>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TaskTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TaskTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TaskTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Task>(
      where: where?.call(Task.t),
      orderBy: orderBy?.call(Task.t),
      orderByList: orderByList?.call(Task.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Task] matching the given query parameters.
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
  Future<Task?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TaskTable>? where,
    int? offset,
    _i1.OrderByBuilder<TaskTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TaskTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Task>(
      where: where?.call(Task.t),
      orderBy: orderBy?.call(Task.t),
      orderByList: orderByList?.call(Task.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Task] by its [id] or null if no such row exists.
  Future<Task?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Task>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Task]s in the list and returns the inserted rows.
  ///
  /// The returned [Task]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Task>> insert(
    _i1.Session session,
    List<Task> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Task>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Task] and returns the inserted row.
  ///
  /// The returned [Task] will have its `id` field set.
  Future<Task> insertRow(
    _i1.Session session,
    Task row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Task>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Task]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Task>> update(
    _i1.Session session,
    List<Task> rows, {
    _i1.ColumnSelections<TaskTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Task>(
      rows,
      columns: columns?.call(Task.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Task]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Task> updateRow(
    _i1.Session session,
    Task row, {
    _i1.ColumnSelections<TaskTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Task>(
      row,
      columns: columns?.call(Task.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Task] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Task?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<TaskUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Task>(
      id,
      columnValues: columnValues(Task.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Task]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Task>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<TaskUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TaskTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TaskTable>? orderBy,
    _i1.OrderByListBuilder<TaskTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Task>(
      columnValues: columnValues(Task.t.updateTable),
      where: where(Task.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Task.t),
      orderByList: orderByList?.call(Task.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Task]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Task>> delete(
    _i1.Session session,
    List<Task> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Task>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Task].
  Future<Task> deleteRow(
    _i1.Session session,
    Task row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Task>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Task>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TaskTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Task>(
      where: where(Task.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TaskTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Task>(
      where: where?.call(Task.t),
      limit: limit,
      transaction: transaction,
    );
  }
}

import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Endpoint for managing user tasks
class TaskEndpoint extends Endpoint {
  /// Get all tasks for the authenticated user
  Future<List<Task>> getTasks(Session session) async {
    final authenticationInfo = await session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('User not authenticated');
    }
    final userId = UuidValue.fromString(authenticationInfo.userIdentifier);

    return await Task.db.find(
      session,
      where: (t) => t.authUserId.equals(userId),
      orderBy: (t) => t.scheduledTime,
    );
  }

  /// Save or update a task
  Future<Task> saveTask(Session session, Task task) async {
    final authenticationInfo = await session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('User not authenticated');
    }
    final userId = UuidValue.fromString(authenticationInfo.userIdentifier);

    // Ensure the task belongs to the authenticated user
    task = task.copyWith(
      authUserId: userId,
      updatedAt: DateTime.now(),
    );

    // Check if task already exists
    final existing = await Task.db.findFirstRow(
      session,
      where: (t) =>
          t.authUserId.equals(userId) & t.clientId.equals(task.clientId),
    );

    if (existing != null) {
      // Update existing task
      return await Task.db.updateRow(
        session,
        task.copyWith(
          id: existing.id,
          createdAt: existing.createdAt, // Preserve original creation time
        ),
      );
    } else {
      // Create new task
      return await Task.db.insertRow(
        session,
        task.copyWith(
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// Save multiple tasks (for bulk sync)
  Future<List<Task>> saveTasks(Session session, List<Task> tasks) async {
    final authenticationInfo = await session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('User not authenticated');
    }
    final userId = UuidValue.fromString(authenticationInfo.userIdentifier);

    final now = DateTime.now();
    final savedTasks = <Task>[];

    for (var task in tasks) {
      // Ensure the task belongs to the authenticated user
      task = task.copyWith(
        authUserId: userId,
        updatedAt: now,
      );

      // Check if task already exists
      final existing = await Task.db.findFirstRow(
        session,
        where: (t) =>
            t.authUserId.equals(userId) & t.clientId.equals(task.clientId),
      );

      if (existing != null) {
        // Update existing task
        savedTasks.add(
          await Task.db.updateRow(
            session,
            task.copyWith(
              id: existing.id,
              createdAt: existing.createdAt,
            ),
          ),
        );
      } else {
        // Create new task
        savedTasks.add(
          await Task.db.insertRow(
            session,
            task.copyWith(createdAt: now),
          ),
        );
      }
    }

    return savedTasks;
  }

  /// Delete a task
  Future<void> deleteTask(Session session, String clientId) async {
    final authenticationInfo = await session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('User not authenticated');
    }
    final userId = UuidValue.fromString(authenticationInfo.userIdentifier);

    final task = await Task.db.findFirstRow(
      session,
      where: (t) =>
          t.authUserId.equals(userId) & t.clientId.equals(clientId),
    );

    if (task != null) {
      await Task.db.deleteRow(session, task);
    }
  }

  /// Delete multiple tasks
  Future<void> deleteTasks(Session session, List<String> clientIds) async {
    final authenticationInfo = await session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('User not authenticated');
    }
    final userId = UuidValue.fromString(authenticationInfo.userIdentifier);

    for (var clientId in clientIds) {
      final task = await Task.db.findFirstRow(
        session,
        where: (t) =>
            t.authUserId.equals(userId) & t.clientId.equals(clientId),
      );

      if (task != null) {
        await Task.db.deleteRow(session, task);
      }
    }
  }
}

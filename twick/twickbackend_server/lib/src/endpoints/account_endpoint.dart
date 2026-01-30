import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Endpoint for managing user account operations
class AccountEndpoint extends Endpoint {
  /// Delete all user data (tasks, categories, settings) for the authenticated user
  /// This permanently deletes all user data from the database
  Future<void> deleteAccount(Session session) async {
    final authenticationInfo = await session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('User not authenticated');
    }
    final userId = UuidValue.fromString(authenticationInfo.userIdentifier);

    // Delete all tasks for this user
    final tasks = await Task.db.find(
      session,
      where: (t) => t.authUserId.equals(userId),
    );
    for (var task in tasks) {
      await Task.db.deleteRow(session, task);
    }

    // Delete all categories for this user
    final categories = await TaskCategory.db.find(
      session,
      where: (c) => c.authUserId.equals(userId),
    );
    for (var category in categories) {
      await TaskCategory.db.deleteRow(session, category);
    }

    // Delete user settings
    final settings = await UserSettings.db.findFirstRow(
      session,
      where: (s) => s.authUserId.equals(userId),
    );
    if (settings != null) {
      await UserSettings.db.deleteRow(session, settings);
    }

    // Note: We don't delete the auth user account itself as that's managed by Serverpod Auth
    // The user can still log in, but all their data will be gone (fresh start)
  }
}

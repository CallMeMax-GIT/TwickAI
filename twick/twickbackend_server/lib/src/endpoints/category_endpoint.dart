import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Endpoint for managing user categories
class CategoryEndpoint extends Endpoint {
  /// Get all categories for the authenticated user
  Future<List<TaskCategory>> getCategories(Session session) async {
    final authenticationInfo = await session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('User not authenticated');
    }
    final userId = UuidValue.fromString(authenticationInfo.userIdentifier);

    return await TaskCategory.db.find(
      session,
      where: (c) => c.authUserId.equals(userId),
      orderBy: (c) => c.name,
    );
  }

  /// Save or update a category
  Future<TaskCategory> saveCategory(Session session, TaskCategory category) async {
    final authenticationInfo = await session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('User not authenticated');
    }
    final userId = UuidValue.fromString(authenticationInfo.userIdentifier);

    // Ensure the category belongs to the authenticated user
    category = category.copyWith(
      authUserId: userId,
      updatedAt: DateTime.now(),
    );

    // Check if category already exists
    final existing = await TaskCategory.db.findFirstRow(
      session,
      where: (c) =>
          c.authUserId.equals(userId) & c.clientId.equals(category.clientId),
    );

    if (existing != null) {
      // Update existing category
      return await TaskCategory.db.updateRow(
        session,
        category.copyWith(
          id: existing.id,
          createdAt: existing.createdAt, // Preserve original creation time
        ),
      );
    } else {
      // Create new category
      return await TaskCategory.db.insertRow(
        session,
        category.copyWith(
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// Save multiple categories (for bulk sync)
  Future<List<TaskCategory>> saveCategories(
    Session session,
    List<TaskCategory> categories,
  ) async {
    final authenticationInfo = await session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('User not authenticated');
    }
    final userId = UuidValue.fromString(authenticationInfo.userIdentifier);

    final now = DateTime.now();
    final savedCategories = <TaskCategory>[];

    for (var category in categories) {
      // Ensure the category belongs to the authenticated user
      category = category.copyWith(
        authUserId: userId,
        updatedAt: now,
      );

      // Check if category already exists
      final existing = await TaskCategory.db.findFirstRow(
        session,
        where: (c) =>
            c.authUserId.equals(userId) & c.clientId.equals(category.clientId),
      );

      if (existing != null) {
        // Update existing category
        savedCategories.add(
          await TaskCategory.db.updateRow(
            session,
            category.copyWith(
              id: existing.id,
              createdAt: existing.createdAt,
            ),
          ),
        );
      } else {
        // Create new category
        savedCategories.add(
          await TaskCategory.db.insertRow(
            session,
            category.copyWith(createdAt: now),
          ),
        );
      }
    }

    return savedCategories;
  }

  /// Delete a category
  Future<void> deleteCategory(Session session, String clientId) async {
    final authenticationInfo = await session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('User not authenticated');
    }
    final userId = UuidValue.fromString(authenticationInfo.userIdentifier);

    final category = await TaskCategory.db.findFirstRow(
      session,
      where: (c) =>
          c.authUserId.equals(userId) & c.clientId.equals(clientId),
    );

    if (category != null) {
      await TaskCategory.db.deleteRow(session, category);
    }
  }
}

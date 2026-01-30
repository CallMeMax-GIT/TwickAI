import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Endpoint for managing user settings
class UserSettingsEndpoint extends Endpoint {
  /// Get user settings for the authenticated user
  Future<UserSettings?> getSettings(Session session) async {
    final authenticationInfo = await session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('User not authenticated');
    }
    final userId = UuidValue.fromString(authenticationInfo.userIdentifier);

    return await UserSettings.db.findFirstRow(
      session,
      where: (s) => s.authUserId.equals(userId),
    );
  }

  /// Save or update user settings
  Future<UserSettings> saveSettings(Session session, UserSettings settings) async {
    final authenticationInfo = await session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('User not authenticated');
    }
    final userId = UuidValue.fromString(authenticationInfo.userIdentifier);

    // Ensure the settings belong to the authenticated user
    settings = settings.copyWith(
      authUserId: userId,
      updatedAt: DateTime.now(),
    );

    // Check if settings already exist
    final existing = await UserSettings.db.findFirstRow(
      session,
      where: (s) => s.authUserId.equals(userId),
    );

    if (existing != null) {
      // Update existing settings
      return await UserSettings.db.updateRow(
        session,
        settings.copyWith(
          id: existing.id,
          createdAt: existing.createdAt, // Preserve original creation time
        ),
      );
    } else {
      // Create new settings
      return await UserSettings.db.insertRow(
        session,
        settings.copyWith(
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// Delete user settings
  Future<void> deleteSettings(Session session) async {
    final authenticationInfo = await session.authenticated;
    if (authenticationInfo == null) {
      throw Exception('User not authenticated');
    }
    final userId = UuidValue.fromString(authenticationInfo.userIdentifier);

    final settings = await UserSettings.db.findFirstRow(
      session,
      where: (s) => s.authUserId.equals(userId),
    );
    if (settings != null) {
      await UserSettings.db.deleteRow(session, settings);
    }
  }
}

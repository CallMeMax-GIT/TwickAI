import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:serverpod_auth_idp_server/providers/google.dart';

/// By extending [GoogleIdpBaseEndpoint], the Google identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
class GoogleIdpEndpoint extends GoogleIdpBaseEndpoint {
  @override
  Future<AuthSuccess> login(
    Session session, {
    required String? accessToken,
    required String idToken,
  }) async {
    // Call parent login to handle authentication
    final authSuccess = await super.login(
      session,
      accessToken: accessToken,
      idToken: idToken,
    );
    
    // Ensure user profile exists after successful authentication
    // Serverpod should create profiles automatically, but we'll ensure it exists
    session.log('Starting profile check after Google login...');
    try {
      final authenticationInfo = await session.authenticated;
      session.log('Authentication info retrieved: ${authenticationInfo != null}');
      
      if (authenticationInfo != null) {
        final userId = UuidValue.fromString(authenticationInfo.userIdentifier);
        session.log('Checking profile for user: $userId');
        
        // Try to get the user profile - if it doesn't exist, log instructions
        try {
          final userProfiles = UserProfiles();
          await userProfiles.findUserProfileByUserId(session, userId);
          session.log('SUCCESS: Profile already exists for user $userId');
        } catch (e) {
          // Profile doesn't exist - log error with instructions for manual creation
          session.log('ERROR: Profile not found for user $userId');
          session.log('Exception: $e');
          session.log('This indicates Serverpod\'s automatic profile creation failed.');
          session.log('Manual profile creation required. Run this SQL:');
          session.log('INSERT INTO serverpod_auth_core_profile ("authUserId", "userName", "fullName", email)');
          session.log('VALUES (\'$userId\'::uuid, \'User\', \'User\', NULL)');
          session.log('ON CONFLICT ("authUserId") DO NOTHING;');
          // Don't fail the login - authentication succeeded, profile issue is separate
        }
      } else {
        session.log('WARNING: authenticationInfo is null after Google login');
      }
    } catch (e, stackTrace) {
      session.log('ERROR: Exception during profile check after Google login: $e');
      session.log('Stack trace: $stackTrace');
      // Don't fail the login if profile check/creation fails
    }
    
    return authSuccess;
  }
}

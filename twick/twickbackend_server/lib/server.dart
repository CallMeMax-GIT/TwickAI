import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod_auth_idp_server/providers/google.dart';
import 'package:serverpod_auth_idp_server/providers/apple.dart';

import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/web/routes/app_config_route.dart';
import 'src/web/routes/root.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Initialize authentication services for the server.
  // Token managers will be used to validate and issue authentication keys,
  // and the identity providers will be the authentication options available for users.
  pod.initializeAuthServices(
    tokenManagerBuilders: [
      // Use JWT for authentication keys towards the server.
      JwtConfigFromPasswords(),
    ],
    identityProviderBuilders: [
      // Configure the email identity provider for email/password authentication.
      EmailIdpConfigFromPasswords(
        sendRegistrationVerificationCode: _sendRegistrationCode,
        sendPasswordResetVerificationCode: _sendPasswordResetCode,
      ),
      // Configure the Google identity provider for Google Sign-In authentication.
      // Using Web OAuth client credentials for server-side token verification.
      // The credentials are loaded from config/google_client_secret.json or environment variable
      GoogleIdpConfig(
        clientSecret: () {
          try {
            // First, try to load from environment variable (for Serverpod Cloud)
            final envJson = Platform.environment['GOOGLE_CLIENT_SECRET_JSON'];
            if (envJson != null && envJson.isNotEmpty) {
              print('Loading Google client secret from environment variable');
              return GoogleClientSecret.fromJson(
                Map<String, dynamic>.from(
                  jsonDecode(envJson) as Map,
                ),
              );
            }

            // Fallback to file (for local development)
            var keyFile = File('config/google_client_secret.json');
            if (!keyFile.existsSync()) {
              keyFile = File('${Directory.current.path}/config/google_client_secret.json');
            }
            if (!keyFile.existsSync()) {
              throw Exception(
                'Google client secret not found. Tried environment variable GOOGLE_CLIENT_SECRET_JSON and file: ${keyFile.absolute.path}',
              );
            }
            final keyContent = keyFile.readAsStringSync();
            if (keyContent.trim().isEmpty) {
              throw Exception('Google client secret file is empty');
            }
            print('Successfully loaded Google client secret from file: ${keyFile.absolute.path}');
            return GoogleClientSecret.fromJsonFile(keyFile);
          } catch (e) {
            print('ERROR: Failed to read Google client secret: $e');
            rethrow;
          }
        }(),
      ),
      // Configure the Apple identity provider for Apple Sign-In authentication.
      // Set APPLE_REDIRECT_URI, APPLE_TEAM_ID, APPLE_KEY_ID in environment or config.
      AppleIdpConfig(
        serviceIdentifier: 'com.mobil80.twick.service',
        bundleIdentifier: 'com.mobil80.twick',
        redirectUri: Platform.environment['APPLE_REDIRECT_URI'] ?? '',
        teamId: Platform.environment['APPLE_TEAM_ID'] ?? '',
        keyId: Platform.environment['APPLE_KEY_ID'] ?? '',
        key: () {
          try {
            // First, try to load from environment variable (for Serverpod Cloud)
            final envKey = Platform.environment['APPLE_PRIVATE_KEY'];
            if (envKey != null && envKey.isNotEmpty) {
              print('Loading Apple private key from environment variable');
              return envKey;
            }

            // Fallback to file (for local development)
            var keyFile = File('config/AuthKey_355638NP98.p8');
            if (!keyFile.existsSync()) {
              keyFile = File('${Directory.current.path}/config/AuthKey_355638NP98.p8');
            }
            if (!keyFile.existsSync()) {
              throw Exception(
                'Apple private key not found. Tried environment variable APPLE_PRIVATE_KEY and file: ${keyFile.absolute.path}',
              );
            }
            final keyContent = keyFile.readAsStringSync();
            if (keyContent.trim().isEmpty) {
              throw Exception('Apple private key file is empty');
            }
            print('Successfully loaded Apple private key from file: ${keyFile.absolute.path}');
            return keyContent;
          } catch (e) {
            print('ERROR: Failed to read Apple private key: $e');
            rethrow;
          }
        }(), // Private key content (function is called immediately to get String)
      ),
    ],
  );

  // Setup a default page at the web root.
  // These are used by the default page.
  pod.webServer.addRoute(RootRoute(), '/');
  pod.webServer.addRoute(RootRoute(), '/index.html');

  // Serve all files in the web/static relative directory under /.
  // These are used by the default web page.
  final root = Directory(Uri(path: 'web/static').toFilePath());
  pod.webServer.addRoute(StaticRoute.directory(root));

  // Setup the app config route.
  // We build this configuration based on the servers api url and serve it to
  // the flutter app.
  pod.webServer.addRoute(
    AppConfigRoute(apiConfig: pod.config.apiServer),
    '/app/assets/assets/config.json',
  );

  // Checks if the flutter web app has been built and serves it if it has.
  final appDir = Directory(Uri(path: 'web/app').toFilePath());
  if (appDir.existsSync()) {
    // Serve the flutter web app under the /app path.
    pod.webServer.addRoute(
      FlutterRoute(
        Directory(
          Uri(path: 'web/app').toFilePath(),
        ),
      ),
      '/app',
    );
  } else {
    // If the flutter web app has not been built, serve the build app page.
    pod.webServer.addRoute(
      StaticRoute.file(
        File(
          Uri(path: 'web/pages/build_flutter_app.html').toFilePath(),
        ),
      ),
      '/app/**',
    );
  }

  // Start the server.
  await pod.start();
}

void _sendRegistrationCode(
  Session session, {
  required String email,
  required UuidValue accountRequestId,
  required String verificationCode,
  required Transaction? transaction,
}) {
  // NOTE: Here you call your mail service to send the verification code to
  // the user. For testing, we will just log the verification code.
  session.log('[EmailIdp] Registration code ($email): $verificationCode');
}

void _sendPasswordResetCode(
  Session session, {
  required String email,
  required UuidValue passwordResetRequestId,
  required String verificationCode,
  required Transaction? transaction,
}) {
  // NOTE: Here you call your mail service to send the verification code to
  // the user. For testing, we will just log the verification code.
  session.log('[EmailIdp] Password reset code ($email): $verificationCode');
}

import 'package:serverpod_auth_idp_server/providers/apple.dart';

/// By extending [AppleIdpBaseEndpoint], the Apple identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// 
/// Note: This endpoint is not configured in server.dart, so it won't be active.
class AppleIdpEndpoint extends AppleIdpBaseEndpoint {}

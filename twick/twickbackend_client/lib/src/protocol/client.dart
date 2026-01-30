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
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i1;
import 'package:serverpod_client/serverpod_client.dart' as _i2;
import 'dart:async' as _i3;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i4;
import 'package:twickbackend_client/src/protocol/task_category.dart' as _i5;
import 'package:twickbackend_client/src/protocol/task.dart' as _i6;
import 'package:twickbackend_client/src/protocol/user_settings.dart' as _i7;
import 'package:twickbackend_client/src/protocol/greetings/greeting.dart'
    as _i8;
import 'protocol.dart' as _i9;

/// By extending [AppleIdpBaseEndpoint], the Apple identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
///
/// Note: This endpoint is not configured in server.dart, so it won't be active.
/// {@category Endpoint}
class EndpointAppleIdp extends _i1.EndpointAppleIdpBase {
  EndpointAppleIdp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'appleIdp';

  /// Signs in a user with their Apple account.
  ///
  /// If no user exists yet linked to the Apple-provided identifier, a new one
  /// will be created (without any `Scope`s). Further their provided name and
  /// email (if any) will be used for the `UserProfile` which will be linked to
  /// their `AuthUser`.
  ///
  /// Returns a session for the user upon successful login.
  @override
  _i3.Future<_i4.AuthSuccess> login({
    required String identityToken,
    required String authorizationCode,
    required bool isNativeApplePlatformSignIn,
    String? firstName,
    String? lastName,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'appleIdp',
    'login',
    {
      'identityToken': identityToken,
      'authorizationCode': authorizationCode,
      'isNativeApplePlatformSignIn': isNativeApplePlatformSignIn,
      'firstName': firstName,
      'lastName': lastName,
    },
  );
}

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _i1.EndpointEmailIdpBase {
  EndpointEmailIdp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<_i4.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _i3.Future<_i2.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _i3.Future<String> verifyRegistrationCode({
    required _i2.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _i3.Future<_i4.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _i3.Future<_i2.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _i3.Future<String> verifyPasswordResetCode({
    required _i2.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );
}

/// By extending [GoogleIdpBaseEndpoint], the Google identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointGoogleIdp extends _i1.EndpointGoogleIdpBase {
  EndpointGoogleIdp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'googleIdp';

  @override
  _i3.Future<_i4.AuthSuccess> login({
    required String? accessToken,
    required String idToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'googleIdp',
    'login',
    {
      'accessToken': accessToken,
      'idToken': idToken,
    },
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i4.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i3.Future<_i4.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// Endpoint for managing user account operations
/// {@category Endpoint}
class EndpointAccount extends _i2.EndpointRef {
  EndpointAccount(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'account';

  /// Delete all user data (tasks, categories, settings) for the authenticated user
  /// This permanently deletes all user data from the database
  _i3.Future<void> deleteAccount() => caller.callServerEndpoint<void>(
    'account',
    'deleteAccount',
    {},
  );
}

/// Endpoint for managing user categories
/// {@category Endpoint}
class EndpointCategory extends _i2.EndpointRef {
  EndpointCategory(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'category';

  /// Get all categories for the authenticated user
  _i3.Future<List<_i5.TaskCategory>> getCategories() =>
      caller.callServerEndpoint<List<_i5.TaskCategory>>(
        'category',
        'getCategories',
        {},
      );

  /// Save or update a category
  _i3.Future<_i5.TaskCategory> saveCategory(_i5.TaskCategory category) =>
      caller.callServerEndpoint<_i5.TaskCategory>(
        'category',
        'saveCategory',
        {'category': category},
      );

  /// Save multiple categories (for bulk sync)
  _i3.Future<List<_i5.TaskCategory>> saveCategories(
    List<_i5.TaskCategory> categories,
  ) => caller.callServerEndpoint<List<_i5.TaskCategory>>(
    'category',
    'saveCategories',
    {'categories': categories},
  );

  /// Delete a category
  _i3.Future<void> deleteCategory(String clientId) =>
      caller.callServerEndpoint<void>(
        'category',
        'deleteCategory',
        {'clientId': clientId},
      );
}

/// Endpoint for managing user tasks
/// {@category Endpoint}
class EndpointTask extends _i2.EndpointRef {
  EndpointTask(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'task';

  /// Get all tasks for the authenticated user
  _i3.Future<List<_i6.Task>> getTasks() =>
      caller.callServerEndpoint<List<_i6.Task>>(
        'task',
        'getTasks',
        {},
      );

  /// Save or update a task
  _i3.Future<_i6.Task> saveTask(_i6.Task task) =>
      caller.callServerEndpoint<_i6.Task>(
        'task',
        'saveTask',
        {'task': task},
      );

  /// Save multiple tasks (for bulk sync)
  _i3.Future<List<_i6.Task>> saveTasks(List<_i6.Task> tasks) =>
      caller.callServerEndpoint<List<_i6.Task>>(
        'task',
        'saveTasks',
        {'tasks': tasks},
      );

  /// Delete a task
  _i3.Future<void> deleteTask(String clientId) =>
      caller.callServerEndpoint<void>(
        'task',
        'deleteTask',
        {'clientId': clientId},
      );

  /// Delete multiple tasks
  _i3.Future<void> deleteTasks(List<String> clientIds) =>
      caller.callServerEndpoint<void>(
        'task',
        'deleteTasks',
        {'clientIds': clientIds},
      );
}

/// Endpoint for managing user settings
/// {@category Endpoint}
class EndpointUserSettings extends _i2.EndpointRef {
  EndpointUserSettings(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'userSettings';

  /// Get user settings for the authenticated user
  _i3.Future<_i7.UserSettings?> getSettings() =>
      caller.callServerEndpoint<_i7.UserSettings?>(
        'userSettings',
        'getSettings',
        {},
      );

  /// Save or update user settings
  _i3.Future<_i7.UserSettings> saveSettings(_i7.UserSettings settings) =>
      caller.callServerEndpoint<_i7.UserSettings>(
        'userSettings',
        'saveSettings',
        {'settings': settings},
      );

  /// Delete user settings
  _i3.Future<void> deleteSettings() => caller.callServerEndpoint<void>(
    'userSettings',
    'deleteSettings',
    {},
  );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i2.EndpointRef {
  EndpointGreeting(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i3.Future<_i8.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i8.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i1.Caller(client);
    serverpod_auth_core = _i4.Caller(client);
  }

  late final _i1.Caller serverpod_auth_idp;

  late final _i4.Caller serverpod_auth_core;
}

class Client extends _i2.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i2.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i2.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i9.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    appleIdp = EndpointAppleIdp(this);
    emailIdp = EndpointEmailIdp(this);
    googleIdp = EndpointGoogleIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    account = EndpointAccount(this);
    category = EndpointCategory(this);
    task = EndpointTask(this);
    userSettings = EndpointUserSettings(this);
    greeting = EndpointGreeting(this);
    modules = Modules(this);
  }

  late final EndpointAppleIdp appleIdp;

  late final EndpointEmailIdp emailIdp;

  late final EndpointGoogleIdp googleIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointAccount account;

  late final EndpointCategory category;

  late final EndpointTask task;

  late final EndpointUserSettings userSettings;

  late final EndpointGreeting greeting;

  late final Modules modules;

  @override
  Map<String, _i2.EndpointRef> get endpointRefLookup => {
    'appleIdp': appleIdp,
    'emailIdp': emailIdp,
    'googleIdp': googleIdp,
    'jwtRefresh': jwtRefresh,
    'account': account,
    'category': category,
    'task': task,
    'userSettings': userSettings,
    'greeting': greeting,
  };

  @override
  Map<String, _i2.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}

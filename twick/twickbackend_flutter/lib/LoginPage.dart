import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:lottie/lottie.dart';
import 'package:twickbackend_flutter/PageController.dart';
import 'package:twickbackend_flutter/main.dart';
import 'package:twickbackend_flutter/models/AuthState.dart';
import 'package:twickbackend_flutter/models/TaskList.dart' show allTasks;
import 'package:twickbackend_flutter/models/CategoryList.dart' show allCategories;
import 'package:twickbackend_flutter/models/NotificationState.dart';
import 'package:twickbackend_flutter/services/ServerSyncService.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isProcessing = false; // Flag to prevent multiple executions
  bool _hasShownWelcome = false; // Flag to prevent showing welcome snackbar multiple times

  // Common logic for handling successful authentication
  Future<void> _handleAuthSuccess() async {
    // Prevent multiple executions
    if (!isProcessing) {
      debugPrint('_handleAuthSuccess called but not processing, skipping...');
      return;
    }

    try {
      // Keep loading dialog open during all processing
      // It will be closed right before navigation

      // Get user info from the authenticated session
      // 
      // IMPORTANT for Apple Sign-In:
      // - Serverpod matched the user using userIdentifier (stable ID from identityToken)
      // - Email/name are optional metadata, stored from first login
      // - On subsequent logins, Apple doesn't provide email/name, but server has them stored
      // - We always fetch from server to get the complete user profile
      // Add a small delay to ensure profile is created on server
      await Future.delayed(const Duration(milliseconds: 500));
      
      try {
        // Fetch user profile from the server with retry logic
        dynamic userProfile;
        int retryCount = 0;
        const maxRetries = 3;
        
        while (retryCount < maxRetries) {
          try {
            userProfile = await client.modules.serverpod_auth_core.userProfileInfo.get();
            debugPrint('Fetched user profile from server (attempt ${retryCount + 1}): userName=${userProfile.userName}, email=${userProfile.email}, fullName=${userProfile.fullName}');
            
            // Check if profile has meaningful data
            if (userProfile.email != null && userProfile.email!.isNotEmpty) {
              break; // Profile is populated, exit retry loop
            }
            
            if (retryCount < maxRetries - 1) {
              debugPrint('Profile empty, retrying in 1 second...');
              await Future.delayed(const Duration(seconds: 1));
            }
            retryCount++;
          } catch (e) {
            debugPrint('Error fetching profile (attempt ${retryCount + 1}): $e');
            if (retryCount < maxRetries - 1) {
              await Future.delayed(const Duration(seconds: 1));
            }
            retryCount++;
          }
        }
        
        if (userProfile == null) {
          throw Exception('Failed to fetch user profile after $maxRetries attempts');
        }

        // Extract user information
        final userName = userProfile.userName ??
            userProfile.fullName ??
            (userProfile.email?.split('@').first ?? 'User');
        final userEmail = userProfile.email ?? '';

        debugPrint('Extracted user info: userName=$userName, userEmail=$userEmail');

        if (userName.isEmpty || userName == 'User') {
          debugPrint('Warning: User name is empty or default, using email: $userEmail');
        }
        
        if (userEmail.isEmpty) {
          debugPrint('ERROR: User email is empty! Profile may not be properly created.');
        }

        // Fix image URL - replace localhost with actual server URL
        String imageUrl = '';
        if (userProfile.imageUrl != null) {
          final imageUri = userProfile.imageUrl!;
          // Replace localhost with the actual server host
          final serverUri = Uri.parse(serverUrl);
          imageUrl = Uri(
            scheme: serverUri.scheme,
            host: serverUri.host,
            port: serverUri.port,
            path: imageUri.path,
            query: imageUri.query,
          ).toString();
        }

        // Update auth state with actual user info
        AuthState.login(
          userName,
          userEmail,
          imageUrl, // Empty string if no image - will show person icon
        );

        debugPrint('AuthState updated: userName=${AuthState.userName.value}, userEmail=${AuthState.userEmail.value}');
      } catch (e) {
        // Fallback on error - use defaults
        debugPrint('Error fetching user profile: $e');
        debugPrint('Stack trace: ${StackTrace.current}');
        AuthState.login('User', '', ''); // Empty image URL - will show person icon
      }

      // Ensure we have valid user info before proceeding
      if (AuthState.userName.value.isEmpty || AuthState.userName.value == 'User') {
        debugPrint('Warning: User name is still default, attempting to fetch again...');
        try {
          final retryProfile = await client.modules.serverpod_auth_core.userProfileInfo.get();
          final retryName = retryProfile.userName ??
              retryProfile.fullName ??
              (retryProfile.email?.split('@').first ?? 'User');
          final retryEmail = retryProfile.email ?? '';
          AuthState.login(retryName, retryEmail, '');
          debugPrint('Retry successful: $retryName, $retryEmail');
        } catch (e) {
          debugPrint('Retry failed: $e');
        }
      }

      // Save login state (but don't set was_previously_logged_in yet - check it first)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_skipped_intro', true);
      await prefs.setBool('is_logged_in', true);
      // Also save user info for debugging
      await prefs.setString('saved_user_name', AuthState.userName.value);
      await prefs.setString('saved_user_email', AuthState.userEmail.value);

      // Check if account has existing data on server
      final hasExistingData = await ServerSyncService.hasExistingAccountData();
      debugPrint('Account has existing data: $hasExistingData');

      // Check if user has local tasks (guest mode tasks)
      final hasLocalTasks = allTasks.isNotEmpty;
      debugPrint('User has local tasks: $hasLocalTasks');

      // Show dialog if:
      // 1. User has local tasks (guest mode tasks)
      // 2. Account has existing data on server (existing account)
      // This means: Guest user with tasks logging into an existing account
      if (hasLocalTasks && hasExistingData) {
        // Guest user with tasks trying to login to existing account - show warning dialog
        debugPrint('Showing dialog: User with local tasks logging into existing account');
        final shouldProceed = await Get.dialog<bool>(
          Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF070A12),
                    Color(0xFF10162F),
                    Color(0xFF1C1444),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.orangeAccent,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Text(
                    'Account Already Exists',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Content
                  Text(
                    'This account already has data saved on the server. If you continue, all your current local tasks will be replaced with the data from your account.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel Button
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(result: false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Continue Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1E88E5),
                                Color(0xFF1565C0),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () => Get.back(result: true),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          barrierDismissible: false,
        );

        // Ensure dialog result is not null (Get.back might return null if route is removed)
        if (shouldProceed == true) {
          debugPrint('User confirmed to proceed with login');
          // Clear guest data before loading server data
          debugPrint('Clearing guest data before loading server data...');
          allTasks.clear();
          // Clear only user-created categories (preserve defaults)
          final defaultCategoryIds = ['work', 'personal', 'health', 'finance', 'general'];
          allCategories.removeWhere((cat) => !defaultCategoryIds.contains(cat.id));
          // Reset notification settings
          NotificationState.notificationsEnabled.value = false;
          NotificationState.sleepModeEnabled.value = false;

          // User confirmed - sync from server (replacing local data)
          try {
            await ServerSyncService.syncAllFromServer();
            debugPrint('Data synced from server after login (existing account)');

            // Small delay to ensure data is fully loaded and UI can update
            await Future.delayed(const Duration(milliseconds: 200));
          } catch (e) {
            debugPrint('Error syncing data from server after login: $e');
            // Continue anyway - user can still use the app
          }

          // Mark that user has now logged in (after dialog check)
          await prefs.setBool('was_previously_logged_in', true);

          // Ensure AuthState is properly set before navigation
          debugPrint('Before navigation - AuthState: isLoggedIn=${AuthState.isLoggedIn.value}, userName=${AuthState.userName.value}, email=${AuthState.userEmail.value}');
          debugPrint('Tasks count: ${allTasks.length}, Categories count: ${allCategories.length}');

          // Small delay to ensure state is fully updated
          await Future.delayed(const Duration(milliseconds: 100));

          // Close any remaining dialogs before navigation
          if (Get.isDialogOpen ?? false) {
            Get.back();
            await Future.delayed(const Duration(milliseconds: 100));
          }

          // Navigate to main app
          Get.offAll(() => const NavbarController());

          // Force a rebuild by refreshing AuthState (ensures UI updates)
          await Future.delayed(const Duration(milliseconds: 300));
          AuthState.refresh();
          debugPrint('AuthState refreshed after navigation - userName=${AuthState.userName.value}, tasks=${allTasks.length}');

          // Show welcome message after navigation (only once)
          if (!_hasShownWelcome && mounted) {
            _hasShownWelcome = true;
            await Future.delayed(const Duration(milliseconds: 300));
            final userName = AuthState.userName.value;
            final displayName = userName.isNotEmpty && userName != 'User'
                ? userName
                : (AuthState.userEmail.value.isNotEmpty
                    ? AuthState.userEmail.value.split('@').first
                    : 'User');
            Get.snackbar(
              'Welcome Back! 👋',
              'Welcome back, $displayName! Your data has been restored.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green[600]?.withOpacity(0.9),
              colorText: Colors.white,
              icon: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 28,
              ),
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
              isDismissible: true,
              dismissDirection: DismissDirection.horizontal,
              forwardAnimationCurve: Curves.easeOutBack,
            );
          }
        } else if (shouldProceed == false) {
          // User explicitly cancelled - sign them out
          debugPrint('User cancelled login dialog');
          try {
            await client.modules.serverpod_auth_core.status.signOutDevice();
            await AuthState.logout();
            Get.snackbar(
              'Login Cancelled',
              'You have been signed out. Your local data remains unchanged.',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 3),
            );
          } catch (e) {
            debugPrint('Error signing out after cancellation: $e');
          }
        } else {
          // Dialog was dismissed or route was removed - don't logout, just return
          debugPrint('Dialog was dismissed (shouldProceed is null) - not logging out');
          return; // Exit the callback without doing anything
        }
      } else if (hasExistingData) {
        // Existing account - sync from server
        // This handles:
        // - Switching between existing accounts (no dialog needed)
        // - Existing account with no local data
        // - Previously logged in user logging into existing account
        debugPrint('Existing account detected - clearing guest data and syncing from server');

        // Clear guest data before loading server data
        allTasks.clear();
        // Clear only user-created categories (preserve defaults)
        final defaultCategoryIds = ['work', 'personal', 'health', 'finance', 'general'];
        allCategories.removeWhere((cat) => !defaultCategoryIds.contains(cat.id));
        // Reset notification settings
        NotificationState.notificationsEnabled.value = false;
        NotificationState.sleepModeEnabled.value = false;

        try {
          await ServerSyncService.syncAllFromServer();
          debugPrint('Data synced from server after login (existing account)');
        } catch (e) {
          debugPrint('Error syncing data from server after login: $e');
          // Continue anyway - user can still use the app
        }

        // Mark that user has now logged in
        await prefs.setBool('was_previously_logged_in', true);

        // Ensure AuthState is properly set before navigation
        debugPrint('Before navigation - AuthState: isLoggedIn=${AuthState.isLoggedIn.value}, userName=${AuthState.userName.value}, email=${AuthState.userEmail.value}');

        // Small delay to ensure state is fully updated
        await Future.delayed(const Duration(milliseconds: 100));

        // Close loading dialog right before navigation
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        // Navigate to main app
        Get.offAll(() => const NavbarController());

        // Force a rebuild by refreshing AuthState (ensures UI updates)
        await Future.delayed(const Duration(milliseconds: 300));
        AuthState.refresh();
        debugPrint('AuthState refreshed after navigation - userName=${AuthState.userName.value}, tasks=${allTasks.length}');

        // Show welcome message after navigation (only once)
        if (!_hasShownWelcome && mounted) {
          _hasShownWelcome = true;
          await Future.delayed(const Duration(milliseconds: 300));
          final userName = AuthState.userName.value;
          final displayName = userName.isNotEmpty && userName != 'User'
              ? userName
              : (AuthState.userEmail.value.isNotEmpty
                  ? AuthState.userEmail.value.split('@').first
                  : 'User');
          Get.snackbar(
            'Welcome Back! 👋',
            'Welcome back, $displayName! Your data has been restored.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green[600]?.withOpacity(0.9),
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle, color: Colors.white, size: 28),
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            isDismissible: true,
            dismissDirection: DismissDirection.horizontal,
            forwardAnimationCurve: Curves.easeOutBack,
          );
        }
      } else {
        // New account (no existing data on server)
        // This handles:
        // - Guest user with tasks logging into a new account → sync local tasks to server, then clear and reload
        // - New user with no local data → just create account
        debugPrint('New account detected - syncing local data to server (guest with tasks or new user)');
        try {
          // Verify user is logged in before syncing
          if (!AuthState.isLoggedIn.value) {
            debugPrint('Error: User not logged in when trying to sync to server');
            throw Exception('User not logged in');
          }

          // Verify session is valid
          try {
            final verifyProfile = await client.modules.serverpod_auth_core.userProfileInfo.get();
            debugPrint('Session verified for new account: ${verifyProfile.email ?? verifyProfile.userName}');
          } catch (e) {
            debugPrint('Session verification failed for new account: $e');
            throw Exception('Session verification failed');
          }

          // Sync local guest data to server first (preserve guest data)
          await ServerSyncService.syncAllToServer();
          debugPrint('Local guest data synced to server after login (new account)');

          // Now clear guest Hive data and reload from server to ensure consistency
          debugPrint('Clearing guest data and reloading from server...');
          allTasks.clear();
          // Clear only user-created categories (preserve defaults)
          final defaultCategoryIds = ['work', 'personal', 'health', 'finance', 'general'];
          allCategories.removeWhere((cat) => !defaultCategoryIds.contains(cat.id));
          // Reset notification settings
          NotificationState.notificationsEnabled.value = false;
          NotificationState.sleepModeEnabled.value = false;

          // Now sync from server to load the data we just saved
          await ServerSyncService.syncAllFromServer();
          debugPrint('Data reloaded from server after clearing guest data');
        } catch (e) {
          debugPrint('Error syncing local data to server after login: $e');
          debugPrint('Stack trace: ${StackTrace.current}');
          // Continue anyway - user can still use the app
        }

        // Mark that user has now logged in
        await prefs.setBool('was_previously_logged_in', true);

        // Ensure AuthState is properly set before navigation
        debugPrint('Before navigation - AuthState: isLoggedIn=${AuthState.isLoggedIn.value}, userName=${AuthState.userName.value}, email=${AuthState.userEmail.value}');

        // Small delay to ensure state is fully updated
        await Future.delayed(const Duration(milliseconds: 100));

        // Close loading dialog right before navigation
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        // Navigate to main app
        Get.offAll(() => const NavbarController());

        // Force a rebuild by refreshing AuthState (ensures UI updates)
        await Future.delayed(const Duration(milliseconds: 300));
        AuthState.refresh();
        debugPrint('AuthState refreshed after navigation - userName=${AuthState.userName.value}, tasks=${allTasks.length}');

        // Show welcome message after navigation (only once)
        if (!_hasShownWelcome && mounted) {
          _hasShownWelcome = true;
          await Future.delayed(const Duration(milliseconds: 300));
          final userName = AuthState.userName.value;
          final displayName = userName.isNotEmpty && userName != 'User'
              ? userName
              : (AuthState.userEmail.value.isNotEmpty
                  ? AuthState.userEmail.value.split('@').first
                  : 'User');
          Get.snackbar(
            'Welcome! 👋',
            'Welcome, $displayName! Your data has been synced to your account.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green[600]?.withOpacity(0.9),
            colorText: Colors.white,
            icon: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 28,
            ),
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            isDismissible: true,
            dismissDirection: DismissDirection.horizontal,
            forwardAnimationCurve: Curves.easeOutBack,
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _handleAuthSuccess: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      // Ensure processing flag is reset on error
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar(
        'Error',
        'Authentication failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF070A12), Color(0xFF10162F), Color(0xFF1C1444)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Version
              const Positioned(
                top: 16,
                right: 16,
                child: Text(
                  'v1.0.4',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),

              // Main content
              Column(
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    "assets/splashWhite.png",
                    height: 180,
                    width: 180,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Future of AI Productivity',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const Spacer(),

                  // Glass card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Google Sign-In button
                              _SocialButton(
                                text: 'Continue with Google',
                                icon: Image.asset(
                                  'assets/google.png',
                                  height: 22,
                                ),
                                backgroundColor: Colors.white,
                                textColor: Colors.black,
                                onTap: () async {
                                  try {
                                    
                                    // First, sign out any existing session to ensure clean login
                                    try {
                                      // Clear local auth state first
                                      AuthState.isLoggedIn.value = false;
                                      AuthState.userName.value = 'Kevin';
                                      AuthState.userEmail.value = '';
                                      AuthState.profileImageUrl.value = '';
                                      
                                      // Sign out from server
                                      await client.modules.serverpod_auth_core.status.signOutDevice();
                                      debugPrint('Signed out previous session before new login');
                                      
                                      // Clear SharedPreferences login flag
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setBool('is_logged_in', false);
                                      
                                      // Small delay to ensure session is cleared
                                      await Future.delayed(const Duration(milliseconds: 300));
                                    } catch (e) {
                                      debugPrint('No previous session to sign out: $e');
                                      // Continue anyway - might not have a previous session
                                    }
                                    
                                    // Prevent multiple sign-in attempts
                                    if (isProcessing) {
                                      debugPrint('Sign-in already in progress, skipping...');
                                      return;
                                    }
                                    isProcessing = true;
                                    _hasShownWelcome = false; // Reset welcome flag for new login
                                    
                                    // Show loading indicator with Lottie animation
                                    Get.dialog(
                                      Center(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 20,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: Lottie.asset(
                                            'assets/quickLoad.json',
                                            width: 135,
                                            height: 135,
                                            fit: BoxFit.contain,
                                            repeat: true,
                                          ),
                                        ),
                                      ),
                                      barrierDismissible: false,
                                    );

                                    // Create Google auth controller
                                    final googleAuthController = GoogleAuthController(
                                      client: client,
                                      onAuthenticated: () async {
                                        // Prevent multiple executions
                                        if (!isProcessing) {
                                          debugPrint('onAuthenticated called but not processing, skipping...');
                                          return;
                                        }
                                        
                                        try {
                                          // Keep loading dialog open during all processing
                                          // It will be closed right before navigation

                                        // Get user info from the authenticated session
                                        // Add a small delay to ensure profile is created on server
                                        await Future.delayed(const Duration(milliseconds: 500));
                                        
                                        try {
                                          // Fetch user profile from the server with retry logic
                                          dynamic userProfile;
                                          int retryCount = 0;
                                          const maxRetries = 3;
                                          
                                          while (retryCount < maxRetries) {
                                            try {
                                              userProfile = await client.modules.serverpod_auth_core.userProfileInfo.get();
                                              debugPrint('Fetched user profile (attempt ${retryCount + 1}): userName=${userProfile.userName}, email=${userProfile.email}, fullName=${userProfile.fullName}');
                                              
                                              // Check if profile has meaningful data
                                              if (userProfile.email != null && userProfile.email!.isNotEmpty) {
                                                break; // Profile is populated, exit retry loop
                                              }
                                              
                                              if (retryCount < maxRetries - 1) {
                                                debugPrint('Profile empty, retrying in 1 second...');
                                                await Future.delayed(const Duration(seconds: 1));
                                              }
                                              retryCount++;
                                            } catch (e) {
                                              debugPrint('Error fetching profile (attempt ${retryCount + 1}): $e');
                                              if (retryCount < maxRetries - 1) {
                                                await Future.delayed(const Duration(seconds: 1));
                                              }
                                              retryCount++;
                                            }
                                          }
                                          
                                          if (userProfile == null) {
                                            throw Exception('Failed to fetch user profile after $maxRetries attempts');
                                          }
                                          
                                          // Extract user information
                                          final userName = userProfile.userName ?? 
                                                          userProfile.fullName ?? 
                                                          (userProfile.email?.split('@').first ?? 'User');
                                          final userEmail = userProfile.email ?? '';
                                          
                                          debugPrint('Extracted user info: userName=$userName, userEmail=$userEmail');
                                          
                                          if (userName.isEmpty || userName == 'User') {
                                            debugPrint('Warning: User name is empty or default, using email: $userEmail');
                                          }
                                          
                                          if (userEmail.isEmpty) {
                                            debugPrint('ERROR: User email is empty! Profile may not be properly created.');
                                          }
                                          
                                          // Fix image URL - replace localhost with actual server URL
                                          String imageUrl = '';
                                          if (userProfile.imageUrl != null) {
                                            final imageUri = userProfile.imageUrl!;
                                            // Replace localhost with the actual server host
                                            final serverUri = Uri.parse(serverUrl);
                                            imageUrl = Uri(
                                              scheme: serverUri.scheme,
                                              host: serverUri.host,
                                              port: serverUri.port,
                                              path: imageUri.path,
                                              query: imageUri.query,
                                            ).toString();
                                          }
                                          
                                          // Update auth state with actual user info from Google
                                          AuthState.login(
                                            userName,
                                            userEmail,
                                            imageUrl, // Empty string if no image - will show person icon
                                          );
                                          
                                          debugPrint('AuthState updated: userName=${AuthState.userName.value}, userEmail=${AuthState.userEmail.value}');
                                        } catch (e) {
                                          // Fallback on error - use defaults
                                          debugPrint('Error fetching user profile: $e');
                                          debugPrint('Stack trace: ${StackTrace.current}');
                                          AuthState.login('User', '', ''); // Empty image URL - will show person icon
                                        }

                                        // Ensure we have valid user info before proceeding
                                        if (AuthState.userName.value.isEmpty || AuthState.userName.value == 'User') {
                                          debugPrint('Warning: User name is still default, attempting to fetch again...');
                                          try {
                                            final retryProfile = await client.modules.serverpod_auth_core.userProfileInfo.get();
                                            final retryName = retryProfile.userName ?? 
                                                             retryProfile.fullName ?? 
                                                             (retryProfile.email?.split('@').first ?? 'User');
                                            final retryEmail = retryProfile.email ?? '';
                                            AuthState.login(retryName, retryEmail, '');
                                            debugPrint('Retry successful: $retryName, $retryEmail');
                                          } catch (e) {
                                            debugPrint('Retry failed: $e');
                                          }
                                        }
                                        
                                        // Save login state (but don't set was_previously_logged_in yet - check it first)
                                        final prefs = await SharedPreferences.getInstance();
                                        await prefs.setBool('has_skipped_intro', true);
                                        await prefs.setBool('is_logged_in', true);
                                        // Also save user info for debugging
                                        await prefs.setString('saved_user_name', AuthState.userName.value);
                                        await prefs.setString('saved_user_email', AuthState.userEmail.value);

                                        // Check if account has existing data on server
                                        final hasExistingData = await ServerSyncService.hasExistingAccountData();
                                        debugPrint('Account has existing data: $hasExistingData');
                                        
                                        // Check if user has local tasks (guest mode tasks)
                                        final hasLocalTasks = allTasks.isNotEmpty;
                                        debugPrint('User has local tasks: $hasLocalTasks');
                                        
                                        // Show dialog if:
                                        // 1. User has local tasks (guest mode tasks)
                                        // 2. Account has existing data on server (existing account)
                                        // This means: Guest user with tasks logging into an existing account
                                        if (hasLocalTasks && hasExistingData) {
                                          // Guest user with tasks trying to login to existing account - show warning dialog
                                          debugPrint('Showing dialog: User with local tasks logging into existing account');
                                          final shouldProceed = await Get.dialog<bool>(
                                              Dialog(
                                                backgroundColor: Colors.transparent,
                                                child: Container(
                                                  padding: const EdgeInsets.all(24),
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [
                                                        Color(0xFF070A12),
                                                        Color(0xFF10162F),
                                                        Color(0xFF1C1444),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius: BorderRadius.circular(20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.3),
                                                        blurRadius: 20,
                                                        spreadRadius: 5,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      // Icon
                                                      Container(
                                                        padding: const EdgeInsets.all(16),
                                                        decoration: BoxDecoration(
                                                          color: Colors.orangeAccent.withOpacity(0.2),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.warning_rounded,
                                                          color: Colors.orangeAccent,
                                                          size: 40,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 20),
                                                      // Title
                                                      const Text(
                                                        'Account Already Exists',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 22,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      const SizedBox(height: 16),
                                                      // Content
                                                      Text(
                                                        'This account already has data saved on the server. If you continue, all your current local tasks will be replaced with the data from your account.',
                                                        style: TextStyle(
                                                          color: Colors.white.withOpacity(0.8),
                                                          fontSize: 14,
                                                          height: 1.5,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      const SizedBox(height: 24),
                                                      // Buttons
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: [
                                                          // Cancel Button
                                                          Expanded(
                                                            child: TextButton(
                                                              onPressed: () => Get.back(result: false),
                                                              style: TextButton.styleFrom(
                                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  side: BorderSide(
                                                                    color: Colors.white.withOpacity(0.3),
                                                                    width: 1.5,
                                                                  ),
                                                                ),
                                                              ),
                                                              child: const Text(
                                                                'Cancel',
                                                                style: TextStyle(
                                                                  color: Colors.white70,
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          // Continue Button
                                                          Expanded(
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                gradient: const LinearGradient(
                                                                  colors: [
                                                                    Color(0xFF1E88E5),
                                                                    Color(0xFF1565C0),
                                                                  ],
                                                                ),
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              child: TextButton(
                                                                onPressed: () => Get.back(result: true),
                                                                style: TextButton.styleFrom(
                                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(12),
                                                                  ),
                                                                ),
                                                                child: const Text(
                                                                  'Continue',
                                                                  style: TextStyle(
                                                                    color: Colors.white,
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              barrierDismissible: false,
                                            );
                                            
                                            // Ensure dialog result is not null (Get.back might return null if route is removed)
                                            if (shouldProceed == true) {
                                              debugPrint('User confirmed to proceed with login');
                                              // Clear guest data before loading server data
                                              debugPrint('Clearing guest data before loading server data...');
                                              allTasks.clear();
                                              // Clear only user-created categories (preserve defaults)
                                              final defaultCategoryIds = ['work', 'personal', 'health', 'finance', 'general'];
                                              allCategories.removeWhere((cat) => !defaultCategoryIds.contains(cat.id));
                                              // Reset notification settings
                                              NotificationState.notificationsEnabled.value = false;
                                              NotificationState.sleepModeEnabled.value = false;
                                              
                                              // User confirmed - sync from server (replacing local data)
                                              try {
                                                await ServerSyncService.syncAllFromServer();
                                                debugPrint('Data synced from server after login (existing account)');
                                                
                                                // Small delay to ensure data is fully loaded and UI can update
                                                await Future.delayed(const Duration(milliseconds: 200));
                                              } catch (e) {
                                                debugPrint('Error syncing data from server after login: $e');
                                                // Continue anyway - user can still use the app
                                              }
                                              
                                              // Mark that user has now logged in (after dialog check)
                                              await prefs.setBool('was_previously_logged_in', true);
                                              
                                              // Ensure AuthState is properly set before navigation
                                              debugPrint('Before navigation - AuthState: isLoggedIn=${AuthState.isLoggedIn.value}, userName=${AuthState.userName.value}, email=${AuthState.userEmail.value}');
                                              debugPrint('Tasks count: ${allTasks.length}, Categories count: ${allCategories.length}');
                                              
                                              // Small delay to ensure state is fully updated
                                              await Future.delayed(const Duration(milliseconds: 100));
                                              
                                              // Close any remaining dialogs before navigation
                                              if (Get.isDialogOpen ?? false) {
                                                Get.back();
                                                await Future.delayed(const Duration(milliseconds: 100));
                                              }
                                              
                                              // Navigate to main app
                                              Get.offAll(() => const NavbarController());
                                              
                                              // Force a rebuild by refreshing AuthState (ensures UI updates)
                                              await Future.delayed(const Duration(milliseconds: 300));
                                              AuthState.refresh();
                                              debugPrint('AuthState refreshed after navigation - userName=${AuthState.userName.value}, tasks=${allTasks.length}');
                                              
                                              // Show welcome message after navigation (only once)
                                              if (!_hasShownWelcome) {
                                                _hasShownWelcome = true;
                                                await Future.delayed(const Duration(milliseconds: 300));
                                                final userName = AuthState.userName.value;
                                                final displayName = userName.isNotEmpty && userName != 'User' 
                                                    ? userName 
                                                    : (AuthState.userEmail.value.isNotEmpty 
                                                        ? AuthState.userEmail.value.split('@').first 
                                                        : 'User');
                                                Get.snackbar(
                                                  'Welcome Back! 👋',
                                                  'Welcome back, $displayName! Your data has been restored.',
                                                  snackPosition: SnackPosition.BOTTOM,
                                                  backgroundColor: Colors.green[600]?.withOpacity(0.9),
                                                  colorText: Colors.white,
                                                  icon: const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                    size: 28,
                                                  ),
                                                  duration: const Duration(seconds: 3),
                                                  margin: const EdgeInsets.all(16),
                                                  borderRadius: 12,
                                                  isDismissible: true,
                                                  dismissDirection: DismissDirection.horizontal,
                                                  forwardAnimationCurve: Curves.easeOutBack,
                                                );
                                              }
                                            } else if (shouldProceed == false) {
                                              // User explicitly cancelled - sign them out
                                              debugPrint('User cancelled login dialog');
                                              try {
                                                await client.modules.serverpod_auth_core.status.signOutDevice();
                                                await AuthState.logout();
                                                Get.snackbar(
                                                  'Login Cancelled',
                                                  'You have been signed out. Your local data remains unchanged.',
                                                  snackPosition: SnackPosition.BOTTOM,
                                                  duration: const Duration(seconds: 3),
                                                );
                                              } catch (e) {
                                                debugPrint('Error signing out after cancellation: $e');
                                              }
                                            } else {
                                              // Dialog was dismissed or route was removed - don't logout, just return
                                              debugPrint('Dialog was dismissed (shouldProceed is null) - not logging out');
                                              return; // Exit the callback without doing anything
                                            }
                                        } else if (hasExistingData) {
                                          // Existing account - sync from server
                                          // This handles:
                                          // - Switching between existing accounts (no dialog needed)
                                          // - Existing account with no local data
                                          // - Previously logged in user logging into existing account
                                          debugPrint('Existing account detected - clearing guest data and syncing from server');
                                          
                                          // Clear guest data before loading server data
                                          allTasks.clear();
                                          // Clear only user-created categories (preserve defaults)
                                          final defaultCategoryIds = ['work', 'personal', 'health', 'finance', 'general'];
                                          allCategories.removeWhere((cat) => !defaultCategoryIds.contains(cat.id));
                                          // Reset notification settings
                                          NotificationState.notificationsEnabled.value = false;
                                          NotificationState.sleepModeEnabled.value = false;
                                          
                                          try {
                                            await ServerSyncService.syncAllFromServer();
                                            debugPrint('Data synced from server after login (existing account)');
                                          } catch (e) {
                                            debugPrint('Error syncing data from server after login: $e');
                                            // Continue anyway - user can still use the app
                                          }
                                          
                                          // Mark that user has now logged in
                                          await prefs.setBool('was_previously_logged_in', true);
                                          
                                          // Ensure AuthState is properly set before navigation
                                          debugPrint('Before navigation - AuthState: isLoggedIn=${AuthState.isLoggedIn.value}, userName=${AuthState.userName.value}, email=${AuthState.userEmail.value}');
                                          
                                          // Small delay to ensure state is fully updated
                                          await Future.delayed(const Duration(milliseconds: 100));
                                          
                                          // Close loading dialog right before navigation
                                          if (Get.isDialogOpen ?? false) {
                                            Get.back();
                                          }
                                          
                                          // Navigate to main app
                                          Get.offAll(() => const NavbarController());
                                          
                                          // Force a rebuild by refreshing AuthState (ensures UI updates)
                                          await Future.delayed(const Duration(milliseconds: 300));
                                          AuthState.refresh();
                                          debugPrint('AuthState refreshed after navigation - userName=${AuthState.userName.value}, tasks=${allTasks.length}');
                                          
                                          // Show welcome message after navigation (only once)
                                          if (!_hasShownWelcome) {
                                            _hasShownWelcome = true;
                                            await Future.delayed(const Duration(milliseconds: 300));
                                            final userName = AuthState.userName.value;
                                            final displayName = userName.isNotEmpty && userName != 'User' 
                                                ? userName 
                                                : (AuthState.userEmail.value.isNotEmpty 
                                                    ? AuthState.userEmail.value.split('@').first 
                                                    : 'User');
                                            Get.snackbar(
                                              'Welcome Back! 👋',
                                              'Welcome back, $displayName! Your data has been restored.',
                                              snackPosition: SnackPosition.BOTTOM,
                                              backgroundColor: Colors.green[600]?.withOpacity(0.9),
                                              colorText: Colors.white,
                                              icon: const Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                              duration: const Duration(seconds: 3),
                                              margin: const EdgeInsets.all(16),
                                              borderRadius: 12,
                                              isDismissible: true,
                                              dismissDirection: DismissDirection.horizontal,
                                              forwardAnimationCurve: Curves.easeOutBack,
                                            );
                                          }
                                        } else {
                                          // New account (no existing data on server)
                                          // This handles:
                                          // - Guest user with tasks logging into a new account → sync local tasks to server, then clear and reload
                                          // - New user with no local data → just create account
                                          debugPrint('New account detected - syncing local data to server (guest with tasks or new user)');
                                          try {
                                            // Verify user is logged in before syncing
                                            if (!AuthState.isLoggedIn.value) {
                                              debugPrint('Error: User not logged in when trying to sync to server');
                                              throw Exception('User not logged in');
                                            }
                                            
                                            // Verify session is valid
                                            try {
                                              final verifyProfile = await client.modules.serverpod_auth_core.userProfileInfo.get();
                                              debugPrint('Session verified for new account: ${verifyProfile.email ?? verifyProfile.userName}');
                                            } catch (e) {
                                              debugPrint('Session verification failed for new account: $e');
                                              throw Exception('Session verification failed');
                                            }
                                            
                                            // Sync local guest data to server first (preserve guest data)
                                            await ServerSyncService.syncAllToServer();
                                            debugPrint('Local guest data synced to server after login (new account)');
                                            
                                            // Now clear guest Hive data and reload from server to ensure consistency
                                            debugPrint('Clearing guest data and reloading from server...');
                                            allTasks.clear();
                                            // Clear only user-created categories (preserve defaults)
                                            final defaultCategoryIds = ['work', 'personal', 'health', 'finance', 'general'];
                                            allCategories.removeWhere((cat) => !defaultCategoryIds.contains(cat.id));
                                            // Reset notification settings
                                            NotificationState.notificationsEnabled.value = false;
                                            NotificationState.sleepModeEnabled.value = false;
                                            
                                            // Now sync from server to load the data we just saved
                                            await ServerSyncService.syncAllFromServer();
                                            debugPrint('Data reloaded from server after clearing guest data');
                                          } catch (e) {
                                            debugPrint('Error syncing local data to server after login: $e');
                                            debugPrint('Stack trace: ${StackTrace.current}');
                                            // Continue anyway - user can still use the app
                                          }
                                          
                                          // Mark that user has now logged in
                                          await prefs.setBool('was_previously_logged_in', true);
                                          
                                          // Ensure AuthState is properly set before navigation
                                          debugPrint('Before navigation - AuthState: isLoggedIn=${AuthState.isLoggedIn.value}, userName=${AuthState.userName.value}, email=${AuthState.userEmail.value}');
                                          
                                          // Small delay to ensure state is fully updated
                                          await Future.delayed(const Duration(milliseconds: 100));
                                          
                                          // Close loading dialog right before navigation
                                          if (Get.isDialogOpen ?? false) {
                                            Get.back();
                                          }
                                          
                                          // Navigate to main app
                                          Get.offAll(() => const NavbarController());
                                          
                                              // Force a rebuild by refreshing AuthState (ensures UI updates)
                                              await Future.delayed(const Duration(milliseconds: 300));
                                              AuthState.refresh();
                                              debugPrint('AuthState refreshed after navigation - userName=${AuthState.userName.value}, tasks=${allTasks.length}');
                                          
                                          // Show welcome message after navigation (only once)
                                          if (!_hasShownWelcome) {
                                            _hasShownWelcome = true;
                                            await Future.delayed(const Duration(milliseconds: 300));
                                            final userName = AuthState.userName.value;
                                            final displayName = userName.isNotEmpty && userName != 'User' 
                                                ? userName 
                                                : (AuthState.userEmail.value.isNotEmpty 
                                                    ? AuthState.userEmail.value.split('@').first 
                                                    : 'User');
                                            Get.snackbar(
                                              'Welcome! 👋',
                                              'Welcome, $displayName! Your data has been synced to your account.',
                                              snackPosition: SnackPosition.BOTTOM,
                                              backgroundColor: Colors.green[600]?.withOpacity(0.9),
                                              colorText: Colors.white,
                                              icon: const Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                              duration: const Duration(seconds: 3),
                                              margin: const EdgeInsets.all(16),
                                              borderRadius: 12,
                                              isDismissible: true,
                                              dismissDirection: DismissDirection.horizontal,
                                              forwardAnimationCurve: Curves.easeOutBack,
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        debugPrint('Error in onAuthenticated callback: $e');
                                        debugPrint('Stack trace: ${StackTrace.current}');
                                      } finally {
                                        // Reset processing flag after completion
                                        isProcessing = false;
                                      }
                                    },
                                      onError: (error) {
                                        // Reset processing flag on error
                                        isProcessing = false;
                                        
                                        // Close loading dialog
                                        if (Get.isDialogOpen ?? false) {
                                          Get.back();
                                        }
                                        Get.snackbar(
                                          'Error',
                                          'Sign in failed: ${error.toString()}',
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      },
                                    );

                                    // Initiate sign-in
                                    try {
                                      await googleAuthController.signIn();
                                      
                                      // Check if sign-in completed but didn't trigger callbacks (user canceled)
                                      // Wait a brief moment for callbacks to fire, then check
                                      await Future.delayed(const Duration(milliseconds: 300));
                                      if (isProcessing) {
                                        // If flag is still set and dialog is closed, user likely canceled
                                        if (!(Get.isDialogOpen ?? false)) {
                                          isProcessing = false;
                                          debugPrint('Sign-in appears to have been canceled, resetting flag');
                                        }
                                      }
                                    } catch (e) {
                                      // Reset processing flag on error/cancellation
                                      isProcessing = false;
                                      
                                      // Close loading dialog if still open
                                      if (Get.isDialogOpen ?? false) {
                                        Get.back();
                                      }
                                      
                                      // Only show error snackbar if it's not a cancellation
                                      if (!e.toString().toLowerCase().contains('cancel')) {
                                        Get.snackbar(
                                          'Error',
                                          'Sign in failed: ${e.toString()}',
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      }
                                    }
                                  } catch (outerError) {
                                    // Handle any unexpected errors in the outer try block
                                    isProcessing = false;
                                    if (Get.isDialogOpen ?? false) {
                                      Get.back();
                                    }
                                    debugPrint('Unexpected error during sign-in: $outerError');
                                    Get.snackbar(
                                      'Error',
                                      'Sign in failed: ${outerError.toString()}',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  }
                                },
                              ),

                              const SizedBox(height: 12),

                              // Apple Sign-In button (iOS only)
                              // Note: serverpod_auth_apple_flutter uses a different Caller type (serverpod_auth_client)
                              // than what Serverpod 3.2.3 uses (serverpod_auth_idp_client), so it's not compatible
                              // We're using the direct approach with client.appleIdp.login() which should work
                              // once FlutterAuthSessionManager properly processes the AuthSuccess response
                              if (Platform.isIOS) ...[
                              _SocialButton(
                                text: 'Continue with Apple',
                                icon: const Icon(
                                  Icons.apple,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                backgroundColor: Colors.black,
                                textColor: Colors.white,
                                onTap: () async {
                                  try {
                                    // First, sign out any existing session to ensure clean login
                                    try {
                                      AuthState.isLoggedIn.value = false;
                                      AuthState.userName.value = 'Kevin';
                                      AuthState.userEmail.value = '';
                                      AuthState.profileImageUrl.value = '';
                                      await client.modules.serverpod_auth_core.status.signOutDevice();
                                      debugPrint('Signed out previous session before new Apple login');
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setBool('is_logged_in', false);
                                      await Future.delayed(const Duration(milliseconds: 300));
                                    } catch (e) {
                                      debugPrint('No previous session to sign out for Apple: $e');
                                    }
                                    
                                    if (isProcessing) {
                                      debugPrint('Apple Sign-in already in progress, skipping...');
                                      return;
                                    }
                                    if (mounted) {
                                      setState(() {
                                        isProcessing = true;
                                        _hasShownWelcome = false;
                                      });
                                    }
                                    
                                    Get.dialog(
                                      Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 20,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: Lottie.asset(
                                            'assets/quickLoad.json',
                                            width: 200,
                                            height: 200,
                                            fit: BoxFit.contain,
                                            repeat: true,
                                          ),
                                        ),
                                      ),
                                      barrierDismissible: false,
                                    );
                                    
                                    // Request Apple Sign-In credentials
                                    final appleCredential = await SignInWithApple.getAppleIDCredential(
                                      scopes: [
                                        AppleIDAuthorizationScopes.email,
                                        AppleIDAuthorizationScopes.fullName,
                                      ],
                                    );
                                    
                                    final userIdentifier = appleCredential.userIdentifier;
                                    debugPrint('Apple Sign-In successful - userIdentifier: $userIdentifier');
                                    
                                    // Get Apple credentials - these are non-null after successful sign-in
                                    // The type system marks them as nullable, but they're always present after successful sign-in
                                    final identityToken = appleCredential.identityToken!;
                                    final authorizationCode = appleCredential.authorizationCode!;
                                    
                                    // Authenticate with Serverpod Apple IDP
                                    // This should return AuthSuccess which FlutterAuthSessionManager processes automatically
                                    await client.appleIdp.login(
                                      identityToken: identityToken,
                                      authorizationCode: authorizationCode,
                                      isNativeApplePlatformSignIn: true,
                                      firstName: appleCredential.givenName,
                                      lastName: appleCredential.familyName,
                                    );
                                    
                                    debugPrint('✅ Serverpod authentication successful');
                                    
                                    // The session should now be established by FlutterAuthSessionManager
                                    // Wait a moment and then proceed with auth success handling
                                    await Future.delayed(const Duration(milliseconds: 500));
                                    
                                    // Now handle the authenticated session
                                    await _handleAuthSuccess();
                                  } on SignInWithAppleAuthorizationException catch (e) {
                                    if (mounted) {
                                      setState(() {
                                        isProcessing = false;
                                      });
                                    }
                                    if (Get.isDialogOpen ?? false) {
                                      Get.back();
                                    }
                                    
                                    String errorMsg = 'Apple Sign-In failed';
                                    if (e.code == AuthorizationErrorCode.canceled) {
                                      errorMsg = 'Apple Sign-In was cancelled';
                                    } else if (e.code == AuthorizationErrorCode.failed) {
                                      errorMsg = 'Apple Sign-In failed. Please try again.';
                                    } else if (e.code == AuthorizationErrorCode.unknown) {
                                      errorMsg = 'Apple Sign-In configuration error. Please ensure "Sign in with Apple" capability is enabled in Xcode.';
                                    }
                                    
                                    Get.snackbar('Error', errorMsg, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() {
                                        isProcessing = false;
                                      });
                                    }
                                    if (Get.isDialogOpen ?? false) {
                                      Get.back();
                                    }
                                    debugPrint('Apple Sign-In error: $e');
                                    Get.snackbar(
                                      'Error',
                                      'Apple Sign-In failed: ${e.toString()}',
                                      snackPosition: SnackPosition.BOTTOM,
                                      duration: const Duration(seconds: 4),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              ],

                              const SizedBox(height: 16),

                              // OR divider
                              Row(
                                children: const [
                                  Expanded(
                                    child: Divider(color: Colors.white24),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: Colors.white24),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Skip for now
                              TextButton(
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setBool('has_skipped_intro', true);
                                  await prefs.setBool('has_skipped_login', true); // Mark that user skipped login
                                  Get.offAll(() => const NavbarController());
                                },
                                child: const Text(
                                  'Skip for now',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'By continuing, you agree to TWICK’s Terms of Service and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

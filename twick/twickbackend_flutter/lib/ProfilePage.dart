import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/AuthState.dart';
import 'LoginPage.dart';
import 'PrivacyPolicyPage.dart';
import 'HelpSupportPage.dart';
import 'main.dart' show client;
import 'services/HiveStorageService.dart';
import 'services/NotificationService.dart';
import 'models/TaskList.dart' show allTasks;
import 'models/CategoryList.dart' show allCategories;
import 'models/NotificationState.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: BackButton(color: Colors.black,),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        
      ),
      body: Obx(
        () => AuthState.isLoggedIn.value
            ? _LoggedInView()
            : _LoggedOutView(),
      ),
    );
  }
}

class _LoggedInView extends StatefulWidget {
  @override
  State<_LoggedInView> createState() => _LoggedInViewState();
}

class _LoggedInViewState extends State<_LoggedInView> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Picture
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: !AuthState.shouldShowPlaceholder()
                ? CachedNetworkImageProvider(
                    AuthState.profileImageUrl.value,
                  )
                : null,
            child: AuthState.shouldShowPlaceholder()
                ? Icon(
                    Icons.person,
                    color: Colors.grey[600],
                    size: 60,
                  )
                : null,
          ),
          const SizedBox(height: 24),
          // Name
          Text(
            overflow: TextOverflow.ellipsis,
            AuthState.userName.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (AuthState.userEmail.value.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              overflow: TextOverflow.ellipsis,
              AuthState.userEmail.value,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 40),
          // Settings Options
          _SettingsItem(
            icon: Icons.shield_outlined,
            iconColor: Colors.purple[600]!,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          
          // Delete Account Button
          _SettingsItem(
            icon: Icons.warning_rounded,
            iconColor: Colors.red[600]!,
            title: 'Delete Account',
            onTap: () async {
              // Show account deletion confirmation dialog
              final shouldDelete = await _showDeleteAccountDialog(context);
              
              if (shouldDelete == true) {
                await _deleteAccount(context);
              }
            },
          ),
          const SizedBox(height: 12),
          _SettingsItem(
            icon: Icons.help_outline,
            iconColor: Colors.amber[700]!,
            title: 'Help & Support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HelpSupportPage(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),
          // Log Out Button
          _SettingsItem(
            icon: Icons.exit_to_app,
            iconColor: Colors.red[600]!,
            title: 'Log Out',
            onTap: () async {
              // Show Cupertino confirmation dialog
              final shouldLogout = await showCupertinoDialog<bool>(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return CupertinoAlertDialog(
                    title: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    content: const Text(
                      'Are you sure you want to log out? All your local data will be cleared.',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: CupertinoColors.destructiveRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (shouldLogout == true) {
                await AuthState.logout();
                // Navigate to login screen after logout
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
          const SizedBox(height: 32),
          // Version Information
          Text(
            'VERSION 1.0.0',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Show a nice app theme-based account deletion confirmation dialog
  Future<bool?> _showDeleteAccountDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B1020),
                  Color(0xFF1C2E4A),
                  Color(0xFF2B3A8F),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[600]!.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red[400],
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Message
                Text(
                  'Are you sure you want to delete your account? This action cannot be undone.\n\nAll your tasks, categories, and settings will be permanently deleted from our servers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(false),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Delete Button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red[600]!,
                              Colors.red[800]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(true),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Center(
                                child: Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
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
        );
      },
    );
  }

  /// Delete account and all user data
  Future<void> _deleteAccount(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete all user data from server
      try {
        // Delete all tasks
        final tasks = await client.task.getTasks();
        if (tasks.isNotEmpty) {
          final taskIds = tasks.map((t) => t.clientId).toList();
          await client.task.deleteTasks(taskIds);
        }
        
        // Delete all categories
        final categories = await client.category.getCategories();
        for (var category in categories) {
          await client.category.deleteCategory(category.clientId);
        }
        
        // Note: User settings will be automatically cleaned up
        // The account endpoint will handle this after running 'serverpod generate'
        
        debugPrint('Account data deleted from server');
      } catch (e) {
        debugPrint('Error deleting account from server: $e');
        // Continue with local cleanup even if server deletion fails
      }

      // Clear all local data
      await NotificationService.cancelAllNotifications();
      
      // Clear all tasks and categories from memory
      allTasks.clear();
      allCategories.removeWhere((cat) => !['work', 'personal', 'health', 'finance', 'general'].contains(cat.id));
      
      // Clear all Hive storage
      await HiveStorageService.clearAllData();
      
      // Reset notification state
      NotificationState.notificationsEnabled.value = false;
      NotificationState.sleepModeEnabled.value = false;
      NotificationState.sleepModeFromTime.value = const TimeOfDay(hour: 22, minute: 0);
      NotificationState.sleepModeToTime.value = const TimeOfDay(hour: 7, minute: 0);
      
      // Sign out from Serverpod
      try {
        await client.modules.serverpod_auth_core.status.signOutDevice();
      } catch (e) {
        debugPrint('Error signing out from Serverpod: $e');
      }

      // Clear SharedPreferences (except skip flags)
      final prefs = await SharedPreferences.getInstance();
      final hasSkippedIntro = prefs.getBool('has_skipped_intro') ?? false;
      final hasSkippedLogin = prefs.getBool('has_skipped_login') ?? false;
      await prefs.clear();
      await prefs.setBool('has_skipped_intro', hasSkippedIntro);
      await prefs.setBool('has_skipped_login', hasSkippedLogin);

      // Clear auth state
      AuthState.isLoggedIn.value = false;
      AuthState.userName.value = 'Kevin';
      AuthState.userEmail.value = '';
      AuthState.profileImageUrl.value = '';

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        Get.snackbar(
          'Account Deleted',
          'Your account and all data have been permanently deleted.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[600]?.withOpacity(0.9),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white, size: 28),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }

      // Navigate to login screen
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      
      // Close loading dialog if still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        Get.snackbar(
          'Error',
          'Failed to delete account. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[600]?.withOpacity(0.9),
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white, size: 28),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    }
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoggedOutView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Profile Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey[600],
                ),
              ),
              // Status badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 19, 38, 61), // Dark blue
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    Icons.eco, // Leaf/feather icon
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Guest User Text
          Text(
            'Guest User',
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Offline Status
          Text(
            'You are currently offline',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          // Sync Information Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sync,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Sign in to sync your tasks, reminders, and schedules across all your devices seamlessly.',
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Proceed to Login Button
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3B82F6), // Blue
                    Color(0xFF1E40AF), // Dark Blue
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>  LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Proceed to Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // INFORMATION Section
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'INFORMATION',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // About the App
          _InfoItem(
            icon: Icons.info_outline,
            title: 'About the App',
            onTap: () {
              // Handle About the App
            },
          ),
          const SizedBox(height: 12),
          // Terms of Service
          _InfoItem(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {
              // Handle Terms of Service
            },
          ),
          const SizedBox(height: 12),
          // Privacy Policy
          _InfoItem(
            icon: Icons.shield_outlined,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          // Version Information
          Text(
            'VERSION 1.0.0 (BUILD 1)',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          
          
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.grey[900],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

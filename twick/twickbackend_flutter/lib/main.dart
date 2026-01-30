import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twickbackend_client/twickbackend_client.dart';
import 'package:twickbackend_flutter/SplashScreen.dart';
import 'package:twickbackend_flutter/models/AuthState.dart';
import 'package:twickbackend_flutter/models/NotificationState.dart';
import 'package:twickbackend_flutter/models/TaskList.dart';
import 'package:twickbackend_flutter/models/ConnectivityState.dart';
import 'package:twickbackend_flutter/services/HiveStorageService.dart';
import 'package:twickbackend_flutter/services/NotificationService.dart';
import 'package:twickbackend_flutter/services/ServerSyncService.dart';
import 'package:twickbackend_flutter/services/WidgetDataService.dart';
late final Client client;

late String serverUrl;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only do minimal initialization here - show splash screen immediately
  // All heavy initialization will happen in SplashScreen
  runApp(const Config());
}

// Initialize all services - called from SplashScreen
Future<void> initializeApp() async {
  // Gemini API key: pass at build time via --dart-define=GEMINI_API_KEY=your_key
  const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  if (geminiApiKey.isNotEmpty) {
    Gemini.init(apiKey: geminiApiKey);
  }

  await notificationInit();
  await HiveStorageService.init();
  await NotificationState.loadState();

  await Future.delayed(const Duration(milliseconds: 300));
  await WidgetDataService.syncTasksToWidget();

  serverUrl = await getServerUrl();
  client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();

  // Initialize auth system
  client.auth.initialize();
  
  // Initialize connectivity monitoring (must be before session restore)
  ConnectivityState.initialize();
  
  // Small delay to let connectivity check complete
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Restore user session if signed in
  await _restoreUserSession();
}

Future<void> notificationInit() async {
  // Initialize timezones first
  tz.initializeTimeZones();
  
  final timezoneInfo = await FlutterTimezone.getLocalTimezone();
  final ianaName = convertToIana(timezoneInfo.localizedName?.name ?? "");
  tz.setLocalLocation(tz.getLocation(ianaName));

  // Android initialization settings
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Register iOS notification categories with actions BEFORE initialization
  final DarwinNotificationCategory taskReminderCategory = DarwinNotificationCategory(
    'TASK_REMINDER',
    actions: <DarwinNotificationAction>[
      DarwinNotificationAction.plain(
        'snooze_action',
        'Snooze',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.foreground,
        },
      ),
      DarwinNotificationAction.plain(
        'dismiss_action',
        'Dismiss',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.destructive,
        },
      ),
    ],
  );

  final iosSettingsWithCategory = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    notificationCategories: [taskReminderCategory],
  );

  final initSettingsWithCategory = InitializationSettings(
    android: androidSettings,
    iOS: iosSettingsWithCategory,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettingsWithCategory,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint('Notification response received: action=${response.actionId}, payload=${response.payload}');
      // Play alarm when notification is received/tapped
      if (response.payload != null && response.payload!.isNotEmpty && response.actionId == null) {
        NotificationService.playAlarm();
      }
      _handleNotificationResponse(response);
    },
    onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationResponse,
  );

  // Create notification channel for Android (required before scheduling)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'task_reminders',
    'Task Reminders',
    description: 'Notifications for task reminders',
    importance: Importance.max, // Max importance for alarm
    playSound: true,
    enableVibration: true,
    sound: RawResourceAndroidNotificationSound('alarm'), // Use alarm.mp3
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Request iOS permissions
  final bool? iosGranted = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
  debugPrint('iOS notification permission granted: $iosGranted');

  // Request Android permissions (Android 13+)
  final bool? androidGranted = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  debugPrint('Android notification permission granted: $androidGranted');
}

// Handle notification response (actions and taps)
void _handleNotificationResponse(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) {
    debugPrint('No payload in notification response');
    return;
  }

  // Extract task ID from payload
  final parts = payload.split('|');
  final taskId = parts[0];

  // Handle action buttons
  if (response.actionId != null) {
    if (response.actionId == NotificationService.snoozeActionId) {
      debugPrint('Snooze action triggered for task: $taskId');
      NotificationService.snoozeNotification(taskId);
    } else if (response.actionId == NotificationService.dismissActionId) {
      debugPrint('Dismiss action triggered for task: $taskId');
      NotificationService.dismissNotification(taskId);
    }
  } else {
    // Notification was tapped or received
    debugPrint('Notification tapped/received for task: $taskId');
    
    // Check if this is a recurring task and reschedule it
    try {
      final task = allTasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () => throw Exception('Task not found: $taskId'),
      );
      
      // If recurring, always reschedule (even if completed)
      if (task.isRecurring) {
        debugPrint('Rescheduling recurring task: ${task.title}');
        NotificationService.rescheduleRecurringTask(task);
      }
    } catch (e) {
      debugPrint('Error handling recurring task reschedule: $e');
    }
  }
}

// Background notification handler (top-level function required)
@pragma('vm:entry-point')
void _handleBackgroundNotificationResponse(NotificationResponse response) {
  debugPrint('Background notification response: action=${response.actionId}, payload=${response.payload}');
  // Play alarm when notification is received in background
  if (response.payload != null && response.payload!.isNotEmpty && response.actionId == null) {
    NotificationService.playAlarm();
  }
  _handleNotificationResponse(response);
}

// Restore user session on app startup
Future<void> _restoreUserSession() async {
  // First, try to load cached user info (works offline)
  final cachedUserLoaded = await AuthState.loadCachedUserInfo();
  
  if (cachedUserLoaded) {
    debugPrint('Loaded cached user info - app will work offline');
    
    // If online, try to verify session and update user info
    if (ConnectivityState.isOnline.value) {
      try {
        // Check if user is signed in by trying to get their profile
        final userProfile = await client.modules.serverpod_auth_core.userProfileInfo.get();
        
        // User is signed in - update their information (may have changed)
        final userName = userProfile.userName ?? userProfile.fullName ?? 'User';
        final userEmail = userProfile.email ?? '';
        
        // Fix image URL - replace localhost with actual server URL
        String imageUrl = '';
        if (userProfile.imageUrl != null) {
          final imageUri = userProfile.imageUrl!;
          final serverUri = Uri.parse(serverUrl);
          imageUrl = Uri(
            scheme: serverUri.scheme,
            host: serverUri.host,
            port: serverUri.port,
            path: imageUri.path,
            query: imageUri.query,
          ).toString();
        }
        
        // Update auth state with fresh user info from server
        AuthState.login(
          userName,
          userEmail,
          imageUrl,
        );
        
        debugPrint('User session verified and updated from server: $userName');
        
        // Sync data from server after restoring session
        try {
          await ServerSyncService.syncAllFromServer();
          debugPrint('Data synced from server after session restoration');
          // Sync to widget after server sync
          await WidgetDataService.syncTasksToWidget();
        } catch (e) {
          debugPrint('Error syncing data from server: $e');
          // Continue anyway - user can still use local data
          // Still sync to widget with local data
          await WidgetDataService.syncTasksToWidget();
        }
      } catch (e) {
        // Check if it's a UserProfileNotFoundException (user authenticated but profile doesn't exist)
        final errorString = e.toString();
        if (errorString.contains('UserProfileNotFoundException')) {
          debugPrint('User profile not found on server - using cached info: $e');
          // Don't clear cached info - user might be offline or profile issue
        } else {
          debugPrint('Session verification failed - using cached info: $e');
          // Don't clear cached info - might be network issue
        }
        // Keep using cached user info - app works offline
      }
    } else {
      debugPrint('Offline - using cached user info');
    }
  } else {
    // No cached user info - check if user was logged in
    final prefs = await SharedPreferences.getInstance();
    final wasLoggedIn = prefs.getBool('is_logged_in') ?? false;
    
    if (!wasLoggedIn) {
      // User was not logged in - they're a guest user
      debugPrint('User was not logged in - keeping guest data intact');
      return;
    }
    
    // Was logged in but no cached info - try to restore from server if online
    if (ConnectivityState.isOnline.value) {
      try {
        // Check if user is signed in by trying to get their profile
        final userProfile = await client.modules.serverpod_auth_core.userProfileInfo.get();
        
        // User is signed in - restore their information
        final userName = userProfile.userName ?? userProfile.fullName ?? 'User';
        final userEmail = userProfile.email ?? '';
        
        // Fix image URL - replace localhost with actual server URL
        String imageUrl = '';
        if (userProfile.imageUrl != null) {
          final imageUri = userProfile.imageUrl!;
          final serverUri = Uri.parse(serverUrl);
          imageUrl = Uri(
            scheme: serverUri.scheme,
            host: serverUri.host,
            port: serverUri.port,
            path: imageUri.path,
            query: imageUri.query,
          ).toString();
        }
        
        // Update auth state with restored user info
        AuthState.login(
          userName,
          userEmail,
          imageUrl,
        );
        
        debugPrint('User session restored from server: $userName');
        
        // Sync data from server after restoring session
        try {
          await ServerSyncService.syncAllFromServer();
          debugPrint('Data synced from server after session restoration');
          // Sync to widget after server sync
          await WidgetDataService.syncTasksToWidget();
        } catch (e) {
          debugPrint('Error syncing data from server: $e');
          // Continue anyway - user can still use local data
          // Still sync to widget with local data
          await WidgetDataService.syncTasksToWidget();
        }
      } catch (e) {
        // Check if it's a UserProfileNotFoundException (user authenticated but profile doesn't exist)
        final errorString = e.toString();
        if (errorString.contains('UserProfileNotFoundException')) {
          debugPrint('User profile not found - user needs to log in again to create profile: $e');
          // Sign out to clear the auth session
          try {
            await client.modules.serverpod_auth_core.status.signOutDevice();
          } catch (signOutError) {
            debugPrint('Error signing out: $signOutError');
          }
        } else {
          debugPrint('Session expired or server unavailable: $e');
        }
        // Clear login state if we can't verify
        await prefs.setBool('is_logged_in', false);
        AuthState.isLoggedIn.value = false;
        AuthState.userName.value = 'Kevin';
        AuthState.userEmail.value = '';
        AuthState.profileImageUrl.value = '';
        debugPrint('Cleared login state but preserved guest data');
      }
    } else {
      // Offline and no cached info - clear login flag
      debugPrint('Offline and no cached user info - clearing login flag');
      await prefs.setBool('is_logged_in', false);
      AuthState.isLoggedIn.value = false;
    }
  }
}

// Simple mapping function
String convertToIana(String tzName) {
  switch (tzName) {
    case "India Standard Time":
      return "Asia/Kolkata";
    case "Pacific Standard Time":
      return "America/Los_Angeles";
    // add other mappings as needed
    default:
      // Fallback: try to use the name as-is, or default to UTC if invalid
      try {
        tz.getLocation(tzName);
        return tzName;
      } catch (e) {
        debugPrint('Unknown timezone: $tzName, defaulting to UTC');
        return "UTC";
      }
  }
}


class Config extends StatefulWidget {
  const Config({super.key});

  @override
  State<Config> createState() => _ConfigState();
}

class _ConfigState extends State<Config> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling, boldText: false),
          child: child!,
        );
      },
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.grey.shade100,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
      ),

      // Dark theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF121212)),
      ),

      // Use system setting (dark/light)
      themeMode: ThemeMode.system,
      home: SplashScreen(),
    );
  }


}

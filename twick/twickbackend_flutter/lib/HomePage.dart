import 'dart:ui';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'models/Task.dart';
import 'models/TaskList.dart';
import 'models/AuthState.dart';
import 'models/NotificationState.dart';
import 'models/CategoryList.dart';
import 'models/ConnectivityState.dart';
import 'services/NotificationService.dart';
import 'services/ServerSyncService.dart';
import 'TaskListPage.dart';
import 'ProfilePage.dart';
import 'CreateTask.dart';

// ───────────────── DELAYED ANIMATION WIDGET ─────────────────
class DelayedWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Object? resetTrigger; // Trigger to reset animation

  const DelayedWidget({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 0),
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOut,
    this.resetTrigger,
  });

  @override
  State<DelayedWidget> createState() => _DelayedWidgetState();
}

class _DelayedWidgetState extends State<DelayedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Object? _lastResetTrigger;

  @override
  void initState() {
    super.initState();
    _lastResetTrigger = widget.resetTrigger;
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(DelayedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset animation if resetTrigger changed
    if (widget.resetTrigger != null && 
        widget.resetTrigger != _lastResetTrigger) {
      _lastResetTrigger = widget.resetTrigger;
      _controller.reset();
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Static variable to persist across widget rebuilds (once per app launch)
  static bool _hasShownOverdueDialog = false;

  @override
  void initState() {
    super.initState();
    // Show overdue tasks dialog after the first frame is built
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _checkAndShowOverdueDialog();
    // });
  }

  void _checkAndShowOverdueDialog() {
    if (_hasShownOverdueDialog) return;
    
    final overdueTasks = TaskFilters.getOverdueTasks();
    if (overdueTasks.isNotEmpty && mounted) {
      _hasShownOverdueDialog = true;
      // Add 500ms delay before showing dialog
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showOverdueTasksDialog(overdueTasks.length);
        }
      });
    }
  }

  void _showOverdueTasksDialog(int count) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red[600],
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Overdue Tasks',
                style: TextStyle(
                  color: Colors.grey[900],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Count
              Text(
                'You have $count ${count == 1 ? 'task' : 'tasks'} that are overdue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // OK Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red[600]!,
                        Colors.red[800]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // border: Border.all(color: Colors.white,width: 2),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6), // Blue
                                    Color(0xFF1E40AF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E40AF).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showCreateTaskBottomSheet(context),
            borderRadius: BorderRadius.circular(28),
            child: const Center(
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DelayedWidget(
                delay: const Duration(milliseconds: 0),
                resetTrigger: widget.key,
                child: _Header(),
              ),
              const SizedBox(height: 28),
              DelayedWidget(
                delay: const Duration(milliseconds: 100),
                resetTrigger: widget.key,
                child: _StatsGrid(),
              ),
              const SizedBox(height: 32),
              DelayedWidget(
                delay: const Duration(milliseconds: 200),
                resetTrigger: widget.key,
                child: _TodayTasks(),
              ),
              const SizedBox(height: 32),
              DelayedWidget(
                delay: const Duration(milliseconds: 300),
                resetTrigger: widget.key,
                child: _RecurringTasks(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final todayTasks = TaskFilters.getTodayTasks();
        final todayCompleted = todayTasks.where((t) => t.isCompleted).length;
        final isAllCompleted = todayTasks.isNotEmpty && 
            todayCompleted == todayTasks.length;
        final hasNoTasks = todayTasks.isEmpty;
        final remainingCount = todayTasks.length - todayCompleted;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    AuthState.isLoggedIn.value
                        ? 'Hello, ${AuthState.userName.value}'
                        : 'Hello',
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasNoTasks
                        ? 'No tasks scheduled for today'
                        : isAllCompleted
                            ? 'All tasks completed! Great job! 🎉'
                            : '$remainingCount tasks remaining for today',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showNotificationDialog(context),
              child: Obx(
                () => Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    NotificationState.notificationsEnabled.value
                        ? Icons.notifications
                        : Icons.notifications_off,
                    color: NotificationState.notificationsEnabled.value
                        ? Colors.blue[600]
                        : Colors.grey[600],
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _showSleepModeDialog(context),
              child: Obx(
                () => Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.bedtime,
                    color: NotificationState.sleepModeEnabled.value
                        ? Colors.blue[600]
                        : Colors.grey[600],
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfilePage(),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
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
                              size: 24,
                            )
                          : null,
                    ),
                  ),
                ),
                // Offline indicator
                Obx(
                  () => !ConnectivityState.isOnline.value
                      ? Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.wifi_off,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Obx(
            () {
              final isEnabled = NotificationState.notificationsEnabled.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: Colors.blue[700],
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Notification Reminders',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    'Enable notifications to get smart reminders for your tasks and never miss a deadline.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Primary Action Button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isEnabled
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.red[600]!,
                                  Colors.red[800]!,
                                ],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF3B82F6), // Blue
                                  Color(0xFF1E40AF), // Dark Blue
                                ],
                              ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          NotificationState.toggleNotifications(!isEnabled);
                          
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
                        child: Text(
                          isEnabled ? 'Disable Notifications' : 'Enable Notifications',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Secondary Action Link
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Not Now',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

void _showSleepModeDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _SleepModeDialog(),
  );
}

class _SleepModeDialog extends StatefulWidget {
  @override
  State<_SleepModeDialog> createState() => _SleepModeDialogState();
}

class _SleepModeDialogState extends State<_SleepModeDialog> {
  late TimeOfDay _fromTime;
  late TimeOfDay _toTime;

  @override
  void initState() {
    super.initState();
    _fromTime = NotificationState.sleepModeFromTime.value;
    _toTime = NotificationState.sleepModeToTime.value;
  }

  Future<void> _selectFromTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _fromTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.grey[900]!,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[600],
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromTime = picked;
      });
    }
  }

  Future<void> _selectToTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _toTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.grey[900]!,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[600],
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _toTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bedtime,
                color: Colors.blue[700],
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'Sleep Mode',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[900],
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              'Silence all reminders during your rest.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            // Time Selection Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // FROM Time
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'FROM',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectFromTime(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatTime(_fromTime).split(' ')[0], // Time without AM/PM
                                style: TextStyle(
                                  color: Colors.grey[900],
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTime(_fromTime).split(' ')[1], // AM/PM
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Arrow Icon
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // TO Time
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'TO',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectToTime(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatTime(_toTime).split(' ')[0], // Time without AM/PM
                                style: TextStyle(
                                  color: Colors.grey[900],
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTime(_toTime).split(' ')[1], // AM/PM
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Buttons based on current state
            Obx(
              () {
                final isEnabled = NotificationState.sleepModeEnabled.value;
                
                return Column(
                  children: [
                    // Save Settings / Disable Button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isEnabled
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.red[600]!,
                                    Colors.red[800]!,
                                  ],
                                )
                              : const LinearGradient(
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
                          onPressed: () async {
                            if (isEnabled) {
                              // Disable sleep mode
                              await NotificationState.setSleepMode(
                                enabled: false,
                                fromTime: _fromTime,
                                toTime: _toTime,
                              );
                              // Reschedule all notifications to make them normal again
                              if (NotificationState.notificationsEnabled.value) {
                                await NotificationService.rescheduleAllNotifications();
                              }
                            } else {
                              // Enable sleep mode
                              await NotificationState.setSleepMode(
                                enabled: true,
                                fromTime: _fromTime,
                                toTime: _toTime,
                              );
                            }
                            Navigator.pop(context);
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
                          child: Text(
                            isEnabled ? 'Disable Sleep Mode' : 'Enable Sleep Mode',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Cancel Button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final todayTasks = TaskFilters.getTodayTasks();
        final scheduledTasks = TaskFilters.getScheduledTasks();
        final overdueTasks = TaskFilters.getOverdueTasks();
        final allTasksCount = allTasks.length;
        final todayCompleted = todayTasks.where((t) => t.isCompleted).length;
        final todayProgress = todayTasks.isEmpty
            ? 0.0
            : todayCompleted / todayTasks.length;
        final isAllCompleted = todayTasks.isNotEmpty && 
            todayCompleted == todayTasks.length;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1,
          children: [
            _StatGlassCard(
              title: 'Today',
              value: '${todayTasks.length}',
              icon: Icons.flash_on_rounded,
              color: const Color.fromARGB(255, 75, 201, 79),
              tag: 'LIVE',
              progress: todayProgress,
              isAllCompleted: isAllCompleted,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TaskListPage(
                    filterType: TaskFilterType.today,
                  ),
                ),
              ),
            ),
            _StatGlassCard(
              title: 'Scheduled',
              value: '${scheduledTasks.length}',
              icon: Icons.calendar_month_rounded,
              color: const Color.fromARGB(255, 85, 155, 247),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TaskListPage(
                    filterType: TaskFilterType.scheduled,
                  ),
                ),
              ),
            ),
            _StatGlassCard(
              title: 'All Tasks',
              value: '$allTasksCount',
              icon: Icons.grid_view_rounded,
              color: Colors.grey,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TaskListPage(
                    filterType: TaskFilterType.all,
                  ),
                ),
              ),
            ),
            _StatGlassCard(
              title: 'Overdue',
              value: '${overdueTasks.length}',
              icon: Icons.error_outline_rounded,
              color: const Color.fromARGB(255, 237, 52, 52),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TaskListPage(
                    filterType: TaskFilterType.overdue,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatGlassCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? tag;
  final double? progress; // 👈 optional
  final bool isAllCompleted;
  final VoidCallback? onTap;

  const _StatGlassCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.tag,
    this.progress,
    this.isAllCompleted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
          child: Container(
        padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
              /// ICON + TAG
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.15),
                    ),
                    child: Center(
                      child: Icon(icon, color: color, size: 24),
                    ),
                  ),
                  if (tag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag!,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      ),
                    ),
                ],
              ),

              const Spacer(),

              /// VALUE with Circular Progress
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              Text(
                value,
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 35,
                  fontWeight: FontWeight.bold,
                  height: 1,
                      letterSpacing: -1,
                    ),
                  ),
                  if (progress != null) ...[
                    const Spacer(),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Stack(
                        alignment: Alignment.center,
                children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              value: progress!.clamp(0, 1),
                              strokeWidth: 3,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                          ),
                          if (isAllCompleted)
                            const Icon(
                              Icons.check,
                      color: Colors.green,
                      size: 16,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

            const SizedBox(height: 8),

              /// TITLE
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  ),
                ),
              ],
          ),
        ),
    );
  }
}

class _RecurringTasks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.repeat,
                  color: Colors.blueAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recurring Tasks',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
                Obx(
                  () {
                    final tasks = TaskFilters.getRecurringTasks();
                    return tasks.length > 4
                        ? GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TaskListPage(
                                    filterType: TaskFilterType.recurring,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'View All',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : const SizedBox();
                  },
                ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(
          () {
            final recurringTasks = TaskFilters.getRecurringTasks();
            
            // Show empty state card if no recurring tasks
            if (recurringTasks.isEmpty) {
              return _EmptyRecurringTasksCard(
                onCreateTask: () => _showCreateTaskBottomSheet(context),
              );
            }
            
            // Sort tasks by priority first, then by time
            final sortedTasks = List<Task>.from(recurringTasks);
            sortedTasks.sort((a, b) {
              // Get priority weights (high = 3, medium = 2, low = 1)
              int getPriorityWeight(TaskPriority priority) {
                switch (priority) {
                  case TaskPriority.high:
                    return 3;
                  case TaskPriority.medium:
                    return 2;
                  case TaskPriority.low:
                    return 1;
                }
              }
              
              // First compare by priority (higher priority first)
              final priorityDiff = getPriorityWeight(b.priority) - getPriorityWeight(a.priority);
              if (priorityDiff != 0) {
                return priorityDiff;
              }
              // If same priority, sort by time (earlier first)
              return a.scheduledTime.compareTo(b.scheduledTime);
            });

            final displayTasks = sortedTasks.length > 4
                ? sortedTasks.sublist(0, 4)
                : sortedTasks;

            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayTasks.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final task = displayTasks[index];
                return GestureDetector(
                  onTap: () {
                    _showTaskActionsDialog(context, task);
                  },
                  child: _TaskTile(
                    task: task,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _TodayTasks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.today,
                  color: Colors.blueAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
              "Today's Tasks",
              style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            Obx(
              () {
                final todayTasks = TaskFilters.getTodayTasks();
                return todayTasks.isNotEmpty && todayTasks.length > 5
                    ? GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TaskListPage(
                              filterType: TaskFilterType.today,
                            ),
                          ),
                        ),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(
          () {
            final todayTasks = TaskFilters.getTodayTasks();
            if (todayTasks.isEmpty) {
              return EmptyTaskCard(
                onCreateTask: () => _showCreateTaskBottomSheet(context),
              );
            }

            // Sort tasks by priority first, then by time
            final sortedTasks = List<Task>.from(todayTasks);
            sortedTasks.sort((a, b) {
              // Get priority weights (high = 3, medium = 2, low = 1)
              int getPriorityWeight(TaskPriority priority) {
                switch (priority) {
                  case TaskPriority.high:
                    return 3;
                  case TaskPriority.medium:
                    return 2;
                  case TaskPriority.low:
                    return 1;
                }
              }
              
              // First compare by priority (higher priority first)
              final priorityDiff = getPriorityWeight(b.priority) - getPriorityWeight(a.priority);
              if (priorityDiff != 0) {
                return priorityDiff;
              }
              // If same priority, sort by time (earlier first)
              return a.scheduledTime.compareTo(b.scheduledTime);
            });

            final displayTasks = sortedTasks.length > 5
                ? sortedTasks.sublist(0, 5)
                : sortedTasks;

            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayTasks.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final task = displayTasks[index];
                return GestureDetector(
                  onTap: () {
                    _showTaskActionsDialog(context, task);
                  },
                  child: _TaskTile(
                    task: task,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

void _showTaskActionsDialog(BuildContext context, Task task) {
  String? selectedCategoryId = task.categoryId ?? getGeneralCategory().id;
  TaskPriority selectedPriority = task.priority;

  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
            child: Container(
          padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
            color: Colors.white,
                borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.title,
                    textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[900],
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
              if (!task.isRecurring)
                  Text(
                    'PRIORITY: ${task.priority.displayName}',
                    style: TextStyle(
                      color: _getPriorityColor(task.priority),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
              // Priority Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRIORITY',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    child: DropdownButtonFormField<TaskPriority>(
                      value: selectedPriority,
                      dropdownColor: Colors.white,
                      style: TextStyle(color: Colors.grey[900]),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      items: TaskPriority.values.map((priority) {
                        Color priorityColor;
                        switch (priority) {
                          case TaskPriority.low:
                            priorityColor = Colors.green;
                            break;
                          case TaskPriority.medium:
                            priorityColor = Colors.orange;
                            break;
                          case TaskPriority.high:
                            priorityColor = Colors.red;
                            break;
                        }
                        return DropdownMenuItem<TaskPriority>(
                          value: priority,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: priorityColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                priority.displayName,
                                style: TextStyle(
                                  color: Colors.grey[900],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedPriority = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
                  const SizedBox(height: 16),
                  // Category Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CATEGORY',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        dropdownColor: Colors.white,
                        style: TextStyle(color: Colors.grey[900]),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        items: allCategories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Row(
                              children: [
                                Icon(
                                  category.icon,
                                  color: category.color,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    color: Colors.grey[900],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedCategoryId = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                      final taskIndex = allTasks.indexWhere((t) => t.id == task.id);
                      if (taskIndex != -1) {
                      allTasks[taskIndex] = task.copyWith(
                        priority: selectedPriority,
                        categoryId: selectedCategoryId,
                      );
                        allTasks.refresh();
                      }
                      Navigator.pop(context);
                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 19, 38, 61),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                      child: const Text(
                        'Update',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Mark Complete/Incomplete Button (hidden for recurring tasks)
                  if (!task.isRecurring) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                      task.isCompleted = !task.isCompleted;
                      if (task.isCompleted) {
                        await NotificationService.cancelTaskNotification(task);
                        // Play swoosh sound when task is marked complete
                        final audioPlayer = AudioPlayer();
                        audioPlayer.play(AssetSource('swoosh.mp3')).catchError((e) {
                          debugPrint('Error playing swoosh sound: $e');
                        });
                      } else {
                        await NotificationService.scheduleTaskNotification(task);
                      }
                      allTasks.refresh();
                      Navigator.pop(context);
                    },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green[700],
                          side: BorderSide(color: Colors.green[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              task.isCompleted ? Icons.undo : Icons.check_circle_outline,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              task.isCompleted ? 'Mark Incomplete' : 'Mark Complete',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ),
                  const SizedBox(height: 12),
                  ],
                  // Delete and Cancel buttons in a row
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            // Show confirmation dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  'Delete Task?',
                                  style: TextStyle(color: Colors.grey[900]),
                                ),
                                content: Text(
                                  'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      // Cancel all notifications for this task
                      await NotificationService.cancelTaskNotification(task);
                      final taskId = task.id;
                      allTasks.remove(task);
                                      // Delete from server (non-blocking)
                                      ServerSyncService.deleteTaskFromServer(taskId).catchError((e) {
                                        debugPrint('Error deleting task from server: $e');
                                      });
                                      Navigator.pop(context); // Close confirmation
                                      Navigator.pop(context); // Close task actions dialog
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red[600],
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                    child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                    onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                      'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
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
        ),
      // ),
  );
}

Color _getPriorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return Colors.green;
    case TaskPriority.medium:
      return Colors.orange;
    case TaskPriority.high:
      return Colors.red;
  }
}

class EmptyTaskCard extends StatelessWidget {
  final VoidCallback onCreateTask;

  const EmptyTaskCard({super.key, required this.onCreateTask});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.task_alt_outlined,
              size: 40,
              color: Colors.blue[600],
            ),
          ),
                  const SizedBox(height: 24),
            Text(
                    'Create Your First Task',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                  color: Colors.grey[900],
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap the + button to create a create a new task ,\nor speak to the TWICK AI assistant which will create the task for you',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                  color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _ActionHint(
                          icon: Icons.add,
                          label: 'Task',
                          color: Colors.blue[600]!,
                          onTap: onCreateTask,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _ActionHint(
                        icon: Icons.auto_awesome,
                        label: 'AI Assistant',
                        color: Colors.blue[600]!,
                        onTap: () => openAssistantTab(context),
            ),
          ],
        ),
                ],
      ),
    );
  }
}

class _EmptyRecurringTasksCard extends StatelessWidget {
  final VoidCallback onCreateTask;

  const _EmptyRecurringTasksCard({required this.onCreateTask});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.repeat,
              size: 40,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Add Recurring Tasks',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Get constant reminders for specific intervals\n(Minutes, Hours, Daily, or Weekly)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3B82F6), // Blue
                                    Color(0xFF1E40AF),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () => _showCreateTaskBottomSheet(context, enableRecurring: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.repeat, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Create Task',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionHint extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionHint({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6), // Blue
                                    Color(0xFF1E40AF),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show a nice toast above the bottom sheet
void _showToastAboveBottomSheet(
  BuildContext context, {
  required String message,
  IconData? icon,
  Color? color,
}) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: color ?? Colors.orange[600],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // Remove the overlay after 3 seconds
  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}

void _showCreateTaskBottomSheet(BuildContext context, {bool enableRecurring = false}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => _CreateTaskBottomSheet(enableRecurring: enableRecurring),
  );
}

class _CreateTaskBottomSheet extends StatefulWidget {
  final bool enableRecurring;
  
  const _CreateTaskBottomSheet({this.enableRecurring = false});

  @override
  State<_CreateTaskBottomSheet> createState() => _CreateTaskBottomSheetState();
}

class _CreateTaskBottomSheetState extends State<_CreateTaskBottomSheet> {
  final _titleController = TextEditingController();
  DateTime? _selectedDateTime;
  TaskPriority _selectedPriority = TaskPriority.medium;
  String? _selectedCategoryId;
  bool _playSound = true; // Default to playing sound
  late bool _isRecurring; // Will be set from widget parameter
  RecurringIntervalType? _selectedRecurringIntervalType;
  int _recurringDuration = 1;
  final TextEditingController _durationController = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Set default to general category
    _selectedCategoryId = getGeneralCategory().id;
    // Set recurring state from widget parameter
    _isRecurring = widget.enableRecurring;
    if (_isRecurring) {
      _selectedRecurringIntervalType = RecurringIntervalType.daily;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }


  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.grey[900]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDateTime != null
            ? TimeOfDay.fromDateTime(_selectedDateTime!)
            : TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.blue[600]!,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.grey[900]!,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _createTask() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDateTime == null) {
        // Show nice toast above the bottom sheet using overlay
        _showToastAboveBottomSheet(
          context,
          message: 'Please select a date and time for your task',
          icon: Icons.access_time,
          color: Colors.orange,
        );
        return;
      }

      // For daily/weekly, always use duration 1
      final duration = (_selectedRecurringIntervalType == RecurringIntervalType.daily ||
                       _selectedRecurringIntervalType == RecurringIntervalType.weekly)
          ? 1
          : _recurringDuration;

      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString() +
            Random().nextInt(1000).toString(),
        title: _titleController.text.trim(),
        scheduledTime: _selectedDateTime!,
        priority: _selectedPriority,
        categoryId: _selectedCategoryId,
        isCompleted: false,
        playSound: _playSound,
        isRecurring: _isRecurring,
        recurringIntervalType: _isRecurring ? _selectedRecurringIntervalType : null,
        recurringDuration: _isRecurring ? duration : 1,
      );

      allTasks.add(task);
      // Schedule notification for the new task
      NotificationService.scheduleTaskNotification(task);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
              ),
            child: Container(
                padding: EdgeInsets.only(
                  top: safeAreaTop > 0 ? safeAreaTop + 24 : 24,
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
              decoration: BoxDecoration(
                  color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
              ),
              child: Form(
                key: _formKey,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 0,
                      ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Draggable Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create New Task',
                        style: TextStyle(
                          color: Colors.grey[900],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title Input
                  TextFormField(
                    textCapitalization: TextCapitalization.sentences,
                    controller: _titleController,
                    style: TextStyle(color: Colors.grey[900]),
                    decoration: InputDecoration(
                      labelText: 'TASK TITLE',
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      hintText: 'e.g., Weekly Team Sync',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue[600]!,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a task title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Date Time Picker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SCHEDULE DATE & TIME',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDateTime(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                              color: Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                              Icon(
                            Icons.calendar_today,
                                color: Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                                child: Text(
                                  _selectedDateTime == null
                                      ? 'Select date and time'
                                      : DateFormat('EEEE, MMM d - hh:mm a')
                                          .format(_selectedDateTime!),
                                  style: TextStyle(
                                    color: _selectedDateTime == null
                                        ? Colors.grey[400]
                                        : Colors.grey[900],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ),
                              Icon(
                            Icons.arrow_forward_ios,
                                color: Colors.grey[400],
                                size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category and Priority side by side
                  Row(
                    children: [
                  // Category Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CATEGORY',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                  Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                                  color: Colors.grey[300]!,
                      ),
                    ),
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                                  dropdownColor: Colors.white,
                                  style: TextStyle(color: Colors.grey[900], fontSize: 14),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                        ),
                        items: allCategories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Row(
                              children: [
                                Icon(
                                  category.icon,
                                  color: category.color,
                                        size: 18,
                                ),
                                      const SizedBox(width: 10),
                                Text(
                                  category.name,
                                            style: TextStyle(
                                              color: Colors.grey[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                  // Priority Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRIORITY',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                  Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                                  color: Colors.grey[300]!,
                      ),
                    ),
                    child: DropdownButtonFormField<TaskPriority>(
                      value: _selectedPriority,
                                dropdownColor: Colors.white,
                                style: TextStyle(color: Colors.grey[900], fontSize: 14),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                      ),
                      items: TaskPriority.values.map((priority) {
                        Color priorityColor;
                        switch (priority) {
                          case TaskPriority.low:
                            priorityColor = Colors.green;
                            break;
                          case TaskPriority.medium:
                            priorityColor = Colors.orange;
                            break;
                          case TaskPriority.high:
                            priorityColor = Colors.red;
                            break;
                        }

                        return DropdownMenuItem<TaskPriority>(
                          value: priority,
                          child: Row(
                            children: [
                              Container(
                                      width: 10,
                                      height: 10,
                                decoration: BoxDecoration(
                                  color: priorityColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                                    const SizedBox(width: 10),
                              Text(
                                priority.displayName,
                                      style: TextStyle(
                                        color: Colors.grey[900],
                                  fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPriority = value;
                          });
                        }
                      },
                    ),
                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sound Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.volume_up,
                              color: Colors.blue[600],
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Play Sound',
                              style: TextStyle(
                                color: Colors.grey[900],
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _playSound,
                          onChanged: (value) {
                            setState(() {
                              _playSound = value;
                            });
                          },
                          activeColor: Colors.blue[600],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Recurring Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.repeat,
                                  color: Colors.purple[600],
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Recurring',
                                  style: TextStyle(
                                    color: Colors.grey[900],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isRecurring,
                              onChanged: (value) {
                                setState(() {
                                  _isRecurring = value;
                                  if (!value) {
                                    _selectedRecurringIntervalType = null;
                                    _recurringDuration = 1;
                                    _durationController.text = '1';
                                  } else {
                                    _selectedRecurringIntervalType = RecurringIntervalType.daily;
                                  }
                                });
                              },
                              activeColor: Colors.purple[600],
                            ),
                          ],
                        ),
                        if (_isRecurring) ...[
                          const SizedBox(height: 16),
                          // Interval Type Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                              ),
                            ),
                            child: DropdownButtonFormField<RecurringIntervalType>(
                              value: _selectedRecurringIntervalType,
                              dropdownColor: Colors.white,
                              style: TextStyle(color: Colors.grey[900]),
                              decoration: const InputDecoration(
                                labelText: 'Interval',
                                labelStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              items: RecurringIntervalType.values.map((type) {
                                return DropdownMenuItem<RecurringIntervalType>(
                                  value: type,
                                  child: Text(
                                    type.displayName,
                                    style: TextStyle(
                                      color: Colors.grey[900],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedRecurringIntervalType = value;
                                    // Reset duration to 1 for daily/weekly, keep current for minutes/hours
                                    if (value == RecurringIntervalType.daily || 
                                        value == RecurringIntervalType.weekly) {
                                      _recurringDuration = 1;
                                      _durationController.text = '1';
                                    } else if (value == RecurringIntervalType.minutes) {
                                      // Ensure duration is within 1-60 for minutes
                                      if (_recurringDuration > 60) {
                                        _recurringDuration = 1;
                                      }
                                    } else if (value == RecurringIntervalType.hours) {
                                      // Ensure duration is within 1-24 for hours
                                      if (_recurringDuration > 24) {
                                        _recurringDuration = 1;
                                        _durationController.text = '1';
                                      }
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          // Duration Input (only for minutes and hours)
                          if (_selectedRecurringIntervalType == RecurringIntervalType.minutes ||
                              _selectedRecurringIntervalType == RecurringIntervalType.hours) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: Colors.grey[900]),
                              decoration: InputDecoration(
                                labelText: _selectedRecurringIntervalType == RecurringIntervalType.minutes
                                    ? 'Duration (1-60)'
                                    : 'Duration (1-24)',
                                hintText: _selectedRecurringIntervalType == RecurringIntervalType.minutes
                                    ? 'e.g., 15, 30, 60'
                                    : 'e.g., 1, 2, 6, 12',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.purple[600]!,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final duration = int.tryParse(value);
                                  if (duration == null || duration < 1) {
                                    return 'Must be at least 1';
                                  }
                                  final maxDuration = _selectedRecurringIntervalType == RecurringIntervalType.minutes
                                      ? 60
                                      : 24;
                                  if (duration > maxDuration) {
                                    return 'Max: $maxDuration';
                                  }
                                }
                                return null;
                              },
                              onChanged: (value) {
                                if (value.isEmpty) return;
                                final duration = int.tryParse(value) ?? 1;
                                final maxDuration = _selectedRecurringIntervalType == RecurringIntervalType.minutes
                                    ? 60
                                    : 24;
                                final clampedDuration = duration.clamp(1, maxDuration);
                                setState(() {
                                  _recurringDuration = clampedDuration;
                                  if (clampedDuration != duration && value.isNotEmpty) {
                                    _durationController.text = clampedDuration.toString();
                                    _durationController.selection = TextSelection.fromPosition(
                                      TextPosition(offset: _durationController.text.length),
                                    );
                                  }
                                });
                              },
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF3B82F6), // Blue
                                    Color(0xFF1E40AF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    child: ElevatedButton(
                      onPressed: _createTask,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                        ),
                          elevation: 0,
                      ),
                      child: const Text(
                        'Create Task',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                      ),
                    ),
                  ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;

  const _TaskTile({
    required this.task,
  });

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatTimeShort(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')}$period';
  }

  String _formatRecurringTime(Task task, DateTime dateTime) {
    if (!task.isRecurring || task.recurringIntervalType == null) {
      return _formatTime(dateTime);
    }

    final now = DateTime.now();
    final timeStr = _formatTimeShort(dateTime);

    switch (task.recurringIntervalType!) {
      case RecurringIntervalType.daily:
        // Check if it's tomorrow
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        final dateTimeDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
        if (dateTimeDay.year == tomorrow.year &&
            dateTimeDay.month == tomorrow.month &&
            dateTimeDay.day == tomorrow.day) {
          return 'Tomorrow, $timeStr';
        }
        // Otherwise show the date
        return '${DateFormat('MMM d').format(dateTime)}, $timeStr';
        
      case RecurringIntervalType.weekly:
        // Show short form like "Jan 24"
        return DateFormat('MMM d').format(dateTime);
        
      case RecurringIntervalType.minutes:
      case RecurringIntervalType.hours:
        // For minutes/hours, just show time
        return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(task.priority);
    final category = getCategoryById(task.categoryId) ?? getGeneralCategory();
    final categoryIcon = category.icon;
    final categoryColor = category.color;
    final timeStr = task.isRecurring 
        ? _formatRecurringTime(task, task.scheduledTime)
        : _formatTime(task.scheduledTime);

    // Check if task is overdue
    final isOverdue = !task.isCompleted && 
        !task.isRecurring && 
        task.scheduledTime.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
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
          Stack(
        children: [
          Container(
                height: 48,
                width: 48,
            decoration: BoxDecoration(
              color: task.isCompleted
                      ? Colors.grey[200]
                      : categoryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              categoryIcon,
                  color: task.isCompleted ? Colors.grey[600] : categoryColor,
                  size: 24,
                ),
              ),
              // Completed tick icon overlay
              if (task.isCompleted)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: task.isCompleted ? Colors.grey[600] : Colors.grey[900],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // For recurring tasks, only show recurring tag, no priority
                    if (task.isRecurring && !task.isCompleted) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(29, 158, 158, 158),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.repeat,
                              size: 12,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getRecurringLabel(task),
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (!task.isCompleted) ...[
                      // For non-recurring tasks, show priority
                      Text(
                        "${task.priority.displayName} PRIORITY",
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          // letterSpacing: 0.3,
                        ),
                      ),
                    ] else ...[
                      // Completed tasks
                      Text(
                        "COMPLETED",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          // letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // For recurring tasks, show "NEXT" tag and next trigger time
              // For non-recurring tasks, show schedule time
              if (task.isRecurring) ...[
                Text(
                  'NEXT',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRecurringTime(task, task.getNextReminderTime() ?? task.scheduledTime),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ] else ...[
                Text(
                  timeStr,
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              // Show status tag (PENDING, OVERDUE, or COMPLETED)
              if (!task.isRecurring) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: task.isCompleted
                        ? LinearGradient(
                            colors: [Colors.green[600]!, const Color.fromARGB(255, 30, 90, 33)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : isOverdue
                            ? LinearGradient(
                                colors: [Colors.red[600]!, Colors.black87],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  Color(0xFF3B82F6), // Blue
                                  Color(0xFF1E40AF), // Dark Blue
                                  Color(0xFF000000), // Black
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    task.isCompleted
                        ? 'COMPLETED'
                        : isOverdue
                            ? 'OVERDUE'
                            : 'PENDING',
                style: const TextStyle(
                  color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                ),
              ),
              ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getRecurringLabel(Task task) {
    if (!task.isRecurring || task.recurringIntervalType == null) {
      return 'DAILY';
    }
    
    final duration = task.recurringDuration;
    final type = task.recurringIntervalType!;
    
    switch (type) {
      case RecurringIntervalType.minutes:
        return duration == 1 ? 'EVERY MIN' : 'EVERY ${duration}M';
      case RecurringIntervalType.hours:
        return duration == 1 ? 'EVERY HR' : 'EVERY ${duration}H';
      case RecurringIntervalType.daily:
        return duration == 1 ? 'DAILY' : 'EVERY ${duration}D';
      case RecurringIntervalType.weekly:
        return duration == 1 ? 'WEEKLY' : 'EVERY ${duration}W';
    }
  }
}


import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'SpeechService.dart';
import 'Gemini.dart';
import 'models/Task.dart';
import 'models/TaskList.dart';
import 'models/CategoryList.dart';
import 'services/NotificationService.dart';

class CreateTaskPage extends StatelessWidget {
  const CreateTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: SafeArea(
        child: Stack(
          children: [
            /// MAIN CONTENT
            Column(
              children: [
                const SizedBox(height: 40),
                _PromptText(),
                const SizedBox(height: 24),
                _MetaChips(),
                const SizedBox(height: 48),
                _VoiceOrb(),
                const Spacer(),
                _InputBar(),
                const SizedBox(height: 16),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        "Sure, I’ll remind you to\nattend your meeting at 5 AM",
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}

class _MetaChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Chip(
          icon: Icons.calendar_month,
          label: 'Today, 5:00 AM',
          active: true,
        ),
        const SizedBox(width: 12),
        _Chip(icon: Icons.flag, label: 'Meeting'),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _Chip({required this.icon, required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? Colors.blueAccent.withOpacity(0.15)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: active
                  ? Colors.blueAccent.withOpacity(0.5)
                  : Colors.white12,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? Colors.blueAccent : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.blueAccent : Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceOrb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            _GlowRing(size: 260, opacity: 0.05),
            _GlowRing(size: 200, opacity: 0.08),
            _GlowRing(size: 140, opacity: 0.15),
            Container(
              height: 80,
              width: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent,
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 36),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'LISTENING',
          style: TextStyle(
            color: Colors.blueAccent,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Icon(Icons.graphic_eq, color: Colors.blueAccent),
      ],
    );
  }
}

class _GlowRing extends StatelessWidget {
  final double size;
  final double opacity;

  const _GlowRing({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blueAccent.withOpacity(opacity),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.keyboard, color: Colors.white54),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Or type your task here...',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
                Container(
                  height: 40,
                  width: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent,
                  ),
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> openAssistantTab(BuildContext context) async {
  // Play a nice sound effect when opening the AI assistant
  // Combine haptic feedback with system sound for a pleasant experience
  HapticFeedback.lightImpact();
  SystemSound.play(SystemSoundType.click);
  
  // Wait a bit to ensure wake word service has fully stopped
  await Future.delayed(const Duration(milliseconds: 300));
  
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true, // allows keyboard to push it up
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: _AssistantTab(),
      ),
    ),
  );
  
  // Restart wake word listening after assistant closes
  // Import WakeWordService here to avoid circular dependency
  // final wakeWordService = WakeWordService();
  // if (context.mounted) {
  //   // Small delay before restarting to ensure clean handoff
  //   await Future.delayed(const Duration(milliseconds: 500));
  //   wakeWordService.startListening(context);
  // }
}

class _AssistantTab extends StatefulWidget {
  const _AssistantTab();

  @override
  State<_AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends State<_AssistantTab> {
  late TtsService _ttsService;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final GeminiService _geminiService = GeminiService();
  final AudioPlayer _swooshPlayer = AudioPlayer();
  
  String _aiMessage = '';
  String _userInput = '';
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isProcessing = false;
  bool _waitingForTime = false;
  bool _waitingForSound = false;
  bool _waitingForRecurring = false;
  String? _pendingTaskTitle;
  TaskPriority? _pendingPriority;
  String? _pendingCategoryId;
  DateTime? _pendingScheduledTime;
  bool? _pendingPlaySound; // Store playSound preference
  RecurringIntervalType? _pendingRecurringIntervalType;
  int _pendingRecurringDuration = 1;
  List<Map<String, dynamic>>? _pendingTasks; // For multiple tasks
  List<Task> _createdTasks = []; // Track tasks created in this session for display

  @override
  void initState() {
    super.initState();
    _ttsService = TtsService();
    // Add delay to ensure wake word service has fully released speech recognition
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _initializeSpeech();
        // Speak greeting when the bottom sheet opens
        _speakGreeting();
      }
    });
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (mounted) {
          setState(() {
            _isListening = status == 'listening';
            debugPrint('Speech status changed: $status, _isListening: $_isListening');
          });
        }
      },
      onError: (error) {
        print('Speech recognition error: $error');
      },
    );
    
    if (mounted) {
      setState(() {
        _speechAvailable = available;
      });
      // Don't start listening here - wait for AI to finish speaking
    }
  }

  Future<void> _speakGreeting() async {
    // Small delay to ensure the sheet is fully visible
    await Future.delayed(const Duration(milliseconds: 300));
    const greeting = "How may I help you?";
    setState(() {
      _aiMessage = greeting;
    });
    // Speak and start listening only after TTS completes
    await _ttsService.speak(greeting, onComplete: () {
      // Start listening only after AI finishes speaking
      if (mounted && _speechAvailable) {
        _startListening();
      }
    });
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    
    // Set listening state immediately
    if (mounted) {
      setState(() {
        _isListening = true;
      });
      debugPrint('Started listening - _isListening set to true');
    }
    
    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _userInput = result.recognizedWords;
          });
          
          // When user finishes speaking (isFinal = true), process the input
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            if (_waitingForTime) {
              _processTimeInput(result.recognizedWords);
            } else if (_waitingForSound) {
              _processSoundPreference(result.recognizedWords);
            } else if (_waitingForRecurring) {
              _processRecurringPreference(result.recognizedWords);
            } else {
              _processUserInput(result.recognizedWords);
            }
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  // Convert written numbers to digits
  int _parseWrittenNumber(String numberStr) {
    final numberMap = {
      'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
      'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15,
      'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19, 'twenty': 20,
      'thirty': 30, 'forty': 40, 'fifty': 50, 'sixty': 60,
    };
    
    final lower = numberStr.toLowerCase().trim();
    return numberMap[lower] ?? int.tryParse(numberStr) ?? 1;
  }

  // Detect recurring patterns from user input
  Map<String, dynamic>? _detectRecurringPattern(String input) {
    final lowerInput = input.toLowerCase().trim();
    bool isRecurring = false;
    RecurringIntervalType? intervalType;
    int duration = 1;
    
    // Pattern 1: "every X minutes/hours/days/weeks" (with digits or written numbers)
    final everyPattern = RegExp(r'every\s+(\d+|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty)\s*(minute|hour|day|week|min|hr|hrs|mins|days|weeks)', caseSensitive: false);
    final match = everyPattern.firstMatch(lowerInput);
    
    if (match != null) {
      isRecurring = true;
      final numberStr = match.group(1) ?? '1';
      duration = _parseWrittenNumber(numberStr);
      final unit = match.group(2)?.toLowerCase() ?? '';
      
      if (unit.contains('min')) {
        intervalType = RecurringIntervalType.minutes;
      } else if (unit.contains('hour') || unit.contains('hr')) {
        intervalType = RecurringIntervalType.hours;
      } else if (unit.contains('day')) {
        intervalType = RecurringIntervalType.daily;
      } else if (unit.contains('week')) {
        intervalType = RecurringIntervalType.weekly;
      }
    } else {
      // Pattern 2: "everyday", "every day", "daily"
      if (lowerInput.contains('everyday') || 
          lowerInput.contains('every day') ||
          lowerInput.contains('daily')) {
        isRecurring = true;
        intervalType = RecurringIntervalType.daily;
        duration = 1;
      }
      // Pattern 3: "every week", "weekly", "everyweek"
      else if (lowerInput.contains('every week') ||
               lowerInput.contains('weekly') ||
               lowerInput.contains('everyweek')) {
        isRecurring = true;
        intervalType = RecurringIntervalType.weekly;
        duration = 1;
      }
      // Pattern 4: "every hour", "hourly"
      else if (lowerInput.contains('every hour') ||
               lowerInput.contains('hourly')) {
        isRecurring = true;
        intervalType = RecurringIntervalType.hours;
        duration = 1;
      }
      // Pattern 5: "every minute", "minutely"
      else if (lowerInput.contains('every minute') ||
               lowerInput.contains('minutely')) {
        isRecurring = true;
        intervalType = RecurringIntervalType.minutes;
        duration = 1;
      }
    }
    
    if (isRecurring && intervalType != null) {
      return {
        'isRecurring': true,
        'intervalType': intervalType,
        'duration': duration,
      };
    }
    
    return null;
  }

  Future<void> _processUserInput(String input) async {
    if (_isProcessing || input.trim().isEmpty) return;
    
    setState(() {
      _isProcessing = true;
      _createdTasks = []; // Clear any previous preview tasks
    });
    
    // Stop listening while processing
    await _speech.stop();
    
    try {
      // Show processing message
      // setState(() {
      //   _aiMessage = "Just a moment...";
      // });
      
      // First check if it's a query/question
      final isQuery = await _geminiService.isQuery(input);
      
      if (isQuery) {
        // Handle query about tasks
        await _handleQuery(input);
        return;
      }
      
      // Call Gemini API to create task from user input
      final taskData = await _geminiService.createTaskFromText(input);
      
      if (taskData == null) {
        throw Exception('Failed to create task from input');
      }
      
      // Check if we have multiple tasks
      if (taskData.containsKey('tasks') && taskData['tasks'] is List) {
        final tasksList = taskData['tasks'] as List;
        // If only one task and it needs time clarification, handle it as a single task
        if (tasksList.length == 1) {
          final singleTaskData = tasksList[0];
          if (singleTaskData is Map<String, dynamic> && 
              singleTaskData['needsTimeClarification'] == true) {
            // Handle as single task with time clarification
            // Merge the single task data into taskData for single task processing
            taskData['title'] = singleTaskData['title'];
            taskData['priority'] = singleTaskData['priority'];
            taskData['categoryId'] = singleTaskData['categoryId'];
            taskData['needsTimeClarification'] = true;
            taskData['scheduledTime'] = singleTaskData['scheduledTime'];
            // Continue with single task processing below
          } else {
            // Single task without time clarification - process as multiple tasks
            await _processMultipleTasks(tasksList, input);
        return;
          }
        } else {
          // Multiple tasks detected - detect recurring patterns per-task
          await _processMultipleTasks(tasksList, input);
          return;
        }
      }
      
      // Single task - detect recurring pattern from the original input
      final recurringInfo = _detectRecurringPattern(input);
      if (recurringInfo != null) {
        _pendingRecurringIntervalType = recurringInfo['intervalType'] as RecurringIntervalType;
        _pendingRecurringDuration = recurringInfo['duration'] as int;
        debugPrint('Detected recurring pattern from input: ${_pendingRecurringIntervalType}, duration: ${_pendingRecurringDuration}');
      }
      
      // Single task - validate it has a title
      if (taskData['title'] == null || taskData['title'].toString().isEmpty) {
        throw Exception('Failed to create task from input');
      }
      
      // If we detected recurring but Gemini says needsTimeClarification, 
      // we should still treat it as recurring and use current time + interval as first occurrence
      if (recurringInfo != null && taskData['needsTimeClarification'] == true) {
        // For recurring tasks, use current time as the first occurrence
        final now = DateTime.now();
        taskData['scheduledTime'] = now.toIso8601String();
        taskData['needsTimeClarification'] = false;
        debugPrint('Recurring task detected - using current time as first occurrence: $now');
      }
      
      // Check if we need to ask for time clarification
      final needsTimeClarification = taskData['needsTimeClarification'] == true;
      
      if (needsTimeClarification) {
        // Parse priority and category for preview
        final priority = TaskPriority.fromString(
                  taskData['priority']?.toString() ?? 'medium',
                );
                final categoryIdStr = taskData['categoryId']?.toString();
        String? categoryId;
                if (categoryIdStr == null || categoryIdStr.isEmpty) {
          categoryId = getGeneralCategory().id;
                } else {
                  final category = getCategoryById(categoryIdStr);
          categoryId = (category == null) ? getGeneralCategory().id : categoryIdStr;
                }
        
        // Create a preview task to show in UI immediately (before asking for time)
        final previewTask = Task(
          id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
          title: taskData['title'].toString(),
          scheduledTime: DateTime.now().add(const Duration(hours: 1)), // Placeholder time
          priority: priority,
          categoryId: categoryId,
          isCompleted: false,
          playSound: true,
          isRecurring: recurringInfo != null,
          recurringIntervalType: recurringInfo?['intervalType'] as RecurringIntervalType?,
          recurringDuration: recurringInfo?['duration'] ?? 1,
        );
        
        // Store task info and ask for time
        setState(() {
          _createdTasks = [previewTask]; // Show preview task immediately
          _pendingTaskTitle = taskData['title'].toString();
          _pendingPriority = priority;
          _pendingCategoryId = categoryId;
          _waitingForTime = true;
          _aiMessage = "When would you like me to remind you?";
        });
        
        // Speak the question
        await _ttsService.speak("When would you like me to remind you?", onComplete: () {
          // Restart listening after asking
          if (mounted && _speechAvailable) {
            _startListening();
          }
        });
        return;
      }
      
      // Parse scheduledTime
      DateTime scheduledTime;
      if (taskData['scheduledTime'] != null) {
        try {
          final timeString = taskData['scheduledTime'].toString();
          print('Parsing scheduledTime: $timeString');
          
          // If it has Z suffix, it's UTC - convert to local
          if (timeString.endsWith('Z')) {
            final parsedTime = DateTime.parse(timeString);
            scheduledTime = parsedTime.toLocal();
            print('Converted UTC to local: $scheduledTime');
          } else {
            // No Z suffix means it's already local time
            scheduledTime = DateTime.parse(timeString);
            print('Parsed as local time: $scheduledTime');
          }
        } catch (e) {
          print('Error parsing scheduledTime: $e');
          // If parsing fails, use current time + 1 hour as default
          scheduledTime = DateTime.now().add(const Duration(hours: 1));
        }
      } else {
        // Default to end of today if no time specified (only for non-recurring tasks)
        // For recurring tasks, we'll use current time (handled later)
        final now = DateTime.now();
        scheduledTime = DateTime(now.year, now.month, now.day, 23, 59);
      }
      
      // Ensure scheduled time is in the future
      final now = DateTime.now();
      print('Current time: $now');
      print('Scheduled time: $scheduledTime');
      
      // If recurring task detected, calculate first occurrence as current time + interval
      if (recurringInfo != null) {
        final intervalType = recurringInfo['intervalType'] as RecurringIntervalType;
        final duration = recurringInfo['duration'] as int;
        
        // Calculate first occurrence based on interval type and duration
        switch (intervalType) {
          case RecurringIntervalType.minutes:
            scheduledTime = now.add(Duration(minutes: duration));
            break;
          case RecurringIntervalType.hours:
            scheduledTime = now.add(Duration(hours: duration));
            break;
          case RecurringIntervalType.daily:
            // For daily, set to same time tomorrow
            scheduledTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
            scheduledTime = scheduledTime.add(Duration(days: duration));
            break;
          case RecurringIntervalType.weekly:
            // For weekly, set to same time next week
            scheduledTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
            scheduledTime = scheduledTime.add(Duration(days: 7 * duration));
            break;
        }
        print('Recurring task: First occurrence at $scheduledTime (current time: $now, interval: $duration ${intervalType.displayName})');
      } else if (scheduledTime.isBefore(now)) {
        print('Warning: Scheduled time $scheduledTime is in the past. Current time: $now');
        print('Adjusting to end of today');
        scheduledTime = DateTime(now.year, now.month, now.day, 23, 59);
      }
      
      // Parse priority
      final priority = TaskPriority.fromString(
        taskData['priority']?.toString() ?? 'medium',
      );
      
      // Parse categoryId (validate and default to general if invalid)
      String? categoryId = taskData['categoryId']?.toString();
      if (categoryId == null || categoryId.isEmpty) {
        categoryId = getGeneralCategory().id;
      } else {
        // Validate that the category exists in the app
        final category = getCategoryById(categoryId);
        if (category == null) {
          print('Warning: Category "$categoryId" not found, defaulting to general');
          categoryId = getGeneralCategory().id;
        }
      }
      
      // Create a preview task to show in UI immediately (before asking for sound preference)
      final previewTask = Task(
        id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
        title: taskData['title'].toString(),
        scheduledTime: scheduledTime,
        priority: priority,
        categoryId: categoryId,
        isCompleted: false,
        playSound: true, // Default, will be updated later
        isRecurring: recurringInfo != null,
        recurringIntervalType: recurringInfo?['intervalType'] as RecurringIntervalType?,
        recurringDuration: recurringInfo?['duration'] ?? 1,
      );
      
      // Show preview task card immediately
      setState(() {
        _createdTasks = [previewTask];
        _pendingTaskTitle = taskData['title'].toString();
        _pendingPriority = priority;
        _pendingCategoryId = categoryId;
        _pendingScheduledTime = scheduledTime;
        _waitingForSound = true;
        _aiMessage = "Should I play a sound alarm when the reminder triggers?";
      });
      
      // Speak the question
      await _ttsService.speak("Should I play a sound alarm when the reminder triggers?", onComplete: () {
        // Restart listening after asking
        if (mounted && _speechAvailable) {
          _startListening();
        }
      });
      
    } catch (e) {
      print('Error creating task: $e');
      setState(() {
        _aiMessage = "Sorry, I couldn't create that task. Please try again.";
      });
      await _ttsService.speak("Sorry, I couldn't create that task. Please try again.");
      
      // Restart listening after error
      if (mounted && _speechAvailable) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _startListening();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processTimeInput(String timeInput) async {
    if (_isProcessing || timeInput.trim().isEmpty || _pendingTaskTitle == null) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    // Stop listening while processing
    await _speech.stop();
    
    try {
      // Show processing message
      setState(() {
        _aiMessage = "Processing time...";
      });
      
      // Check for recurring patterns in time input (e.g., "every 3 hours")
      final recurringInfo = _detectRecurringPattern(timeInput);
      if (recurringInfo != null) {
        _pendingRecurringIntervalType = recurringInfo['intervalType'] as RecurringIntervalType;
        _pendingRecurringDuration = recurringInfo['duration'] as int;
        debugPrint('Detected recurring pattern in time input: ${_pendingRecurringIntervalType}, duration: ${_pendingRecurringDuration}');
      }
      
      // Create a combined input with the task title and time
      final combinedInput = "$_pendingTaskTitle at $timeInput";
      
      // Call Gemini API to parse the time
      final taskData = await _geminiService.createTaskFromText(combinedInput);
      
      if (taskData == null) {
        throw Exception('Failed to parse time');
      }
      
      // Parse scheduledTime
      DateTime scheduledTime;
      final now = DateTime.now();
      
      if (taskData['scheduledTime'] != null) {
        try {
          final timeString = taskData['scheduledTime'].toString();
          print('Parsing scheduledTime from time input: $timeString');
          
          DateTime parsedTime;
          // If it has Z suffix, it's UTC - convert to local
          if (timeString.endsWith('Z')) {
            parsedTime = DateTime.parse(timeString).toLocal();
          } else {
            // No Z suffix - parse and ensure it's treated as local time
            parsedTime = DateTime.parse(timeString);
            // If parsed time doesn't have timezone info, assume it's local
            if (parsedTime.isUtc) {
              parsedTime = parsedTime.toLocal();
            }
          }
          
          // Extract just the date part (year, month, day) from the parsed time
          // But use the time (hour, minute) from the parsed time
          // If the date is today or in the past, use today's date
          final parsedDate = DateTime(parsedTime.year, parsedTime.month, parsedTime.day);
          final today = DateTime(now.year, now.month, now.day);
          
          if (parsedDate.isBefore(today)) {
            // If parsed date is in the past, use today with the parsed time
            scheduledTime = DateTime(
              now.year,
              now.month,
              now.day,
              parsedTime.hour,
              parsedTime.minute,
            );
          } else {
            // Use the parsed time as-is
            scheduledTime = parsedTime;
          }
          
          print('Parsed scheduled time: $scheduledTime (current time: $now)');
        } catch (e) {
          print('Error parsing scheduledTime: $e');
          // If parsing fails, use end of today as default
          scheduledTime = DateTime(now.year, now.month, now.day, 23, 59);
        }
      } else {
        // Default to end of today if no time specified
        scheduledTime = DateTime(now.year, now.month, now.day, 23, 59);
      }
      
      // Ensure scheduled time is in the future
      // If it's today but the time has passed, move to tomorrow at the same time
      if (scheduledTime.isBefore(now)) {
        print('Warning: Scheduled time $scheduledTime is in the past. Current time: $now');
        // If it's the same day but time has passed, move to tomorrow
        final scheduledDate = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day);
        final today = DateTime(now.year, now.month, now.day);
        
        if (scheduledDate.year == today.year && 
            scheduledDate.month == today.month && 
            scheduledDate.day == today.day) {
          // Same day but time passed - move to tomorrow
          scheduledTime = scheduledTime.add(const Duration(days: 1));
          print('Moved to tomorrow: $scheduledTime');
        } else {
          // Different day in the past - use end of today
        scheduledTime = DateTime(now.year, now.month, now.day, 23, 59);
          print('Using end of today: $scheduledTime');
        }
      }
      
      // Update preview task with the scheduled time or create one if it doesn't exist
      if (_createdTasks.isNotEmpty && _createdTasks.first.id.startsWith('preview_')) {
      setState(() {
          _createdTasks = [
            Task(
              id: _createdTasks.first.id,
              title: _createdTasks.first.title,
              scheduledTime: scheduledTime,
              priority: _createdTasks.first.priority,
              categoryId: _createdTasks.first.categoryId,
              isCompleted: false,
              playSound: true,
              isRecurring: _pendingRecurringIntervalType != null,
              recurringIntervalType: _pendingRecurringIntervalType,
              recurringDuration: _pendingRecurringDuration,
            ),
          ];
        _pendingScheduledTime = scheduledTime;
        _waitingForTime = false;
        _waitingForSound = true;
        _aiMessage = "Should I play a sound alarm when the reminder triggers?";
      });
      } else {
        // Create preview task if it doesn't exist
        final previewTask = Task(
          id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
          title: _pendingTaskTitle!,
          scheduledTime: scheduledTime,
          priority: _pendingPriority ?? TaskPriority.medium,
          categoryId: _pendingCategoryId ?? getGeneralCategory().id,
          isCompleted: false,
          playSound: true,
          isRecurring: _pendingRecurringIntervalType != null,
          recurringIntervalType: _pendingRecurringIntervalType,
          recurringDuration: _pendingRecurringDuration,
        );
        setState(() {
          _createdTasks = [previewTask];
          _pendingScheduledTime = scheduledTime;
          _waitingForTime = false;
          _waitingForSound = true;
          _aiMessage = "Should I play a sound alarm when the reminder triggers?";
        });
      }
      
      // Speak the question
      await _ttsService.speak("Should I play a sound alarm when the reminder triggers?", onComplete: () {
        // Restart listening after asking
        if (mounted && _speechAvailable) {
          _startListening();
        }
      });
      
    } catch (e) {
      print('Error creating task with time: $e');
      setState(() {
        _aiMessage = "Sorry, I couldn't understand that time. Please try again.";
      });
      await _ttsService.speak("Sorry, I couldn't understand that time. Please try again.");
      
      // Restart listening after error
      if (mounted && _speechAvailable) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _startListening();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleQuery(String input) async {
    try {
      // Get task statistics
      final todayTasks = TaskFilters.getTodayTasks();
      final todayCount = todayTasks.length;
      final todayCompleted = todayTasks.where((t) => t.isCompleted).length;
      final todayPending = todayCount - todayCompleted;
      
      final allPending = TaskFilters.getIncompleteTasks().length;
      final allCompleted = TaskFilters.getCompletedTasks().length;
      final overdueTasks = TaskFilters.getOverdueTasks().length;
      final scheduledTasks = TaskFilters.getScheduledTasks().length;
      
      // Use Gemini to generate a natural response
      final gemini = Gemini.instance;
      final prompt = """
You are a helpful AI assistant answering questions about tasks.

Task Statistics:
- Tasks today: $todayCount (Completed: $todayCompleted, Pending: $todayPending)
- Total pending tasks: $allPending
- Total completed tasks: $allCompleted
- Overdue tasks: $overdueTasks
- Future scheduled tasks: $scheduledTasks

User question: "$input"

Provide a natural, conversational answer to the user's question using the statistics above.
Keep it brief and friendly (1-2 sentences max).
Do NOT include any JSON formatting, just plain text answer.

Answer:""";

      final response = await gemini.prompt(
        parts: [Part.text(prompt)],
        model: 'gemini-2.0-flash', // Fast Flash model
      ).catchError((error) {
        print("Gemini query response error: $error");
        return null;
      });

      String answer;
      if (response != null && response.output != null && response.output!.trim().isNotEmpty) {
        // Clean up the response (remove markdown, extra formatting)
        answer = response.output!.trim();
        // Remove markdown code blocks if present
        answer = answer.replaceAll(RegExp(r'```[a-z]*\n?'), '').replaceAll('```', '').trim();
      } else {
        // Fallback answer based on common queries
        if (input.toLowerCase().contains('today')) {
          answer = "You have $todayCount tasks today. $todayPending are pending and $todayCompleted are completed.";
        } else if (input.toLowerCase().contains('pending')) {
          answer = "You have $allPending pending tasks in total.";
        } else if (input.toLowerCase().contains('completed')) {
          answer = "You have completed $allCompleted tasks.";
        } else {
          answer = "You have $todayCount tasks today, with $todayPending pending and $allPending total pending tasks.";
        }
      }

      // Display and speak the answer
      setState(() {
        _aiMessage = answer;
      });

      await _ttsService.speak(answer, onComplete: () {
        // Restart listening after answering
        if (mounted && _speechAvailable) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _startListening();
            }
          });
        }
      });

    } catch (e) {
      print('Error handling query: $e');
      setState(() {
        _aiMessage = "Sorry, I couldn't process that question. Please try again.";
      });
      await _ttsService.speak("Sorry, I couldn't process that question. Please try again.");
      
      // Restart listening after error
      if (mounted && _speechAvailable) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _startListening();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processMultipleTasks(List<dynamic> tasksList, String originalInput) async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> processedTasks = [];
      
      for (var taskData in tasksList) {
        if (taskData is! Map<String, dynamic>) continue;
        
        // Skip if no title
        if (taskData['title'] == null || taskData['title'].toString().isEmpty) continue;
        
        // Detect recurring patterns PER-TASK by finding the relevant section in original input
        final taskTitle = taskData['title'].toString();
        Map<String, dynamic>? taskRecurringInfo;
        
        // Find the section of input related to this specific task
        // Look for the task title in the original input and extract context around it
        final taskTitleLower = taskTitle.toLowerCase();
        final inputLower = originalInput.toLowerCase();
        final taskIndex = inputLower.indexOf(taskTitleLower);
        
        if (taskIndex != -1) {
          // Extract context around this task (look 30 chars before and 80 chars after)
          final start = taskIndex > 30 ? taskIndex - 30 : 0;
          final end = taskIndex + taskTitle.length + 80 < originalInput.length 
              ? taskIndex + taskTitle.length + 80 
              : originalInput.length;
          final taskContext = originalInput.substring(start, end);
          
          // Detect recurring pattern in this task's context only
          taskRecurringInfo = _detectRecurringPattern(taskContext);
          debugPrint('Task: "$taskTitle" - Context: "$taskContext" - Recurring: ${taskRecurringInfo != null}');
        }
        
        // Handle recurring for each task if detected
        if (taskRecurringInfo != null && taskData['needsTimeClarification'] == true) {
          taskData['scheduledTime'] = now.toIso8601String();
          taskData['needsTimeClarification'] = false;
        }
        
        // Check if needs time clarification
        if (taskData['needsTimeClarification'] == true) {
          // For multiple tasks, we can't ask for time clarification individually
          // So we'll skip tasks without time or use a default
          continue;
        }
        
        // Parse scheduledTime
        DateTime scheduledTime;
        if (taskData['scheduledTime'] != null) {
          try {
            final timeString = taskData['scheduledTime'].toString();
            if (timeString.endsWith('Z')) {
              final parsedTime = DateTime.parse(timeString);
              scheduledTime = parsedTime.toLocal();
            } else {
              scheduledTime = DateTime.parse(timeString);
            }
          } catch (e) {
            scheduledTime = now.add(const Duration(hours: 1));
          }
        } else {
          scheduledTime = DateTime(now.year, now.month, now.day, 23, 59);
        }
        
        // Ensure scheduled time is in the future
        if (scheduledTime.isBefore(now)) {
          scheduledTime = DateTime(now.year, now.month, now.day, 23, 59);
        }
        
        // Parse priority
        final priority = TaskPriority.fromString(
          taskData['priority']?.toString() ?? 'medium',
        );
        
        // Parse categoryId
        String? categoryId = taskData['categoryId']?.toString();
        if (categoryId == null || categoryId.isEmpty) {
          categoryId = getGeneralCategory().id;
        } else {
          final category = getCategoryById(categoryId);
          if (category == null) {
            categoryId = getGeneralCategory().id;
          }
        }
        
        // Add to processed tasks (use per-task recurring info, not global)
        processedTasks.add({
          'title': taskData['title'].toString(),
          'scheduledTime': scheduledTime,
          'priority': priority,
          'categoryId': categoryId,
          'isRecurring': taskRecurringInfo != null,
          'recurringIntervalType': taskRecurringInfo?['intervalType'],
          'recurringDuration': taskRecurringInfo?['duration'] ?? 1,
        });
      }
      
      if (processedTasks.isEmpty) {
        throw Exception('No valid tasks found');
      }
      
      // Create preview tasks to show in UI immediately (before asking for sound preference)
      final previewTasks = processedTasks.map((taskData) {
        return Task(
          id: 'preview_${DateTime.now().millisecondsSinceEpoch}_${taskData['title']}',
          title: taskData['title'] as String,
          scheduledTime: taskData['scheduledTime'] as DateTime,
          priority: taskData['priority'] as TaskPriority,
          categoryId: taskData['categoryId'] as String,
          isCompleted: false,
          playSound: true, // Default, will be updated later
          isRecurring: taskData['isRecurring'] as bool? ?? false,
          recurringIntervalType: taskData['recurringIntervalType'] as RecurringIntervalType?,
          recurringDuration: taskData['recurringDuration'] as int? ?? 1,
        );
      }).toList();
      
      final taskCount = processedTasks.length;
      
      // Show preview tasks immediately (skip "I found X tasks" message)
      setState(() {
        _createdTasks = previewTasks; // Show preview tasks immediately
        _pendingTasks = processedTasks;
        _aiMessage = ''; // Don't show "I found X tasks" message
      });
      
      // Small delay to let cards animate in, then ask about sound preference
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        setState(() {
        _waitingForSound = true;
        _aiMessage = taskCount == 1 
    ? "Do you want a sound alarm for this reminder?"
    : "Do you want sound alarms for all reminders?";
      });
      
      // Speak the question
        final question = taskCount == 1 
            ? "Do you want a sound alarm for this reminder?"
    : "Do you want sound alarms for all reminders?";
      await _ttsService.speak(question, onComplete: () {
        if (mounted && _speechAvailable) {

          _startListening();
        }
      });
      }
      
    } catch (e) {
      print('Error processing multiple tasks: $e');
      setState(() {
        _aiMessage = "Sorry, I couldn't create those tasks. Please try again.";
      });
      await _ttsService.speak("Sorry, I couldn't create those tasks. Please try again.");
      
      if (mounted && _speechAvailable) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _startListening();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processMultipleTasksSoundPreference(String input) async {
    if (_isProcessing || input.trim().isEmpty || _pendingTasks == null || _pendingTasks!.isEmpty) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    // Stop listening while processing
    await _speech.stop();
    
    try {
      // Determine sound preference from user input
      final lowerInput = input.toLowerCase().trim();
      bool playSound = false;
      
      // Check for affirmative responses
      if (lowerInput.contains('yes') || 
          lowerInput.contains('yeah') || 
          lowerInput.contains('yep') ||
          lowerInput.contains('sure') ||
          lowerInput.contains('okay') ||
          lowerInput.contains('ok') ||
          lowerInput.contains('play') ||
          lowerInput.contains('sound') ||
          lowerInput.contains('alarm')) {
        playSound = true;
      }
      
      // Check for negative responses
      if (lowerInput.contains('no') && 
          !lowerInput.contains('not') && 
          !lowerInput.contains('nothing')) {
        if (lowerInput.contains('no sound') || 
            lowerInput.contains('silent') || 
            lowerInput.contains('quiet') ||
            (lowerInput.startsWith('no') && lowerInput.length < 5)) {
          playSound = false;
        }
      }
      
      // Give acknowledgment
      final taskCount = _pendingTasks!.length;
      String acknowledgment;
      if (playSound) {
        acknowledgment = taskCount == 1 
            ? "Sure, I'll add a sound alarm."
            : "Perfect! I'll add sound alarms for all $taskCount tasks.";
      } else {
        acknowledgment = taskCount == 1 
            ? "Got it, I'll keep it silent."
            : "Got it, I'll keep all $taskCount tasks silent.";
      }
      
      setState(() {
        _aiMessage = acknowledgment;
      });
      
      await _ttsService.speak(acknowledgment);
      
      // Create all tasks
      final List<Task> createdTasksList = [];
      for (var taskData in _pendingTasks!) {
        final task = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              Random().nextInt(1000).toString(),
          title: taskData['title'] as String,
          scheduledTime: taskData['scheduledTime'] as DateTime,
          priority: taskData['priority'] as TaskPriority,
          categoryId: taskData['categoryId'] as String,
          isCompleted: false,
          playSound: playSound,
          isRecurring: taskData['isRecurring'] as bool? ?? false,
          recurringIntervalType: taskData['recurringIntervalType'] as RecurringIntervalType?,
          recurringDuration: taskData['recurringDuration'] as int? ?? 1,
        );
        
        allTasks.add(task);
        createdTasksList.add(task);
        await NotificationService.scheduleTaskNotification(task);
      }
      
      // Store created tasks for display
      setState(() {
        _createdTasks = createdTasksList;
      });
      
      // Play swoosh sound after tasks are created
      _swooshPlayer.play(AssetSource('swoosh.mp3')).catchError((e) {
        debugPrint('Error playing swoosh sound: $e');
      });
      
      // Reset state
      setState(() {
        _waitingForSound = false;
        _pendingTasks = null;
        _pendingTaskTitle = null;
        _pendingPriority = null;
        _pendingCategoryId = null;
        _pendingScheduledTime = null;
        _pendingPlaySound = null;
        _pendingRecurringIntervalType = null;
        _pendingRecurringDuration = 1;
      });
      
      // Show success message
      // final successMessage = taskCount == 1 
      //     ? "Task added successfully!"
      //     : "All $taskCount tasks have been added successfully!";
      
      // setState(() {
      //   _aiMessage = successMessage;
      // });
      
      // await _ttsService.speak(successMessage);
      
      // Close the bottom sheet
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
      
    } catch (e) {
      print('Error creating multiple tasks: $e');
      setState(() {
        _aiMessage = "Sorry, I couldn't create those tasks. Please try again.";
      });
      await _ttsService.speak("Sorry, I couldn't create those tasks. Please try again.");
      
      if (mounted && _speechAvailable) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _startListening();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processSoundPreference(String input) async {
    // Check if we're processing multiple tasks
    if (_pendingTasks != null && _pendingTasks!.isNotEmpty) {
      await _processMultipleTasksSoundPreference(input);
      return;
    }
    
    if (_isProcessing || input.trim().isEmpty || _pendingTaskTitle == null || _pendingScheduledTime == null) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    // Stop listening while processing
    await _speech.stop();
    
    try {
      // Determine sound preference from user input
      final lowerInput = input.toLowerCase().trim();
      bool playSound = false; // Default to silent (if user says nothing or says no)
      
      // Check for affirmative responses (user wants sound)
      if (lowerInput.contains('yes') || 
          lowerInput.contains('yeah') || 
          lowerInput.contains('yep') ||
          lowerInput.contains('sure') ||
          lowerInput.contains('okay') ||
          lowerInput.contains('ok') ||
          lowerInput.contains('play') ||
          lowerInput.contains('sound') ||
          lowerInput.contains('alarm') ||
          lowerInput.contains('ring') ||
          lowerInput.contains('with sound') ||
          lowerInput.contains('play sound') ||
          lowerInput.contains('make it sound')) {
        playSound = true;
      }
      
      // Explicitly check for negative responses (user wants silent)
      if (lowerInput.contains('no') && 
          !lowerInput.contains('not') && 
          !lowerInput.contains('nothing')) {
        // Only set to false if it's a clear "no" (not "not" or "nothing")
        if (lowerInput.contains('no sound') || 
            lowerInput.contains('silent') || 
            lowerInput.contains('quiet') ||
            lowerInput.contains('mute') ||
            lowerInput.contains('without sound') ||
            (lowerInput.startsWith('no') && lowerInput.length < 5)) {
          playSound = false;
        }
      }
      
      // Give immediate acknowledgment based on preference
      String acknowledgment;
      if (playSound) {
        acknowledgment = "Sure, I'll add a sound alarm.";
      } else {
        acknowledgment = "Got it, I'll keep it silent.";
      }
      
      setState(() {
        _aiMessage = acknowledgment;
      });
      
      // Speak the acknowledgment
      await _ttsService.speak(acknowledgment);
      
      // Store playSound preference
      _pendingPlaySound = playSound;
      
      // Check if recurring was already detected - if so, create task directly
      if (_pendingRecurringIntervalType != null) {
        // Recurring already detected, create task directly
        final isRecurring = true;
        final intervalType = _pendingRecurringIntervalType;
        final duration = _pendingRecurringDuration;
        
        // For recurring tasks, calculate first occurrence as current time + interval
        final now = DateTime.now();
        DateTime firstOccurrence = now;
        
        // Calculate first occurrence based on interval type and duration
        switch (intervalType!) {
          case RecurringIntervalType.minutes:
            firstOccurrence = now.add(Duration(minutes: duration));
            break;
          case RecurringIntervalType.hours:
            firstOccurrence = now.add(Duration(hours: duration));
            break;
          case RecurringIntervalType.daily:
            // For daily, set to same time tomorrow (or today if time hasn't passed)
            firstOccurrence = DateTime(now.year, now.month, now.day, now.hour, now.minute);
            firstOccurrence = firstOccurrence.add(Duration(days: duration));
            break;
          case RecurringIntervalType.weekly:
            // For weekly, set to same time next week
            firstOccurrence = DateTime(now.year, now.month, now.day, now.hour, now.minute);
            firstOccurrence = firstOccurrence.add(Duration(days: 7 * duration));
            break;
        }
        
        debugPrint('Recurring task: First occurrence at $firstOccurrence (current time: $now, interval: $duration ${intervalType.displayName})');
        
        // Give acknowledgment about recurring
        final intervalName = intervalType == RecurringIntervalType.minutes ? 'minute${duration > 1 ? 's' : ''}' :
                            intervalType == RecurringIntervalType.hours ? 'hour${duration > 1 ? 's' : ''}' :
                            intervalType == RecurringIntervalType.daily ? 'day${duration > 1 ? 's' : ''}' :
                            'week${duration > 1 ? 's' : ''}';
        final recurringAck = "Perfect! I'll set it to repeat every $duration $intervalName.";
        
        setState(() {
          _aiMessage = recurringAck;
        });
        
        await _ttsService.speak(recurringAck);
        
        // Create the task with all preferences
        final task = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              Random().nextInt(1000).toString(),
          title: _pendingTaskTitle!,
          scheduledTime: firstOccurrence,
          priority: _pendingPriority ?? TaskPriority.medium,
          categoryId: _pendingCategoryId ?? getGeneralCategory().id,
          isCompleted: false,
          playSound: playSound,
          isRecurring: isRecurring,
          recurringIntervalType: intervalType,
          recurringDuration: duration,
        );
        
        // Add task to the list
        allTasks.add(task);
        
        // Update created tasks list with the actual task (replace preview)
        setState(() {
          _createdTasks = [task];
        });
        
        // Schedule notification
        await NotificationService.scheduleTaskNotification(task);
        
        // Play swoosh sound after task creation
        _swooshPlayer.play(AssetSource('swoosh.mp3')).catchError((e) {
          debugPrint('Error playing swoosh sound: $e');
        });
        
        // Reset waiting state
        setState(() {
          _waitingForSound = false;
          _pendingTaskTitle = null;
          _pendingPriority = null;
          _pendingCategoryId = null;
          _pendingScheduledTime = null;
          _pendingPlaySound = null;
          _pendingRecurringIntervalType = null;
          _pendingRecurringDuration = 1;
        });
        
        // Close the bottom sheet after TTS completes (no extra confirmation)
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
        return;
      }
      
      // Recurring not detected - create one-time task directly without asking
      // setState(() {
      //   _aiMessage = "Adding your task to the list now.";
      // });
      
      // await _ttsService.speak("Adding your task to the list now.");
      
      // Create the task as one-time (not recurring)
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString() +
            Random().nextInt(1000).toString(),
        title: _pendingTaskTitle!,
        scheduledTime: _pendingScheduledTime!,
        priority: _pendingPriority ?? TaskPriority.medium,
        categoryId: _pendingCategoryId ?? getGeneralCategory().id,
        isCompleted: false,
        playSound: playSound,
        isRecurring: false,
        recurringIntervalType: null,
        recurringDuration: 1,
      );
      
      // Add task to the list
      allTasks.add(task);
      
      // Update created tasks list with the actual task (replace preview)
      setState(() {
        _createdTasks = [task];
      });
      
      // Schedule notification
      await NotificationService.scheduleTaskNotification(task);
      
      // Play swoosh sound after task creation
      _swooshPlayer.play(AssetSource('swoosh.mp3')).catchError((e) {
        debugPrint('Error playing swoosh sound: $e');
      });
      
      // Reset waiting state
      setState(() {
        _waitingForSound = false;
        _pendingTaskTitle = null;
        _pendingPriority = null;
        _pendingCategoryId = null;
        _pendingScheduledTime = null;
        _pendingPlaySound = null;
        _pendingRecurringIntervalType = null;
        _pendingRecurringDuration = 1;
      });
      
      // Close the bottom sheet after TTS completes (no extra confirmation)
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
      
    } catch (e) {
      print('Error creating task with sound preference: $e');
      setState(() {
        _aiMessage = "Sorry, I couldn't create that task. Please try again.";
      });
      await _ttsService.speak("Sorry, I couldn't create that task. Please try again.");
      
      // Restart listening after error
      if (mounted && _speechAvailable) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _startListening();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processRecurringPreference(String input) async {
    if (_isProcessing || input.trim().isEmpty || _pendingTaskTitle == null || _pendingScheduledTime == null) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    // Stop listening while processing
    await _speech.stop();
    
    try {
      // Determine recurring preference from user input
      final lowerInput = input.toLowerCase().trim();
      bool isRecurring = false;
      RecurringIntervalType? intervalType;
      int duration = 1;
      
      // Check for recurring patterns
      // Pattern: "every X minutes/hours/days/weeks" or "X times a day/hour/week"
      final everyPattern = RegExp(r'every\s+(\d+)\s*(minute|hour|day|week|min|hr|hrs|mins|days|weeks)');
      final match = everyPattern.firstMatch(lowerInput);
      
      if (match != null) {
        isRecurring = true;
        duration = int.tryParse(match.group(1) ?? '1') ?? 1;
        final unit = match.group(2)?.toLowerCase() ?? '';
        
        if (unit.contains('min')) {
          intervalType = RecurringIntervalType.minutes;
        } else if (unit.contains('hour') || unit.contains('hr')) {
          intervalType = RecurringIntervalType.hours;
        } else if (unit.contains('day')) {
          intervalType = RecurringIntervalType.daily;
        } else if (unit.contains('week')) {
          intervalType = RecurringIntervalType.weekly;
        }
      } else {
        // Check for simple affirmative responses (default to daily)
        if (lowerInput.contains('yes') || 
            lowerInput.contains('yeah') || 
            lowerInput.contains('yep') ||
            lowerInput.contains('sure') ||
            lowerInput.contains('okay') ||
            lowerInput.contains('ok') ||
            lowerInput.contains('repeat') ||
            lowerInput.contains('daily') ||
            lowerInput.contains('every day') ||
            lowerInput.contains('recurring')) {
          isRecurring = true;
          intervalType = RecurringIntervalType.daily;
          duration = 1;
        }
      }
      
      // Store recurring preferences
      _pendingRecurringIntervalType = intervalType;
      _pendingRecurringDuration = duration;
      
      // Get playSound from previous step
      bool playSound = _pendingPlaySound ?? true;
      
      // Give immediate acknowledgment
      String acknowledgment;
      if (isRecurring && intervalType != null) {
        final intervalName = intervalType == RecurringIntervalType.minutes ? 'minute${duration > 1 ? 's' : ''}' :
                            intervalType == RecurringIntervalType.hours ? 'hour${duration > 1 ? 's' : ''}' :
                            intervalType == RecurringIntervalType.daily ? 'day${duration > 1 ? 's' : ''}' :
                            'week${duration > 1 ? 's' : ''}';
        acknowledgment = "Perfect! I'll set it to repeat every $duration $intervalName.";
      } else if (isRecurring) {
        acknowledgment = "Perfect! I'll set it to repeat daily.";
      } else {
        acknowledgment = "Got it, it's a one-time task.";
      }
      
      setState(() {
        _aiMessage = acknowledgment;
      });
      
      // Speak the acknowledgment
      await _ttsService.speak(acknowledgment);
      
      // Create the task with all preferences
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString() +
            Random().nextInt(1000).toString(),
        title: _pendingTaskTitle!,
        scheduledTime: _pendingScheduledTime!,
        priority: _pendingPriority ?? TaskPriority.medium,
        categoryId: _pendingCategoryId ?? getGeneralCategory().id,
        isCompleted: false,
        playSound: playSound,
        isRecurring: isRecurring,
        recurringIntervalType: intervalType,
        recurringDuration: duration,
      );
      
      // Add task to the list
      allTasks.add(task);
      
      // Schedule notification
      await NotificationService.scheduleTaskNotification(task);
      
      // Play swoosh sound after task creation
      _swooshPlayer.play(AssetSource('swoosh.mp3')).catchError((e) {
        debugPrint('Error playing swoosh sound: $e');
      });
      
      // Reset waiting state
      setState(() {
        _waitingForRecurring = false;
        _pendingTaskTitle = null;
        _pendingPriority = null;
        _pendingCategoryId = null;
        _pendingScheduledTime = null;
        _pendingPlaySound = null;
        _pendingRecurringIntervalType = null;
        _pendingRecurringDuration = 1;
      });
      
      // Close the bottom sheet after TTS completes (no extra confirmation)
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
      
    } catch (e) {
      debugPrint('Error creating task with recurring preference: $e');
      setState(() {
        _aiMessage = "Sorry, I couldn't create that task. Please try again.";
      });
      await _ttsService.speak("Sorry, I couldn't create that task. Please try again.");
      
      // Restart listening after error
      if (mounted && _speechAvailable) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _startListening();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    _speech.stop();
    _swooshPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: screenHeight * 0.67, // Bottom two-thirds of screen
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Draggable Handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
        decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
            ),
          // Header
            const Text(
              'TWICK',
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            ),
            const SizedBox(height: 4),
          Text(
              'Your AI Assistant',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
            // Conversation display
            Expanded(
              child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: 24, // Extra bottom padding to prevent cropping
              ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // AI Message Bubble (Animated)
                    if (_aiMessage.isNotEmpty)
                      _AnimatedMessageBubble(
                        text: _aiMessage,
                        isAI: true,
                      ),
                  if (_aiMessage.isNotEmpty) const SizedBox(height: 16),
                  // Animated Task Cards
                  if (_createdTasks.isNotEmpty) ...[
                    ...List.generate(_createdTasks.length, (index) {
                      return _AnimatedTaskCard(
                        task: _createdTasks[index],
                        delay: Duration(milliseconds: 500 + (index * 200)), // Stagger animation
                        isCompact: _createdTasks.length > 1, // Use compact mode for multiple tasks
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                  // Listening indicator - always show when listening
                  if (_isListening && !_isProcessing)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: Lottie.asset(
                              'assets/agentListening.json',
                              fit: BoxFit.contain,
                              repeat: true,
                              ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                          'Listening...',
                          style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                          ),
                        ),
                  // User Input
                  if (_userInput.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _MessageBubble(
                      text: _userInput,
                      isAI: false,
                      ),
                  ],
                  if (_isProcessing) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: Lottie.asset(
                                'assets/loading animation.json',
                                fit: BoxFit.contain,
                                repeat: true,
                              ),
                            ),
                          const SizedBox(width: 12),
                            Text(
                              'Just a moment...',
                              style: TextStyle(
                              color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32,width: double.infinity,),
          // Microphone Button
          // Center(
          //   child: Stack(
          //     alignment: Alignment.center,
          //     children: [
          //       // Outer glow ring
          //       Container(
          //         width: 100,
          //         height: 100,
          //         decoration: BoxDecoration(
          //           shape: BoxShape.circle,
          //           color: Colors.grey[300]!.withOpacity(0.3),
          //         ),
          //       ),
          //       // Main button
          //       Container(
          //         width: 80,
          //         height: 80,
          //         decoration: BoxDecoration(
          //           shape: BoxShape.circle,
          //           color: const Color(0xFF1A1F2A), // Dark blue/black
          //           boxShadow: [
          //             BoxShadow(
          //               color: Colors.black.withOpacity(0.3),
          //               blurRadius: 12,
          //               offset: const Offset(0, 4),
          //             ),
          //           ],
          //         ),
          //         child: IconButton(
          //           onPressed: _isListening ? null : () {
          //             if (_speechAvailable && !_isProcessing) {
          //               _startListening();
          //             }
          //           },
          //           icon: const Icon(
          //             Icons.mic,
          //             color: Colors.white,
          //             size: 36,
          //     ),
          //   ),
          //       ),
          //     ],
          //   ),
          // ),
          SizedBox(height: keyboardHeight > 0 ? keyboardHeight : 32),
          ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isAI;

  const _MessageBubble({
    required this.text,
    required this.isAI,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isAI
              ? Colors.blue[50] // Light blue/gray for AI
              : Colors.grey[200], // Light gray for user
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: isAI ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _AnimatedMessageBubble extends StatefulWidget {
  final String text;
  final bool isAI;

  const _AnimatedMessageBubble({
    required this.text,
    required this.isAI,
  });

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Slide from left
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    // Start animation immediately with a small delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(_AnimatedMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the text changes, restart the animation
    if (oldWidget.text != widget.text) {
      _controller.reset();
      Future.delayed(const Duration(milliseconds: 100), () {
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
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Align(
            alignment: widget.isAI ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isAI
                    ? Colors.blue[50] // Light blue/gray for AI
                    : Colors.grey[200], // Light gray for user
                borderRadius: BorderRadius.circular(16),
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Text(
                widget.text,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: widget.isAI ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedTaskCard extends StatefulWidget {
  final Task task;
  final Duration delay;
  final bool isCompact;

  const _AnimatedTaskCard({
    required this.task,
    required this.delay,
    this.isCompact = false,
  });

  @override
  State<_AnimatedTaskCard> createState() => _AnimatedTaskCardState();
}

class _AnimatedTaskCardState extends State<_AnimatedTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    // Start animation after delay
    // Future.delayed(widget.delay, () {
      if (mounted) {
        // Play swoosh sound when animation starts
        _audioPlayer.play(AssetSource('swoosh.mp3'),volume: 1.0).catchError((e) {
          debugPrint('Error playing swoosh sound: $e');
        });
        _controller.forward();
      }
    // });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = getCategoryById(widget.task.categoryId);
    final timeFormat = DateFormat('MMM d, h:mm a');
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: EdgeInsets.only(bottom: widget.isCompact ? 8 : 12),
            padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Category Icon
                if (category != null)
                  Container(
                    width: widget.isCompact ? 32 : 40,
                    height: widget.isCompact ? 32 : 40,
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: widget.isCompact ? 18 : 20,
                    ),
                  )
                else
                  Container(
                    width: widget.isCompact ? 32 : 40,
                    height: widget.isCompact ? 32 : 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.task,
                      color: Colors.blue,
                      size: widget.isCompact ? 18 : 20,
                    ),
                  ),
                SizedBox(width: widget.isCompact ? 10 : 12),
                // Task Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.task.title,
                        style: TextStyle(
                          fontSize: widget.isCompact ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: widget.isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: widget.isCompact ? 2 : 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: widget.isCompact ? 12 : 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: widget.isCompact ? 3 : 4),
                          Flexible(
                            child: Text(
                              timeFormat.format(widget.task.scheduledTime),
                              style: TextStyle(
                                fontSize: widget.isCompact ? 11 : 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.task.isRecurring) ...[
                            SizedBox(width: widget.isCompact ? 6 : 8),
                            Icon(
                              Icons.repeat,
                              size: widget.isCompact ? 12 : 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: widget.isCompact ? 3 : 4),
                            Text(
                              'Recurring',
                              style: TextStyle(
                                fontSize: widget.isCompact ? 11 : 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Priority Indicator
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isCompact ? 6 : 8,
                    vertical: widget.isCompact ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.task.priority == TaskPriority.high
                        ? Colors.red.withOpacity(0.1)
                        : widget.task.priority == TaskPriority.medium
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.task.priority.displayName,
                    style: TextStyle(
                      fontSize: widget.isCompact ? 9 : 10,
                      fontWeight: FontWeight.w600,
                      color: widget.task.priority == TaskPriority.high
                          ? Colors.red
                          : widget.task.priority == TaskPriority.medium
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

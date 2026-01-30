import 'dart:convert';
import 'dart:developer';
import 'dart:async';
import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiService {
  // Detect if input is a query/question vs task creation
  Future<bool> isQuery(String input) async {
    try {
      final gemini = Gemini.instance;
      
      final prompt = """Is this a question about tasks (true) or task creation (false)? Return JSON: {"isQuery": true/false}

QUERIES: "How many tasks?", "What tasks today?", "Show tasks"
CREATION: "Remind me at 4PM", "Create task", "Schedule meeting"

Input: "$input" """;

      // Start timer for query detection
      final stopwatch = Stopwatch()..start();
      
      final response = await gemini.prompt(
        parts: [Part.text(prompt)],
        model: 'gemini-pro', // Gemini 3 Flash Preview model
      ).catchError((error) {
        log("Gemini query detection error: $error");
        return null;
      });
      
      // Stop timer and print elapsed time
      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;
      print("⏱️  QUERY DETECTION TIMER: ${elapsedMs}ms");

      if (response == null || response.output == null) {
        return false; // Default to task creation if detection fails
      }

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response.output!);
      if (jsonMatch == null) {
        return false;
      }

      final data = jsonDecode(jsonMatch.group(0)!);
      return data['isQuery'] == true;
    } catch (e) {
      log("Error detecting query: $e");
      return false; // Default to task creation
    }
  }

  Future<Map<String, dynamic>?> createTaskFromText(String input) async {
    try {
      print("Input: $input");
      
      final gemini = Gemini.instance;
      
      // Get current date and time for context
      final now = DateTime.now();
      final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final tomorrowDate = now.add(const Duration(days: 1));
      final tomorrow = "${tomorrowDate.year}-${tomorrowDate.month.toString().padLeft(2, '0')}-${tomorrowDate.day.toString().padLeft(2, '0')}";
      
      final prompt = """Extract task(s) from input. Return JSON only.

MULTIPLE tasks (use "and", "also", commas): {"tasks": [{"title":"","scheduledTime":null,"priority":"medium","categoryId":null,"needsTimeClarification":false}]}
SINGLE task: {"title":"","scheduledTime":null,"priority":"medium","categoryId":null,"needsTimeClarification":false}

TIME (local, no Z): Today=$today, Tomorrow=$tomorrow, Now=${now.hour}:${now.minute.toString().padLeft(2, '0')}
- Time only (e.g. "4PM") → TODAY: "${today}T16:00:00"
- Date+time → use specified
- No time/date → scheduledTime:null, needsTimeClarification:true
- Date only → time:23:59:00
- Recurring ("every X", "daily") → scheduledTime:current time (${now.toIso8601String().substring(0, 19)})

CATEGORIES: "work" (meetings, deadlines, projects), "personal" (family, friends, errands), "health" (exercise, doctor), "finance" (bills, banking), "general" (default)
PRIORITY: "low"/"medium"/"high" (default:"medium")
TITLE: Clean, remove "remind me" filler words

Input: "$input" """;

      // Start timer for performance measurement
      final stopwatch = Stopwatch()..start();
      
      // Use prompt method with fast Flash model
      final response = await gemini.prompt(
        parts: [Part.text(prompt)],
        model: 'gemini-pro', // Gemini 3 Flash Preview model
      ).catchError((error) {
        log("Gemini API Error: $error");
        return null;
      });
      
      // Stop timer and print elapsed time
      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;
      final elapsedSeconds = (elapsedMs / 1000).toStringAsFixed(2);
      print("⏱️  TASK CREATION TIMER: ${elapsedMs}ms (${elapsedSeconds}s)");
      log("Task creation response time: ${elapsedMs}ms");

      if (response == null || response.output == null) {
        log("No response from Gemini");
        return null;
      }

      print("Output: ${response.output}");

      // Extract JSON from response - handle both single object and array
      final jsonMatch = RegExp(r'\{[\s\S]*\}|\[[\s\S]*\]').firstMatch(response.output!);
      
      if (jsonMatch == null) {
        log("No JSON found in response: ${response.output}");
        return null;
      }

      final jsonData = jsonDecode(jsonMatch.group(0)!);
      
      // Check if it's an array of tasks or a single task
      if (jsonData is List) {
        // Multiple tasks - return as map with "tasks" key
        return {"tasks": jsonData};
      } else if (jsonData is Map<String, dynamic>) {
        // Check if it already has "tasks" key (multiple tasks format)
        if (jsonData.containsKey('tasks')) {
          return jsonData;
        } else {
          // Single task - return as is
          return jsonData;
        }
      }
      
      return jsonData as Map<String, dynamic>;
      
    } catch (e, stackTrace) {
      log("Error creating task from text: $e");
      log("StackTrace: $stackTrace");
      return null;
    }
  }
}

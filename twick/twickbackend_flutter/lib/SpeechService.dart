import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setVoice({
   "name": "Samantha",
});

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5); // Natural speaking rate
    await _tts.setPitch(1.05); // Slightly lower pitch for more natural sound
    await _tts.setVolume(1.0);
  }

  Future<void> speak(String text, {VoidCallback? onComplete}) async {
    if (text.trim().isEmpty) return;

    await _tts.stop();
    
    // Create a completer to wait for speech completion
    final completer = Completer<void>();
    
    // Set completion handler
    _tts.setCompletionHandler(() {
      if (!completer.isCompleted) {
        completer.complete();
      }
      // Call optional callback if provided
      if (onComplete != null) {
        onComplete();
      }
    });
    
    await _tts.speak(text);
    
    // Wait for speech to complete
    await completer.future;
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}

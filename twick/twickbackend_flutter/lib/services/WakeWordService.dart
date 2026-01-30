// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:flutter/material.dart';
// import 'package:twick/CreateTask.dart';

// class WakeWordService {
//   static final WakeWordService _instance = WakeWordService._internal();
//   factory WakeWordService() => _instance;
//   WakeWordService._internal();

//   final stt.SpeechToText _speech = stt.SpeechToText();
//   bool _isInitialized = false;
//   bool _isListening = false;
//   bool _isEnabled = false;
//   BuildContext? _context;
  
//   // Wake word variations
//   final List<String> _wakeWords = [
//     'hey twick',
//     'hi twick',
//     'twick',
//     'hey twik',
//     'hi twik',
//     'hi kevin',
//     'kevin'
//   ];

//   Future<void> initialize() async {
//     if (_isInitialized) return;
    
//     bool available = await _speech.initialize(
//       onStatus: (status) {
//         print('Wake word service status: $status');
//         _isListening = status == 'listening';
        
//         // If listening stopped and we're still enabled, restart
//         if (status == 'notListening' || status == 'done') {
//           if (_isEnabled && !_isListening) {
//             // Restart listening after a short delay
//             Future.delayed(const Duration(milliseconds: 500), () {
//               if (_isEnabled && !_isListening) {
//                 _listenForWakeWord();
//               }
//             });
//           }
//         }
//       },
//       onError: (error) {
//         print('Wake word service error: $error');
//         // Retry on error if still enabled
//         if (_isEnabled) {
//           Future.delayed(const Duration(seconds: 2), () {
//             if (_isEnabled) {
//               _listenForWakeWord();
//             }
//           });
//         }
//       },
//     );
    
//     _isInitialized = available;
//     print('Wake word service initialized: $available');
//   }

//   void startListening(BuildContext context) {
//     if (!_isInitialized) return;
    
//     // Update context
//     _context = context;
    
//     // If already listening, just update context and return
//     if (_isEnabled && _isListening) {
//       return;
//     }
    
//     // Start listening
//     _isEnabled = true;
//     _listenForWakeWord();
//   }

//   void stopListening() {
//     if (!_isEnabled) return;
    
//     _isEnabled = false;
//     _speech.stop();
//     _isListening = false;
//     // Keep context for potential restart
//   }

//   Future<void> _listenForWakeWord() async {
//     if (!_isEnabled || !_isInitialized) return;
    
//     // Prevent multiple simultaneous listening sessions
//     if (_isListening) return;
    
//     try {
//       await _speech.listen(
//         onResult: (result) {
//           if (!_isEnabled) return;
          
//           final recognizedText = result.recognizedWords.toLowerCase().trim();
//           print('Wake word recognition: $recognizedText');
          
//           // Check if any wake word is detected
//           for (final wakeWord in _wakeWords) {
//             if (recognizedText.contains(wakeWord)) {
//               print('Wake word detected: $wakeWord');
//               // Call async function without await (callback can't be async)
//               _onWakeWordDetected();
//               return;
//             }
//           }
          
//           // If final result and no wake word, restart listening
//           if (result.finalResult) {
//             // Small delay before restarting to avoid rapid restarts
//             Future.delayed(const Duration(milliseconds: 300), () {
//               if (_isEnabled && !_isListening) {
//                 _listenForWakeWord();
//               }
//             });
//           }
//         },
//         listenFor: const Duration(seconds: 30), // Longer listening period
//         pauseFor: const Duration(seconds: 2),
//         localeId: 'en_US',
//         listenMode: stt.ListenMode.confirmation,
//         cancelOnError: false,
//         partialResults: true,
//       );
//     } catch (e) {
//       print('Error in wake word listening: $e');
//       _isListening = false;
//       if (_isEnabled) {
//         // Retry after a short delay
//         Future.delayed(const Duration(seconds: 2), () {
//           if (_isEnabled && !_isListening) {
//             _listenForWakeWord();
//           }
//         });
//       }
//     }
//   }

//   Future<void> _onWakeWordDetected() async {
//     if (_context == null) return;
    
//     // Completely stop listening - disable the service
//     _isEnabled = false;
//     await _speech.stop();
//     _isListening = false;
    
//     // Wait a bit to ensure speech recognition is fully released
//     await Future.delayed(const Duration(milliseconds: 500));
    
//     // Open the assistant bottom sheet
//     openAssistantTab(_context!);
    
//     // Note: Wake word listening will be restarted when bottom sheet closes
//     // This is handled externally by checking if we're back on HomePage
//   }

//   bool get isListening => _isListening;
//   bool get isEnabled => _isEnabled;
// }

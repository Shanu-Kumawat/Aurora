import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';
import '../models/intent.dart';

/// Service to parse voice commands into intents
class CommandService {
  static final CommandService _instance = CommandService._internal();
  factory CommandService() => _instance;
  CommandService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  static const _listenDuration = Duration(seconds: 10);
  static const _cleanupDelay = Duration(milliseconds: 1000);
  String _currentLocaleId = 'en_US';

  // Stream for recognized text (for UI display)
  final StreamController<String> _recognizedTextController =
      StreamController<String>.broadcast();
  Stream<String> get recognizedTextStream => _recognizedTextController.stream;

  String _lastRecognizedText = '';
  bool _isListening = false;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          print('Speech recognition error: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          _isListening = (status == 'listening');
        },
        debugLogging: true,
      );
      
      if (_isInitialized) {
        final systemLocale = await _speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? 'en_US';
        print('Speech recognition initialized successfully with locale: $_currentLocaleId');
      }
    } catch (e) {
      print('Speech initialization error: $e');
      _isInitialized = false;
    }

    return _isInitialized;
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    return await initialize();
  }

  /// Listen for a command and parse it into an intent
  Future<Intent> listenForCommand({
    Duration timeout = _listenDuration,
  }) async {
    if (!_isInitialized) {
      print('CommandService: Not initialized, initializing now...');
      await initialize();
    }

    if (!_isInitialized) {
      print('CommandService: Speech recognition not initialized');
      return Intent(type: IntentType.unknown);
    }

    // Cleanup: Stop any existing session and wait
    try {
      await _speech.stop();
      await Future.delayed(_cleanupDelay);
    } catch (e) {
      print('CommandService: Cleanup error: $e');
    }

    print('CommandService: Starting to listen for command...');
    
    _lastRecognizedText = '';
    _recognizedTextController.add('');
    
    final completer = Completer<String>();

    // Start listening
    try {
      _isListening = true;
      
      await _speech.listen(
        onResult: (result) {
          _lastRecognizedText = result.recognizedWords.toLowerCase();
          print('CommandService: Recognized text: "$_lastRecognizedText"');

          // Emit to UI stream
          _recognizedTextController.add(_lastRecognizedText);

          // If final result, complete
          if (result.finalResult && !completer.isCompleted) {
            print('CommandService: Final result received');
            completer.complete(_lastRecognizedText);
          }
        },
        listenFor: timeout,
        localeId: _currentLocaleId,
        partialResults: true,
      );

      print('CommandService: Listen started successfully');
    } catch (e) {
      print('CommandService: Failed to start listening: $e');
      _isListening = false;
      if (!completer.isCompleted) {
        completer.complete('');
      }
    }

    // Wait for result with timeout
    String recognizedText = '';
    try {
      recognizedText = await completer.future.timeout(
        timeout,
        onTimeout: () {
          print('CommandService: Timeout waiting for speech');
          return _lastRecognizedText;
        },
      );
    } catch (e) {
      print('CommandService: Error waiting for result: $e');
    }

    await _speech.stop();
    _isListening = false;
    _recognizedTextController.add(''); // Clear UI

    print('CommandService: Listening stopped. Final text: "$recognizedText"');

    if (recognizedText.isEmpty) {
      print('CommandService: No speech detected');
      // Double vibrate to indicate no speech
      Vibration.vibrate(duration: 100);
      await Future.delayed(const Duration(milliseconds: 200));
      Vibration.vibrate(duration: 100);
      return Intent(type: IntentType.unknown);
    }

    return parseCommand(recognizedText);
  }

  /// Parse a text command into an intent
  Intent parseCommand(String command) {
    final lowerCommand = command.toLowerCase().trim();

    // StartNavigation: "navigate to [destination]"
    if (lowerCommand.contains('navigate to')) {
      final destination = lowerCommand.replaceFirst('navigate to', '').trim();
      if (destination.isNotEmpty) {
        return Intent(
          type: IntentType.startNavigation,
          entities: {'destination': destination},
        );
      }
    }

    // StopNavigation: "stop navigation"
    if (lowerCommand.contains('stop navigation') ||
        lowerCommand.contains('cancel navigation')) {
      return Intent(type: IntentType.stopNavigation);
    }

    // GetCurrentLocation: "where am i"
    if (lowerCommand.contains('where am i') ||
        lowerCommand.contains('where am i') ||
        lowerCommand.contains('my location')) {
      return Intent(type: IntentType.getCurrentLocation);
    }

    // GetTripStatus: "how much further" or "eta"
    if (lowerCommand.contains('how much further') ||
        lowerCommand.contains('how far') ||
        lowerCommand.contains('eta') ||
        lowerCommand.contains('time remaining')) {
      return Intent(type: IntentType.getTripStatus);
    }

    // TriggerEmergency: "start emergency" or "emergency"
    if (lowerCommand.contains('start emergency') ||
        lowerCommand == 'emergency') {
      return Intent(type: IntentType.triggerEmergency);
    }

    // CancelEmergency: "cancel emergency"
    if (lowerCommand.contains('cancel emergency')) {
      return Intent(type: IntentType.cancelEmergency);
    }

    // QueryAI: "ask gemini" or "describe my surroundings"
    if (lowerCommand.contains('ask gemini')) {
      final query = lowerCommand.replaceFirst('ask gemini', '').trim();
      return Intent(
        type: IntentType.queryAI,
        entities: {'query': query.isNotEmpty ? query : 'general question'},
      );
    }

    if (lowerCommand.contains('describe my surroundings') ||
        lowerCommand.contains('what do you see')) {
      return Intent(
        type: IntentType.queryAI,
        entities: {'query': 'describe surroundings'},
      );
    }

    // Unknown command
    return Intent(type: IntentType.unknown);
  }

  /// Check if speech recognition is available
  bool get isAvailable => _speech.isAvailable;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Stop listening
  Future<void> stop() async {
    await _speech.stop();
    _recognizedTextController.add(''); // Clear UI
  }

  /// Clear recognized text display
  void clearRecognizedText() {
    _recognizedTextController.add('');
  }

  /// Dispose resources
  void dispose() {
    _speech.stop();
    _recognizedTextController.close();
  }
}

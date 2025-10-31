import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

/// Manages all audio (TTS) and haptic feedback in the app
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// Initialize the TTS engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Set up completion handlers
    _tts.setStartHandler(() {
      _isSpeaking = true;
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      print('TTS Error: $msg');
    });

    _isInitialized = true;
  }

  /// Speak a message using TTS and wait for it to complete
  Future<void> speak(String message) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _tts.speak(message);

    // Wait for speech to complete
    while (_isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    await _tts.stop();
  }

  /// Short single vibration
  Future<void> vibrateShort() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      await Vibration.vibrate(duration: 100);
    }
  }

  /// Short double vibration (for GPS lost)
  Future<void> vibrateDouble() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      await Vibration.vibrate(duration: 100);
      await Future.delayed(const Duration(milliseconds: 100));
      await Vibration.vibrate(duration: 100);
    }
  }

  /// Short triple vibration (for hardware reconnected)
  Future<void> vibrateTriple() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      await Vibration.vibrate(duration: 100);
      await Future.delayed(const Duration(milliseconds: 100));
      await Vibration.vibrate(duration: 100);
      await Future.delayed(const Duration(milliseconds: 100));
      await Vibration.vibrate(duration: 100);
    }
  }

  /// Long slow pulse vibration (for hardware disconnected)
  Future<void> vibrateLongPulse() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      await Vibration.vibrate(duration: 500);
    }
  }

  /// Urgent vibration pattern (for obstacles)
  Future<void> vibrateUrgent() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      await Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 200]);
    }
  }

  /// Cancel any ongoing vibration
  Future<void> cancelVibration() async {
    await Vibration.cancel();
  }

  /// Dispose resources
  void dispose() {
    _tts.stop();
  }
}

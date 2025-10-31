import 'dart:async';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import '../constants/app_constants.dart';

/// Service for wake word detection using Porcupine
class WakeWordService {
  static final WakeWordService _instance = WakeWordService._internal();
  factory WakeWordService() => _instance;
  WakeWordService._internal();

  PorcupineManager? _porcupineManager;
  bool _isListening = false;

  final StreamController<bool> _wakeWordController =
      StreamController<bool>.broadcast();
  Stream<bool> get wakeWordStream => _wakeWordController.stream;

  bool get isListening => _isListening;

  /// Initialize wake word detection
  Future<bool> initialize(String accessKey) async {
    try {
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        accessKey,
        [AppConstants.wakeWordAssetPath],
        _wakeWordCallback,
        errorCallback: _errorCallback,
      );
      return true;
    } catch (e) {
      print('Error initializing Porcupine: $e');
      return false;
    }
  }

  /// Start listening for wake word
  Future<void> startListening() async {
    if (_isListening || _porcupineManager == null) return;

    try {
      await _porcupineManager!.start();
      _isListening = true;
    } on PorcupineException catch (e) {
      print('Failed to start wake word detection: $e');
    }
  }

  /// Stop listening for wake word
  Future<void> stopListening() async {
    if (!_isListening || _porcupineManager == null) return;

    try {
      await _porcupineManager!.stop();
      _isListening = false;
    } on PorcupineException catch (e) {
      print('Failed to stop wake word detection: $e');
    }
  }

  /// Wake word detected callback
  void _wakeWordCallback(int keywordIndex) {
    if (keywordIndex >= 0) {
      print('Wake word detected!');
      _wakeWordController.add(true);
    }
  }

  /// Error callback
  void _errorCallback(PorcupineException error) {
    print('Porcupine error: $error');
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopListening();
    await _porcupineManager?.delete();
    _wakeWordController.close();
  }
}

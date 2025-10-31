import 'dart:async';
import '../config/api_keys.dart';
import '../constants/app_constants.dart';
import '../models/intent.dart';
import 'audio_manager.dart';
import 'command_service.dart';
import 'connectivity_service.dart';
import 'emergency_service.dart';
import 'geocoding_service.dart';
import 'hardware_service.dart';
import 'location_service.dart';
import 'navigation_service.dart';
import 'wake_word_service.dart';
import 'onboarding_service.dart';

/// Main coordinator that handles all app logic and error scenarios
class AppCoordinator {
  static final AppCoordinator _instance = AppCoordinator._internal();
  factory AppCoordinator() => _instance;
  AppCoordinator._internal();

  final AudioManager _audioManager = AudioManager();
  final CommandService _commandService = CommandService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final EmergencyService _emergencyService = EmergencyService();
  final GeocodingService _geocodingService = GeocodingService();
  final HardwareService _hardwareService = HardwareService();
  final LocationService _locationService = LocationService();
  final NavigationService _navigationService = NavigationService();
  final WakeWordService _wakeWordService = WakeWordService();
  final OnboardingService _onboardingService = OnboardingService();

  StreamSubscription? _wakeWordSubscription;
  StreamSubscription? _gpsStatusSubscription;
  StreamSubscription? _hardwareConnectionSubscription;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _hardwareMessageSubscription;

  bool _isProcessingCommand = false;

  /// Initialize the app
  Future<void> initialize() async {
    // Initialize all services
    await _audioManager.initialize();
    await _commandService.initialize();
    await _connectivityService.initialize();
    await _emergencyService.loadEmergencyContact();
    await _locationService.startTracking();

    // Set up error monitoring
    _setupErrorMonitoring();

    // Check if first launch
    final isFirstLaunch = await _onboardingService.isFirstLaunch();
    if (isFirstLaunch) {
      await _onboardingService.runOnboarding();
    }

    // Start wake word detection with Porcupine
    final initialized = await _wakeWordService.initialize(
      ApiKeys.porcupineAccessKey,
    );
    if (initialized) {
      await _wakeWordService.startListening();
    } else {
      print(
        'Wake word detection failed to initialize. Using manual trigger only.',
      );
    }

    // Set up wake word listener
    _setupWakeWordListener();
  }

  /// Set up error monitoring for GPS, hardware, and connectivity
  void _setupErrorMonitoring() {
    // Monitor GPS signal
    _gpsStatusSubscription = _locationService.gpsStatusStream.listen((
      hasSignal,
    ) {
      if (!hasSignal) {
        _handleGpsLost();
      } else {
        _handleGpsRestored();
      }
    });

    // Monitor hardware connection
    _hardwareConnectionSubscription = _hardwareService.connectionStream.listen((
      isConnected,
    ) {
      if (!isConnected) {
        _handleHardwareDisconnected();
      } else {
        _handleHardwareReconnected();
      }
    });

    // Monitor hardware messages (for obstacle detection)
    _hardwareMessageSubscription = _hardwareService.messageStream.listen((
      message,
    ) {
      if (message['type'] == 'obstacle_detected') {
        _handleObstacleDetected(message);
      }
    });

    // Monitor connectivity
    _connectivitySubscription = _connectivityService.connectivityStream.listen((
      isConnected,
    ) {
      // Handle connectivity changes if needed
    });
  }

  /// Set up wake word listener
  void _setupWakeWordListener() {
    _wakeWordSubscription = _wakeWordService.wakeWordStream.listen((_) {
      _handleWakeWord();
    });
  }

  /// Handle wake word detected
  Future<void> _handleWakeWord() async {
    if (_isProcessingCommand) return;

    _isProcessingCommand = true;

    print('AppCoordinator: Wake word detected, listening for command...');

    // Stop wake word detection temporarily to release microphone
    await _wakeWordService.stopListening();

    // Provide haptic feedback only (no speech to avoid blocking microphone)
    await _audioManager.vibrateShort();

    // CRITICAL: Stop any existing speech recognition session
    await _commandService.stop();

    // Short delay to ensure microphone is released
    await Future.delayed(const Duration(milliseconds: 500));

    // Listen for command with 10-second timeout
    final intent = await _commandService.listenForCommand(
      timeout: const Duration(seconds: 10),
    );

    print('AppCoordinator: Intent received: ${intent.type}');

    await _handleIntent(intent);

    // Restart wake word detection
    await _wakeWordService.startListening();

    _isProcessingCommand = false;
  }

  /// Handle parsed intent
  Future<void> _handleIntent(Intent intent) async {
    switch (intent.type) {
      case IntentType.startNavigation:
        final destination = intent.destination;
        if (destination != null && destination.isNotEmpty) {
          await _navigationService.startNavigation(destination);
        } else {
          await _audioManager.speak('Please specify a destination');
        }
        break;

      case IntentType.stopNavigation:
        _navigationService.stopNavigation();
        break;

      case IntentType.getCurrentLocation:
        await _handleGetCurrentLocation();
        break;

      case IntentType.getTripStatus:
        await _handleGetTripStatus();
        break;

      case IntentType.triggerEmergency:
        await _emergencyService.triggerEmergency();
        break;

      case IntentType.cancelEmergency:
        await _emergencyService.cancelEmergency();
        break;

      case IntentType.queryAI:
        await _handleQueryAI();
        break;

      case IntentType.unknown:
        await _audioManager.speak(AppConstants.msgCommandNotUnderstood);
        break;
    }
  }

  /// Handle get current location intent
  Future<void> _handleGetCurrentLocation() async {
    final location = _locationService.currentLocation;

    if (location == null) {
      await _audioManager.speak('Unable to get your current location');
      return;
    }

    // Try to reverse geocode
    final address = await _geocodingService.reverseGeocode(location);

    if (address != null) {
      await _audioManager.speak('You are at $address');
    } else {
      await _audioManager.speak(
        'You are at latitude ${location.latitude.toStringAsFixed(4)}, '
        'longitude ${location.longitude.toStringAsFixed(4)}',
      );
    }
  }

  /// Handle get trip status intent
  Future<void> _handleGetTripStatus() async {
    final status = await _navigationService.getTripStatus();
    await _audioManager.speak(status);
  }

  /// Handle AI query intent (stubbed for future)
  Future<void> _handleQueryAI() async {
    await _audioManager.speak(AppConstants.msgAiFeatureComingSoon);
  }

  // Error Handlers

  /// Handle GPS signal lost
  void _handleGpsLost() {
    _audioManager.speak(AppConstants.msgGpsLost);
    _audioManager.vibrateDouble();
    _navigationService.pauseNavigation();
  }

  /// Handle GPS signal restored
  void _handleGpsRestored() {
    _audioManager.speak(AppConstants.msgGpsRestored);
    _audioManager.vibrateShort();
    _navigationService.resumeNavigation();
  }

  /// Handle hardware disconnected
  void _handleHardwareDisconnected() {
    _audioManager.speak(AppConstants.msgHardwareDisconnected);
    _audioManager.vibrateLongPulse();
  }

  /// Handle hardware reconnected
  void _handleHardwareReconnected() {
    _audioManager.speak(AppConstants.msgHardwareReconnected);
    _audioManager.vibrateTriple();
  }

  /// Handle obstacle detected
  void _handleObstacleDetected(Map<String, dynamic> data) {
    final distance = data['distance'] as int? ?? 0;
    _audioManager.speak(
      '${AppConstants.msgObstacleDetected} at $distance centimeters',
    );
    _audioManager.vibrateUrgent();
  }

  /// Manually trigger command listening (for testing without wake word)
  Future<void> triggerCommandListening() async {
    await _handleWakeWord();
  }

  /// Dispose all resources
  void dispose() {
    _wakeWordSubscription?.cancel();
    _gpsStatusSubscription?.cancel();
    _hardwareConnectionSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _hardwareMessageSubscription?.cancel();

    _wakeWordService.dispose();
    _locationService.dispose();
    _hardwareService.dispose();
    _connectivityService.dispose();
    _navigationService.dispose();
    _audioManager.dispose();
    _commandService.dispose();
  }
}

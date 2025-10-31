import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../constants/app_constants.dart';
import 'audio_manager.dart';
import 'command_service.dart';
import 'hardware_service.dart';
import 'location_service.dart';
import 'emergency_service.dart';

/// Service to handle first-launch onboarding
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  final AudioManager _audioManager = AudioManager();
  final CommandService _commandService = CommandService();
  final HardwareService _hardwareService = HardwareService();
  final LocationService _locationService = LocationService();
  final EmergencyService _emergencyService = EmergencyService();

  /// Check if this is the first launch
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyOnboardingComplete) != true;
  }

  /// Mark onboarding as complete
  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingComplete, true);
  }

  /// Run the complete onboarding flow
  Future<void> runOnboarding() async {
    // Step 1: Welcome message
    await _audioManager.speak(AppConstants.msgWelcome);
    await Future.delayed(const Duration(seconds: 2));

    // Step 2-3: Request location permission
    await _requestLocationPermission();

    // Step 4-5: Request microphone permission
    await _audioManager.speak(AppConstants.msgLocationPermission);
    await Future.delayed(const Duration(seconds: 1));
    await _requestMicrophonePermission();

    // Step 6-9: Set up emergency contact
    await _audioManager.speak(AppConstants.msgEmergencyContactSetup);
    await Future.delayed(const Duration(seconds: 1));
    await _setupEmergencyContact();

    // Step 10-12: Connect to hardware
    await _audioManager.speak(AppConstants.msgHardwareSetup);
    await _waitForHardwareConnection();

    // Step 13: Demo command
    await _audioManager.speak(AppConstants.msgTutorial);
    await _demoCommand();

    // Step 14: Complete
    await _audioManager.speak(AppConstants.msgOnboardingComplete);
    await markOnboardingComplete();
  }

  /// Request location permission
  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      await _locationService.requestPermission();
    } else {
      await _audioManager.speak(
        'Location permission is required for navigation',
      );
    }
  }

  /// Request microphone permission
  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      await _commandService.initialize();
    } else {
      await _audioManager.speak(
        'Microphone permission is required to hear your commands',
      );
    }
  }

  /// Set up emergency contact
  Future<void> _setupEmergencyContact() async {
    // Request contacts permission
    final contactsStatus = await Permission.contacts.request();

    if (!contactsStatus.isGranted) {
      await _audioManager.speak(
        'Contacts permission is needed to set up emergency contact',
      );
      return;
    }

    // Listen for contact name
    final intent = await _commandService.listenForCommand(
      timeout: const Duration(seconds: 10),
    );

    if (intent.type.toString().isEmpty) {
      await _audioManager.speak(
        'I didn\'t hear a name. Skipping emergency contact setup',
      );
      return;
    }

    // Search for contact (simplified - in real app, use speech recognition result)
    // For demo purposes, we'll use a placeholder
    try {
      // Check permission and get contacts
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );

        if (contacts.isNotEmpty) {
          // Use first contact as example (in production, search by name)
          final contact = contacts.first;
          final phone = contact.phones.isNotEmpty
              ? contact.phones.first.number
              : '';

          if (phone.isNotEmpty) {
            await _emergencyService.saveEmergencyContact(
              contact.displayName,
              phone,
            );

            await _audioManager.speak(
              'Contact ${contact.displayName} with number $phone saved. ${AppConstants.msgEmergencyContactSaved}',
            );
          } else {
            await _audioManager.speak(
              'Contact has no phone number. Skipping emergency contact setup',
            );
          }
        } else {
          await _audioManager.speak(
            'No contacts found. You can set this up later',
          );
        }
      }
    } catch (e) {
      print('Error accessing contacts: $e');
      await _audioManager.speak(
        'Unable to access contacts. You can set this up later',
      );
    }
  }

  /// Wait for hardware connection
  Future<void> _waitForHardwareConnection() async {
    // Give user time to connect to Wi-Fi
    await Future.delayed(const Duration(seconds: 3));

    // Try to connect multiple times
    for (int i = 0; i < 10; i++) {
      final connected = await _hardwareService.connect();

      if (connected) {
        await _audioManager.speak(AppConstants.msgHardwareConnected);
        await _audioManager.vibrateShort();
        return;
      }

      await Future.delayed(const Duration(seconds: 3));
    }

    await _audioManager.speak(
      'Unable to connect to hardware. You can continue without it, '
      'but obstacle detection will not be available',
    );
  }

  /// Demo the "where am I" command
  Future<void> _demoCommand() async {
    // Wait for user to say the command
    await Future.delayed(const Duration(seconds: 3));

    final location = await _locationService.getCurrentLocation();

    if (location != null) {
      await _audioManager.speak(
        'You are at latitude ${location.latitude.toStringAsFixed(4)}, '
        'longitude ${location.longitude.toStringAsFixed(4)}',
      );
    }
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../models/intent.dart';
import 'audio_manager.dart';
import 'location_service.dart';
import 'command_service.dart';

/// Service to handle emergency protocol
class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  final AudioManager _audioManager = AudioManager();
  final LocationService _locationService = LocationService();
  final CommandService _commandService = CommandService();

  String? _emergencyContactName;
  String? _emergencyContactPhone = '6350207472'; // Default emergency contact

  /// Load emergency contact from storage
  Future<void> loadEmergencyContact() async {
    final prefs = await SharedPreferences.getInstance();
    _emergencyContactName = prefs.getString(
      AppConstants.keyEmergencyContactName,
    );
    // Load from storage, but keep default if not set
    final storedPhone = prefs.getString(
      AppConstants.keyEmergencyContactPhone,
    );
    if (storedPhone != null && storedPhone.isNotEmpty) {
      _emergencyContactPhone = storedPhone;
    }
  }

  /// Save emergency contact to storage
  Future<void> saveEmergencyContact(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyEmergencyContactName, name);
    await prefs.setString(AppConstants.keyEmergencyContactPhone, phone);

    _emergencyContactName = name;
    _emergencyContactPhone = phone;
  }

  /// Check if emergency contact is set up
  bool get hasEmergencyContact => _emergencyContactPhone != null;

  /// Trigger emergency protocol
  Future<void> triggerEmergency() async {
    if (!hasEmergencyContact) {
      await _audioManager.speak('Emergency contact not set up');
      return;
    }

    // Ask for confirmation
    await _audioManager.speak(AppConstants.msgEmergencyConfirm);

    // Listen for "yes" response
    final response = await _commandService.listenForCommand(
      timeout: const Duration(seconds: 5),
    );

    // For now, assuming any spoken response confirms (simplified)
    // In production, parse response for explicit "yes"
    if (response.type != IntentType.unknown) {
      await _sendEmergencySMS();
    } else {
      await _audioManager.speak('Emergency cancelled');
    }
  }

  /// Send emergency SMS
  Future<void> _sendEmergencySMS() async {
    if (!hasEmergencyContact) return;

    final location = _locationService.currentLocation;
    final locationText = location != null
        ? 'My location: https://www.google.com/maps?q=${location.latitude},${location.longitude}'
        : 'Location unavailable';

    final message = 'AURORA EMERGENCY ALERT: I need help. $locationText';

    final smsUri = Uri.parse(
      'sms:$_emergencyContactPhone?body=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        await _audioManager.speak(
          'Emergency message sent to $_emergencyContactName',
        );
      } else {
        await _audioManager.speak('Unable to send emergency message');
      }
    } catch (e) {
      print('Error sending emergency SMS: $e');
      await _audioManager.speak('Error sending emergency message');
    }
  }

  /// Cancel emergency
  Future<void> cancelEmergency() async {
    await _audioManager.speak('Emergency cancelled');
  }
}

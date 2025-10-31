/// App-wide constants for Aurora
class AppConstants {
  // Hardware Configuration
  static const String piWifiSSID = 'AuroraPi';
  static const String piIPAddress = '192.168.4.1';
  static const String piWebSocketUrl = 'ws://192.168.4.1:8765';
  static const String piOsrmUrl = 'http://192.168.4.1:5000';

  // Wake Word
  static const String wakeWord = 'Hey Aurora';
  static const String wakeWordAssetPath = 'assets/hey_aurora.ppn';

  // Shared Preferences Keys
  static const String keyFirstLaunch = 'first_launch';
  static const String keyEmergencyContactName = 'emergency_contact_name';
  static const String keyEmergencyContactPhone = 'emergency_contact_phone';
  static const String keyOnboardingComplete = 'onboarding_complete';

  // Navigation
  static const double arrivalThresholdMeters = 20.0;
  static const double waypointThresholdMeters = 30.0;
  static const int navigationUpdateIntervalMs = 2000;

  // Geocoding
  static const String nominatimUrl =
      'https://nominatim.openstreetmap.org/search';

  // Audio Feedback Messages
  static const String msgWelcome =
      'Welcome to Aurora. To get started, I\'ll need a few permissions. First, to provide navigation, Aurora needs access to your location. Is it okay to enable this?';
  static const String msgLocationPermission =
      'Thank you. Next, I need to use the microphone to hear your commands. Is that alright?';
  static const String msgEmergencyContactSetup =
      'Now, let\'s set up your emergency contact. This person will be notified if you use the emergency command. This information will be stored securely only on your device. Please say the full name of your contact.';
  static const String msgEmergencyContactSaved =
      'Great. Emergency contact saved.';
  static const String msgHardwareSetup =
      'The final setup step is to connect to your Aurora hardware. This device provides obstacle detection. Please go to your phone\'s Wi-Fi settings, find the network named \'AuroraPi\', and connect to it. Once you are connected, please return to this app.';
  static const String msgHardwareConnected =
      'Hardware connected. Obstacle detection is now active.';
  static const String msgTutorial =
      'Setup is complete. Let\'s try a few basic commands. To find out where you are, say \'Hey Aurora, where am I?\'';
  static const String msgOnboardingComplete =
      'Perfect. You are now ready to use Aurora.';

  static const String msgNeedInternet =
      'To find your destination, I need a brief internet connection. Please connect to Wi-Fi or mobile data and try again.';
  static const String msgDestinationNotFound =
      'I\'m sorry, I could not find that destination.';
  static const String msgOfflineNavigationUnavailable =
      'Offline navigation is not available. I can try using an online service, which will use mobile data. Is that okay?';
  static const String msgRouteCalculationFailed =
      'I\'m sorry, I couldn\'t calculate a route to that destination.';

  static const String msgGpsLost =
      'Lost GPS signal. Trying to reconnect. Navigation is paused.';
  static const String msgGpsRestored =
      'GPS signal restored. Resuming navigation.';
  static const String msgHardwareDisconnected =
      'Warning: Hardware connection lost. Obstacle detection is offline.';
  static const String msgHardwareReconnected =
      'Hardware reconnected. Obstacle detection is active.';
  static const String msgCommandNotUnderstood =
      'I\'m sorry, I didn\'t quite get that. Please try again.';
  static const String msgObstacleDetected = 'Obstacle detected ahead.';

  static const String msgEmergencyConfirm =
      'Confirm emergency protocol? Say \'yes\' or \'no\'.';
  static const String msgAiFeatureComingSoon =
      'This feature requires an internet connection and will be available in a future update.';
}

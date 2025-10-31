# 🚀 Aurora - Navigation Assistant for the Visually Impaired

Aurora is a voice-first, offline-preferred navigation and object detection application designed specifically for visually impaired users. The app uses a hybrid approach combining local Raspberry Pi hardware for offline routing and obstacle detection with online services as fallback.

## ✨ Core Features

- **Voice-First Interface**: Control everything with voice commands using "Hey Aurora" wake word
- **Two-Stage Navigation**: 
  - Stage 1 (Finding): Uses online geocoding to convert destination names to coordinates
  - Stage 2 (Routing): Offline-first routing using Raspberry Pi OSRM, with online fallback
- **Hardware Integration**: Connects to Raspberry Pi for obstacle detection via camera and ultrasonic sensor
- **Emergency Protocol**: Quick voice-activated emergency contact system
- **Comprehensive Feedback**: Audio (TTS) and haptic feedback for all operations
- **Accessible Onboarding**: Complete voice-guided first-time setup

## 🎯 Voice Commands

After saying "Hey Aurora", you can use:

- **"Navigate to [destination]"** - Start navigation
- **"Stop navigation"** - Stop current navigation
- **"Where am I?"** - Get current location
- **"How much further?"** - Get trip status
- **"Start emergency"** - Trigger emergency protocol
- **"Cancel emergency"** - Cancel emergency
- **"Ask Gemini [query]"** - AI features (coming soon)
- **"Describe my surroundings"** - AI vision (coming soon)

## 📋 Prerequisites

### Software Requirements
- Flutter SDK 3.9.0 or higher
- Android Studio (for Android development)
- Dart SDK (included with Flutter)

### Hardware Requirements (Optional but Recommended)
- Raspberry Pi with:
  - Pi Camera Module
  - Ultrasonic Distance Sensor
  - Wi-Fi capability
  - Running OSRM server on port 5000
  - Running WebSocket server on port 8765

### API Keys Required
- **Porcupine Wake Word**: Get free access key from [Picovoice Console](https://console.picovoice.ai/)
- **OpenRouteService** (optional): Get free API key from [OpenRouteService](https://openrouteservice.org/)

## 🛠️ Installation & Setup

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure API Keys

Create a file `lib/config/api_keys.dart`:
```dart
class ApiKeys {
  static const String porcupineAccessKey = 'YOUR_PORCUPINE_KEY_HERE';
  static const String openRouteServiceKey = 'YOUR_ORS_KEY_HERE'; // Optional
}
```

### 3. Wake Word Setup

Download your "Hey Aurora" wake word model from Picovoice Console and place it in:
```
assets/hey_aurora.ppn
```

### 4. Run the App
```bash
flutter run
```

## 📱 First Launch - Onboarding Flow

On first launch, Aurora will guide you through:

1. **Location Permission** - Required for navigation
2. **Microphone Permission** - Required for voice commands
3. **Emergency Contact Setup** - Voice-guided contact selection
4. **Hardware Connection** - Connect to AuroraPi Wi-Fi network
5. **Tutorial** - Try your first command

## 🏗️ Project Structure

```
lib/
├── constants/
│   └── app_constants.dart          # App-wide constants and messages
├── models/
│   ├── intent.dart                 # Voice command intent models
│   └── route.dart                  # Navigation route models
├── providers/
│   ├── osrm_routing_provider.dart  # Offline routing (Pi)
│   └── online_routing_provider.dart # Online routing fallback
├── screens/
│   └── home_screen.dart            # Main UI screen
├── services/
│   ├── app_coordinator.dart        # Main app coordinator
│   ├── audio_manager.dart          # TTS and haptic feedback
│   ├── command_service.dart        # Voice command parsing
│   ├── connectivity_service.dart   # Internet connectivity
│   ├── emergency_service.dart      # Emergency protocol
│   ├── geocoding_service.dart      # Address to coordinates
│   ├── hardware_service.dart       # Pi WebSocket communication
│   ├── location_service.dart       # GPS and location tracking
│   ├── navigation_service.dart     # Navigation logic
│   ├── onboarding_service.dart     # First-time setup
│   └── wake_word_service.dart      # Wake word detection
└── main.dart                        # App entry point
```

## 🔧 Configuration

### Raspberry Pi Setup

Your Raspberry Pi should:
1. Create a Wi-Fi hotspot named `AuroraPi`
2. Have static IP `192.168.4.1`
3. Run OSRM server: `http://192.168.4.1:5000`
4. Run WebSocket server: `ws://192.168.4.1:8765`

### Modify Constants

Edit `lib/constants/app_constants.dart` to change:
- Pi IP address and ports
- Navigation thresholds
- Audio feedback messages
- Wake word settings

## 🚨 Error Handling

Aurora provides comprehensive error handling with audio and haptic feedback:

| Scenario | Voice Feedback | Haptic Pattern |
|----------|---------------|----------------|
| GPS Lost | "Lost GPS signal..." | Double vibration |
| GPS Restored | "GPS signal restored..." | Single vibration |
| Hardware Disconnected | "Hardware connection lost..." | Long pulse |
| Hardware Reconnected | "Hardware reconnected..." | Triple vibration |
| Obstacle Detected | "Obstacle detected ahead..." | Urgent pattern |
| Command Not Understood | "I didn't quite get that..." | None |

## 🧪 Testing

### Test Without Hardware
The app gracefully handles missing hardware and will offer online routing as fallback.

### Test Without Wake Word
Use the "TAP TO SPEAK" button on the main screen to manually trigger voice command listening.

## 📦 Building for Release

### Android APK
```bash
flutter build apk --release
```

## 🔒 Privacy & Safety

- All emergency contact data stored locally on device
- Location data only accessed with explicit permission
- Emergency SMS sent only after voice confirmation

## 📄 License

MIT License

---

**Remember**: Aurora is designed to be a trustworthy companion. Every feature prioritizes user safety, clear communication, and accessibility.

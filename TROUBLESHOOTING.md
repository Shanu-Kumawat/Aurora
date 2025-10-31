# 🔧 Aurora Troubleshooting Guide

## Common Issues and Solutions

### 🚫 Build & Setup Issues

#### "Package not found" errors
**Problem:** Dependencies not installed
**Solution:**
```bash
cd /home/shanu/Projects/Flutter/aurora
flutter clean
flutter pub get
```

#### "SDK version" errors
**Problem:** Incompatible Flutter SDK
**Solution:**
```bash
flutter --version  # Check current version
flutter upgrade    # Upgrade to latest
```

#### Android build fails
**Problem:** Android configuration issues
**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

### 🎤 Voice Recognition Issues

#### "Command not understood" every time
**Symptoms:** App always responds with "I didn't quite get that"
**Possible Causes:**
1. Microphone permission not granted
2. Background noise
3. Speaking before beep/vibration
4. Speech recognition not initialized

**Solutions:**
```
1. Check Settings > Apps > Aurora > Permissions > Microphone = Allowed
2. Test in quiet environment
3. Wait for short vibration after tapping button before speaking
4. Restart app to reinitialize speech recognition
5. Check device microphone with another app
```

#### Wake word not working
**Problem:** "Hey Aurora" doesn't trigger listening
**Possible Causes:**
1. Porcupine API key not configured
2. Wake word model file missing
3. Wake word service not started

**Solutions:**
```
1. Configure API key in lib/config/api_keys.dart
2. Download hey_aurora.ppn from Picovoice Console
3. Place file in assets/hey_aurora.ppn
4. Uncomment wake word initialization in app_coordinator.dart
5. Rebuild app: flutter run
```

**Workaround:** Use "TAP TO SPEAK" button instead

---

### 📍 Location & GPS Issues

#### "Unable to get current location"
**Symptoms:** Location commands fail
**Possible Causes:**
1. Location permission not granted
2. GPS disabled
3. Indoor location with weak signal
4. Location services disabled

**Solutions:**
```
1. Settings > Apps > Aurora > Permissions > Location = "Allow all the time"
2. Enable GPS in device Quick Settings
3. Go outside or near window for better signal
4. Settings > Location > Turn ON
5. Wait 30 seconds for GPS to acquire satellites
```

#### GPS keeps losing signal
**Symptoms:** Constant "Lost GPS signal" messages
**Possible Causes:**
1. Weak GPS signal (indoor, urban canyon)
2. Device GPS hardware issue
3. Power saving mode interfering

**Solutions:**
```
1. Move to open area
2. Test GPS with Google Maps
3. Disable battery optimization for Aurora:
   Settings > Apps > Aurora > Battery > Unrestricted
4. Turn off power saving mode temporarily
```

---

### 🗺️ Navigation Issues

#### "I could not find that destination"
**Symptoms:** Geocoding always fails
**Possible Causes:**
1. No internet connection (required for Stage 1)
2. Destination name too vague
3. Nominatim service down

**Solutions:**
```
1. Connect to Wi-Fi or mobile data
2. Use more specific names:
   ❌ "the park"
   ✅ "Central Park New York"
3. Try a well-known landmark
4. Check internet with browser
5. Wait and retry (service may be temporarily down)
```

#### "Couldn't calculate a route"
**Symptoms:** Routing fails after successful geocoding
**Possible Causes:**
1. Pi not connected (offline mode)
2. OpenRouteService key not configured
3. Destination unreachable

**Solutions:**
```
1. For offline mode: Connect to AuroraPi Wi-Fi
2. For online mode: Configure OpenRouteService API key
3. Try a different, accessible destination
4. Check if you said "yes" to online routing permission
```

#### Navigation starts but no voice guidance
**Symptoms:** Route calculated but no turn instructions
**Possible Causes:**
1. TTS not working
2. Device volume muted
3. Route has no intermediate steps

**Solutions:**
```
1. Increase device volume
2. Check Do Not Disturb is OFF
3. Test TTS: Say "Where am I?" and listen for response
4. Restart app
5. Try longer route with more turns
```

---

### 🔌 Hardware Connection Issues

#### Cannot connect to Raspberry Pi
**Symptoms:** Hardware status always red
**Possible Causes:**
1. Not connected to AuroraPi Wi-Fi
2. Pi not running
3. WebSocket server not started on Pi
4. Wrong IP address

**Solutions:**
```
1. Phone Wi-Fi Settings > Connect to "AuroraPi"
2. Verify Pi is powered on and Wi-Fi active
3. SSH to Pi and check WebSocket server:
   ps aux | grep websocket
4. Verify Pi IP is 192.168.4.1:
   ip addr show
5. Test WebSocket manually:
   curl http://192.168.4.1:8765
```

#### Pi keeps disconnecting
**Symptoms:** Hardware connection unstable
**Possible Causes:**
1. Weak Wi-Fi signal
2. Pi power issues
3. WebSocket server crashing

**Solutions:**
```
1. Move closer to Pi
2. Check Pi power supply (5V 3A minimum)
3. Check Pi logs for WebSocket errors
4. Restart WebSocket server on Pi
```

**Workaround:** App works without Pi using online routing

---

### 🚨 Emergency Features Issues

#### Cannot set up emergency contact
**Symptoms:** Contact setup fails in onboarding
**Possible Causes:**
1. Contacts permission denied
2. No contacts in phone
3. Voice recognition failed

**Solutions:**
```
1. Settings > Apps > Aurora > Permissions > Contacts = Allowed
2. Add contact in phone Contacts app first
3. Speak contact name clearly
4. Try setting up later via voice command
```

#### Emergency SMS not sending
**Symptoms:** Emergency triggered but SMS doesn't send
**Possible Causes:**
1. SMS permission denied
2. No emergency contact set
3. SMS app issue

**Solutions:**
```
1. Settings > Apps > Aurora > Permissions > SMS = Allowed
2. Complete emergency contact setup in onboarding
3. Test sending SMS manually from Messages app
4. Check if SMS service is working
```

---

### 🔊 Audio & Haptic Issues

#### No voice feedback at all
**Symptoms:** App never speaks
**Possible Causes:**
1. TTS not initialized
2. Volume muted
3. TTS engine missing
4. Do Not Disturb enabled

**Solutions:**
```
1. Restart app
2. Check volume is > 50%
3. Settings > Accessibility > Text-to-speech
   - Ensure preferred engine is installed
4. Disable Do Not Disturb mode
5. Test TTS in Android Settings
```

#### No vibration feedback
**Symptoms:** App doesn't vibrate
**Possible Causes:**
1. Vibration disabled in settings
2. Device doesn't support vibration
3. Battery saver blocking vibration

**Solutions:**
```
1. Settings > Sound & vibration > Vibration = ON
2. Test vibration with another app
3. Disable battery saver
4. Device may not support vibration patterns
```

---

### 🌐 Internet & Connectivity Issues

#### "Need internet connection" but phone is online
**Symptoms:** App says no internet but other apps work
**Possible Causes:**
1. Connected to AuroraPi (no internet gateway)
2. Captive portal not signed in
3. Connectivity service not detecting connection

**Solutions:**
```
1. If using Pi: Pi needs internet gateway configured
2. If on public Wi-Fi: Open browser and sign in
3. Try mobile data instead of Wi-Fi
4. Toggle airplane mode ON then OFF
5. Restart app
```

---

### 📱 App Crashes & Freezes

#### App crashes on startup
**Symptoms:** App closes immediately after launch
**Possible Causes:**
1. Missing assets
2. Permission crash
3. Service initialization error

**Solutions:**
```
1. Check Android logs:
   flutter logs
2. Clear app data:
   Settings > Apps > Aurora > Storage > Clear data
3. Reinstall app:
   flutter clean
   flutter run
4. Check for error in logs and report issue
```

#### App freezes during onboarding
**Symptoms:** App stops responding during setup
**Possible Causes:**
1. Permission dialog timeout
2. Contact search hanging
3. Hardware connection timeout

**Solutions:**
```
1. Force close app and reopen
2. Grant permissions manually in Settings first
3. Skip hardware setup (say "no" or wait for timeout)
4. Clear app data and restart onboarding
```

---

### 🔍 Debugging Tips

#### Enable detailed logging
```bash
flutter run --verbose
```

#### Check Android logs
```bash
adb logcat | grep -i aurora
```

#### Test specific features
```dart
// In app_coordinator.dart, add debug lines:
print('Service initialized: ${service.isReady}');
```

#### Reset app completely
```bash
# Clear all data and rebuild
flutter clean
rm -rf build/
Settings > Apps > Aurora > Storage > Clear Data
flutter run
```

---

## 📊 System Requirements Checklist

Ensure your device meets these requirements:

- [ ] Android 6.0 (API 23) or higher
- [ ] Microphone (for voice commands)
- [ ] GPS (for navigation)
- [ ] 100MB free storage
- [ ] Internet connection (for geocoding)
- [ ] Contacts app (for emergency setup)
- [ ] SMS capability (for emergency)

---

## 🆘 Still Having Issues?

### Collect Debug Information:

1. **Flutter Doctor Output:**
```bash
flutter doctor -v > flutter_info.txt
```

2. **App Logs:**
```bash
flutter logs > app_logs.txt
```

3. **Device Info:**
- Android version
- Device model
- Available RAM
- Storage space

4. **Steps to Reproduce:**
- Exact steps taken
- Expected behavior
- Actual behavior
- Error messages

### Report Issue:
[Add your issue reporting method here]

---

## ✅ Verification Checklist

Use this to verify everything is working:

- [ ] App launches without crash
- [ ] Onboarding completes successfully
- [ ] Location permission granted
- [ ] Microphone permission granted
- [ ] Voice command recognized
- [ ] TTS speaks responses
- [ ] Vibration works
- [ ] GPS gets location
- [ ] "Where am I?" command works
- [ ] Navigation to landmark works
- [ ] Emergency contact can be set
- [ ] Status indicators update correctly

---

## 💡 Pro Tips

1. **First Time Setup:**
   - Do onboarding in quiet environment
   - Have good GPS signal (near window or outside)
   - Have internet connection ready
   - Allow all permissions when asked

2. **Best Experience:**
   - Use with earphones for clearer TTS
   - Keep device volume at 70-80%
   - Test in familiar area first
   - Have backup navigation method

3. **Battery Optimization:**
   - Disable optimization for Aurora in Settings
   - Keep screen on during navigation
   - Close other GPS apps

4. **Testing Without Hardware:**
   - App fully functional without Pi
   - Uses online routing automatically
   - All voice features work
   - Emergency features work

---

**Remember:** Aurora is designed to work gracefully even when components fail. Most features should work independently.

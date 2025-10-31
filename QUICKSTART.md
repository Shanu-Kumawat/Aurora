# Aurora Quick Start Guide

## 🚀 Getting Started in 5 Minutes

### Step 1: Install Dependencies (1 minute)
```bash
cd /home/shanu/Projects/Flutter/aurora
flutter pub get
```

### Step 2: Test the App Without Hardware (2 minutes)

The app works without Raspberry Pi hardware! It will automatically use online routing as fallback.

```bash
flutter run
```

**What to expect:**
- App launches with black background and "AURORA" title
- Status indicators show GPS, Hardware, and Internet status
- Onboarding will guide you through permissions
- Use "TAP TO SPEAK" button instead of wake word

### Step 3: Try Voice Commands (2 minutes)

1. **Tap the "TAP TO SPEAK" button**
2. **Say one of these commands:**
   - "Navigate to Times Square" (or any landmark)
   - "Where am I?"
   - "Stop navigation"
   - "How much further?" (during navigation)

## 📱 Testing Checklist

- [ ] App launches successfully
- [ ] Location permission granted
- [ ] Microphone permission granted
- [ ] Voice recognition works (tap button and speak)
- [ ] TTS speaks responses
- [ ] Can navigate to a destination
- [ ] Emergency contact can be set up

## ⚙️ Optional: Advanced Setup

### Enable Wake Word Detection

1. **Get Porcupine Access Key:**
   - Visit https://console.picovoice.ai/
   - Sign up for free account
   - Create access key

2. **Download Wake Word Model:**
   - In Porcupine Console, create "Hey Aurora" wake word
   - Download the `.ppn` file
   - Place in `assets/hey_aurora.ppn`

3. **Configure API Key:**
   - Open `lib/config/api_keys.dart`
   - Replace `YOUR_PORCUPINE_ACCESS_KEY_HERE` with your key

4. **Enable in Code:**
   - Open `lib/services/app_coordinator.dart`
   - Uncomment lines 56-59 in the `initialize()` method

### Enable Online Routing Fallback

1. **Get OpenRouteService Key:**
   - Visit https://openrouteservice.org/dev/#/signup
   - Sign up for free account (2,000 requests/day)
   - Get API key

2. **Configure API Key:**
   - Open `lib/config/api_keys.dart`
   - Replace `YOUR_OPENROUTESERVICE_KEY_HERE` with your key

### Connect Raspberry Pi Hardware

1. **Set up Pi as described in hardware documentation**
2. **On your phone, go to Wi-Fi settings**
3. **Connect to network: `AuroraPi`**
4. **Return to Aurora app**
5. **Hardware status indicator will turn green**

## 🐛 Troubleshooting

### "Command not understood" every time
- Check microphone permission is granted
- Speak clearly after tapping button
- Wait for beep/vibration before speaking

### Navigation fails
- Ensure internet connection for first-time geocoding
- Check location permission is granted
- Make sure GPS is enabled on device

### No voice feedback
- Check device volume is not muted
- Check TTS is initialized (should hear welcome message)
- Try restarting the app

### Hardware won't connect
- Verify Pi is running and broadcasting AuroraPi Wi-Fi
- Check Pi IP is 192.168.4.1
- Ensure WebSocket server is running on Pi at port 8765

## 📋 Development Checklist

If you're developing or customizing Aurora:

- [ ] All services initialized without errors
- [ ] Voice commands parsed correctly
- [ ] Navigation calculates routes
- [ ] Audio feedback works for all scenarios
- [ ] Haptic feedback works
- [ ] Error handling provides appropriate feedback
- [ ] Onboarding completes successfully
- [ ] Emergency protocol works
- [ ] Hardware connection (if available) works
- [ ] GPS tracking works
- [ ] All permissions requested properly

## 🎯 Next Steps

1. **Test all voice commands** listed in README.md
2. **Try navigation** to a real destination
3. **Set up emergency contact** in onboarding
4. **Configure optional features** (wake word, online routing)
5. **Connect hardware** for obstacle detection

## 💡 Tips

- **Volume**: Keep device volume at 70%+ for clear TTS
- **Quiet Environment**: Test voice commands in quiet space first
- **Clear Speech**: Speak commands clearly and at normal pace
- **Manual Trigger**: Use "TAP TO SPEAK" button if wake word isn't configured
- **Test Incrementally**: Test one feature at a time
- **Check Logs**: Use `flutter logs` to see debug output

---

**Need help?** Check the main README.md for detailed documentation.

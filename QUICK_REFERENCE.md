# 🎴 Aurora Quick Reference Card

## 🚀 Quick Start (30 seconds)
```bash
cd /home/shanu/Projects/Flutter/aurora
flutter run
```

## 🎤 Voice Commands

| Command | Action |
|---------|--------|
| "Navigate to [place]" | Start navigation |
| "Stop navigation" | End navigation |
| "Where am I?" | Get location |
| "How much further?" | Trip status |
| "Start emergency" | Trigger emergency |
| "Cancel emergency" | Cancel emergency |
| "Ask Gemini [query]" | AI (coming soon) |

## 📊 Status Indicators

| Indicator | Green | Red |
|-----------|-------|-----|
| GPS | Signal good | No signal |
| Hardware | Pi connected | Disconnected |
| Internet | Online | Offline |

## 🎯 Navigation States

| State | Color | Meaning |
|-------|-------|---------|
| READY | Grey | Idle, waiting |
| FINDING | Orange | Geocoding address |
| ROUTING | Orange | Calculating route |
| NAVIGATING | Green | Active guidance |
| PAUSED | Yellow | GPS lost |

## 🔊 Audio Feedback

| Scenario | Message |
|----------|---------|
| Need Internet | "To find your destination, I need..." |
| Not Found | "I could not find that destination" |
| Offline Unavailable | "Offline navigation is not available..." |
| Route Failed | "I couldn't calculate a route..." |
| GPS Lost | "Lost GPS signal..." |
| GPS Restored | "GPS signal restored..." |
| Hardware Lost | "Hardware connection lost..." |
| Hardware Connected | "Hardware reconnected..." |
| Unknown Command | "I didn't quite get that..." |
| Obstacle | "Obstacle detected ahead..." |

## 📳 Haptic Patterns

| Pattern | When |
|---------|------|
| Single Short | Confirmation, GPS restored |
| Double Short | GPS lost |
| Triple Short | Hardware reconnected |
| Long Pulse | Hardware disconnected |
| Urgent Pattern | Obstacle detected |

## 🔑 Important Files

| File | Purpose |
|------|---------|
| `lib/config/api_keys.dart` | API key configuration |
| `lib/constants/app_constants.dart` | All constants |
| `lib/services/app_coordinator.dart` | Main logic |
| `lib/screens/home_screen.dart` | UI screen |
| `README.md` | Full documentation |
| `QUICKSTART.md` | Quick start guide |
| `TROUBLESHOOTING.md` | Common issues |

## 🔧 Configuration

### Optional API Keys:
```dart
// lib/config/api_keys.dart
porcupineAccessKey: 'YOUR_KEY'     // Wake word
openRouteServiceKey: 'YOUR_KEY'    // Online routing
```

### Get Keys:
- Porcupine: https://console.picovoice.ai/
- ORS: https://openrouteservice.org/

## 🏗️ Project Structure

```
lib/
├── config/         # API keys
├── constants/      # Constants
├── models/         # Data models
├── providers/      # Routing
├── screens/        # UI
└── services/       # Core logic
```

## ⚡ Quick Commands

```bash
# Run app
flutter run

# Check status
flutter doctor

# Clean build
flutter clean && flutter pub get

# View logs
flutter logs

# Build APK
flutter build apk
```

## 🐛 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| "Command not understood" | Grant microphone permission |
| "Unable to get location" | Enable GPS, grant location permission |
| "Could not find destination" | Connect to internet |
| "Couldn't calculate route" | Connect to AuroraPi or configure ORS key |
| No voice feedback | Check volume, TTS settings |
| No vibration | Enable vibration in settings |
| App crash | `flutter clean && flutter run` |

## 📱 Permissions Required

- [x] Location (Always)
- [x] Microphone
- [x] Contacts
- [x] SMS
- [x] Internet
- [x] Network State
- [x] Vibration

## 🎯 Testing Checklist

- [ ] App launches
- [ ] Tap button works
- [ ] Voice recognized
- [ ] TTS speaks
- [ ] Navigation starts
- [ ] Status updates
- [ ] Errors handled

## 🔗 Important URLs

- Porcupine Console: https://console.picovoice.ai/
- OpenRouteService: https://openrouteservice.org/
- Nominatim API: https://nominatim.openstreetmap.org/
- Flutter Docs: https://flutter.dev/docs

## 📞 Emergency Setup

1. Complete onboarding
2. Say contact name clearly
3. Confirm phone number
4. Test with "Start emergency"

## 🤖 Hardware Setup (Optional)

1. Pi creates hotspot: `AuroraPi`
2. Pi IP: `192.168.4.1`
3. OSRM server: port `5000`
4. WebSocket: port `8765`
5. Connect phone to AuroraPi
6. Return to app

## 💡 Pro Tips

- Use earphones for clearer TTS
- Test in quiet environment first
- Keep volume at 70%+
- Use "TAP TO SPEAK" without wake word
- Allow all permissions in onboarding
- App works without Pi hardware

## 📈 Performance

- App size: ~50MB
- RAM usage: ~100MB
- Battery: Moderate (GPS + continuous audio)
- Network: Minimal (geocoding only)

## ✅ Success Indicators

- Green GPS indicator
- TTS speaking clearly
- Commands recognized
- Routes calculated
- Turn-by-turn works
- Status updates visible

---

## 🆘 Need Help?

1. Check `TROUBLESHOOTING.md`
2. Run `flutter doctor`
3. Check `flutter logs`
4. Review `README.md`
5. Clear app data and retry

---

**Keep this card handy for quick reference! 📌**

*Aurora v1.0.0 - Voice-First Navigation for the Visually Impaired*

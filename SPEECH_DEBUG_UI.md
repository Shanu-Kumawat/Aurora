# Real-Time Speech Recognition Display - Debug Feature

## ✨ What Was Added

### Visual Feedback for Speech Recognition
A **live text display** that shows exactly what words the app is capturing in real-time.

## 📱 How It Looks

When you say a command after "Hey Aurora", you'll see a **green box** appear on screen showing:

```
┌─────────────────────────────────────┐
│         LISTENING...                │
│                                     │
│   "navigate to central park"       │
└─────────────────────────────────────┘
```

### Visual States:

1. **Nothing showing** = Not listening
2. **Green box appears** = Listening started
3. **Text updates live** = Words being captured
4. **Box disappears** = Command processed

## 🔧 Technical Implementation

### 1. Added Stream in CommandService
**File:** `lib/services/command_service.dart`

```dart
// Stream for recognized text (for UI display)
final StreamController<String> _recognizedTextController =
    StreamController<String>.broadcast();
Stream<String> get recognizedTextStream => _recognizedTextController.stream;
```

### 2. Emit Text During Recognition
```dart
onResult: (result) {
  recognizedText = result.recognizedWords.toLowerCase();
  
  // Emit to UI stream ← NEW!
  _recognizedTextController.add(recognizedText);
  
  if (result.finalResult && !completer.isCompleted) {
    completer.complete(recognizedText);
  }
}
```

### 3. UI Listens to Stream
**File:** `lib/screens/home_screen.dart`

```dart
// Listen to recognized text for debugging
_commandService.recognizedTextStream.listen((text) {
  setState(() {
    _recognizedText = text;
  });
});
```

### 4. Display in UI
```dart
// Recognized text display (for debugging)
if (_recognizedText.isNotEmpty)
  Container(
    decoration: BoxDecoration(
      color: Colors.green.withOpacity(0.2),
      border: Border.all(color: Colors.green, width: 2),
    ),
    child: Column(
      children: [
        Text('LISTENING...'),
        Text(_recognizedText), // ← Shows captured words!
      ],
    ),
  ),
```

## 🧪 Testing

### Test 1: Wake Word Path
1. Say **"Hey Aurora"**
2. **Green box appears** with "LISTENING..."
3. Say **"Navigate to Times Square"**
4. Watch text update **live** as you speak:
   - "navigate"
   - "navigate to"
   - "navigate to times"
   - "navigate to times square"

### Test 2: Manual Button
1. Tap **"TAP TO SPEAK"** button
2. Green box appears
3. Speak any command
4. See words appear in real-time

## 🔍 Debug Information

### If green box appears but text stays empty:
- ❌ Microphone not capturing audio
- Check: Android mic permissions
- Check: Another app using microphone

### If green box never appears:
- ❌ Speech recognition not starting
- Check logs for: `CommandService: Listen started successfully`

### If text appears but is gibberish:
- ✅ Good! Microphone is working
- ⚠️ Speech recognition having trouble understanding
- Solution: Speak louder/clearer or check accent settings

### If text appears correctly:
- ✅ Everything working!
- If navigation still doesn't start, problem is in command parsing logic

## 📊 What This Tells You

| What You See | What It Means | Next Step |
|--------------|---------------|-----------|
| No green box | Not listening | Check wake word/button press |
| Green box, no text | Mic not working | Check permissions |
| Green box, wrong text | Mic works, recognition confused | Speak clearer |
| Correct text shown | Everything works! | Check intent parsing |

## 🎨 UI Layout

The debug display appears **between** navigation status and the manual button:

```
┌─────────────────────────┐
│       AURORA            │
│                         │
│  GPS      ●             │
│  Hardware ●             │
│  Internet ●             │
│                         │
│    [IDLE]               │
│                         │
│  ┌─────────────────┐    │  ← NEW DEBUG BOX
│  │  LISTENING...   │    │
│  │  "your words"   │    │
│  └─────────────────┘    │
│                         │
│  [TAP TO SPEAK]         │
└─────────────────────────┘
```

## 💡 Tips

1. **Leave this feature in** during testing - helps diagnose issues quickly
2. **Green box timing** tells you when mic is active
3. **Text updates** show if speech recognition is working at all
4. **Compare with logs** to see if intent parsing is the issue

## 🚀 Try It Now!

1. **Hot restart** the app: `R` in terminal
2. Say **"Hey Aurora"**
3. **Watch the green box** appear
4. Say **"Navigate to Central Park"**
5. **Watch words appear** as you speak

If you see the text appearing correctly, the microphone is working! 🎤✅

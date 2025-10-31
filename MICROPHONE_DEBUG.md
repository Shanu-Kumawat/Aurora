# Microphone Access Issue - Diagnostic Guide

## 🔍 Current Issue

Your logs show speech recognition timing out **without detecting any audio**:
```
Speech recognition status: listening
Speech recognition status: notListening  ← Stops immediately
error_speech_timeout
CommandService: No speech detected
```

**Notice:** No `CommandService: Audio detected` log = microphone not capturing sound.

## 🎯 Root Cause Analysis

The issue is likely one of these:

### 1. **Microphone Conflict** (Most Likely)
- Porcupine (wake word) holds the microphone
- When we try to start speech-to-text, mic is still locked
- Android doesn't allow two services to use mic simultaneously

### 2. **Insufficient Delay**
- 300ms wasn't enough for Porcupine to release microphone
- Audio routing takes time to stabilize

### 3. **Permission Issue**
- Microphone permission might be "while using app" only
- Porcupine uses it, then STT can't access it

## ✅ Fixes Applied

### Fix #1: Stop Wake Word Before Listening
**File:** `app_coordinator.dart` - `_handleWakeWord()`

```dart
// Stop wake word detection to release microphone
await _wakeWordService.stopListening();

await _audioManager.vibrateShort();

// Longer delay (800ms) for:
// - Porcupine to release mic
// - Audio routing to stabilize
await Future.delayed(const Duration(milliseconds: 800));

// Now listen for command
final intent = await _commandService.listenForCommand();

// Restart wake word detection
await _wakeWordService.startListening();
```

### Fix #2: Better Diagnostics
**File:** `command_service.dart` - `listenForCommand()`

Added detailed logging:
```dart
// Check permission
final available = await _speech.hasPermission;
print('Speech available: ${_speech.isAvailable}');
print('Speech listening: ${_speech.isListening}');

await _speech.listen(...);
print('Listen started successfully');
```

## 🧪 Test Again

### Run the app and say "Hey Aurora"

**Expected logs:**
```
Wake word detected!
AppCoordinator: Wake word detected, listening for command...
CommandService: Not initialized, initializing now...     ← If first time
CommandService: Speech available: true                   ← Should be true
CommandService: Speech listening: false                  ← Should be false initially
CommandService: Starting to listen for command...
CommandService: Listen started successfully              ← New log!
Speech recognition status: listening
CommandService: Audio detected, level: 2.5               ← Should see this!
CommandService: Recognized text: "your command here"
```

### If Still Failing - Check These Logs:

#### ❌ If you see:
```
CommandService: Speech available: false
```
**Problem:** Speech recognition not initialized properly
**Solution:** Need to debug initialization

#### ❌ If you see:
```
CommandService: Speech listening: true
```
**Problem:** Previous session didn't stop properly
**Solution:** Need to call `_speech.stop()` before starting

#### ❌ If you see:
```
CommandService: No microphone permission
```
**Problem:** Permission denied
**Solution:** Check Android settings → Apps → Aurora → Permissions → Microphone

#### ❌ If you see:
```
CommandService: Listen started successfully
Speech recognition status: listening
Speech recognition status: notListening  ← Immediate stop
```
**Problem:** Microphone still locked by Porcupine
**Solution:** Need even longer delay (try 1500ms)

## 🔧 Emergency Workaround

If wake word path keeps failing, test with the manual button:

1. Tap **"TEST COMMAND"** button (bypasses wake word)
2. Speak your command
3. Check if it works

**If manual button works:**
- Problem is Porcupine → STT handoff
- Solution: Increase delay or add explicit mic release

**If manual button also fails:**
- Problem is speech-to-text itself
- Solution: Check mic permissions in Android settings

## 📱 Android Permission Check

1. Open **Settings** → **Apps** → **Aurora**
2. Tap **Permissions** → **Microphone**
3. Ensure it's set to **"Allow only while using the app"** or **"Allow all the time"**
4. If it says "Ask every time", that could be the issue

## 🎛️ Adjustable Parameters

If the 800ms delay isn't enough, you can increase it in `app_coordinator.dart`:

```dart
// Try 1500ms if 800ms doesn't work
await Future.delayed(const Duration(milliseconds: 1500));
```

## 📊 Next Steps

Run the app and share the **new logs** showing:
- `Speech available: true/false`
- `Speech listening: true/false`  
- `Listen started successfully`
- Whether `Audio detected` appears

This will tell us exactly where the problem is! 🔍

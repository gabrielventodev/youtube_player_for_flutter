# YouTube Player for Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.35+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9+-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?logo=android)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A native Flutter plugin that embeds YouTube videos using the **YouTube IFrame Player API** through platform-specific WebViews. Built with **Kotlin Multiplatform (KMP)** for shared logic across platforms.

---

## Features

- **Embedded YouTube Player** — Native WebView-based player using the YouTube IFrame Player API
- **Full Playback Control** — Play, pause, seek, load/cue videos, volume, mute/unmute
- **Fullscreen Support** — Native immersive fullscreen with automatic orientation handling
- **YouTube Shorts Detection** — Automatically detects Shorts and adjusts fullscreen to portrait mode
- **Playback Quality Control** — Get and set video quality (small, medium, large, HD720, HD1080, highres)
- **Reactive State** — `ValueNotifier`-based controller for real-time player state updates
- **Dynamic Video Loading** — Load new videos at runtime by URL or video ID
- **Privacy-Enhanced Mode** — Uses `youtube-nocookie.com` for enhanced privacy
- **KMP Architecture** — Shared Kotlin code for HTML generation and player configuration

---

## Getting Started

### Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  youtube_player_for_flutter: ^0.0.1
```

Then run:

```bash
flutter pub get
```

### Android Requirements

- **Min SDK**: 24 (Android 7.0)
- **Compile SDK**: 36

No additional configuration required.

### iOS Requirements

- **Min iOS**: 13.0
- **Fullscreen support**: iOS 15.4+ (uses WKWebView element fullscreen)
- **Orientation control**: iOS 16.0+ (uses `requestGeometryUpdate`)

No additional configuration required.

---

## Usage

### Basic Setup

```dart
import 'package:youtube_player_for_flutter/youtube_player_for_flutter.dart';

class PlayerScreen extends StatefulWidget {
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      videoId: 'dQw4w9WgXcQ',
      autoPlay: false,
      showControls: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerWidget(controller: _controller);
  }
}
```

### Listening to Player State

The controller extends `ValueNotifier<YoutubePlayerValue>`, so you can listen to state changes reactively:

```dart
_controller.addListener(() {
  final value = _controller.value;
  print('State: ${value.playerState}');
  print('Is playing: ${value.isPlaying}');
  print('Is fullscreen: ${value.isFullscreen}');
  print('Is Short: ${value.isShort}');
});
```

Or use `ValueListenableBuilder` in your widget tree:

```dart
ValueListenableBuilder<YoutubePlayerValue>(
  valueListenable: _controller,
  builder: (context, value, child) {
    return Text('State: ${value.playerState.name}');
  },
);
```

### Controlling Playback

```dart
// Play / Pause
await _controller.play();
await _controller.pause();

// Seek to a position
await _controller.seekTo(const Duration(seconds: 30));

// Load a new video (starts playing immediately)
await _controller.loadVideo('jNQXAC9IVRw');

// Cue a new video (loads but doesn't auto-play)
await _controller.cueVideo('jNQXAC9IVRw', startSeconds: 10);
```

### Volume Control

```dart
await _controller.setVolume(80);  // 0-100
await _controller.mute();
await _controller.unMute();
```

### Quality Control

```dart
// Set playback quality
await _controller.setPlaybackQuality(PlaybackQuality.hd720);

// Get current quality
final quality = await _controller.getPlaybackQuality();

// Get available quality levels
final levels = await _controller.getAvailableQualityLevels();
```

### Position & Duration

```dart
final position = await _controller.getCurrentPosition(); // Duration
final duration = await _controller.getDuration();         // Duration
```

### Dynamic Video Loading from URL

You can parse YouTube URLs to extract video IDs:

```dart
String? extractVideoId(String url) {
  final patterns = [
    RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com.*[?&]v=([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
    RegExp(r'^([a-zA-Z0-9_-]{11})$'),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(url.trim());
    if (match != null) return match.group(1);
  }
  return null;
}

// Supported URL formats:
// https://www.youtube.com/watch?v=VIDEO_ID
// https://youtu.be/VIDEO_ID
// https://www.youtube.com/shorts/VIDEO_ID
// VIDEO_ID (raw 11-character ID)
```

---

## API Reference

### YoutubePlayerController

| Parameter | Type | Default | Description |
|---|---|---|---|
| `videoId` | `String` | *required* | The YouTube video ID to play |
| `autoPlay` | `bool` | `false` | Start playing automatically when ready |
| `showControls` | `bool` | `true` | Show YouTube player controls |
| `startSeconds` | `int` | `0` | Start position in seconds |
| `endSeconds` | `int` | `0` | End position (0 = no limit) |
| `showFullscreenButton` | `bool` | `true` | Show the fullscreen button |
| `showRelatedVideos` | `bool` | `false` | Show related videos at the end |
| `loop` | `bool` | `false` | Loop the video |

#### Methods

| Method | Description |
|---|---|
| `play()` | Start or resume playback |
| `pause()` | Pause playback |
| `seekTo(Duration)` | Seek to a specific position |
| `loadVideo(String, {int startSeconds})` | Load and play a new video |
| `cueVideo(String, {int startSeconds})` | Cue a video without auto-playing |
| `setPlaybackQuality(PlaybackQuality)` | Set the playback quality |
| `getPlaybackQuality()` | Get the current playback quality |
| `getAvailableQualityLevels()` | Get available quality options |
| `setVolume(int)` | Set volume (0–100) |
| `mute()` | Mute the player |
| `unMute()` | Unmute the player |
| `exitFullscreen()` | Exit fullscreen mode |
| `getCurrentPosition()` | Get current playback position as `Duration` |
| `getDuration()` | Get video duration as `Duration` |

### YoutubePlayerValue

| Property | Type | Description |
|---|---|---|
| `isReady` | `bool` | Whether the player has initialized |
| `isPlaying` | `bool` | Whether the video is currently playing |
| `isPaused` | `bool` | Whether the video is paused |
| `isBuffering` | `bool` | Whether the video is buffering |
| `isFullscreen` | `bool` | Whether the player is in fullscreen mode |
| `isShort` | `bool` | Whether the video is a YouTube Short |
| `videoAspectRatio` | `double` | Detected video aspect ratio |
| `playerState` | `PlayerState` | Current player state enum |
| `playbackQuality` | `PlaybackQuality` | Current playback quality |
| `error` | `YoutubeError` | Error state (if any) |

### YoutubePlayerWidget

| Parameter | Type | Default | Description |
|---|---|---|---|
| `controller` | `YoutubePlayerController` | *required* | The player controller |
| `aspectRatio` | `double?` | `16/9` | Custom aspect ratio for the player |

### Enums

#### PlayerState

| Value | YouTube API Code |
|---|---|
| `unstarted` | -1 |
| `ended` | 0 |
| `playing` | 1 |
| `paused` | 2 |
| `buffering` | 3 |
| `videoCued` | 5 |

#### PlaybackQuality

`small` · `medium` · `large` · `hd720` · `hd1080` · `highres` · `defaultQuality`

#### YoutubeError

`none` · `invalidParam` · `html5Error` · `videoNotFound` · `notEmbeddable`

---

## Fullscreen Behavior

The plugin provides native fullscreen support with smart orientation handling:

- **Normal videos** → Rotate to **landscape** on fullscreen
- **YouTube Shorts** → Stay in **portrait** on fullscreen
- Fullscreen uses **Android immersive sticky mode** (hides status bar and navigation)
- The player automatically detects if a video is a Short using a native HTTP request

---

## Architecture

```
┌─────────────────────────────────────────────┐
│                  Dart Layer                 │
│  YoutubePlayerController (ValueNotifier)    │
│  YoutubePlayerWidget (AndroidView)          │
│  YoutubePlayerValue (immutable state)       │
├─────────────────────────────────────────────┤
│           MethodChannel / EventChannel      │
├─────────────────────────────────────────────┤
│              Android Native Layer           │
│  YoutubePlayerPlatformView (WebView)        │
│  YoutubePlayerViewFactory                   │
│  YoutubePlayerForFlutterPlugin              │
├─────────────────────────────────────────────┤
│            KMP Shared Module                │
│  YoutubeIFrameGenerator (HTML + JS)         │
│  PlayerConfig / PlayerState / Quality       │
└─────────────────────────────────────────────┘
```

---

## Example App

The `example/` directory contains a full demo app with:

- Embedded YouTube player
- URL input field for loading videos dynamically
- Playback controls (play, pause, seek, load)
- Real-time player state display
- Quality selector dropdown

Run the example:

```bash
cd example
flutter run -d android
```

---

## Platform Support

| Platform | Status |
|---|---|
| Android | ✅ Supported |
| iOS | ✅ Supported (iOS 13+) |
| Web | ❌ Not planned |

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

### iOS (requires macOS)

1. Build the shared framework first:

```bash
chmod +x build_ios_framework.sh
./build_ios_framework.sh
```

2. Then run the Flutter app:

```bash
cd example
flutter run -d ios
```

## Adding Shared Code

1. Add your shared Kotlin interfaces/classes in `shared/src/commonMain/kotlin/com/openpass/shared/`
2. Add platform-specific implementations in `androidMain/` and `iosMain/`
3. Call the shared code from the Android plugin (Kotlin) and iOS plugin (Swift via framework import)
4. Expose the functionality to Dart via method channels in `lib/`

## Consuming This Plugin in Another App

Apps that consume this plugin need to add the KMP shared module to their Android Gradle settings.
In the consuming app's `android/settings.gradle.kts`, add:

```kotlin
include(":shared")
project(":shared").projectDir = file("<path-to-plugin>/shared")
```

For iOS, the XCFramework is vendored in the plugin's `ios/Frameworks/` directory and is picked up automatically by CocoaPods.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


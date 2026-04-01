# youtube_player_for_flutter

Flutter plugin with Kotlin Multiplatform (KMP) shared module for Android and iOS.

## Project Structure

```
youtube_player_for_flutter/
├── shared/                          # KMP shared module
│   ├── src/
│   │   ├── commonMain/kotlin/       # Shared Kotlin code (expect declarations)
│   │   ├── androidMain/kotlin/      # Android actual implementations
│   │   └── iosMain/kotlin/          # iOS actual implementations
│   ├── build.gradle.kts
│   └── settings.gradle.kts
├── android/                         # Flutter Android plugin (uses shared via Gradle)
├── ios/                             # Flutter iOS plugin (uses shared XCFramework)
│   └── Frameworks/                  # Pre-built Shared.xcframework (gitignored)
├── lib/                             # Dart API
├── example/                         # Example Flutter app
└── build_ios_framework.sh           # Script to build iOS framework (run on macOS)
```

## How It Works

- **Shared code** lives in `shared/src/commonMain/`. Use `expect`/`actual` for platform-specific implementations.
- **Android** depends on the shared module directly via Gradle (`project(':shared')`).
- **iOS** uses a pre-built `Shared.xcframework` vendored in `ios/Frameworks/`.

## Development Setup

### Android

No extra setup needed. The example app's `settings.gradle.kts` includes the shared module.
Run normally:

```bash
cd example
flutter run -d android
```

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


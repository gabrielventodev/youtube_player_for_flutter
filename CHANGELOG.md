## 0.0.2

* Fix the Android build with Kotlin Gradle Plugin 2.2+ (required by Flutter 3.47): the shared module now uses the `compilerOptions` DSL instead of `kotlinOptions`, which is an error since Kotlin 2.2.

## 0.0.1

* Initial release.
* Embedded YouTube player using YouTube IFrame Player API via native WebView.
* Full playback controls: play, pause, seek, load/cue videos, volume, mute/unmute.
* Native fullscreen support with automatic orientation (landscape for videos, portrait for Shorts).
* YouTube Shorts detection via native HTTP request.
* Playback quality management (get/set/available levels).
* Reactive `ValueNotifier`-based controller for real-time player state.
* Privacy-enhanced mode using `youtube-nocookie.com`.
* Android support (min SDK 24).
* iOS support (min iOS 13.0).

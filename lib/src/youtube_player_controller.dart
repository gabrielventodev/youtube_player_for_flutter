import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'youtube_player_value.dart';

/// Controller for a YouTube player instance.
///
/// Manages communication with the native platform view via method and event channels.
/// Extends [ValueNotifier] so listeners are notified of state changes.
class YoutubePlayerController extends ValueNotifier<YoutubePlayerValue> {
  YoutubePlayerController({
    required this.videoId,
    this.autoPlay = false,
    this.showControls = true,
    this.startSeconds = 0,
    this.endSeconds = 0,
    this.showFullscreenButton = true,
    this.showRelatedVideos = false,
    this.loop = false,
  }) : super(const YoutubePlayerValue());

  final String videoId;
  final bool autoPlay;
  final bool showControls;
  final int startSeconds;
  final int endSeconds;
  final bool showFullscreenButton;
  final bool showRelatedVideos;
  final bool loop;

  MethodChannel? _methodChannel;
  EventChannel? _eventChannel;
  StreamSubscription? _eventSubscription;

  /// Called by the widget when the platform view is created.
  void onPlatformViewCreated(int viewId) {
    _methodChannel = MethodChannel('youtube_player_$viewId');
    _eventChannel = EventChannel('youtube_player_events_$viewId');

    _eventSubscription = _eventChannel!.receiveBroadcastStream().listen(
      _handleEvent,
      onError: _handleEventError,
    );
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;

    final eventName = event['event'] as String?;
    switch (eventName) {
      case 'onReady':
        value = value.copyWith(isReady: true);
        break;
      case 'onStateChange':
        final state = event['state'] as int?;
        if (state != null) {
          value = value.copyWith(playerState: playerStateFromInt(state));
        }
        break;
      case 'onError':
        final errorCode = event['errorCode'] as int?;
        if (errorCode != null) {
          value = value.copyWith(error: youtubeErrorFromInt(errorCode));
        }
        break;
      case 'onPlaybackQualityChange':
        final quality = event['quality'] as String?;
        if (quality != null) {
          value = value.copyWith(
            playbackQuality: playbackQualityFromString(quality),
          );
        }
        break;
      case 'onFullscreenChange':
        final isFullscreen = event['isFullscreen'] as bool?;
        if (isFullscreen != null) {
          value = value.copyWith(isFullscreen: isFullscreen);
        }
        break;
      case 'onVideoSizeDetected':
        final width = (event['width'] as num?)?.toDouble() ?? 0;
        final height = (event['height'] as num?)?.toDouble() ?? 0;
        final isShort = event['isShort'] as bool? ?? false;
        final aspectRatio = (width > 0 && height > 0) ? width / height : 16 / 9;
        value = value.copyWith(isShort: isShort, videoAspectRatio: aspectRatio);
        break;
    }
  }

  void _handleEventError(Object error) {
    debugPrint('YoutubePlayerController event error: $error');
  }

  /// Map of creation parameters sent to the native platform view.
  Map<String, dynamic> get creationParams => {
        'videoId': videoId,
        'autoPlay': autoPlay,
        'showControls': showControls,
        'startSeconds': startSeconds,
        'endSeconds': endSeconds,
        'showFullscreenButton': showFullscreenButton,
        'showRelatedVideos': showRelatedVideos,
        'loop': loop,
      };

  // -- Playback controls --

  Future<void> play() async {
    await _methodChannel?.invokeMethod('play');
  }

  Future<void> pause() async {
    await _methodChannel?.invokeMethod('pause');
  }

  Future<void> seekTo(Duration position) async {
    await _methodChannel?.invokeMethod('seekTo', {
      'seconds': position.inMilliseconds / 1000.0,
    });
  }

  Future<void> loadVideo(String videoId, {int startSeconds = 0}) async {
    await _methodChannel?.invokeMethod('loadVideo', {
      'videoId': videoId,
      'startSeconds': startSeconds.toDouble(),
    });
  }

  Future<void> cueVideo(String videoId, {int startSeconds = 0}) async {
    await _methodChannel?.invokeMethod('cueVideo', {
      'videoId': videoId,
      'startSeconds': startSeconds.toDouble(),
    });
  }

  // -- Quality --

  Future<void> setPlaybackQuality(PlaybackQuality quality) async {
    await _methodChannel?.invokeMethod('setPlaybackQuality', {
      'quality': playbackQualityToString(quality),
    });
  }

  Future<PlaybackQuality> getPlaybackQuality() async {
    final result =
        await _methodChannel?.invokeMethod<String>('getPlaybackQuality');
    return playbackQualityFromString(result ?? 'default');
  }

  Future<List<PlaybackQuality>> getAvailableQualityLevels() async {
    final result = await _methodChannel
        ?.invokeMethod<String>('getAvailableQualityLevels');
    if (result == null || result == '[]') return [];
    // Result is a JSON array string like '["hd720","large","medium","small"]'
    final cleaned = result.replaceAll(RegExp(r'[\[\]"]'), '');
    return cleaned
        .split(',')
        .where((s) => s.isNotEmpty)
        .map(playbackQualityFromString)
        .toList();
  }

  // -- Volume --

  Future<void> setVolume(int volume) async {
    await _methodChannel?.invokeMethod('setVolume', {
      'volume': volume.clamp(0, 100),
    });
  }

  Future<void> mute() async {
    await _methodChannel?.invokeMethod('mute');
  }

  Future<void> unMute() async {
    await _methodChannel?.invokeMethod('unMute');
  }

  // -- Fullscreen --

  Future<void> exitFullscreen() async {
    await _methodChannel?.invokeMethod('exitFullscreen');
  }

  // -- Position/Duration --

  Future<Duration> getCurrentPosition() async {
    final seconds =
        await _methodChannel?.invokeMethod<double>('getCurrentTime');
    return Duration(milliseconds: ((seconds ?? 0.0) * 1000).round());
  }

  Future<Duration> getDuration() async {
    final seconds =
        await _methodChannel?.invokeMethod<double>('getDuration');
    return Duration(milliseconds: ((seconds ?? 0.0) * 1000).round());
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _methodChannel = null;
    _eventChannel = null;
    super.dispose();
  }
}

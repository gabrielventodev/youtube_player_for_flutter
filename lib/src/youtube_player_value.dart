/// Represents the state of the YouTube player, matching the YouTube IFrame API states.
enum PlayerState {
  unstarted,
  ended,
  playing,
  paused,
  buffering,
  videoCued,
}

PlayerState playerStateFromInt(int value) {
  switch (value) {
    case -1:
      return PlayerState.unstarted;
    case 0:
      return PlayerState.ended;
    case 1:
      return PlayerState.playing;
    case 2:
      return PlayerState.paused;
    case 3:
      return PlayerState.buffering;
    case 5:
      return PlayerState.videoCued;
    default:
      return PlayerState.unstarted;
  }
}

/// Represents the playback quality of the YouTube player.
enum PlaybackQuality {
  small,
  medium,
  large,
  hd720,
  hd1080,
  highres,
  defaultQuality,
}

PlaybackQuality playbackQualityFromString(String value) {
  switch (value) {
    case 'small':
      return PlaybackQuality.small;
    case 'medium':
      return PlaybackQuality.medium;
    case 'large':
      return PlaybackQuality.large;
    case 'hd720':
      return PlaybackQuality.hd720;
    case 'hd1080':
      return PlaybackQuality.hd1080;
    case 'highres':
      return PlaybackQuality.highres;
    default:
      return PlaybackQuality.defaultQuality;
  }
}

String playbackQualityToString(PlaybackQuality quality) {
  switch (quality) {
    case PlaybackQuality.small:
      return 'small';
    case PlaybackQuality.medium:
      return 'medium';
    case PlaybackQuality.large:
      return 'large';
    case PlaybackQuality.hd720:
      return 'hd720';
    case PlaybackQuality.hd1080:
      return 'hd1080';
    case PlaybackQuality.highres:
      return 'highres';
    case PlaybackQuality.defaultQuality:
      return 'default';
  }
}

/// YouTube IFrame API error codes.
enum YoutubeError {
  none,
  invalidParam,
  html5Error,
  videoNotFound,
  notEmbeddable,
}

YoutubeError youtubeErrorFromInt(int code) {
  switch (code) {
    case 2:
      return YoutubeError.invalidParam;
    case 5:
      return YoutubeError.html5Error;
    case 100:
      return YoutubeError.videoNotFound;
    case 101:
    case 150:
    case 152:
      return YoutubeError.notEmbeddable;
    default:
      return YoutubeError.none;
  }
}

/// Immutable value representing the current state of a YouTube player.
class YoutubePlayerValue {
  const YoutubePlayerValue({
    this.isReady = false,
    this.isFullscreen = false,
    this.isShort = false,
    this.videoAspectRatio = 16 / 9,
    this.playerState = PlayerState.unstarted,
    this.playbackQuality = PlaybackQuality.defaultQuality,
    this.error = YoutubeError.none,
  });

  final bool isReady;
  final bool isFullscreen;
  final bool isShort;
  final double videoAspectRatio;
  final PlayerState playerState;
  final PlaybackQuality playbackQuality;
  final YoutubeError error;

  bool get isPlaying => playerState == PlayerState.playing;
  bool get isPaused => playerState == PlayerState.paused;
  bool get isBuffering => playerState == PlayerState.buffering;

  YoutubePlayerValue copyWith({
    bool? isReady,
    bool? isFullscreen,
    bool? isShort,
    double? videoAspectRatio,
    PlayerState? playerState,
    PlaybackQuality? playbackQuality,
    YoutubeError? error,
  }) {
    return YoutubePlayerValue(
      isReady: isReady ?? this.isReady,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isShort: isShort ?? this.isShort,
      videoAspectRatio: videoAspectRatio ?? this.videoAspectRatio,
      playerState: playerState ?? this.playerState,
      playbackQuality: playbackQuality ?? this.playbackQuality,
      error: error ?? this.error,
    );
  }

  @override
  String toString() =>
      'YoutubePlayerValue(isReady: $isReady, isFullscreen: $isFullscreen, '
      'isShort: $isShort, videoAspectRatio: $videoAspectRatio, '
      'playerState: $playerState, '
      'playbackQuality: $playbackQuality, error: $error)';
}

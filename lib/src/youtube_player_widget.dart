import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'youtube_player_controller.dart';
import 'youtube_player_value.dart';

/// A widget that displays a YouTube player using the native platform's WebView.
///
/// Requires a [YoutubePlayerController] to control playback and receive events.
/// The aspect ratio adjusts automatically based on detected video dimensions.
class YoutubePlayerWidget extends StatelessWidget {
  const YoutubePlayerWidget({
    super.key,
    required this.controller,
    this.aspectRatio,
  });

  final YoutubePlayerController controller;

  /// If null, defaults to 16/9.
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio ?? 16 / 9,
      child: _buildPlatformView(),
    );
  }

  Widget _buildPlatformView() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: 'youtube_player_view',
          creationParams: controller.creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: controller.onPlatformViewCreated,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
        );
      case TargetPlatform.iOS:
        // iOS support will be added in a future version
        return const Center(
          child: Text('iOS support coming soon'),
        );
      default:
        return Center(
          child: Text('Platform ${defaultTargetPlatform.name} not supported'),
        );
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'youtube_player_for_flutter_platform_interface.dart';

/// An implementation of [YoutubePlayerForFlutterPlatform] that uses method channels.
class MethodChannelYoutubePlayerForFlutter extends YoutubePlayerForFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('youtube_player_for_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

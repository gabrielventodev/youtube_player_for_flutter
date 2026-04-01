import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'youtube_player_for_flutter_method_channel.dart';

abstract class YoutubePlayerForFlutterPlatform extends PlatformInterface {
  /// Constructs a YoutubePlayerForFlutterPlatform.
  YoutubePlayerForFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static YoutubePlayerForFlutterPlatform _instance = MethodChannelYoutubePlayerForFlutter();

  /// The default instance of [YoutubePlayerForFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelYoutubePlayerForFlutter].
  static YoutubePlayerForFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [YoutubePlayerForFlutterPlatform] when
  /// they register themselves.
  static set instance(YoutubePlayerForFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

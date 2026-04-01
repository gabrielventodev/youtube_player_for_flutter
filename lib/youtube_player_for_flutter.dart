
import 'youtube_player_for_flutter_platform_interface.dart';

export 'src/youtube_player_value.dart';
export 'src/youtube_player_controller.dart';
export 'src/youtube_player_widget.dart';

class YoutubePlayerForFlutter {
  Future<String?> getPlatformVersion() {
    return YoutubePlayerForFlutterPlatform.instance.getPlatformVersion();
  }
}

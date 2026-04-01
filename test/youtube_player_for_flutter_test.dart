import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_for_flutter/youtube_player_for_flutter.dart';
import 'package:youtube_player_for_flutter/youtube_player_for_flutter_platform_interface.dart';
import 'package:youtube_player_for_flutter/youtube_player_for_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockYoutubePlayerForFlutterPlatform
    with MockPlatformInterfaceMixin
    implements YoutubePlayerForFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final YoutubePlayerForFlutterPlatform initialPlatform = YoutubePlayerForFlutterPlatform.instance;

  test('$MethodChannelYoutubePlayerForFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelYoutubePlayerForFlutter>());
  });

  test('getPlatformVersion', () async {
    YoutubePlayerForFlutter youtubePlayerForFlutterPlugin = YoutubePlayerForFlutter();
    MockYoutubePlayerForFlutterPlatform fakePlatform = MockYoutubePlayerForFlutterPlatform();
    YoutubePlayerForFlutterPlatform.instance = fakePlatform;

    expect(await youtubePlayerForFlutterPlugin.getPlatformVersion(), '42');
  });
}

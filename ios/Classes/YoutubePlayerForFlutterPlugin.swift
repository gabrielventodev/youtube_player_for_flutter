import Flutter
import UIKit

public class YoutubePlayerForFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = YoutubePlayerViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "youtube_player_view")
  }
}

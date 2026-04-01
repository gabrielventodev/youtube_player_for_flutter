import Flutter
import UIKit
import Shared

public class YoutubePlayerForFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "youtube_player_for_flutter", binaryMessenger: registrar.messenger())
    let instance = YoutubePlayerForFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      let platform = Shared.Platform()
      result(platform.name)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

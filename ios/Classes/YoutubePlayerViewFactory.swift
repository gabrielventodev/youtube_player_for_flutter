import Flutter
import UIKit

class YoutubePlayerViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let creationParams = args as? [String: Any] ?? [:]
        return YoutubePlayerPlatformView(
            frame: frame,
            viewId: viewId,
            messenger: messenger,
            args: creationParams
        )
    }

    func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol) {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

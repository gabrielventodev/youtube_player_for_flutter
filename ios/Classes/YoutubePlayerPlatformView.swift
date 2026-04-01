import Flutter
import UIKit
import WebKit

class YoutubePlayerPlatformView: NSObject, FlutterPlatformView {

    private let webView: WKWebView
    private let methodChannel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?
    private var isVerticalVideo = false

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: [String: Any]) {
        // -- WKWebView configuration --
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        if #available(iOS 15.4, *) {
            config.preferences.isElementFullscreenEnabled = true
        }

        // JS bridge: creates a YTBridge object that forwards calls to the native handler,
        // so the shared YouTube IFrame HTML (which uses YTBridge.onReady() etc.) works on iOS.
        let userContentController = WKUserContentController()
        let bridgeScript = WKUserScript(
            source: """
            window.YTBridge = {
                onReady: function() {
                    window.webkit.messageHandlers.ytBridge.postMessage({event: 'onReady'});
                },
                onStateChange: function(state) {
                    window.webkit.messageHandlers.ytBridge.postMessage({event: 'onStateChange', state: state});
                },
                onError: function(errorCode) {
                    window.webkit.messageHandlers.ytBridge.postMessage({event: 'onError', errorCode: errorCode});
                },
                onPlaybackQualityChange: function(quality) {
                    window.webkit.messageHandlers.ytBridge.postMessage({event: 'onPlaybackQualityChange', quality: quality});
                }
            };
            document.addEventListener('webkitfullscreenchange', function() {
                var isFS = !!document.webkitFullscreenElement;
                window.webkit.messageHandlers.ytBridge.postMessage({event: 'onFullscreenChange', isFullscreen: isFS});
            });
            document.addEventListener('fullscreenchange', function() {
                var isFS = !!document.fullscreenElement;
                window.webkit.messageHandlers.ytBridge.postMessage({event: 'onFullscreenChange', isFullscreen: isFS});
            });
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        userContentController.addUserScript(bridgeScript)
        config.userContentController = userContentController

        webView = WKWebView(frame: frame, configuration: config)

        methodChannel = FlutterMethodChannel(name: "youtube_player_\(viewId)", binaryMessenger: messenger)
        eventChannel = FlutterEventChannel(name: "youtube_player_events_\(viewId)", binaryMessenger: messenger)

        super.init()

        // Register message handler (weak wrapper to avoid retain cycle)
        userContentController.add(WeakScriptMessageHandler(delegate: self), name: "ytBridge")

        // Setup channels
        methodChannel.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call: call, result: result)
        }
        eventChannel.setStreamHandler(self)

        // Configure WebView appearance
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        // Parse creation params
        let videoId = args["videoId"] as? String ?? ""
        let autoPlay = args["autoPlay"] as? Bool ?? false
        let showControls = args["showControls"] as? Bool ?? true
        let startSeconds = args["startSeconds"] as? Int ?? 0
        let endSeconds = args["endSeconds"] as? Int ?? 0
        let showFullscreenButton = args["showFullscreenButton"] as? Bool ?? true
        let showRelatedVideos = args["showRelatedVideos"] as? Bool ?? false
        let loop = args["loop"] as? Bool ?? false

        // Generate and load HTML
        let html = Self.generateHTML(
            videoId: videoId,
            autoPlay: autoPlay,
            showControls: showControls,
            startSeconds: startSeconds,
            endSeconds: endSeconds,
            showFullscreenButton: showFullscreenButton,
            showRelatedVideos: showRelatedVideos,
            loop: loop
        )
        // baseURL must match the host used in the IFrame to avoid postMessage origin mismatch
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com"))

        // Detect if the video is a YouTube Short
        detectIfShort(videoId: videoId)
    }

    func view() -> UIView {
        return webView
    }

    // MARK: - HTML Generation (mirrors KMP YoutubeIFrameGenerator)

    static func generateHTML(
        videoId: String,
        autoPlay: Bool,
        showControls: Bool,
        startSeconds: Int,
        endSeconds: Int,
        showFullscreenButton: Bool,
        showRelatedVideos: Bool,
        loop: Bool
    ) -> String {
        let safeVideoId = videoId.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        let autoPlayVal = autoPlay ? 1 : 0
        let controlsVal = showControls ? 1 : 0
        let fsVal = showFullscreenButton ? 1 : 0
        let relVal = showRelatedVideos ? 1 : 0
        let loopVal = loop ? 1 : 0
        let playlist = loop ? "'playlist': '\(safeVideoId)'," : ""
        let start = startSeconds > 0 ? "'start': \(startSeconds)," : ""
        let end = endSeconds > 0 ? "'end': \(endSeconds)," : ""

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
        <style>*{margin:0;padding:0;overflow:hidden}html,body{width:100%;height:100%;background:#000}#player{width:100%;height:100%}</style>
        </head>
        <body>
        <div id="player"></div>
        <script>
        var tag=document.createElement('script');
        tag.src='https://www.youtube.com/iframe_api';
        document.head.appendChild(tag);
        var player;
        function onYouTubeIframeAPIReady(){
        player=new YT.Player('player',{
        height:'100%',width:'100%',
        videoId:'\(safeVideoId)',
        host:'https://www.youtube-nocookie.com',
        playerVars:{
        'autoplay':\(autoPlayVal),'controls':\(controlsVal),'fs':\(fsVal),
        'enablejsapi':1,'rel':\(relVal),'loop':\(loopVal),
        'playsinline':1,
        \(playlist) \(start) \(end)
        },
        events:{
        'onReady':function(e){try{YTBridge.onReady()}catch(x){}},
        'onStateChange':function(e){try{YTBridge.onStateChange(e.data)}catch(x){}},
        'onError':function(e){try{YTBridge.onError(e.data)}catch(x){}},
        'onPlaybackQualityChange':function(e){try{YTBridge.onPlaybackQualityChange(e.data)}catch(x){}}
        }
        });
        }
        function ytPlay(){if(player)player.playVideo()}
        function ytPause(){if(player)player.pauseVideo()}
        function ytSeekTo(s){if(player)player.seekTo(s,true)}
        function ytLoadVideo(id,s){if(player){player.loadVideoById(id,s||0)}}
        function ytCueVideo(id,s){if(player){player.cueVideoById(id,s||0)}}
        function ytSetQuality(q){if(player)player.setPlaybackQuality(q)}
        function ytSetVolume(v){if(player)player.setVolume(v)}
        function ytMute(){if(player)player.mute()}
        function ytUnMute(){if(player)player.unMute()}
        function ytGetCurrentTime(){return player?player.getCurrentTime():0}
        function ytGetDuration(){return player?player.getDuration():0}
        function ytGetQuality(){return player?player.getPlaybackQuality():'default'}
        function ytGetAvailableQualities(){return player?JSON.stringify(player.getAvailableQualityLevels()):'[]'}
        </script>
        </body>
        </html>
        """
    }

    // MARK: - Shorts Detection

    private func detectIfShort(videoId: String) {
        let safeId = videoId.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        guard let url = URL(string: "https://www.youtube.com/shorts/\(safeId)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let delegate = NoRedirectDelegate()
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)

        let task = session.dataTask(with: request) { [weak self] _, response, _ in
            guard let httpResponse = response as? HTTPURLResponse else { return }
            // 200 = it's a Short, 302/303 = redirect to /watch (not a Short)
            let isShort = httpResponse.statusCode == 200

            DispatchQueue.main.async {
                self?.isVerticalVideo = isShort
                self?.eventSink?([
                    "event": "onVideoSizeDetected",
                    "width": isShort ? 9 : 16,
                    "height": isShort ? 16 : 9,
                    "isShort": isShort
                ] as [String: Any])
            }
        }
        task.resume()
    }

    // MARK: - Fullscreen Orientation

    private func setOrientation(landscape: Bool) {
        if #available(iOS 16.0, *) {
            let orientations: UIInterfaceOrientationMask = landscape ? .landscape : .portrait
            guard let windowScene = webView.window?.windowScene
                    ?? UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientations))
            windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            let orientation: UIInterfaceOrientation = landscape ? .landscapeRight : .portrait
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        }
    }

    private func restoreOrientation() {
        if #available(iOS 16.0, *) {
            guard let windowScene = webView.window?.windowScene
                    ?? UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
            windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }

    // MARK: - Method Channel Handler

    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        switch call.method {
        case "play":
            webView.evaluateJavaScript("window.ytPlay && window.ytPlay();")
            result(nil)
        case "pause":
            webView.evaluateJavaScript("window.ytPause && window.ytPause();")
            result(nil)
        case "seekTo":
            let seconds = (args?["seconds"] as? NSNumber)?.doubleValue ?? 0.0
            webView.evaluateJavaScript("window.ytSeekTo && window.ytSeekTo(\(seconds));")
            result(nil)
        case "loadVideo":
            let videoId = args?["videoId"] as? String ?? ""
            let safeId = videoId.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
            let startSeconds = (args?["startSeconds"] as? NSNumber)?.doubleValue ?? 0.0
            webView.evaluateJavaScript("window.ytLoadVideo && window.ytLoadVideo('\(safeId)', \(startSeconds));")
            detectIfShort(videoId: safeId)
            result(nil)
        case "cueVideo":
            let videoId = args?["videoId"] as? String ?? ""
            let safeId = videoId.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
            let startSeconds = (args?["startSeconds"] as? NSNumber)?.doubleValue ?? 0.0
            webView.evaluateJavaScript("window.ytCueVideo && window.ytCueVideo('\(safeId)', \(startSeconds));")
            detectIfShort(videoId: safeId)
            result(nil)
        case "setPlaybackQuality":
            let quality = args?["quality"] as? String ?? "default"
            let safeQuality = quality.filter { $0.isLetter || $0.isNumber }
            webView.evaluateJavaScript("window.ytSetQuality && window.ytSetQuality('\(safeQuality)');")
            result(nil)
        case "setVolume":
            let volume = (args?["volume"] as? NSNumber)?.intValue ?? 100
            let clampedVolume = max(0, min(100, volume))
            webView.evaluateJavaScript("window.ytSetVolume && window.ytSetVolume(\(clampedVolume));")
            result(nil)
        case "mute":
            webView.evaluateJavaScript("window.ytMute && window.ytMute();")
            result(nil)
        case "unMute":
            webView.evaluateJavaScript("window.ytUnMute && window.ytUnMute();")
            result(nil)
        case "getCurrentTime":
            webView.evaluateJavaScript("window.ytGetCurrentTime ? window.ytGetCurrentTime() : 0;") { value, _ in
                result(value as? Double ?? 0.0)
            }
        case "getDuration":
            webView.evaluateJavaScript("window.ytGetDuration ? window.ytGetDuration() : 0;") { value, _ in
                result(value as? Double ?? 0.0)
            }
        case "getPlaybackQuality":
            webView.evaluateJavaScript("window.ytGetQuality ? window.ytGetQuality() : 'default';") { value, _ in
                result(value as? String ?? "default")
            }
        case "getAvailableQualityLevels":
            webView.evaluateJavaScript("window.ytGetAvailableQualities ? window.ytGetAvailableQualities() : '[]';") { value, _ in
                result(value as? String ?? "[]")
            }
        case "exitFullscreen":
            webView.evaluateJavaScript(
                "if(document.exitFullscreen){document.exitFullscreen();}else if(document.webkitExitFullscreen){document.webkitExitFullscreen();}"
            )
            restoreOrientation()
            eventSink?(["event": "onFullscreenChange", "isFullscreen": false] as [String: Any])
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Cleanup

    deinit {
        methodChannel.setMethodCallHandler(nil)
        eventChannel.setStreamHandler(nil)
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "ytBridge")
        webView.stopLoading()
    }
}

// MARK: - FlutterStreamHandler

extension YoutubePlayerPlatformView: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// MARK: - WKScriptMessageHandler

extension YoutubePlayerPlatformView: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? [String: Any],
              let event = body["event"] as? String else { return }

        switch event {
        case "onReady":
            eventSink?(["event": "onReady"] as [String: Any])
        case "onStateChange":
            if let state = body["state"] as? Int {
                eventSink?(["event": "onStateChange", "state": state] as [String: Any])
            }
        case "onError":
            if let errorCode = body["errorCode"] as? Int {
                eventSink?(["event": "onError", "errorCode": errorCode] as [String: Any])
            }
        case "onPlaybackQualityChange":
            if let quality = body["quality"] as? String {
                eventSink?(["event": "onPlaybackQualityChange", "quality": quality] as [String: Any])
            }
        case "onFullscreenChange":
            if let isFullscreen = body["isFullscreen"] as? Bool {
                if isFullscreen {
                    setOrientation(landscape: !isVerticalVideo)
                } else {
                    restoreOrientation()
                }
                eventSink?(["event": "onFullscreenChange", "isFullscreen": isFullscreen] as [String: Any])
            }
        default:
            break
        }
    }
}

// MARK: - Weak Script Message Handler (avoids WKWebView retain cycle)

private class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

// MARK: - No-Redirect Session Delegate (for Shorts detection)

private class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        // Don't follow redirects — a redirect means it's NOT a Short
        completionHandler(nil)
    }
}

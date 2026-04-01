package com.openpass.youtube_player_for_flutter

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.pm.ActivityInfo
import android.view.View
import android.webkit.CookieManager
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import com.openpass.shared.PlayerConfig
import com.openpass.shared.YoutubeIFrameGenerator
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.net.HttpURLConnection
import java.net.URL

@SuppressLint("SetJavaScriptEnabled")
class YoutubePlayerPlatformView(
    context: Context,
    private val viewId: Int,
    messenger: BinaryMessenger,
    params: Map<*, *>,
    private val activity: Activity?
) : PlatformView, MethodChannel.MethodCallHandler {

    private val webView: WebView
    private val methodChannel: MethodChannel
    private val eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private var fullscreenView: View? = null
    private var fullscreenCallback: WebChromeClient.CustomViewCallback? = null
    private var originalSystemUiVisibility: Int = 0
    private var originalOrientation: Int = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
    private var isVerticalVideo: Boolean = false

    init {
        // Setup channels
        methodChannel = MethodChannel(messenger, "youtube_player_$viewId")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(messenger, "youtube_player_events_$viewId")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        // Parse config from creation params
        val videoId = params["videoId"] as? String ?: ""
        val autoPlay = params["autoPlay"] as? Boolean ?: false
        val showControls = params["showControls"] as? Boolean ?: true
        val startSeconds = (params["startSeconds"] as? Number)?.toInt() ?: 0
        val endSeconds = (params["endSeconds"] as? Number)?.toInt() ?: 0
        val showFullscreenButton = params["showFullscreenButton"] as? Boolean ?: true
        val showRelatedVideos = params["showRelatedVideos"] as? Boolean ?: false
        val loop = params["loop"] as? Boolean ?: false

        val config = PlayerConfig(
            videoId = videoId,
            autoPlay = autoPlay,
            showControls = showControls,
            startSeconds = startSeconds,
            endSeconds = endSeconds,
            showFullscreenButton = showFullscreenButton,
            showRelatedVideos = showRelatedVideos,
            loop = loop,
        )

        // Enable cookies
        val cookieManager = CookieManager.getInstance()
        cookieManager.setAcceptCookie(true)

        // Setup WebView
        webView = WebView(context).apply {
            settings.javaScriptEnabled = true
            settings.mediaPlaybackRequiresUserGesture = false
            settings.domStorageEnabled = true
            settings.loadWithOverviewMode = true
            settings.useWideViewPort = true
            settings.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            settings.cacheMode = WebSettings.LOAD_DEFAULT

            setBackgroundColor(0xFF000000.toInt())
            isVerticalScrollBarEnabled = false
            isHorizontalScrollBarEnabled = false

            webViewClient = WebViewClient()
            webChromeClient = object : WebChromeClient() {
                override fun onShowCustomView(view: View?, callback: CustomViewCallback?) {
                    if (fullscreenView != null || view == null) {
                        callback?.onCustomViewHidden()
                        return
                    }

                    val act = activity ?: return

                    fullscreenView = view
                    fullscreenCallback = callback

                    originalOrientation = act.requestedOrientation

                    @Suppress("DEPRECATION")
                    originalSystemUiVisibility = act.window.decorView.systemUiVisibility

                    @Suppress("DEPRECATION")
                    act.window.decorView.systemUiVisibility = (
                        View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            or View.SYSTEM_UI_FLAG_FULLSCREEN
                            or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    )

                    val decorView = act.window.decorView as FrameLayout
                    decorView.addView(
                        view,
                        FrameLayout.LayoutParams(
                            FrameLayout.LayoutParams.MATCH_PARENT,
                            FrameLayout.LayoutParams.MATCH_PARENT
                        )
                    )

                    act.requestedOrientation = if (isVerticalVideo) {
                        ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
                    } else {
                        ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
                    }

                    eventSink?.success(mapOf("event" to "onFullscreenChange", "isFullscreen" to true))
                }

                override fun onHideCustomView() {
                    exitFullscreen()
                }
            }

            addJavascriptInterface(YTBridge(), "YTBridge")
        }

        cookieManager.setAcceptThirdPartyCookies(webView, true)

        // Load HTML with IFrame API
        // baseURL must match what YouTube expects for postMessage origin
        val html = YoutubeIFrameGenerator.generate(config)
        webView.loadDataWithBaseURL(
            "https://www.youtube-nocookie.com",
            html,
            "text/html",
            "UTF-8",
            null
        )

        // Detect if the video is a Short from native side
        detectIfShort(videoId)
    }

    override fun getView(): View = webView

    private fun detectIfShort(videoId: String) {
        Thread {
            try {
                val url = URL("https://www.youtube.com/shorts/$videoId")
                val connection = url.openConnection() as HttpURLConnection
                connection.instanceFollowRedirects = false
                connection.requestMethod = "HEAD"
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                connection.setRequestProperty("User-Agent", "Mozilla/5.0")
                val responseCode = connection.responseCode
                connection.disconnect()

                // 200 = it's a short, 302/303 = redirect to /watch (not a short)
                val isShort = responseCode == 200
                isVerticalVideo = isShort

                webView.post {
                    eventSink?.success(
                        mapOf(
                            "event" to "onVideoSizeDetected",
                            "width" to if (isShort) 9 else 16,
                            "height" to if (isShort) 16 else 9,
                            "isShort" to isShort
                        )
                    )
                }
            } catch (_: Exception) {
                // Default: assume regular video
            }
        }.start()
    }

    private fun exitFullscreen() {
        if (fullscreenView == null) return

        val act = activity ?: return

        val decorView = act.window.decorView as FrameLayout
        decorView.removeView(fullscreenView)

        @Suppress("DEPRECATION")
        act.window.decorView.systemUiVisibility = originalSystemUiVisibility

        fullscreenCallback?.onCustomViewHidden()
        fullscreenView = null
        fullscreenCallback = null

        act.requestedOrientation = originalOrientation

        eventSink?.success(mapOf("event" to "onFullscreenChange", "isFullscreen" to false))
    }

    override fun dispose() {
        exitFullscreen()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        webView.removeJavascriptInterface("YTBridge")
        webView.stopLoading()
        webView.destroy()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "play" -> {
                webView.evaluateJavascript("window.ytPlay && window.ytPlay();", null)
                result.success(null)
            }
            "pause" -> {
                webView.evaluateJavascript("window.ytPause && window.ytPause();", null)
                result.success(null)
            }
            "seekTo" -> {
                val seconds = call.argument<Number>("seconds")?.toDouble() ?: 0.0
                webView.evaluateJavascript("window.ytSeekTo && window.ytSeekTo($seconds);", null)
                result.success(null)
            }
            "loadVideo" -> {
                val videoId = call.argument<String>("videoId") ?: ""
                val startSeconds = call.argument<Number>("startSeconds")?.toDouble() ?: 0.0
                webView.evaluateJavascript(
                    "window.ytLoadVideo && window.ytLoadVideo('$videoId', $startSeconds);",
                    null
                )
                detectIfShort(videoId)
                result.success(null)
            }
            "cueVideo" -> {
                val videoId = call.argument<String>("videoId") ?: ""
                val startSeconds = call.argument<Number>("startSeconds")?.toDouble() ?: 0.0
                webView.evaluateJavascript(
                    "window.ytCueVideo && window.ytCueVideo('$videoId', $startSeconds);",
                    null
                )
                detectIfShort(videoId)
                result.success(null)
            }
            "setPlaybackQuality" -> {
                val quality = call.argument<String>("quality") ?: "default"
                webView.evaluateJavascript(
                    "window.ytSetQuality && window.ytSetQuality('$quality');",
                    null
                )
                result.success(null)
            }
            "setVolume" -> {
                val volume = call.argument<Number>("volume")?.toInt() ?: 100
                webView.evaluateJavascript(
                    "window.ytSetVolume && window.ytSetVolume($volume);",
                    null
                )
                result.success(null)
            }
            "mute" -> {
                webView.evaluateJavascript("window.ytMute && window.ytMute();", null)
                result.success(null)
            }
            "unMute" -> {
                webView.evaluateJavascript("window.ytUnMute && window.ytUnMute();", null)
                result.success(null)
            }
            "getCurrentTime" -> {
                webView.evaluateJavascript(
                    "window.ytGetCurrentTime ? window.ytGetCurrentTime() : 0;"
                ) { value ->
                    val time = value?.toDoubleOrNull() ?: 0.0
                    result.success(time)
                }
            }
            "getDuration" -> {
                webView.evaluateJavascript(
                    "window.ytGetDuration ? window.ytGetDuration() : 0;"
                ) { value ->
                    val duration = value?.toDoubleOrNull() ?: 0.0
                    result.success(duration)
                }
            }
            "getPlaybackQuality" -> {
                webView.evaluateJavascript(
                    "window.ytGetQuality ? window.ytGetQuality() : 'default';"
                ) { value ->
                    val quality = value?.removeSurrounding("\"") ?: "default"
                    result.success(quality)
                }
            }
            "getAvailableQualityLevels" -> {
                webView.evaluateJavascript(
                    "window.ytGetAvailableQualities ? window.ytGetAvailableQualities() : '[]';"
                ) { value ->
                    val cleaned = value?.removeSurrounding("\"")?.replace("\\\"", "\"") ?: "[]"
                    result.success(cleaned)
                }
            }
            "exitFullscreen" -> {
                exitFullscreen()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private inner class YTBridge {
        @JavascriptInterface
        fun onReady() {
            webView.post {
                eventSink?.success(mapOf("event" to "onReady"))
            }
        }

        @JavascriptInterface
        fun onStateChange(state: Int) {
            webView.post {
                eventSink?.success(mapOf("event" to "onStateChange", "state" to state))
            }
        }

        @JavascriptInterface
        fun onError(errorCode: Int) {
            webView.post {
                eventSink?.success(mapOf("event" to "onError", "errorCode" to errorCode))
            }
        }

        @JavascriptInterface
        fun onPlaybackQualityChange(quality: String) {
            webView.post {
                eventSink?.success(
                    mapOf("event" to "onPlaybackQualityChange", "quality" to quality)
                )
            }
        }
    }
}

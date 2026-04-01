package com.openpass.youtube_player_for_flutter

import com.openpass.shared.Platform
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** YoutubePlayerForFlutterPlugin */
class YoutubePlayerForFlutterPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var factory: YoutubePlayerViewFactory

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "youtube_player_for_flutter")
        channel.setMethodCallHandler(this)

        factory = YoutubePlayerViewFactory(flutterPluginBinding.binaryMessenger)
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "youtube_player_view",
            factory
        )
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        factory.activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        factory.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        factory.activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        factory.activity = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        if (call.method == "getPlatformVersion") {
            result.success(Platform().name)
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

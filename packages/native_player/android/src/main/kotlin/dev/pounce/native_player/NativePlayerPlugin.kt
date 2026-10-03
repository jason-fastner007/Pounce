package dev.pounce.native_player

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Registers the playback channels for each Flutter engine. */
class NativePlayerPlugin : FlutterPlugin {
    private var bridge: PlayerBridge? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        bridge = PlayerBridge(binding.applicationContext, binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        bridge?.dispose()
        bridge = null
    }
}

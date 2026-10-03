package dev.kittyfork.kittyfork

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // One UpdateBridge per distribution channel (src/play or src/github), same channel name.
        UpdateBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }
}

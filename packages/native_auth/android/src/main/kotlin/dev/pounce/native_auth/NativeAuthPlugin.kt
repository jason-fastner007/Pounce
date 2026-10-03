package dev.pounce.native_auth

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Login via the system browser (Custom Tab). The redirect sc://auth?code=…
 * comes back as an intent and is streamed to Flutter.
 */
class NativeAuthPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler, PluginRegistry.NewIntentListener {

    private lateinit var methods: MethodChannel
    private lateinit var events: EventChannel
    private var binding: ActivityPluginBinding? = null
    private var sink: EventChannel.EventSink? = null
    private val pending = mutableListOf<String>()

    override fun onAttachedToEngine(b: FlutterPlugin.FlutterPluginBinding) {
        methods = MethodChannel(b.binaryMessenger, "pounce/auth").also { it.setMethodCallHandler(this) }
        events = EventChannel(b.binaryMessenger, "pounce/auth/links").also { it.setStreamHandler(this) }
    }

    override fun onDetachedFromEngine(b: FlutterPlugin.FlutterPluginBinding) {
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "authenticate") return result.notImplemented()
        val activity = binding?.activity ?: return result.error("no_activity", null, null)
        val uri = Uri.parse(call.argument<String>("url"))
        try {
            CustomTabsIntent.Builder().setShowTitle(true).build().launchUrl(activity, uri)
        } catch (e: ActivityNotFoundException) {
            activity.startActivity(Intent(Intent.ACTION_VIEW, uri).addCategory(Intent.CATEGORY_BROWSABLE))
        }
        result.success(null) // the result arrives via the link stream
    }

    // ---- Redirect ----

    override fun onNewIntent(intent: Intent): Boolean = handle(intent)

    private fun handle(intent: Intent?): Boolean {
        val data = intent?.data ?: return false
        if (data.scheme != "sc" || data.host != "auth") return false
        val link = data.toString()
        intent.data = null // don't process twice
        sink?.success(link) ?: pending.add(link)
        return true
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        pending.forEach(events::success)
        pending.clear()
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    // ---- Activity ----

    override fun onAttachedToActivity(b: ActivityPluginBinding) {
        binding = b
        b.addOnNewIntentListener(this)
        handle(b.activity.intent) // cold start via the link
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()
    override fun onReattachedToActivityForConfigChanges(b: ActivityPluginBinding) = onAttachedToActivity(b)

    override fun onDetachedFromActivity() {
        binding?.removeOnNewIntentListener(this)
        binding = null
    }
}

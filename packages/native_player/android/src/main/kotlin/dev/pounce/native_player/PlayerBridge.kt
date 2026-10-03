package dev.pounce.native_player

import android.content.ComponentName
import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Connects Flutter (pounce/player) with the PlaybackService via MediaController and direct deck faders. */
class PlayerBridge(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private var active: PlayerBridge? = null

        /** Commands from the system controls (next/previous). */
        fun command(name: String) {
            active?.let { b -> b.main.post { b.sink?.success(mapOf("type" to "command", "command" to name)) } }
        }
    }

    private val main = Handler(Looper.getMainLooper())
    private val methods = MethodChannel(messenger, "pounce/player")
    private val events = EventChannel(messenger, "pounce/player/events")
    private val featureEvents = EventChannel(messenger, "pounce/player/features")
    private var sink: EventChannel.EventSink? = null
    private var featureSink: EventChannel.EventSink? = null
    private var controller: MediaController? = null
    private val pending = mutableListOf<(MediaController) -> Unit>()

    private val listener = object : Player.Listener {
        override fun onEvents(player: Player, events: Player.Events) = emit()
    }

    // Only report the position for drift correction (Dart extrapolates in between); every real
    // state change arrives immediately via onEvents.
    private val ticker = object : Runnable {
        override fun run() {
            emit()
        }
    }

    // Analysis batches every 40 ms while Flutter is listening.
    private var lastFeatureUs = Long.MIN_VALUE
    private var lastGeneration = -1
    private var lastAnalyzer: FeatureAnalyzer? = null
    private val featurePump = object : Runnable {
        override fun run() {
            val s = PlaybackService.instance
            val out = featureSink
            if (s == null || out == null) return
            val deck = s.active
            val a = deck.analyzer
            if (a !== lastAnalyzer || a.generation != lastGeneration) {
                lastAnalyzer = a
                lastGeneration = a.generation
                lastFeatureUs = Long.MIN_VALUE
            }
            val batch = a.drain(lastFeatureUs)
            if (batch != null) {
                lastFeatureUs = java.nio.ByteBuffer.wrap(batch, batch.size - FeatureAnalyzer.HOP_BYTES, 8)
                    .order(java.nio.ByteOrder.LITTLE_ENDIAN).long
            }
            val l = deck.loudness
            out.success(
                mapOf(
                    "gen" to (System.identityHashCode(a) * 31 + a.generation),
                    "hops" to batch,
                    "m" to l.momentary,
                    "i" to l.integrated,
                    "g" to if (l.target == null) null else l.gainDb,
                    "l" to l.limiterDb,
                )
            )
            main.postDelayed(this, 40)
        }
    }

    init {
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
        featureEvents.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                featureSink = events
                PlaybackService.instance?.analysisActive = true
                main.removeCallbacks(featurePump)
                main.post(featurePump)
            }

            override fun onCancel(arguments: Any?) {
                featureSink = null
                PlaybackService.instance?.analysisActive = false
                main.removeCallbacks(featurePump)
            }
        })
        active = this
        val token = SessionToken(context, ComponentName(context, PlaybackService::class.java))
        val future = MediaController.Builder(context, token).buildAsync()
        future.addListener({
            val c = future.get()
            c.addListener(listener)
            controller = c
            pending.forEach { it(c) }
            pending.clear()
            PlaybackService.instance?.let { s ->
                s.onStreamTitle = { title -> main.post { sink?.success(mapOf("type" to "title", "title" to title)) } }
                s.onActiveDeckEvents = { emit() }
                s.onAutoAdvanced = { pos, dur ->
                    sink?.success(
                        mapOf(
                            "type" to "state", "status" to "ended", "playing" to false,
                            "position" to pos, "duration" to dur, "buffered" to dur, "error" to null,
                        )
                    )
                }
                s.analysisActive = featureSink != null
            }
            emit()
        }, ContextCompat.getMainExecutor(context))
    }

    fun dispose() {
        PlaybackService.instance?.onActiveDeckEvents = null
        PlaybackService.instance?.onAutoAdvanced = null
        main.removeCallbacks(ticker)
        main.removeCallbacks(featurePump)
        controller?.removeListener(listener)
        controller?.release()
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        featureEvents.setStreamHandler(null)
        if (active === this) active = null
    }

    private fun withController(f: (MediaController) -> Unit) {
        controller?.let(f) ?: pending.add(f)
    }

    private fun withActivePlayer(f: (Player) -> Unit) {
        val s = PlaybackService.instance
        if (s != null) {
            f(s.activeDeck)
        } else {
            withController(f)
        }
    }

    private fun buildMediaItem(call: MethodCall): MediaItem {
        val url = call.argument<String>("url")!!
        val art = call.argument<String>("artUrl")
        val meta = MediaMetadata.Builder()
            .setTitle(call.argument<String>("title"))
            .setArtist(call.argument<String>("artist"))
            .setArtworkUri(art?.let(Uri::parse))
            .build()
        val hls = call.argument<Boolean>("hls") == true
        // Set the URI directly: if the service runs in the same process, items go to ExoPlayer without
        // a MediaSession (and thus without onAddMediaItems) – without localConfiguration there'd be an NPE.
        return MediaItem.Builder()
            .setMediaId(call.argument<String>("id")!!)
            .setUri(url)
            .setMimeType(if (hls) MimeTypes.APPLICATION_M3U8 else null)
            .setMediaMetadata(meta)
            .setRequestMetadata(
                MediaItem.RequestMetadata.Builder()
                    .setMediaUri(Uri.parse(url))
                    .setExtras(Bundle().apply { putBoolean("hls", hls) })
                    .build()
            )
            .build()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "load" -> {
                val item = buildMediaItem(call)
                val start = (call.argument<Number>("startMs") ?: 0).toLong()
                val play = call.argument<Boolean>("play") != false
                val service = PlaybackService.instance
                if (service != null) {
                    service.load(item, start, play)
                } else {
                    withController { c ->
                        c.setMediaItem(item, start)
                        c.prepare()
                        c.playWhenReady = play
                    }
                }
            }
            "prebuffer" -> {
                val item = buildMediaItem(call)
                val start = (call.argument<Number>("startMs") ?: 0).toLong()
                PlaybackService.instance?.prebuffer(item, start, call.argument<Boolean>("autoAdvance") == true)
            }
            "cancelPrebuffer" -> PlaybackService.instance?.cancelPrebuffer()
            "crossfade" -> {
                val item = buildMediaItem(call)
                val start = (call.argument<Number>("startMs") ?: 0).toLong()
                val durationMs = (call.argument<Number>("durationMs") ?: 3000).toLong()
                val tempo = (call.argument<Number>("tempo") ?: 1.0).toFloat()
                val service = PlaybackService.instance
                if (service != null) {
                    service.crossfade(item, start, durationMs, tempo) {
                        emit()
                    }
                } else {
                    withController { c ->
                        c.setMediaItem(item, start)
                        c.prepare()
                        c.playWhenReady = true
                    }
                }
            }
            "play" -> withActivePlayer { it.play() }
            "pause" -> withActivePlayer { it.pause() }
            "seek" -> withActivePlayer { it.seekTo((call.arguments as Number).toLong()) }
            "stop" -> withActivePlayer { it.stop() }
            "volume" -> {
                val v = (call.arguments as Number).toFloat()
                val s = PlaybackService.instance
                if (s != null) {
                    s.masterVolume = v
                } else {
                    withController { it.volume = v }
                }
            }
            "speed" -> {
                val sp = (call.arguments as Number).toFloat()
                val s = PlaybackService.instance
                if (s != null) {
                    s.masterSpeed = sp
                } else {
                    withController { it.playbackParameters = PlaybackParameters(sp) }
                }
            }
            "loudness" -> PlaybackService.instance?.loudnessTarget = (call.arguments as Number?)?.toDouble()
            else -> return result.notImplemented()
        }
        result.success(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        emit()
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    private fun emit() {
        val s = PlaybackService.instance
        val p: Player? = s?.displayDeck ?: controller
        if (p == null) return
        val err = (p as? ExoPlayer)?.playerError ?: (p as? MediaController)?.playerError
        val status = when {
            err != null -> "error"
            p.playbackState == Player.STATE_BUFFERING -> "loading"
            p.playbackState == Player.STATE_READY -> "ready"
            p.playbackState == Player.STATE_ENDED -> "ended"
            else -> "idle"
        }
        sink?.success(
            mapOf(
                "type" to "state",
                "status" to status,
                "playing" to p.isPlaying,
                "position" to p.currentPosition,
                "duration" to p.duration.coerceAtLeast(0),
                "buffered" to p.bufferedPosition,
                "error" to err?.message,
            )
        )
        main.removeCallbacks(ticker)
        if (p.isPlaying) main.postDelayed(ticker, 1000)
    }
}

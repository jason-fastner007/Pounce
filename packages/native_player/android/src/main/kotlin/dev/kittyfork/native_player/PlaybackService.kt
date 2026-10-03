package dev.kittyfork.native_player

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.ForwardingPlayer
import androidx.media3.common.MediaItem
import androidx.media3.common.Metadata
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.SeekParameters
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.DefaultAudioSink
import androidx.media3.extractor.metadata.icy.IcyInfo
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import kotlin.math.cos
import kotlin.math.sin

/**
 * System playback with a real dual deck (deck A and deck B) for seamless,
 * gapless DJ transitions and automix.
 *
 * Each deck has an analysis tap (spectrum/bass with media time, see [TapAudioSink]) and
 * loudness normalisation ([LoudnessProcessor]).
 */
@OptIn(UnstableApi::class)
class PlaybackService : MediaSessionService() {

    companion object {
        var instance: PlaybackService? = null
    }

    /** One deck: player plus its audio stages. */
    class Deck(val player: ExoPlayer, val analyzer: FeatureAnalyzer, val loudness: LoudnessProcessor)

    private var session: MediaSession? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private lateinit var deckA: Deck
    private lateinit var deckB: Deck
    private var activeDeckIndex = 0 // 0 = A, 1 = B

    val active: Deck get() = if (activeDeckIndex == 0) deckA else deckB
    val inactive: Deck get() = if (activeDeckIndex == 0) deckB else deckA
    val activeDeck: ExoPlayer get() = active.player

    /** What Flutter sees as the "current song": during a crossfade already the incoming deck. */
    val displayDeck: ExoPlayer get() = if (crossfadeRunnable != null) inactiveDeck else activeDeck
    val inactiveDeck: ExoPlayer get() = inactive.player

    /** State changes of the active deck – directly, without the detour through the MediaController. */
    var onActiveDeckEvents: (() -> Unit)? = null

    /** Title from stream metadata (radio), passed on to Flutter. */
    var onStreamTitle: ((String?) -> Unit)? = null

    var masterVolume: Float = 1.0f
        set(value) {
            field = value.coerceIn(0f, 1f)
            activeDeck.volume = outVolume
        }

    /** Output level: master volume, lowered while "ducking" (e.g. a navigation prompt). */
    private var duck = 1f
    private val outVolume: Float get() = masterVolume * duck

    /** One audio focus for the whole app (both decks). */
    private val focus = Focus()

    private inner class Focus : AudioManager.OnAudioFocusChangeListener {
        private val am by lazy { getSystemService(AUDIO_SERVICE) as AudioManager }
        private val request by lazy {
            AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(
                    android.media.AudioAttributes.Builder()
                        .setUsage(android.media.AudioAttributes.USAGE_MEDIA)
                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .setOnAudioFocusChangeListener(this, mainHandler)
                .build()
        }
        private var held = false
        private var resumeOnGain = false

        /** Hold focus as long as a deck should play; otherwise release it. */
        fun update() {
            if (!::deckA.isInitialized || !::deckB.isInitialized) return
            val wants = deckA.player.playWhenReady || deckB.player.playWhenReady
            if (wants && !held) {
                held = am.requestAudioFocus(request) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
                if (!held) pauseAll() // e.g. during a phone call
            } else if (!wants && held && !resumeOnGain) {
                am.abandonAudioFocusRequest(request)
                held = false
            }
        }

        override fun onAudioFocusChange(change: Int) {
            when (change) {
                AudioManager.AUDIOFOCUS_LOSS -> {
                    held = false
                    resumeOnGain = false
                    pauseAll()
                }
                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                    resumeOnGain = activeDeck.playWhenReady
                    pauseAll()
                }
                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> setDuck(0.25f)
                AudioManager.AUDIOFOCUS_GAIN -> {
                    held = true
                    setDuck(1f)
                    if (resumeOnGain) activeDeck.playWhenReady = true
                    resumeOnGain = false
                }
            }
        }

        private fun pauseAll() {
            cancelCrossfade()
            deckA.player.playWhenReady = false
            deckB.player.playWhenReady = false
        }

        private fun setDuck(v: Float) {
            duck = v
            if (crossfadeRunnable == null) activeDeck.volume = outVolume
        }

        fun release() {
            if (held) am.abandonAudioFocusRequest(request)
            held = false
        }
    }

    var masterSpeed: Float = 1.0f
        set(value) {
            field = value.coerceIn(0.25f, 2.0f)
            val params = PlaybackParameters(field)
            deckA.player.playbackParameters = params
            deckB.player.playbackParameters = params
        }

    /** Target loudness in LUFS for both decks (null = off). */
    var loudnessTarget: Double? = null
        set(value) {
            field = value
            deckA.loudness.target = value
            deckB.loudness.target = value
        }

    /** Analysis only while Flutter is polling the values. */
    var analysisActive: Boolean = false
        set(value) {
            field = value
            deckA.analyzer.active = value
            deckB.analyzer.active = value
        }

    private var crossfadeRunnable: Runnable? = null
    private var tempoRunnable: Runnable? = null

    private fun createDeck(): Deck {
        val analyzer = FeatureAnalyzer()
        val loudness = LoudnessProcessor()
        val renderers = object : DefaultRenderersFactory(this) {
            override fun buildAudioSink(
                context: Context,
                enableFloatOutput: Boolean,
                enableAudioTrackPlaybackParams: Boolean,
            ): AudioSink {
                val sink = DefaultAudioSink.Builder(context)
                    .setAudioProcessors(arrayOf(loudness))
                    .setEnableAudioTrackPlaybackParams(enableAudioTrackPlaybackParams)
                    .build()
                return TapAudioSink(sink, analyzer)
            }
        }.apply {
            // Tempo via the audio system instead of Sonic: tempo changes (DJ matching, 8 s ramp)
            // don't rebuild the processing chain – otherwise it clicks on every step.
            setEnableAudioTrackPlaybackParams(true)
        }
        // Start as soon as 250 ms of audio is there (default: 2.5 s). After a stall only continue at
        // 1.5 s so it doesn't stutter on a weak network. Buffer as default (15–50 s).
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(15_000, 50_000, 250, 1_500)
            .setPrioritizeTimeOverSizeThresholds(true)
            .build()
        val player = ExoPlayer.Builder(this, renderers)
            .setLoadControl(loadControl)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(C.USAGE_MEDIA)
                    .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                    .build(),
                // No focus per deck: two decks would take focus from each other and pause
                // (transition aborts, next song stalls). [focus] manages focus centrally.
                false,
            )
            .setHandleAudioBecomingNoisy(true) // headphones unplugged -> pause
            .setWakeMode(C.WAKE_MODE_NETWORK)
            .setSeekParameters(SeekParameters.EXACT)
            .build()
        player.addListener(object : Player.Listener {
            override fun onMetadata(metadata: Metadata) {
                for (i in 0 until metadata.length()) {
                    val e = metadata.get(i)
                    if (e is IcyInfo && player === activeDeck) {
                        onStreamTitle?.invoke(e.title)
                        showStreamTitle(player, e.title)
                    }
                }
            }

            override fun onEvents(p: Player, events: Player.Events) {
                if (p === displayDeck) onActiveDeckEvents?.invoke()
            }

            override fun onPlaybackStateChanged(state: Int) {
                if (state == Player.STATE_ENDED) autoAdvance(player)
            }

            override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) {
                focus.update()
            }

            override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
                loudness.resetMeasurement()
            }
        })
        return Deck(player, analyzer, loudness)
    }

    /**
     * Radio: the current song (ICY) as the "artist" line in the notification and lock screen.
     * Only the item's metadata is swapped – Media3 keeps playing without interruption.
     */
    private fun showStreamTitle(player: ExoPlayer, title: String?) {
        val item = player.currentMediaItem ?: return
        val song = title?.trim()?.removePrefix("-")?.trim()?.takeIf { it.isNotEmpty() } ?: return
        if (item.mediaMetadata.artist?.toString() == song) return
        val meta = item.mediaMetadata.buildUpon().setArtist(song).build()
        player.replaceMediaItem(player.currentMediaItemIndex, item.buildUpon().setMediaMetadata(meta).build())
    }

    override fun onCreate() {
        super.onCreate()
        instance = this

        deckA = createDeck()
        deckB = createDeck()

        // Tapping the notification opens the app.
        val launch = packageManager.getLaunchIntentForPackage(packageName)
            ?.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val open = launch?.let { PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_IMMUTABLE) }

        session = MediaSession.Builder(this, QueueForwarder(deckA.player))
            .apply { open?.let(::setSessionActivity) }
            .setCallback(Callback)
            .build()
    }

    override fun onGetSession(info: MediaSession.ControllerInfo) = session

    override fun onTaskRemoved(rootIntent: Intent?) {
        val p = activeDeck
        if (!p.playWhenReady || p.mediaItemCount == 0) stopSelf()
    }

    override fun onDestroy() {
        cancelCrossfade()
        focus.release()
        instance = null
        session?.run {
            release()
        }
        session = null
        deckA.player.release()
        deckB.player.release()
        super.onDestroy()
    }

    fun load(item: MediaItem, startMs: Long, play: Boolean) {
        cancelCrossfade()
        val active = activeDeck
        val inactive = inactiveDeck

        autoAdvanceId = null

        // Already advanced automatically (see [autoAdvance]): it's playing already.
        val advanced = advancedId
        advancedId = null
        if (advanced == item.mediaId && active.currentMediaItem?.mediaId == item.mediaId && startMs == 0L) {
            active.playWhenReady = play
            return
        }

        // Already pre-buffered (finger rested on the row): just swap decks, no reload.
        if (inactive.currentMediaItem?.mediaId == item.mediaId && inactive.playbackState != Player.STATE_IDLE) {
            swapDecks(startMs, play)
            return
        }

        inactive.stop()
        inactive.clearMediaItems()
        inactive.volume = 0f

        active.volume = outVolume
        active.playbackParameters = PlaybackParameters(masterSpeed)
        active.setMediaItem(item, startMs)
        active.prepare()
        active.playWhenReady = play
        this.active.loudness.resetMeasurement()
        onStreamTitle?.invoke(null)
        session?.player = QueueForwarder(active)
    }

    /** The free deck takes over (it's already prepared), the previous one is cleared. */
    private fun swapDecks(startMs: Long, play: Boolean) {
        val old = activeDeck
        val next = inactiveDeck
        activeDeckIndex = 1 - activeDeckIndex
        next.volume = outVolume
        next.playbackParameters = PlaybackParameters(masterSpeed)
        if (Math.abs(next.currentPosition - startMs) > 200) next.seekTo(startMs)
        next.playWhenReady = play
        old.stop()
        old.clearMediaItems()
        old.volume = 0f
        active.loudness.resetMeasurement()
        onStreamTitle?.invoke(null)
        session?.player = QueueForwarder(next)
    }

    /**
     * Track the free deck starts by itself right at the end of the active one (next queue entry).
     * Saves the round trip through Flutter; its subsequent [load] then finds it already playing.
     */
    private var autoAdvanceId: String? = null

    /** Last automatically started track – Flutter's following [load] lets it keep playing. */
    private var advancedId: String? = null

    /** Reports the end of the old track to Flutter (the old deck is no longer active by then). */
    var onAutoAdvanced: ((positionMs: Long, durationMs: Long) -> Unit)? = null

    private fun autoAdvance(ended: ExoPlayer) {
        val next = inactiveDeck
        val id = autoAdvanceId ?: return
        if (ended !== activeDeck || crossfadeRunnable != null) return
        if (next.currentMediaItem?.mediaId != id || next.playbackState != Player.STATE_READY) return
        autoAdvanceId = null
        advancedId = id
        val pos = ended.currentPosition
        val dur = ended.duration.coerceAtLeast(0)
        swapDecks(0, true)
        onAutoAdvanced?.invoke(pos, dur)
    }

    /** Discard the free deck's pre-buffer (the finger moved to scroll). */
    fun cancelPrebuffer() {
        autoAdvanceId = null
        val inactive = inactiveDeck
        if (crossfadeRunnable != null) return // a crossfade is running: don't touch
        inactive.stop()
        inactive.clearMediaItems()
    }

    /** Pre-buffer request during a crossfade – applied after the deck swap. */
    private var deferredPrebuffer: Triple<MediaItem, Long, Boolean>? = null

    fun prebuffer(item: MediaItem, startMs: Long, autoAdvance: Boolean = false) {
        // During the crossfade the "free" deck is the incoming one: don't overwrite it
        // (otherwise the new song stalls), pre-buffer after the swap instead.
        if (crossfadeRunnable != null) {
            deferredPrebuffer = Triple(item, startMs, autoAdvance)
            return
        }
        val inactive = inactiveDeck
        autoAdvanceId = if (autoAdvance && startMs == 0L) item.mediaId else null
        if (inactive.currentMediaItem?.mediaId == item.mediaId) {
            // Already loaded, but at a different position: seek there now (muted, paused) – not only at the crossfade.
            if (Math.abs(inactive.currentPosition - startMs) > 200) inactive.seekTo(startMs)
            return
        }
        inactive.volume = 0f
        inactive.setMediaItem(item, startMs)
        inactive.prepare()
        inactive.playWhenReady = false
    }

    /**
     * Equal-power crossfade. [tempo] matches the new track's tempo to the old one
     * (beat matching, pitch is preserved) and glides back to the original over 8 s after the transition.
     */
    fun crossfade(item: MediaItem, startMs: Long, durationMs: Long, tempo: Float, onDone: (() -> Unit)? = null) {
        cancelCrossfade()
        autoAdvanceId = null

        val oldDeck = activeDeck
        val newDeck = inactiveDeck

        val needsSetItem = newDeck.currentMediaItem?.mediaId != item.mediaId
        if (needsSetItem) {
            newDeck.setMediaItem(item, startMs)
            newDeck.prepare()
        } else if (startMs > 0 && Math.abs(newDeck.currentPosition - startMs) > 200) {
            newDeck.seekTo(startMs)
        }
        val matched = (masterSpeed * tempo.coerceIn(0.9f, 1.1f))
        newDeck.playbackParameters = PlaybackParameters(matched)
        inactive.loudness.resetMeasurement()

        newDeck.volume = 0f
        newDeck.playWhenReady = true
        newDeck.play()

        val fadeDur = durationMs.coerceIn(1000L, 16000L)
        val startTime = System.currentTimeMillis()

        crossfadeRunnable = object : Runnable {
            override fun run() {
                val elapsed = System.currentTimeMillis() - startTime
                val progress = (elapsed.toFloat() / fadeDur.toFloat()).coerceIn(0f, 1f)

                // Equal-power crossfade curve: sin(t * pi/2) for in, cos(t * pi/2) for out
                newDeck.volume = sin(progress * (Math.PI / 2.0)).toFloat() * outVolume
                oldDeck.volume = cos(progress * (Math.PI / 2.0)).toFloat() * outVolume

                if (progress < 1f) {
                    mainHandler.postDelayed(this, 16)
                } else {
                    // Crossfade done: swap decks
                    oldDeck.stop()
                    oldDeck.clearMediaItems()
                    oldDeck.volume = 0f

                    activeDeckIndex = 1 - activeDeckIndex
                    newDeck.volume = outVolume
                    onStreamTitle?.invoke(null)

                    session?.player = QueueForwarder(activeDeck)
                    crossfadeRunnable = null
                    rampTempo(newDeck, matched)
                    deferredPrebuffer?.let { (i, start, auto) -> prebuffer(i, start, auto) }
                    deferredPrebuffer = null
                    onDone?.invoke()
                }
            }
        }
        mainHandler.post(crossfadeRunnable!!)
    }

    /** After the transition, inaudibly (8 s) bring the tempo back to master speed. */
    private fun rampTempo(deck: ExoPlayer, from: Float) {
        if (from == masterSpeed) return
        val start = System.currentTimeMillis()
        tempoRunnable = object : Runnable {
            override fun run() {
                val p = ((System.currentTimeMillis() - start) / 8000f).coerceIn(0f, 1f)
                deck.playbackParameters = PlaybackParameters(from + (masterSpeed - from) * p)
                if (p < 1f) mainHandler.postDelayed(this, 100) else tempoRunnable = null
            }
        }
        mainHandler.post(tempoRunnable!!)
    }

    private fun cancelCrossfade() {
        deferredPrebuffer = null
        crossfadeRunnable?.let { mainHandler.removeCallbacks(it) }
        crossfadeRunnable = null
        tempoRunnable?.let { mainHandler.removeCallbacks(it) }
        tempoRunnable = null
    }

    /** The URI comes via RequestMetadata (localConfiguration isn't transferred). */
    private object Callback : MediaSession.Callback {
        override fun onAddMediaItems(
            mediaSession: MediaSession,
            controller: MediaSession.ControllerInfo,
            mediaItems: MutableList<MediaItem>,
        ): ListenableFuture<MutableList<MediaItem>> = Futures.immediateFuture(
            mediaItems.map { item ->
                val uri = item.requestMetadata.mediaUri ?: return@map item
                val hls = item.requestMetadata.extras?.getBoolean("hls") == true
                item.buildUpon()
                    .setUri(uri)
                    .setMimeType(if (hls) MimeTypes.APPLICATION_M3U8 else null)
                    .build()
            }.toMutableList()
        )
    }

    /**
     * The queue lives in Dart. We still show next/previous in the system
     * and forward the commands to Flutter.
     */
    private class QueueForwarder(player: Player) : ForwardingPlayer(player) {
        private val extra = Player.Commands.Builder()
            .addAll(
                COMMAND_SEEK_TO_NEXT, COMMAND_SEEK_TO_NEXT_MEDIA_ITEM,
                COMMAND_SEEK_TO_PREVIOUS, COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM,
            ).build()

        override fun getAvailableCommands(): Player.Commands =
            super.getAvailableCommands().buildUpon().addAll(extra).build()

        override fun isCommandAvailable(command: Int) =
            extra.contains(command) || super.isCommandAvailable(command)

        override fun seekToNext() = PlayerBridge.command("next")
        override fun seekToNextMediaItem() = PlayerBridge.command("next")
        override fun seekToPrevious() = PlayerBridge.command("previous")
        override fun seekToPreviousMediaItem() = PlayerBridge.command("previous")
    }
}

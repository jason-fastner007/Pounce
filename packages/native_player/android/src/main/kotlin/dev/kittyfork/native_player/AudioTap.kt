package dev.kittyfork.native_player

import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.ForwardingAudioSink
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.math.tan

/**
 * Spectrum and bass analysis right at the audio sink, with the media time of every buffer.
 *
 * The renderer hands over every decoded buffer together with its presentationTime before
 * it disappears into the AudioTrack buffer. That way the UI knows exactly, for every playback
 * position, what the currently *audible* audio looks like – without microphone permission
 * (Visualizer API) and without the ~200 ms offset that tapping at the end of the chain would have.
 *
 * Cost: only while Flutter is listening (visualisation visible), one 1024-point FFT every
 * 512 samples (~90×/s) – zero in the background.
 */
@OptIn(UnstableApi::class)
class TapAudioSink(sink: AudioSink, private val analyzer: FeatureAnalyzer) : ForwardingAudioSink(sink) {

    private var sampleRate = 44_100
    private var channels = 2
    private var encoding = C.ENCODING_PCM_16BIT
    private var lastBuffer: ByteBuffer? = null
    private var lastPts = Long.MIN_VALUE

    override fun configure(inputFormat: Format, specifiedBufferSize: Int, outputChannels: IntArray?) {
        sampleRate = if (inputFormat.sampleRate > 0) inputFormat.sampleRate else 44_100
        channels = max(1, inputFormat.channelCount)
        encoding = inputFormat.pcmEncoding
        super.configure(inputFormat, specifiedBufferSize, outputChannels)
    }

    override fun handleBuffer(buffer: ByteBuffer, presentationTimeUs: Long, encodedAccessUnitCount: Int): Boolean {
        // Buffers that weren't accepted come again: only evaluate them the first time.
        if (analyzer.active && (buffer !== lastBuffer || presentationTimeUs != lastPts)) {
            lastBuffer = buffer
            lastPts = presentationTimeUs
            analyzer.feed(buffer.duplicate().order(ByteOrder.LITTLE_ENDIAN), presentationTimeUs, sampleRate, channels, encoding)
        }
        return super.handleBuffer(buffer, presentationTimeUs, encodedAccessUnitCount)
    }

    override fun flush() {
        analyzer.flush()
        lastBuffer = null
        super.flush()
    }
}

/**
 * Per hop (512 samples): 64 logarithmic bands 30 Hz – 16 kHz (like the browser's AnalyserNode:
 * 0..255 over −100 … −30 dB, smoothing 0.55) and the bass level (150 Hz low-pass).
 * Results sit with their media time in a ring buffer; Flutter fetches them in batches.
 */
class FeatureAnalyzer {
    companion object {
        const val BANDS = 64
        private const val N = 1024
        private const val HOP = 512
        private const val RING = 512
        /** Bytes per hop in the batch: time (Int64 µs) + bass dB (Float32) + 64 bands. */
        const val HOP_BYTES = 8 + 4 + BANDS
    }

    @Volatile
    var active = false

    private val window = FloatArray(N) { (0.5 - 0.5 * cos(2.0 * PI * it / N)).toFloat() }
    private val re = FloatArray(N)
    private val im = FloatArray(N)
    private val mono = FloatArray(N)
    private val smooth = FloatArray(N / 2)
    private var fill = 0
    private var hopStartUs = 0L
    private var rate = 44_100
    private var edges = IntArray(BANDS + 1)
    private var cos = FloatArray(N / 2)
    private var sin = FloatArray(N / 2)
    private val rev = IntArray(N)

    // 150 Hz low-pass (biquad) for the bass level.
    private var b0 = 0f; private var b1 = 0f; private var b2 = 0f; private var a1 = 0f; private var a2 = 0f
    private var z1 = 0f; private var z2 = 0f
    private var bassSum = 0f

    private val ringTime = LongArray(RING)
    private val ringBass = FloatArray(RING)
    private val ringBands = Array(RING) { ByteArray(BANDS) }
    private var head = 0L // Anzahl geschriebener Hops

    init {
        val bits = 10
        for (i in 0 until N) rev[i] = Integer.reverse(i) ushr (32 - bits)
        for (k in 0 until N / 2) {
            cos[k] = cos(2.0 * PI * k / N).toFloat()
            sin[k] = sin(2.0 * PI * k / N).toFloat()
        }
        configure(44_100)
    }

    private fun configure(sr: Int) {
        rate = sr
        val binHz = sr.toDouble() / N
        edges = IntArray(BANDS + 1) { i ->
            (30.0 * (16_000.0 / 30.0).pow(i.toDouble() / BANDS) / binHz).toInt().coerceIn(1, N / 2 - 1)
        }
        // RBJ-Tiefpass, Q = 0,707.
        val k = tan(PI * 150.0 / sr)
        val q = 0.7071
        val norm = 1.0 / (1.0 + k / q + k * k)
        b0 = (k * k * norm).toFloat(); b1 = 2f * b0; b2 = b0
        a1 = (2.0 * (k * k - 1.0) * norm).toFloat()
        a2 = ((1.0 - k / q + k * k) * norm).toFloat()
    }

    /** Counts flushes (seek, new track): Flutter then discards its buffer. */
    @Volatile
    var generation = 0
        private set

    @Synchronized
    fun flush() {
        fill = 0
        z1 = 0f; z2 = 0f; bassSum = 0f
        smooth.fill(0f)
        head = 0L
        generation++
    }

    /** Runs on ExoPlayer's playback thread. */
    @Synchronized
    fun feed(buf: ByteBuffer, ptsUs: Long, sr: Int, ch: Int, encoding: Int) {
        if (sr != rate) configure(sr)
        val float = encoding == C.ENCODING_PCM_FLOAT
        val bytesPerFrame = ch * if (float) 4 else 2
        val frames = buf.remaining() / bytesPerFrame
        var pos = buf.position()
        for (f in 0 until frames) {
            if (fill == 0) hopStartUs = ptsUs + f * 1_000_000L / sr
            var s = 0f
            for (c in 0 until ch) {
                s += if (float) buf.getFloat(pos) else buf.getShort(pos) / 32768f
                pos += if (float) 4 else 2
            }
            s /= ch
            mono[fill++] = s
            // Bass: low-pass and energy over the hop.
            val y = b0 * s + z1
            z1 = b1 * s - a1 * y + z2
            z2 = b2 * s - a2 * y
            bassSum += y * y
            if (fill == N) hop()
        }
    }

    /** A full window: FFT, bands, bass – then shift by HOP. */
    private fun hop() {
        for (i in 0 until N) {
            val j = rev[i]
            re[j] = mono[i] * window[i]
            im[j] = 0f
        }
        var half = 1
        while (half < N) {
            val step = N / (half * 2)
            var start = 0
            while (start < N) {
                for (k in 0 until half) {
                    val c = cos[k * step]; val s = sin[k * step]
                    val a = start + k; val b = a + half
                    val tr = re[b] * c + im[b] * s
                    val ti = im[b] * c - re[b] * s
                    re[b] = re[a] - tr; im[b] = im[a] - ti
                    re[a] += tr; im[a] += ti
                }
                start += half * 2
            }
            half *= 2
        }
        val slot = (head % RING).toInt()
        val bands = ringBands[slot]
        for (bin in 1 until N / 2) {
            val mag = sqrt(re[bin] * re[bin] + im[bin] * im[bin]) / N
            smooth[bin] = 0.55f * smooth[bin] + 0.45f * mag
        }
        for (b in 0 until BANDS) {
            var peak = 0f
            val hi = max(edges[b], edges[b + 1] - 1)
            for (bin in edges[b]..hi) peak = max(peak, smooth[bin])
            val db = 20f * log10(peak + 1e-12f)
            bands[b] = (((db + 100f) / 70f).coerceIn(0f, 1f) * 255f).toInt().toByte()
        }
        // Bass RMS over the whole window (≈ 23 ms): kicks don't get lost.
        ringBass[slot] = 10f * log10(bassSum / N + 1e-12f)
        // Time of the window = its middle (the way you hear it).
        ringTime[slot] = hopStartUs + (N / 2) * 1_000_000L / rate
        head++

        // Shift by HOP; the bass sum only keeps counting the new half.
        System.arraycopy(mono, HOP, mono, 0, N - HOP)
        fill = N - HOP
        hopStartUs += HOP * 1_000_000L / rate
        bassSum *= 0.5f
    }

    /**
     * All hops after [afterUs] as a batch (at most [max]), null = nothing new.
     * Format per hop: Int64 time µs, Float32 bass dB, 64 × UInt8 band.
     */
    @Synchronized
    fun drain(afterUs: Long, max: Int = 48): ByteArray? {
        if (head == 0L) return null
        val oldest = max(0L, head - RING)
        var first = head
        var i = head - 1
        while (i >= oldest && ringTime[(i % RING).toInt()] > afterUs) {
            first = i
            i--
        }
        val count = min(max.toLong(), head - first).toInt()
        if (count <= 0) return null
        val out = ByteBuffer.allocate(count * HOP_BYTES).order(ByteOrder.LITTLE_ENDIAN)
        for (n in 0 until count) {
            val slot = ((first + n) % RING).toInt()
            out.putLong(ringTime[slot])
            out.putFloat(ringBass[slot])
            out.put(ringBands[slot])
        }
        return out.array()
    }
}

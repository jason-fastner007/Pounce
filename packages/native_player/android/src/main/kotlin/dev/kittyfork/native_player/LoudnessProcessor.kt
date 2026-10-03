package dev.kittyfork.native_player

import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.BaseAudioProcessor
import androidx.media3.common.util.UnstableApi
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.pow
import kotlin.math.tan

/**
 * Loud/quiet mode for Android: measures loudness per ITU-R BS.1770 (K-weighting,
 * 400 ms blocks, gates) and moves the gain smoothly towards the target (LUFS) – with a
 * peak limiter at −1 dBFS so boosted quiet tracks don't clip.
 *
 * As in the browser: track quickly at the start of a track (first 6 s), calmly afterwards.
 */
@OptIn(UnstableApi::class)
class LoudnessProcessor : BaseAudioProcessor() {

    /** Target in LUFS, null = off (pass-through without computation). */
    @Volatile
    var target: Double? = null

    // Readings for the display.
    @Volatile var momentary = -70.0; private set
    @Volatile var integrated: Double? = null; private set
    @Volatile var gainDb = 0.0; private set
    @Volatile var limiterDb = 0.0; private set

    private var rate = 44_100
    private var ch = 2
    // K-weighting: two biquads per channel (high shelf + high-pass).
    private var k1 = DoubleArray(5)
    private var k2 = DoubleArray(5)
    private var z = Array(8) { DoubleArray(4) }

    private var blockSum = 0.0
    private var blockFrames = 0
    private var blockLen = 4410 // 100 ms
    private val last4 = DoubleArray(4)
    private var last4n = 0
    private val gated = ArrayList<Double>()
    private var gatedSum = 0.0
    private var sinceStart = 0.0
    private var gain = 1.0
    private var targetGain = 1.0
    private var env = 0.0

    override fun onConfigure(inputAudioFormat: AudioProcessor.AudioFormat): AudioProcessor.AudioFormat {
        if (inputAudioFormat.encoding != C.ENCODING_PCM_16BIT) return AudioProcessor.AudioFormat.NOT_SET
        rate = inputAudioFormat.sampleRate
        ch = inputAudioFormat.channelCount.coerceIn(1, 8)
        blockLen = rate / 10
        k1 = shelf(rate.toDouble())
        k2 = highpass(rate.toDouble())
        z = Array(ch) { DoubleArray(4) }
        return inputAudioFormat
    }

    /**
     * New track: restart the measurement and start neutral (0 dB). Previously the gain carried
     * over from this deck's track before last – up to +12 dB on someone else's intro, which clicked.
     */
    fun resetMeasurement() {
        synchronized(this) {
            gated.clear(); gatedSum = 0.0; last4n = 0; sinceStart = 0.0
            integrated = null
            gain = 1.0; targetGain = 1.0; gainDb = 0.0; env = 0.0
        }
    }

    override fun queueInput(inputBuffer: ByteBuffer) {
        val remaining = inputBuffer.remaining()
        if (remaining == 0) return
        val out = replaceOutputBuffer(remaining)
        val t = target
        if (t == null && gain == 1.0) {
            // Off: just pass through.
            out.put(inputBuffer)
            out.flip()
            return
        }
        val input = inputBuffer.order(ByteOrder.LITTLE_ENDIAN)
        val frames = remaining / (2 * ch)
        val release = exp(-1.0 / (0.12 * rate))
        // 1 ms attack instead of instant: a gain jump from sample to sample is audible (click).
        val attack = exp(-1.0 / (0.001 * rate))
        val ceiling = 0.891 // −1 dBFS
        synchronized(this) {
            for (f in 0 until frames) {
                var peak = 0.0
                val start = input.position()
                for (c in 0 until ch) {
                    val x = input.getShort(start + c * 2) / 32768.0
                    // K-weighted energy (channels summed, BS.1770).
                    val zc = z[c]
                    val y1 = k1[0] * x + zc[0]
                    zc[0] = k1[1] * x - k1[3] * y1 + zc[1]
                    zc[1] = k1[2] * x - k1[4] * y1
                    val y2 = k2[0] * y1 + zc[2]
                    zc[2] = k2[1] * y1 - k2[3] * y2 + zc[3]
                    zc[3] = k2[2] * y1 - k2[4] * y2
                    blockSum += y2 * y2
                    peak = max(peak, abs(x * gain))
                }
                // Limiter: 1 ms down, 120 ms back; whatever the soft attack lets through, softClip catches.
                env = if (peak > env) env * attack + peak * (1 - attack) else env * release + peak * (1 - release)
                val lim = if (env > ceiling) ceiling / env else 1.0
                limiterDb = 20 * log10(lim)
                for (c in 0 until ch) {
                    val x = input.getShort(start + c * 2) / 32768.0
                    val y = softClip(x * gain * lim)
                    out.putShort((y * 32767).toInt().toShort())
                }
                input.position(start + ch * 2)
                // Gain glides (0.4 s or 3 s time constant depending on the phase).
                val tau = if (sinceStart < 6) 0.4 else 3.0
                gain += (targetGain - gain) * (1 - exp(-1.0 / (tau * rate)))
                if (++blockFrames >= blockLen) block(t)
            }
        }
        out.flip()
    }

    /** 100 ms block done: momentary (400 ms), integrated (gated), target gain. */
    private fun block(t: Double?) {
        val ms = blockSum / blockFrames
        blockSum = 0.0; blockFrames = 0
        sinceStart += 0.1
        last4[last4n % 4] = ms
        last4n++
        val n = minOf(last4n, 4)
        var m = 0.0
        for (i in 0 until n) m += last4[i]
        m /= n
        val mLufs = lufs(m)
        momentary = mLufs
        if (mLufs > -70) {
            gated.add(m); gatedSum += m
            if (gated.size > 36_000) { gatedSum -= gated.removeAt(0) }
        }
        if (gated.isNotEmpty() && last4n % 5 == 0) {
            val rel = lufs(gatedSum / gated.size) - 10
            val thr = 10.0.pow((rel + 0.691) / 10)
            var s = 0.0; var c = 0
            for (e in gated) if (e >= thr) { s += e; c++ }
            if (c > 0) integrated = lufs(s / c)
        }
        val ref = integrated ?: if (mLufs > -70) mLufs else null
        if (t != null && ref != null) {
            // The first 3 s are often a quiet intro: at most ±6 dB there, otherwise the level jumps.
            gainDb = if (sinceStart < 3) (t - ref).coerceIn(-6.0, 6.0) else (t - ref).coerceIn(-18.0, 12.0)
            targetGain = 10.0.pow(gainDb / 20)
        } else if (t == null) {
            gainDb = 0.0
            targetGain = 1.0
        }
    }

    /** Soft clipping above 0.95 (instead of hard clipping). */
    private fun softClip(y: Double): Double {
        val a = abs(y)
        if (a <= 0.95) return y
        return Math.copySign(0.95 + 0.05 * kotlin.math.tanh((a - 0.95) / 0.05), y)
    }

    private fun lufs(ms: Double) = if (ms <= 0) -100.0 else -0.691 + 10 * log10(ms)

    override fun onFlush() {
        blockSum = 0.0; blockFrames = 0
        for (zc in z) zc.fill(0.0)
    }

    override fun onReset() {
        onFlush()
        resetMeasurement()
    }

    private fun shelf(fs: Double): DoubleArray {
        val f0 = 1681.974450955533; val g = 3.999843853973347; val q = 0.7071752369554196
        val k = tan(PI * f0 / fs)
        val vh = 10.0.pow(g / 20); val vb = vh.pow(0.4996667741545416)
        val a0 = 1 + k / q + k * k
        return doubleArrayOf(
            (vh + vb * k / q + k * k) / a0, 2 * (k * k - vh) / a0, (vh - vb * k / q + k * k) / a0,
            2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0,
        )
    }

    private fun highpass(fs: Double): DoubleArray {
        val f0 = 38.13547087602444; val q = 0.5003270373238773
        val k = tan(PI * f0 / fs)
        val a0 = 1 + k / q + k * k
        return doubleArrayOf(1 / a0, -2 / a0, 1 / a0, 2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0)
    }
}

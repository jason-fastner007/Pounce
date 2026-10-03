import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/debug_export.dart';
import '../../dj/beat_analyzer.dart';
import '../../player/audio_engine.dart';
import '../../player/player_controller.dart';
import '../../sc/models.dart';
import '../tokens.dart';

/// One analysis tick for the whole app: reads the spectrum once per frame
/// and distributes it to all displays (repaint without widget rebuild).
///
/// Sources: the platform's real spectrum (Android tap, Web Audio), otherwise the
/// SoundCloud waveform. If a reliable beat grid from the audio analysis is available,
/// the beat pulses come exactly from it instead of the live detection.
class SpectrumBus extends ChangeNotifier {
  SpectrumBus(this._player, TickerProvider vsync, this._waveform, {this.grid}) {
    _ticker = vsync.createTicker(_tick);
    _player.addListener(_sync);
    try {
      _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    } catch (_) {}
    _sync();
  }

  static const bands = SpectrumSource.bands;

  final PlayerController _player;
  final Future<List<double>> Function(Track) _waveform;

  /// Beat grid of the current track (from the deckengine analysis), if known.
  final BeatInfo? Function()? grid;
  late final Ticker _ticker;
  AppLifecycleListener? _lifecycle;
  bool _visible = true;

  final levels = Float32List(bands);
  final peaks = Float32List(bands);
  final _in = Float32List(bands);
  SpectrumSource? _listening;

  /// Bass energy 0..1 (for glowing/pulsing).
  double energy = 0;

  /// true = real FFT, false = derived from the waveform.
  bool live = false;

  // ---------- Beat-Erkennung ----------

  /// Energy per register (0..1, smoothed) and spectral centroid (0 low … 1 high).
  double bass = 0, mid = 0, high = 0, centroid = .3;

  /// Running time in seconds (for drifting colours).
  double time = 0;

  /// true = the tick is running (playback or decay).
  bool get ticking => _ticker.isActive;

  /// Throttled to ~30 Hz when the frame rate drops persistently (e.g. Firefox).
  bool lowPower = false;
  double _frameAvg = 1 / 60, _slowFor = 0, _sinceNotify = 0, _debugIn = 0;

  /// Pulse 0..1: jumps to 1 on every beat and decays.
  double pulse = 0;

  /// Counts beats (colour changes in the background).
  int beats = 0;

  /// Seconds since the last beat (for soft colour transitions).
  double sinceBeat = 10;

  /// Hue shift in degrees that travels with the bass kicks: every kick pushes the hue
  /// a bit further, every "one" of a bar noticeably (colour follows the bass).
  double hueShift = 0;
  double _hueTarget = 0;

  /// Slow displays (live LED, BPM) – change rarely, no rebuild per frame.
  final status = ValueNotifier<(bool live, double? bpm)>((false, null));

  final _intervals = <double>[];

  Duration _last = Duration.zero;
  List<double> _env = const [];
  int? _envTrack;
  int _lastGridBeat = -1;

  static final _debug = kIsWeb && Uri.base.queryParameters.containsKey('debug');

  void _sync() {
    final t = _player.current;
    if (t != null && t.id != _envTrack) {
      _envTrack = t.id;
      _env = const [];
      _lastGridBeat = -1;
      _waveform(t).then((w) {
        if (_envTrack == t.id) _env = w;
      });
    }
    if (_player.playing && _visible && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
    _syncListening();
  }

  /// Platform analysis only while something is actually being drawn.
  void _syncListening() {
    final want = _ticker.isActive && _visible ? _player.spectrum : null;
    if (want == _listening) return;
    _listening?.listen(false);
    _listening = want;
    want?.listen(true);
  }

  void _onLifecycle(AppLifecycleState s) {
    _visible = s == AppLifecycleState.resumed || s == AppLifecycleState.inactive;
    if (!_visible && _ticker.isActive) _ticker.stop();
    _sync();
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final playing = _player.playing;
    final src = _player.spectrum;
    live = playing && src != null && src.readBands(_in);

    final t = elapsed.inMicroseconds / 1e6;
    var bass = 0.0;
    var rawBass = 0.0; // unsmoothed, for beat detection
    var maxLevel = 0.0;
    for (var b = 0; b < bands; b++) {
      double target;
      if (live) {
        target = _in[b];
        if (b < 6) rawBass += target / 6;
      } else if (playing && _env.isNotEmpty) {
        // Envelope at the playback position, spectrally shaped.
        final d = _player.duration.inMilliseconds;
        final p = d == 0 ? 0.0 : _player.livePosition.inMilliseconds / d;
        final e = _env[(p * (_env.length - 1)).clamp(0, _env.length - 1).round()];
        if (b == 0) rawBass = e;
        final tilt = 1 - b / bands * .55;
        final wobble = .55 + .45 * math.sin(t * (2.1 + b * .31) + b * 1.7);
        target = (e * tilt * wobble).clamp(0, 1);
      } else {
        target = 0;
      }
      // Fast attack, soft release (frame-rate independent).
      final k = target > levels[b] ? 1 - math.pow(.02, dt * 6) : 1 - math.pow(.02, dt * 1.6);
      levels[b] += (target - levels[b]) * k;
      peaks[b] = math.max(levels[b], peaks[b] - dt * .45);
      if (b < 8) bass += levels[b];
      maxLevel = math.max(maxLevel, peaks[b]);
    }
    energy += (bass / 8 - energy) * (1 - math.pow(.05, dt * 4));
    // Real bass channel (unsmoothed), otherwise the waveform envelope.
    final kick = live ? (src?.bass() ?? rawBass) : rawBass;
    _detectBeat(playing ? kick : 0, dt);
    _gridBeat(playing);
    // Colour glides after the kicks (~120 ms) – visible, but without flicker.
    hueShift += (_hueTarget - hueShift) * (1 - math.exp(-dt / .12));
    _bands(dt);
    time += dt;
    if (_debug) {
      _debugIn -= dt;
      if (_debugIn <= 0) {
        _debugIn = .25;
        debugExport({
          'kick': double.parse(kick.toStringAsFixed(3)),
          'pulse': double.parse(pulse.toStringAsFixed(3)),
          'beats': beats,
          'bpm': status.value.$2,
          'live': live,
          'playing': playing,
          'lowPower': lowPower,
          'fps': (1 / _frameAvg).round(),
        });
      }
    }

    // Adaptive quality: persistently < ~45 FPS -> 30 Hz tick.
    _frameAvg += (dt - _frameAvg) * .05;
    _slowFor = _frameAvg > 1 / 45 ? _slowFor + dt : 0;
    if (!lowPower && _slowFor > 3) lowPower = true;
    _sinceNotify += dt;
    if (lowPower && _sinceNotify < 1 / 31) return;
    _sinceNotify = 0;
    notifyListeners();
    if (!playing && maxLevel < .005) {
      _ticker.stop();
      _syncListening();
    }
  }

  /// Energy per register + centroid, smoothly tracked.
  void _bands(double dt) {
    double avg(int a, int b) {
      var s = 0.0;
      for (var i = a; i < b; i++) {
        s += levels[i];
      }
      return s / (b - a);
    }

    var w = 0.0, sum = 0.0;
    for (var i = 0; i < bands; i++) {
      w += levels[i] * i;
      sum += levels[i];
    }
    final k = 1 - math.pow(.02, dt * 3);
    bass += (avg(0, 9) - bass) * k;
    mid += (avg(9, 39) - mid) * k;
    high += (avg(39, bands) - high) * k;
    if (sum > .5) centroid += ((w / sum) / bands - centroid) * (1 - math.pow(.1, dt));
  }

  /// Bass envelope (fast) for the background – follows every kick.
  double kick = 0;
  double _slow = 0, _dev = .05;

  bool get _hasGrid => grid?.call()?.hasGrid ?? false;

  /// Beats from the analysed grid: exactly on the beat, even with quiet kicks.
  void _gridBeat(bool playing) {
    final g = grid?.call();
    if (!playing || g == null || !g.hasGrid) return;
    final elapsed = _player.livePosition.inMicroseconds / 1000 - g.downbeatOffsetMs;
    if (elapsed < 0) return;
    final n = (elapsed / g.periodMs).floor();
    if (n == _lastGridBeat) return;
    final first = _lastGridBeat < 0;
    _lastGridBeat = n;
    if (first) return;
    _onBeat(strength: (kick * 1.4 + .55).clamp(.6, 1.0), downbeat: n % 4 == 0, phrase: n % 16 == 0);
  }

  void _onBeat({required double strength, bool downbeat = false, bool phrase = false}) {
    pulse = strength;
    beats++;
    sinceBeat = 0;
    // Colour follows the bass: small step per kick, bigger one on the downbeat, jump at the phrase.
    _hueTarget += phrase ? 72 : (downbeat ? 28 : 9);
  }

  /// Onset detection: fast minus slow bass envelope above an adaptive
  /// threshold, 250 ms lockout. BPM = median of the intervals (70–180).
  void _detectBeat(double x, double dt) {
    // Fast up, quick down (≈60 ms) – stays punchy.
    kick = x > kick ? x : kick + (x - kick) * (1 - math.exp(-dt / .06));
    _slow += (x - _slow) * (1 - math.exp(-dt / .45));
    final flux = x - _slow;
    _dev += (flux.abs() - _dev) * (1 - math.exp(-dt / 1.5));
    sinceBeat += dt;
    pulse *= math.exp(-dt / .12);
    // Absolute rise OR relative jump (+25 %) – also catches bass carpets/808s.
    final rise = flux > math.max(.05, _dev * 1.6) || (x > _slow * 1.25 && flux > .03);
    if (rise && x > .18 && sinceBeat > .25) {
      if (sinceBeat < 2) {
        _intervals.add(sinceBeat);
        if (_intervals.length > 16) _intervals.removeAt(0);
      }
      // With a grid the beats come from there; live detection only counts for the tempo.
      if (!_hasGrid) {
        _onBeat(strength: (flux * 4 + .55).clamp(.6, 1.0));
      } else {
        sinceBeat = 0;
      }
    }

    double? bpm = grid?.call()?.bpm;
    if (bpm == null && _intervals.length >= 6) {
      final sorted = [..._intervals]..sort();
      var v = 60 / sorted[sorted.length ~/ 2];
      while (v < 70) {
        v *= 2;
      }
      while (v > 180) {
        v /= 2;
      }
      bpm = v.roundToDouble();
    }
    if (status.value.$1 != live || status.value.$2 != bpm) status.value = (live, bpm);
  }

  @override
  void dispose() {
    _listening?.listen(false);
    _lifecycle?.dispose();
    status.dispose();
    _player.removeListener(_sync);
    _ticker.dispose();
    super.dispose();
  }
}

/// Provides the bus in the tree.
class SpectrumScope extends InheritedWidget {
  const SpectrumScope({super.key, required this.bus, required super.child});
  final SpectrumBus bus;

  static SpectrumBus of(BuildContext c) => c.getInheritedWidgetOfExactType<SpectrumScope>()!.bus;

  @override
  bool updateShouldNotify(SpectrumScope old) => old.bus != bus;
}

/// Bar spectrum with peak caps.
class SpectrumBars extends StatelessWidget {
  const SpectrumBars({super.key, this.height = 48, this.bars = 48, this.mirror = false, this.opacity = 1});

  final double height;
  final int bars;
  final bool mirror;
  final double opacity;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarsPainter(SpectrumScope.of(context), Theme.of(context).colorScheme.primary, bars, mirror, opacity),
      ),
    ),
  );
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.bus, this.accent, this.bars, this.mirror, this.opacity) : super(repaint: bus);

  final SpectrumBus bus;
  final Color accent;
  final int bars;
  final bool mirror;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.width / bars * .28;
    final w = size.width / bars - gap;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          accent.withValues(alpha: .25 * opacity),
          accent.withValues(alpha: opacity),
        ],
      ).createShader(Offset.zero & size);
    final cap = Paint()..color = Studio.text.withValues(alpha: .55 * opacity);
    final base = mirror ? size.height / 2 : size.height;
    final maxH = mirror ? size.height / 2 : size.height;
    for (var i = 0; i < bars; i++) {
      final b = (i * SpectrumBus.bands / bars).floor();
      final v = bus.levels[b];
      final h = math.max(1.0, v * maxH);
      final x = i * (w + gap) + gap / 2;
      canvas.drawRRect(RRect.fromLTRBR(x, base - h, x + w, mirror ? base + h : base, const Radius.circular(1)), fill);
      if (!mirror) {
        final py = base - bus.peaks[b] * maxH - 2;
        canvas.drawRect(Rect.fromLTWH(x, py, w, 1.5), cap);
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter o) => o.accent != accent || o.bars != bars || o.opacity != opacity;
}

/// Soft glow that breathes with the bass energy (KittyTune style).
class EnergyGlow extends StatelessWidget {
  const EnergyGlow({super.key, required this.child, this.radius = 8});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _GlowPainter(SpectrumScope.of(context), Theme.of(context).colorScheme.primary, radius),
    child: child,
  );
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.bus, this.accent, this.radius) : super(repaint: bus);
  final SpectrumBus bus;
  final Color accent;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    // Radial gradient instead of Gaussian blur: same effect, a fraction of the cost.
    final e = (bus.kick * .6 + bus.pulse * .6).clamp(0.0, 1.0);
    final c = size.center(Offset.zero);
    final r = size.longestSide * (.72 + e * .18);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: .20 + e * .30),
            accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter o) => o.accent != accent;
}

/// Background as a frequency colour field:
/// bass = large warm area (pulses with the beat), mids and highs have their own hues.
/// Hue follows the pitch (centroid) and rotates slowly; areas drift.
/// Only radial gradients with additive blending – no blur.
class BeatBackdrop extends StatelessWidget {
  const BeatBackdrop({super.key, this.intensity = 1, this.enabled = true});

  final double intensity;
  final bool enabled;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.infinite,
      painter: _BeatPainter(
        SpectrumScope.of(context),
        Theme.of(context).colorScheme.primary,
        enabled && !MediaQuery.disableAnimationsOf(context) ? intensity : 0,
      ),
    ),
  );
}

class _BeatPainter extends CustomPainter {
  _BeatPainter(this.bus, this.accent, this.intensity) : super(repaint: intensity > 0 ? bus : null);

  final SpectrumBus bus;
  final Color accent;
  final double intensity;

  Color _hue(double base, double shift, {double sat = .95, double light = .52}) =>
      HSLColor.fromAHSL(1, (base + shift) % 360, sat, light).toColor();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Studio.bg0);
    if (intensity <= 0) return;

    final t = bus.time;
    final p = bus.pulse;
    final low = bus.lowPower ? .75 : 1.0;
    // Base hue = accent, shifted by the kicks (colour follows the bass), the pitch
    // and a slow drift.
    final base = HSLColor.fromColor(accent).hue + bus.hueShift + (bus.centroid - .3) * 90 + t * 1.5;
    final s = size.longestSide;

    void field(Offset c, double r, Color color, double alpha) {
      final a = (alpha * intensity * low).clamp(0.0, .45);
      if (a < .005) return;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: a),
              color.withValues(alpha: a * .35),
              color.withValues(alpha: 0),
            ],
            stops: const [0, .45, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    // Bass: bottom, large, follows every kick (fast envelope + beat pulse) – brighter on the kick.
    final bassColor = _hue(base, 0, light: .48 + bus.kick * .14);
    field(
      Offset(size.width * (.30 + .10 * math.sin(t * .23)), size.height * (.95 + .05 * math.cos(t * .19))),
      s * (.40 + bus.kick * .22 + p * .10),
      bassColor,
      .03 + bus.kick * .26 + p * .18,
    );
    // Beat flash across the whole area.
    if (p > .02) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = bassColor.withValues(alpha: (p * .05 * intensity * low).clamp(0.0, .06)),
      );
    }
    // Mids: right, own hue.
    field(
      Offset(size.width * (.86 + .08 * math.cos(t * .17)), size.height * (.40 + .18 * math.sin(t * .13))),
      s * (.30 + bus.mid * .30),
      _hue(base, 120, light: .55),
      .03 + bus.mid * .24,
    );
    // Highs: top, cool and smaller, flickers along.
    field(
      Offset(size.width * (.22 + .14 * math.sin(t * .31)), size.height * (.08 + .06 * math.cos(t * .27))),
      s * (.20 + bus.high * .26),
      _hue(base, 220, sat: .85, light: .62),
      .02 + bus.high * .30,
    );
  }

  @override
  bool shouldRepaint(_BeatPainter o) => o.intensity != intensity || o.accent != accent;
}

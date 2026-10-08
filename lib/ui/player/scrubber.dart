import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../player/player_controller.dart';
import '../../sc/models.dart';
import '../../sc/soundcloud.dart';
import '../tokens.dart';
import '../widgets/common.dart';

/// Waveform of a track (0..1), loaded once and shared.
Future<List<double>> waveformOf(SoundCloud sc, Track t) => sc.waveform(t);

enum ScrubStyle { waveform, squiggly }

/// Precision scrubber: waveform (loudness curve) or an animated wave.
/// The position flows via [PlayerController.position] straight into the painter.
class Scrubber extends StatefulWidget {
  const Scrubber({
    super.key,
    required this.track,
    this.style = ScrubStyle.waveform,
    this.height = 28,
    this.showTimes = true,
  });

  final Track track;
  final ScrubStyle style;
  final double height;
  final bool showTimes;

  @override
  State<Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends State<Scrubber> with TickerProviderStateMixin {
  late final PlayerController _player = context.deps.player;
  late final _grow = AnimationController(vsync: this, duration: Motion.long);
  // Wave amplitude: 1 = playing, 0 = flat (paused/dragging).
  late final _amp = AnimationController(vsync: this, duration: Motion.medium);
  late final Ticker _phaseTicker = createTicker(_onPhase);
  final _phase = ValueNotifier(0.0);
  final _hover = ValueNotifier<double?>(null);
  List<double> _samples = const [];
  double? _drag;

  @override
  void initState() {
    super.initState();
    _player.addListener(_syncPlaying);
    _load();
    _syncPlaying();
  }

  @override
  void didUpdateWidget(Scrubber old) {
    super.didUpdateWidget(old);
    if (old.track.id != widget.track.id) _load();
    _syncPlaying();
  }

  @override
  void dispose() {
    _player.removeListener(_syncPlaying);
    _phaseTicker.dispose();
    _grow.dispose();
    _amp.dispose();
    _phase.dispose();
    _hover.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.track.id;
    _grow.value = 0;
    final s = await waveformOf(context.deps.sc, widget.track);
    if (!mounted || widget.track.id != id) return;
    setState(() => _samples = s);
    _grow.animateTo(1, curve: Motion.decelerate);
  }

  void _syncPlaying() {
    if (widget.style != ScrubStyle.squiggly) return;
    final wavy = _player.playing && _drag == null;
    _amp.animateTo(wavy ? 1 : 0, curve: wavy ? Motion.spring : Curves.easeOut);
    if (wavy && !_phaseTicker.isActive) _phaseTicker.start();
  }

  Duration _lastTick = Duration.zero;
  void _onPhase(Duration e) {
    final dt = _lastTick == Duration.zero ? 0.016 : (e - _lastTick).inMicroseconds / 1e6;
    _lastTick = e;
    _phase.value = (_phase.value + dt * 1.6) % 1; // waves per second
    if (_amp.value == 0 && !_player.playing) {
      _phaseTicker.stop();
      _lastTick = Duration.zero;
    }
  }

  double _fraction(Offset local, double width) {
    final x = (local.dx / width).clamp(0.0, 1.0);
    return Directionality.of(context) == TextDirection.rtl ? 1 - x : x;
  }

  String _precise(Duration d) => '${fmtDuration(d)}.${(d.inMilliseconds % 1000).toString().padLeft(3, '0')}';

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final bar = LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        void start(Offset p) {
          setState(() => _drag = _fraction(p, w));
          _syncPlaying();
        }

        void end() {
          final f = _drag;
          setState(() => _drag = null);
          if (f != null) _player.seek(_player.duration * f);
          _syncPlaying();
        }

        return Semantics(
          slider: true,
          label: context.l10n.nowPlaying,
          value: fmtDuration(_drag != null ? _player.duration * _drag! : _player.position.value),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onHover: (e) => _hover.value = _fraction(e.localPosition, w),
            onExit: (_) => _hover.value = null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) => start(d.localPosition),
              onHorizontalDragUpdate: (d) {
                setState(() => _drag = _fraction(d.localPosition, w));
                _hover.value = _drag;
              },
              onHorizontalDragEnd: (_) => end(),
              onTapDown: (d) => start(d.localPosition),
              onTapUp: (_) => end(),
              child: SizedBox(
                height: widget.height,
                width: w,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _ScrubPainter(
                            style: widget.style,
                            samples: _samples,
                            position: _player.position,
                            duration: () => _player.duration,
                            buffered: () => _player.buffered,
                            drag: _drag,
                            hover: _hover,
                            grow: _grow,
                            amp: _amp,
                            phase: _phase,
                            rtl: rtl,
                            accent: accent,
                          ),
                        ),
                      ),
                    ),
                    // Time tooltip at the mouse position (ms-accurate).
                    ValueListenableBuilder<double?>(
                      valueListenable: _hover,
                      builder: (_, f, _) {
                        if (f == null) return const SizedBox.shrink();
                        final x = (rtl ? 1 - f : f) * w;
                        return PositionedDirectional(
                          start: 0,
                          bottom: widget.height + 6,
                          child: Transform.translate(
                            offset: Offset(x.clamp(36, math.max(36, w - 36)) - 36, 0),
                            child: IgnorePointer(
                              child: Container(
                                width: 72,
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                decoration: BoxDecoration(
                                  color: Studio.surfaceTop,
                                  borderRadius: Studio.br4,
                                  border: Border.all(color: Studio.lineStrong),
                                ),
                                child: Text(
                                  _precise(_player.duration * f),
                                  textAlign: TextAlign.center,
                                  style: Studio.monoStyle(size: 10, color: Studio.text),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!widget.showTimes) return bar;
    // Hour-long mixes need room for "1:01:56"; FittedBox catches anything longer without wrapping.
    final timeWidth = _player.duration >= const Duration(hours: 1) ? 60.0 : 44.0;
    return Row(
      children: [
        SizedBox(
          width: timeWidth,
          child: ValueListenableBuilder<Duration>(
            valueListenable: _player.position,
            builder: (_, p, _) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                fmtDuration(_drag != null ? _player.duration * _drag! : p),
                maxLines: 1,
                style: Studio.monoStyle(color: _drag != null ? accent : Studio.text2),
              ),
            ),
          ),
        ),
        const SizedBox(width: Studio.s3),
        Expanded(child: bar),
        const SizedBox(width: Studio.s3),
        SizedBox(
          width: timeWidth,
          child: ListenableBuilder(
            listenable: _player,
            builder: (_, _) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(fmtDuration(_player.duration), maxLines: 1, style: Studio.monoStyle(color: Studio.text3)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScrubPainter extends CustomPainter {
  _ScrubPainter({
    required this.style,
    required this.samples,
    required this.position,
    required this.duration,
    required this.buffered,
    required this.drag,
    required this.hover,
    required this.grow,
    required this.amp,
    required this.phase,
    required this.rtl,
    required this.accent,
  }) : super(repaint: Listenable.merge([position, hover, grow, amp, phase]));

  final ScrubStyle style;
  final List<double> samples;
  final ValueNotifier<Duration> position;
  final Duration Function() duration;
  final Duration Function() buffered;
  final double? drag;
  final ValueNotifier<double?> hover;
  final Animation<double> grow, amp;
  final ValueNotifier<double> phase;
  final bool rtl;
  final Color accent;

  double get _played {
    if (drag != null) return drag!;
    final d = duration().inMilliseconds;
    return d == 0 ? 0 : (position.value.inMilliseconds / d).clamp(0.0, 1.0);
  }

  double get _buffered {
    final d = duration().inMilliseconds;
    return d == 0 ? 0 : (buffered().inMilliseconds / d).clamp(0.0, 1.0);
  }

  double _x(double f, double w) => (rtl ? 1 - f : f) * w;

  @override
  void paint(Canvas canvas, Size size) {
    style == ScrubStyle.squiggly ? _squiggly(canvas, size) : _wave(canvas, size);
    // Hover-Linie
    final h = hover.value;
    if (h != null) {
      final x = _x(h, size.width);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()..color = Studio.text.withValues(alpha: .5));
    }
  }

  void _wave(Canvas canvas, Size size) {
    final played = _played, buf = _buffered;
    final paint = Paint();
    if (samples.isEmpty) {
      final y = size.height / 2;
      final r = RRect.fromLTRBR(0, y - 1, size.width, y + 1, Studio.r2);
      canvas.drawRRect(r, paint..color = Studio.lineStrong);
      final px = _x(played, size.width);
      canvas.drawRect(Rect.fromLTRB(rtl ? px : 0, y - 1, rtl ? size.width : px, y + 1), paint..color = accent);
      return;
    }
    const bar = 2.0, gap = 1.0;
    final n = math.max(1, (size.width / (bar + gap)).floor());
    final per = samples.length / n;
    final mid = size.height / 2;
    for (var i = 0; i < n; i++) {
      var peak = 0.0;
      final from = (i * per).floor(), to = math.min(samples.length, ((i + 1) * per).ceil());
      for (var j = from; j < to; j++) {
        peak = math.max(peak, samples[j]);
      }
      final local = ((grow.value * 1.4) - i / n).clamp(0.0, 1.0);
      final h = math.max(2.0, peak * size.height * Curves.easeOut.transform(local));
      final f = (i + .5) / n;
      paint.color = f <= played
          ? accent
          : (f <= buf ? Studio.text.withValues(alpha: .28) : Studio.text.withValues(alpha: .12));
      final x = rtl ? size.width - (i + 1) * (bar + gap) : i * (bar + gap);
      canvas.drawRect(Rect.fromLTRB(x, mid - h / 2, x + bar, mid + h / 2), paint);
    }
  }

  void _squiggly(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final px = _x(_played, size.width);
    final a = amp.value * math.min(4.5, size.height / 4);
    const wave = 36.0;
    final track = Paint()
      ..color = Studio.text.withValues(alpha: .16)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final bx = _x(_buffered, size.width);
    // Remainder (straight), buffered part slightly brighter
    canvas.drawLine(Offset(rtl ? 0 : px, mid), Offset(rtl ? px : size.width, mid), track);
    canvas.drawLine(Offset(px, mid), Offset(bx, mid), track..color = Studio.text.withValues(alpha: .28));
    // Played: a wave that moves over time
    final path = Path();
    final startX = rtl ? size.width : 0.0;
    final dir = rtl ? -1 : 1;
    final len = (px - startX).abs();
    for (var d = 0.0; d <= len; d += 1.5) {
      final x = startX + d * dir;
      // The wave fades out towards the end so the transition is soft.
      final fade = math.min(1.0, (len - d) / 18);
      final y = mid + math.sin((d / wave + phase.value) * 2 * math.pi) * a * fade;
      d == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    // Thumb: vertical bar
    canvas.drawRRect(RRect.fromLTRBR(px - 2, mid - 9, px + 2, mid + 9, Studio.r2), Paint()..color = Studio.text);
  }

  @override
  bool shouldRepaint(_ScrubPainter o) =>
      o.samples != samples || o.drag != drag || o.accent != accent || o.style != style || o.rtl != rtl;
}

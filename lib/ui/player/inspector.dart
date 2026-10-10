import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../player/audio_engine.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import '../widgets/studio.dart';
import 'controls.dart';
import 'lyrics_view.dart';
import 'queue_view.dart';
import 'spectrum.dart';

enum InspectorTab { queue, lyrics, signal }

/// Right column: queue, lyrics, signal telemetry.
class Inspector extends StatefulWidget {
  const Inspector({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  State<Inspector> createState() => _InspectorState();
}

class _InspectorState extends State<Inspector> {
  InspectorTab _tab = InspectorTab.queue;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final player = context.deps.player;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xE60B0D12),
        border: BorderDirectional(start: BorderSide(color: Studio.line)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Studio.s3, Studio.s3, Studio.s2, Studio.s2),
            child: Row(
              children: [
                Expanded(
                  child: Segments<InspectorTab>(
                    height: 30,
                    values: InspectorTab.values,
                    selected: _tab,
                    label: (t) => switch (t) {
                      InspectorTab.queue => l.queue.toUpperCase(),
                      InspectorTab.lyrics => l.lyrics.toUpperCase(),
                      InspectorTab.signal => l.signal.toUpperCase(),
                    },
                    onChanged: (t) => setState(() => _tab = t),
                  ),
                ),
                StudioIcon(
                  Icons.close_rounded,
                  onTap: widget.onClose,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: AnimatedSwitcher(
              duration: Motion.medium,
              switchInCurve: Motion.decelerate,
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(.04, 0), end: Offset.zero).animate(a),
                  child: c,
                ),
              ),
              child: ListenableBuilder(
                key: ValueKey(_tab),
                listenable: player,
                builder: (context, _) {
                  final t = player.current;
                  return switch (_tab) {
                    InspectorTab.queue => const QueueView(),
                    InspectorTab.lyrics =>
                      t == null ? const SizedBox.shrink() : LyricsView(key: ValueKey(t.id), track: t, compact: true),
                    InspectorTab.signal => const _SignalPanel(),
                  };
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Telemetry: spectrum, loudness meter, key figures.
class _SignalPanel extends StatelessWidget {
  const _SignalPanel();

  @override
  Widget build(BuildContext context) {
    final d = context.deps;
    final l = context.l10n;
    final bus = SpectrumScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(Studio.s3),
      children: [
        Container(
          height: 132,
          padding: const EdgeInsetsDirectional.fromSTEB(Studio.s2, Studio.s3, Studio.s2, Studio.s2),
          decoration: Studio.panel(color: Studio.bg0),
          child: const SpectrumBars(height: 116, bars: 40),
        ),
        const SizedBox(height: Studio.s2),
        ValueListenableBuilder<(bool, double?)>(
          valueListenable: bus.status,
          builder: (_, st, _) => Row(
            children: [
              Led(on: st.$1, color: Studio.signal),
              const SizedBox(width: Studio.s2),
              Mono(st.$1 ? l.sigLive : l.sigEnvelope, size: 10, color: Studio.text3),
              const Spacer(),
              // Beat LED blinks in time
              _BeatLed(bus: bus),
              const SizedBox(width: Studio.s2),
              Mono(st.$2 == null ? '— BPM' : '${st.$2!.toInt()} BPM', size: 10, color: Studio.text2, weight: 600),
            ],
          ),
        ),
        const SizedBox(height: Studio.s4),
        const Overline('LUFS'),
        ValueListenableBuilder<Loudness>(
          valueListenable: d.player.loudness,
          builder: (_, loud, _) => _LufsMeter(loud: loud, target: d.settings.loudMode.lufs),
        ),
        const SizedBox(height: Studio.s3),
        const Center(child: LoudnessControl(width: 200, showReadout: false)),
        const SizedBox(height: Studio.s4),
        ValueListenableBuilder<Loudness>(
          valueListenable: d.player.loudness,
          builder: (context, loud, _) {
            String db(double? v, {bool sign = false}) =>
                v == null ? '—' : '${sign && v >= 0 ? '+' : ''}${v.toStringAsFixed(1)} dB';
            String lufs(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)} LUFS';
            final mode = d.settings.loudMode;
            return Container(
              decoration: Studio.panel(),
              child: Column(
                children: [
                  _Row(l.sigSource, d.player.stream?.label ?? '—'),
                  _Row(
                    l.loudTitle,
                    '${LoudnessControl.name(context, mode)}${mode.lufs == null ? '' : ' · ${mode.lufs!.toInt()} LUFS'}',
                  ),
                  _Row(l.sigLoudness, lufs(loud.integrated)),
                  _Row(l.sigMomentary, lufs(loud.momentary)),
                  _Row(l.sigGain, db(loud.gainDb, sign: true)),
                  _Row(l.sigLimiter, loud.limiterDb.abs() < .05 ? '0.0 dB' : db(loud.limiterDb)),
                  _Row(
                    l.sigOutput,
                    loud.clipping ? l.sigClip : l.sigClean,
                    led: Led(on: true, color: loud.clipping ? Studio.clip : Studio.signal),
                    last: true,
                  ),
                ],
              ),
            );
          },
        ),
        if (!d.player.supportsLoudness)
          Padding(
            padding: const EdgeInsets.only(top: Studio.s3),
            child: Text(l.loudUnsupported, style: Studio.bodyDim),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.led, this.last = false});
  final String label, value;
  final Widget? led;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: Studio.s3),
    decoration: BoxDecoration(
      border: last ? null : const Border(bottom: BorderSide(color: Studio.line)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(label.toUpperCase(), style: Studio.overline, overflow: TextOverflow.ellipsis),
        ),
        if (led != null) ...[led!, const SizedBox(width: Studio.s2)],
        Mono(value, color: Studio.text, weight: 550),
      ],
    ),
  );
}

/// Horizontal loudness meter −40 … 0 LUFS with a target mark.
class _LufsMeter extends StatelessWidget {
  const _LufsMeter({required this.loud, required this.target});
  final Loudness loud;
  final double? target;

  static double _f(double lufs) => ((lufs + 40) / 40).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final m = loud.momentary;
    return Column(
      children: [
        SizedBox(
          height: 14,
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              children: [
                Container(
                  decoration: BoxDecoration(color: Studio.bg0, borderRadius: Studio.br4, border: Studio.border),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: m == null ? 0 : _f(m)),
                  duration: const Duration(milliseconds: 120),
                  builder: (_, v, _) => Container(
                    width: c.maxWidth * v,
                    decoration: BoxDecoration(
                      borderRadius: Studio.br4,
                      gradient: LinearGradient(colors: [accent.withValues(alpha: .35), accent]),
                    ),
                  ),
                ),
                if (target != null)
                  PositionedDirectional(
                    start: c.maxWidth * _f(target!) - 1,
                    top: -2,
                    bottom: -2,
                    child: Container(width: 2, color: Studio.text),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Mono('-40', size: 9, color: Studio.text3),
            Mono('-30', size: 9, color: Studio.text3),
            Mono('-20', size: 9, color: Studio.text3),
            Mono('-10', size: 9, color: Studio.text3),
            Mono('0', size: 9, color: Studio.text3),
          ],
        ),
      ],
    );
  }
}

/// Small LED that lights up with every detected beat (repaint only).
class _BeatLed extends StatelessWidget {
  const _BeatLed({required this.bus});
  final SpectrumBus bus;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(size: const Size.square(8), painter: _BeatLedPainter(bus, Theme.of(context).colorScheme.primary)),
  );
}

class _BeatLedPainter extends CustomPainter {
  _BeatLedPainter(this.bus, this.color) : super(repaint: bus);
  final SpectrumBus bus;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = bus.pulse;
    canvas.drawCircle(c, size.width / 2, Paint()..color = Color.lerp(Studio.lineStrong, color, p)!);
    if (p > .05) canvas.drawCircle(c, size.width * (1 + p), Paint()..color = color.withValues(alpha: .25 * p));
  }

  @override
  bool shouldRepaint(_BeatLedPainter o) => o.color != color;
}

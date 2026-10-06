import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../player/audio_engine.dart';
import '../../player/player_controller.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import '../widgets/studio.dart';

/// Play/pause with shape morphing: circle (paused) ↔ rounded square (playing).
class MorphPlayButton extends StatefulWidget {
  const MorphPlayButton({super.key, required this.player, this.size = 40});

  final PlayerController player;
  final double size;

  @override
  State<MorphPlayButton> createState() => _MorphPlayButtonState();
}

class _MorphPlayButtonState extends State<MorphPlayButton> with SingleTickerProviderStateMixin {
  late final _icon = AnimationController(vsync: this, duration: Motion.medium, value: widget.player.playing ? 1 : 0);
  bool _down = false;

  @override
  void didUpdateWidget(MorphPlayButton old) {
    super.didUpdateWidget(old);
    widget.player.playing ? _icon.forward() : _icon.reverse();
  }

  @override
  void dispose() {
    _icon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    final s = widget.size;
    final accent = Theme.of(context).colorScheme.primary;
    final on = Theme.of(context).colorScheme.onPrimary;
    final label = p.playing ? context.l10n.pause : context.l10n.play;
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _down = true),
            onTapCancel: () => setState(() => _down = false),
            onTapUp: (_) => setState(() => _down = false),
            onTap: p.toggle,
            child: AnimatedScale(
              scale: _down ? .88 : 1,
              duration: _down ? Motion.micro : Motion.medium,
              curve: _down ? Curves.easeOut : Motion.spring,
              child: AnimatedContainer(
                duration: Motion.long,
                curve: Motion.spring,
                width: s,
                height: s,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(s / 2),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: p.playing ? .40 : .25),
                      blurRadius: s * .45,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedIcon(icon: AnimatedIcons.play_pause, progress: _icon, size: s * .5, color: on),
                    if (p.loading)
                      SizedBox.square(
                        dimension: s * .8,
                        child: CircularProgressIndicator(strokeWidth: 2, color: on),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Transport block: shuffle · previous · play · next · repeat.
class Transport extends StatelessWidget {
  const Transport({super.key, this.playSize = 40, this.iconSize = 32});

  final double playSize, iconSize;

  @override
  Widget build(BuildContext context) {
    final p = context.deps.player;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            toggled: p.shuffle,
            label: l.shuffle,
            child: StudioIcon(
              Icons.shuffle_rounded,
              tooltip: l.shuffle,
              active: p.shuffle,
              onTap: p.toggleShuffle,
              size: iconSize,
            ),
          ),
          const SizedBox(width: Studio.s1),
          StudioIcon(Icons.skip_previous_rounded, tooltip: l.previous, onTap: p.previous, size: iconSize + 4),
          const SizedBox(width: Studio.s2),
          MorphPlayButton(player: p, size: playSize),
          const SizedBox(width: Studio.s2),
          StudioIcon(Icons.skip_next_rounded, tooltip: l.next, onTap: p.next, size: iconSize + 4),
          const SizedBox(width: Studio.s1),
          Semantics(
            button: true,
            toggled: p.repeat != LoopMode.off,
            label: switch (p.repeat) {
              LoopMode.off => l.repeatOff,
              LoopMode.all => l.repeatAll,
              LoopMode.one => l.repeatOne,
            },
            child: StudioIcon(
              p.repeat == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              tooltip: switch (p.repeat) {
                LoopMode.off => l.repeatOff,
                LoopMode.all => l.repeatAll,
                LoopMode.one => l.repeatOne,
              },
              active: p.repeat != LoopMode.off,
              onTap: p.cycleRepeat,
              size: iconSize,
            ),
          ),
        ],
      ),
    );
  }
}

/// Logarithmic volume fader (−60 … 0 dB) with a clip LED.
class VolumeAttenuator extends StatefulWidget {
  const VolumeAttenuator({super.key, this.width = 104});
  final double width;

  @override
  State<VolumeAttenuator> createState() => _VolumeAttenuatorState();
}

class _VolumeAttenuatorState extends State<VolumeAttenuator> {
  static const _range = 60.0; // dB
  double? _beforeMute;
  bool _show = false;

  // Fader travel 0..1 <-> linear level (dB-linear, 0 = mute).
  static double _toGain(double p) => p <= 0 ? 0 : math.pow(10, -_range * (1 - p) / 20).toDouble();
  static double _toPos(double g) => g <= 0 ? 0 : (1 + 20 * math.log(g) / math.ln10 / _range).clamp(0, 1);
  static String _db(double g) => g <= 0 ? '−∞ dB' : '${(20 * math.log(g) / math.ln10).toStringAsFixed(1)} dB';

  @override
  Widget build(BuildContext context) {
    final player = context.deps.player;
    final accent = Theme.of(context).colorScheme.primary;
    return ValueListenableBuilder<double>(
      valueListenable: player.volume,
      builder: (context, gain, _) {
        final pos = _toPos(gain);
        void setPos(double p) => player.setVolume(_toGain(p.clamp(0, 1)));
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StudioIcon(
              gain <= 0 ? Icons.volume_off_rounded : (pos < .5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
              tooltip: context.l10n.mute,
              active: gain <= 0,
              onTap: () {
                if (gain > 0) {
                  _beforeMute = gain;
                  player.setVolume(0);
                } else {
                  player.setVolume(_beforeMute ?? 1);
                }
              },
            ),
            Semantics(
              slider: true,
              label: context.l10n.volume,
              value: _db(gain),
              child: Tooltip(
                message: '${context.l10n.volume} · ${_db(gain)}',
                child: Listener(
                  // Mouse wheel = fine steps (1 dB)
                  onPointerSignal: (e) {
                    if (e is PointerScrollEvent) setPos(pos + (e.scrollDelta.dy < 0 ? 1 : -1) / _range);
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _show = true),
                    onExit: (_) => setState(() => _show = false),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => setPos(d.localPosition.dx / widget.width),
                      onHorizontalDragUpdate: (d) => setPos(d.localPosition.dx / widget.width),
                      child: SizedBox(
                        width: widget.width,
                        height: 24,
                        child: CustomPaint(painter: _FaderPainter(pos, accent, _show)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Studio.s2),
            ValueListenableBuilder<Loudness>(
              valueListenable: player.loudness,
              builder: (_, l, _) => Tooltip(
                message: l.clipping ? context.l10n.sigClip : context.l10n.sigClean,
                child: Led(on: l.clipping, color: Studio.clip),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FaderPainter extends CustomPainter {
  _FaderPainter(this.pos, this.accent, this.hover);
  final double pos;
  final Color accent;
  final bool hover;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final h = hover ? 4.0 : 2.0;
    canvas.drawRRect(
      RRect.fromLTRBR(0, y - h / 2, size.width, y + h / 2, Studio.r2),
      Paint()..color = Studio.lineStrong,
    );
    final x = pos * size.width;
    canvas.drawRRect(RRect.fromLTRBR(0, y - h / 2, x, y + h / 2, Studio.r2), Paint()..color = accent);
    // dB scale: ticks at −48/−36/−24/−12 dB
    final tick = Paint()..color = Studio.text3;
    for (var i = 1; i < 5; i++) {
      final tx = size.width * i / 5;
      canvas.drawLine(Offset(tx, y + 5), Offset(tx, y + 7), tick);
    }
    canvas.drawRRect(RRect.fromLTRBR(x - 2, y - 7, x + 2, y + 7, Studio.r2), Paint()..color = Studio.text);
  }

  @override
  bool shouldRepaint(_FaderPainter o) => o.pos != pos || o.accent != accent || o.hover != hover;
}

/// Loud/quiet: segmented switch + live reading.
class LoudnessControl extends StatelessWidget {
  const LoudnessControl({super.key, this.showReadout = true, this.width = 132, this.expanded = false});

  final bool showReadout;
  final double width;
  final bool expanded;

  static String name(BuildContext c, LoudMode m) => switch (m) {
    LoudMode.off => c.l10n.loudOff,
    LoudMode.quiet => c.l10n.loudQuiet,
    LoudMode.normal => c.l10n.loudNormal,
    LoudMode.loud => c.l10n.loudLoud,
  };

  @override
  Widget build(BuildContext context) {
    final d = context.deps;
    final supported = d.player.supportsLoudness;
    final segments = Segments<LoudMode>(
      height: 32,
      values: LoudMode.values,
      selected: d.settings.loudMode,
      label: (m) => switch (m) {
        LoudMode.off => 'OFF',
        LoudMode.quiet => 'Q',
        LoudMode.normal => 'N',
        LoudMode.loud => 'L',
      },
      tooltip: (m) => supported
          ? '${context.l10n.loudTitle}: ${name(context, m)}${m.lufs == null ? '' : ' · ${m.lufs!.toInt()} LUFS'}'
          : context.l10n.loudUnsupported,
      onChanged: supported ? (m) => d.settings.loudMode = m : null,
    );

    return ListenableBuilder(
      listenable: d.settings,
      builder: (context, _) => Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (expanded)
            Expanded(child: segments)
          else
            SizedBox(width: width, child: segments),
          if (showReadout) ...[
            const SizedBox(width: Studio.s2),
            SizedBox(
              width: 58,
              child: ValueListenableBuilder<Loudness>(
                valueListenable: d.player.loudness,
                builder: (_, l, _) {
                  final v = l.integrated ?? l.momentary;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Mono(v == null ? '—' : v.toStringAsFixed(1), size: 11, color: Studio.text, weight: 600),
                      Mono(
                        l.gainDb == null ? 'LUFS' : '${l.gainDb! >= 0 ? '+' : ''}${l.gainDb!.toStringAsFixed(1)} dB',
                        size: 9,
                        color: Studio.text3,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Current track, compact: cover · title/artist.
class NowPlayingLabel extends StatelessWidget {
  const NowPlayingLabel({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.deps.player;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) {
        final t = p.current;
        return AnimatedSwitcher(
          duration: Motion.medium,
          switchInCurve: Motion.decelerate,
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, .25), end: Offset.zero).animate(a),
              child: c,
            ),
          ),
          layoutBuilder: (cur, prev) => Stack(alignment: AlignmentDirectional.centerStart, children: [...prev, ?cur]),
          child: t == null
              ? const SizedBox(key: ValueKey('none'))
              : Tactile(
                  key: ValueKey(t.id),
                  onTap: onTap,
                  radius: Studio.br4,
                  padding: const EdgeInsets.all(Studio.s1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Artwork(t.art('t120x120'), size: 48, radius: 4),
                      const SizedBox(width: Studio.s3),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Studio.body.copyWith(fontVariations: const [FontVariation.weight(600)]),
                            ),
                            const SizedBox(height: 2),
                            Text(t.user.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: Studio.bodyDim),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

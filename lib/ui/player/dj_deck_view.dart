import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../dj/harmonic_mixer.dart';
import '../../dj/beat_analyzer.dart';
import '../../dj/dj_flow_controller.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../player/player_controller.dart';
import '../../sc/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/studio.dart';
import 'spectrum.dart';

/// Dedicated DJ deck and audio energy view for the player.
class DjDeckView extends StatelessWidget {
  const DjDeckView({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dj = context.deps.dj;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return ListenableBuilder(
      listenable: dj,
      builder: (context, _) {
        final state = dj.state;
        final rustAvailable = dj.analyzer.hasEngine;
        final info = dj.currentBeatInfo;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. DJ mode activation header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: Studio.panel(radius: Studio.br16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: state.isActive ? primary.withValues(alpha: .18) : Studio.surfaceHi,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: state.isActive ? primary.withValues(alpha: .4) : Studio.line),
                      ),
                      child: Icon(Icons.album_rounded, color: state.isActive ? primary : Studio.text3, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.djFlowAutomix,
                                style: TextStyle(
                                  fontFamily: Studio.sans,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: state.isActive ? Studio.text : Studio.text2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: rustAvailable
                                      ? const Color(0xFF00E676).withValues(alpha: .15)
                                      : Studio.surfaceHi,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: rustAvailable ? const Color(0xFF00E676).withValues(alpha: .35) : Studio.line,
                                  ),
                                ),
                                child: Text(
                                  dj.analyzer.engineLabel,
                                  style: TextStyle(
                                    fontFamily: Studio.mono,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: rustAvailable ? const Color(0xFF00E676) : Studio.text3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.isActive ? l10n.djFlowActiveDesc : l10n.djTapToActivate,
                            style: const TextStyle(fontFamily: Studio.sans, fontSize: 12, color: Studio.text2),
                          ),
                        ],
                      ),
                    ),
                    Switch(value: state.isActive, activeThumbColor: primary, onChanged: (_) => dj.toggleDjFlow()),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 2. Live beat & bar display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: Studio.panel(radius: Studio.br16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // BPM & Key
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${state.currentBpm > 0 ? state.currentBpm.toStringAsFixed(1) : "---"} ',
                                  style: const TextStyle(
                                    fontFamily: Studio.mono,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: Studio.text,
                                  ),
                                ),
                                Text(
                                  l10n.djBpm,
                                  style: TextStyle(
                                    fontFamily: Studio.sans,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Studio.text3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.currentKey != null
                                  ? '${state.currentKey!.code} · ${state.currentKey!.standardName}'
                                        '${info != null && info.keyConfidence < .15 ? ' (${l10n.djKeyUncertain})' : ''}'
                                  : state.analyzing
                                  ? l10n.djAnalyzing
                                  : l10n.djNoKey,
                              style: TextStyle(
                                fontFamily: Studio.sans,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
                            ),
                          ],
                        ),

                        // Bar & beat display (changes once per beat)
                        ValueListenableBuilder<BeatClock>(
                          valueListenable: dj.beat,
                          builder: (context, b, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                l10n.djBar(b.bar),
                                style: const TextStyle(
                                  fontFamily: Studio.mono,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Studio.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.djPhraseBeat(b.beatInPhrase),
                                style: const TextStyle(fontFamily: Studio.sans, fontSize: 12, color: Studio.text3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 4-beat grid visualiser with frame-accurate 120 Hz phase animation
                    BeatPhaseGridVisualizer(
                      player: context.deps.player,
                      bpm: state.currentBpm > 0 ? state.currentBpm : 125.0,
                      firstBeatOffsetMs: info?.downbeatOffsetMs ?? info?.firstBeatOffsetMs ?? 0,
                      primaryColor: primary,
                    ),
                    if (info != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _Stat(l10n.statGrid, '${(info.confidence * 100).round()} %'),
                          _Stat('Downbeat', '${(info.downbeatConfidence * 100).round()} %'),
                          _Stat(l10n.statKey, '${(info.keyConfidence * 100).round()} %'),
                          if (info.lufs != null) _Stat(l10n.statLoudness, '${info.lufs!.toStringAsFixed(1)} LUFS'),
                          _Stat(l10n.statEnergy, '${info.energyLevel}/10'),
                          _Stat(l10n.statSource, switch (info.source) {
                            BeatSource.pcm => l10n.srcAudio,
                            BeatSource.waveform => l10n.srcWaveform,
                            BeatSource.hint => l10n.srcTitle,
                          }),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Audio energies (3-band bass / mid / high & RMS)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: Studio.panel(radius: Studio.br16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.djEnergiesLive,
                          style: TextStyle(
                            fontFamily: Studio.sans,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Studio.text2,
                          ),
                        ),
                        if (state.isActive)
                          ValueListenableBuilder<BeatClock>(
                            valueListenable: dj.beat,
                            builder: (context, b, _) => Text(
                              b.beatsUntilTransition == null || b.beatsUntilTransition == 0
                                  ? ''
                                  : l10n.djTransitionIn(b.beatsUntilTransition!),
                              style: TextStyle(
                                fontFamily: Studio.mono,
                                fontSize: 12,
                                color: primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _LiveBands(),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 4. Energy mode selector (build up, hold, cool down)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: Studio.panel(radius: Studio.br16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.djEnergyMode,
                      style: TextStyle(
                        fontFamily: Studio.sans,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Studio.text2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final mode in EnergyMode.values)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: _ModeButton(
                                label: energyModeLabel(l10n, mode),
                                sub: switch (mode) {
                                  EnergyMode.buildUp => '+1..2 Key',
                                  EnergyMode.hold => l10n.djHarmonic,
                                  EnergyMode.windDown => '-1 Key',
                                },
                                selected: state.energyMode == mode,
                                onTap: () => dj.setEnergyMode(mode),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 5. Next harmonic track & "mix now"
              if (state.nextTrackMatch != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: Studio.panel(radius: Studio.br16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.djNextBest,
                            style: TextStyle(
                              fontFamily: Studio.sans,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Studio.text2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.djMatch(state.nextTrackMatch!.score.toStringAsFixed(0)),
                              style: TextStyle(
                                fontFamily: Studio.mono,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Artwork(state.nextTrackMatch!.track.art('t67x67'), size: 44, radius: 10),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.nextTrackMatch!.track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: Studio.sans,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Studio.text,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${state.nextTrackMatch!.track.user.username} · ${state.nextTrackMatch!.transitionStyle.title}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontFamily: Studio.sans, fontSize: 12, color: Studio.text3),
                                ),
                                const SizedBox(height: 4),
                                Mono(djPlanText(l10n, dj), size: 10.5, color: primary),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => dj.triggerMixNow(),
                            icon: const Icon(Icons.flash_on_rounded, size: 16),
                            label: Text(l10n.djMixNow, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

/// Live bass/mid/high levels from the spectrum tick (repaint without rebuild).
class _LiveBands extends StatelessWidget {
  const _LiveBands();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: SizedBox(
      height: 96,
      width: double.infinity,
      child: CustomPaint(
        painter: _BandsPainter(SpectrumScope.of(context), [
          context.l10n.bandBass,
          context.l10n.bandMid,
          context.l10n.bandHigh,
        ]),
      ),
    ),
  );
}

class _BandsPainter extends CustomPainter {
  _BandsPainter(this.bus, this.names) : super(repaint: bus);
  final SpectrumBus bus;
  final List<String> names;

  static const _colors = [Color(0xFFFF5252), Color(0xFF00E5FF), Color(0xFFE040FB)];

  // Only lay out labels on a new width or language, not per frame (text layout is expensive).
  late final _labels = [
    for (final label in names)
      TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontFamily: Studio.mono,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Studio.text3,
          ),
        ),
        textDirection: TextDirection.ltr,
      ),
  ];
  double? _labelWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [bus.bass, bus.mid, bus.high];
    const rowH = 32.0;
    if (_labelWidth != size.width) {
      for (final tp in _labels) {
        tp.layout(maxWidth: size.width);
      }
      _labelWidth = size.width;
    }
    for (var i = 0; i < 3; i++) {
      final color = _colors[i];
      final v = (values[i] * 1.6).clamp(0.0, 1.0);
      final y = i * rowH;
      _labels[i].paint(canvas, Offset(0, y));
      final bar = RRect.fromLTRBR(0, y + 18, size.width, y + 24, const Radius.circular(3));
      canvas.drawRRect(bar, Paint()..color = Studio.lineStrong);
      canvas.drawRRect(
        RRect.fromLTRBR(0, y + 18, size.width * v, y + 24, const Radius.circular(3)),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_BandsPainter o) => o.bus != bus || o.names.join() != names.join();
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$label ',
          style: const TextStyle(color: Studio.text3),
        ),
        TextSpan(
          text: value,
          style: const TextStyle(color: Studio.text, fontWeight: FontWeight.w600),
        ),
      ],
    ),
    style: const TextStyle(fontFamily: Studio.mono, fontSize: 11),
  );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.sub, required this.selected, required this.onTap});

  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Tactile(
      onTap: onTap,
      radius: Studio.br10,
      active: selected,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: Studio.sans,
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? primary : Studio.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontFamily: Studio.mono,
              fontSize: 10,
              color: selected ? primary.withValues(alpha: .8) : Studio.text3,
            ),
          ),
        ],
      ),
    );
  }
}

/// 4-beat grid with a pulse on every beat. Paints at the rate of the spectrum bus
/// (one frame tick for the whole app) with the extrapolated position – no ticker of its own.
class BeatPhaseGridVisualizer extends StatelessWidget {
  const BeatPhaseGridVisualizer({
    super.key,
    required this.player,
    required this.bpm,
    required this.firstBeatOffsetMs,
    required this.primaryColor,
  });

  final PlayerController player;
  final double bpm;

  /// Time of a downbeat (beat 1).
  final int firstBeatOffsetMs;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: SizedBox(
      height: 8,
      width: double.infinity,
      child: CustomPaint(
        painter: _GridPainter(SpectrumScope.of(context), player, bpm, firstBeatOffsetMs, primaryColor),
      ),
    ),
  );
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.bus, this.player, this.bpm, this.anchorMs, this.color) : super(repaint: bus);
  final SpectrumBus bus;
  final PlayerController player;
  final double bpm;
  final int anchorMs;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final periodMs = 60000.0 / (bpm > 0 ? bpm : 125.0);
    final elapsed = player.livePosition.inMicroseconds / 1000 - anchorMs;
    var current = 0;
    var decay = 0.0;
    if (elapsed >= 0 && player.playing) {
      final total = (elapsed / periodMs).floor();
      current = total % 4;
      final phase = (elapsed % periodMs) / periodMs;
      decay = math.pow((1.0 - phase / 0.35).clamp(0.0, 1.0), 2.5).toDouble();
    }
    const gap = 6.0;
    final w = (size.width - gap * 3) / 4;
    for (var i = 0; i < 4; i++) {
      _BeatBarPainter(
        isCurrent: i == current,
        isDownbeat: i == 0,
        decay: i == current ? decay : 0.0,
        primaryColor: color,
      ).paint(
        canvas
          ..save()
          ..translate(i * (w + gap), 0),
        Size(w, size.height),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GridPainter o) => o.bpm != bpm || o.anchorMs != anchorMs || o.color != color;
}

class _BeatBarPainter extends CustomPainter {
  _BeatBarPainter({required this.isCurrent, required this.isDownbeat, required this.decay, required this.primaryColor});

  final bool isCurrent;
  final bool isDownbeat;
  final double decay;
  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4));

    // Grundfarbe (Inaktiv)
    final bgPaint = Paint()..color = Studio.lineStrong;
    canvas.drawRRect(rrect, bgPaint);

    if (isCurrent && decay > 0.01) {
      final activeColor = isDownbeat
          ? primaryColor.withValues(alpha: 0.2 + 0.8 * decay)
          : Studio.text.withValues(alpha: 0.2 + 0.8 * decay);

      final activePaint = Paint()..color = activeColor;

      // Glow effect for the downbeat (beat 1)
      if (isDownbeat && decay > 0.15) {
        final glowPaint = Paint()
          ..color = primaryColor.withValues(alpha: 0.5 * decay)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawRRect(rrect, glowPaint);
      }

      canvas.drawRRect(rrect, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BeatBarPainter old) =>
      old.decay != decay || old.isCurrent != isCurrent || old.primaryColor != primaryColor;
}

/// "Entry 0:24 · drop 0:32 · 8 s fade" for the next transition.
/// Localised label of an [EnergyMode].
String energyModeLabel(AppLocalizations l, EnergyMode m) => switch (m) {
  EnergyMode.buildUp => l.djModeBuildUp,
  EnergyMode.hold => l.djModeHold,
  EnergyMode.windDown => l.djModeWindDown,
};

String djPlanText(AppLocalizations l, DjFlowController dj) {
  final plan = dj.nextPlan;
  if (plan == null) return '';
  String t(int ms) => '${ms ~/ 60000}:${(ms ~/ 1000 % 60).toString().padLeft(2, '0')}';
  final info = dj.nextInfo;
  final drop = info?.dropMs;
  final dropText = drop != null
      ? l.planDrop(t(drop))
      : info?.eventsScanned == true
      ? l.planNoDrop
      : l.planSearching;
  return l.planText(t(plan.startMs), dropText, (plan.fadeMs / 1000).toStringAsFixed(0));
}

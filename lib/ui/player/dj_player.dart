import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../dj/dj_flow_controller.dart';
import '../../sc/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/studio.dart';
import 'controls.dart';
import 'dj_deck_view.dart' show djPlanText;
import 'scrubber.dart';
import 'spectrum.dart';
import 'status_line.dart';

/// Player in DJ mode: only the essentials – song, beat, next transition, ♥, pause, skip.
/// Skip crossfades cleanly and is learned (see TasteModel).
class DjPlayer extends StatelessWidget {
  const DjPlayer({super.key, required this.track, required this.onCollapse, required this.art});

  final Track track;
  final VoidCallback onCollapse;

  /// Cover including room for the flight animation from the mini bar (from the player sheet).
  final Widget art;

  @override
  Widget build(BuildContext context) {
    final d = context.deps;
    final accent = Theme.of(context).colorScheme.primary;
    final pad = MediaQuery.paddingOf(context);
    return ListenableBuilder(
      listenable: Listenable.merge([d.dj, d.taste]),
      builder: (context, _) {
        final dj = d.dj;
        final next = dj.state.nextTrackMatch;
        return Column(
          children: [
            // Header: collapse · "DJ" · stop
            Padding(
              padding: EdgeInsets.only(top: pad.top),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: onCollapse,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                    ),
                    const Spacer(),
                    Led(on: true, color: accent),
                    const SizedBox(width: 8),
                    const Mono('DJ FLOW', size: 12, color: Studio.text, weight: 700),
                    const Spacer(),
                    TextButton(onPressed: dj.toggleDjFlow, child: Text(context.l10n.djStop)),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Expanded(child: art),
                    const SizedBox(height: 12),
                    const SpectrumBars(height: 36, bars: 48, opacity: .6),
                    const SizedBox(height: 12),
                    // Title, artist, ♥
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: Studio.sans, fontSize: 20, fontWeight: FontWeight.w800, color: Studio.text),
                              ),
                              Text(track.user.username, maxLines: 1, style: const TextStyle(fontFamily: Studio.sans, fontSize: 14, color: Studio.text2)),
                              const SizedBox(height: 6),
                              StatusLine(track: track),
                            ],
                          ),
                        ),
                        ListenableBuilder(
                          listenable: d.library,
                          builder: (context, _) {
                            final liked = d.library.isLiked(track);
                            return IconButton(
                              iconSize: 28,
                              onPressed: () => d.library.toggleLike(track),
                              icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: liked ? accent : null),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    IgnorePointer(child: Scrubber(track: track, style: ScrubStyle.squiggly, height: 24)),
                    const SizedBox(height: 8),
                    // Next transition
                    if (next != null) _NextCard(next.track, djPlanText(context.l10n, dj), beatsLeft: dj.beat),
                    const SizedBox(height: 12),
                    // Pause · skip (with transition)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MorphPlayButton(player: d.player, size: 72),
                        const SizedBox(width: 28),
                        IconButton.filledTonal(
                          iconSize: 34,
                          tooltip: context.l10n.djSkip,
                          onPressed: () => dj.triggerMixNow(skip: true),
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // What was learned most recently
                    SizedBox(
                      height: 26,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final r in d.taste.recent)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 6),
                              child: Chip(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                label: Text(r, style: Studio.monoStyle(size: 10.5, color: Studio.text2)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: pad.bottom + 16),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard(this.track, this.plan, {required this.beatsLeft});

  final Track track;
  final String plan;
  final ValueListenable<BeatClock> beatsLeft;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: Studio.panel(radius: Studio.br14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: Studio.br8,
            child: Image.network(track.art('t67x67') ?? '', width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox(width: 40, height: 40)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: Studio.sans, fontSize: 13, fontWeight: FontWeight.w600, color: Studio.text)),
                Mono(plan, size: 10.5, color: accent),
              ],
            ),
          ),
          ValueListenableBuilder<BeatClock>(
            valueListenable: beatsLeft,
            builder: (_, b, _) => Mono(b.beatsUntilTransition == null ? '' : '${b.beatsUntilTransition}', size: 18, color: Studio.text, weight: 700),
          ),
        ],
      ),
    );
  }
}

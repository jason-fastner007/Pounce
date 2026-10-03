import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import '../widgets/studio.dart';
import 'controls.dart';
import 'scrubber.dart';

/// Permanently docked master deck (80 px, no layout jump).
/// Only track/state changes rebuild; the position flows straight into the painters.
class MasterDeck extends StatelessWidget {
  const MasterDeck({
    super.key,
    required this.onExpand,
    required this.onToggleInspector,
    required this.inspectorOpen,
    this.compact = false,
  });

  final VoidCallback onExpand;
  final VoidCallback onToggleInspector;
  final bool inspectorOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final d = context.deps;
    final l = context.l10n;
    // Fixed side widths: the middle stays exactly centred (no layout jump).
    final left = compact ? 210.0 : 390.0;
    final right = left;
    return Container(
      height: Studio.deck,
      decoration: const BoxDecoration(
        color: Color(0xE60B0D12),
        border: Border(top: BorderSide(color: Studio.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Studio.s3),
      child: Row(
        children: [
          // Left: current track + like
          SizedBox(
            width: left,
            child: Row(
              children: [
                Flexible(child: NowPlayingLabel(onTap: onExpand)),
                ListenableBuilder(
                  listenable: Listenable.merge([d.player, d.library]),
                  builder: (_, _) {
                    final t = d.player.current;
                    if (t == null) return const SizedBox.shrink();
                    final liked = d.library.isLiked(t);
                    return StudioIcon(
                      liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      tooltip: liked ? l.unlike : l.like,
                      active: liked,
                      onTap: () => d.library.toggleLike(t),
                    );
                  },
                ),
              ],
            ),
          ),
          // Middle: transport + scrubber
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Transport(playSize: 36, iconSize: 30),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListenableBuilder(
                    listenable: d.player,
                    builder: (_, _) {
                      final t = d.player.current;
                      return t == null
                          ? const SizedBox(height: 20)
                          : Scrubber(key: ValueKey(t.id), track: t, height: 20);
                    },
                  ),
                ),
              ],
            ),
          ),
          // Right: loud/quiet, volume, views
          SizedBox(
            width: right,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!compact) ...[const LoudnessControl(width: 116), const SizedBox(width: Studio.s2)],
                VolumeAttenuator(width: compact ? 56 : 88),
                const SizedBox(width: Studio.s1),
                StudioIcon(
                  Icons.view_sidebar_outlined,
                  tooltip: l.inspector,
                  active: inspectorOpen,
                  onTap: onToggleInspector,
                ),
                StudioIcon(Icons.open_in_full_rounded, tooltip: l.expandPlayer, onTap: onExpand),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

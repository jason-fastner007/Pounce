import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../tokens.dart';
import '../widgets/studio.dart';
import '../widgets/track_tile.dart';

/// Queue: drag to reorder, swipe to remove.
class QueueView extends StatelessWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.deps.player;
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final q = player.queue;
        return ReorderableListView.builder(
          padding: const EdgeInsets.only(top: Studio.s2, bottom: 120),
          buildDefaultDragHandles: false,
          itemCount: q.length,
          onReorderItem: player.move,
          proxyDecorator: (child, _, _) => Material(color: Studio.surfaceHi, borderRadius: Studio.br4, child: child),
          itemBuilder: (context, i) {
            final tr = q[i];
            final current = i == player.index;
            final row = Opacity(
              key: ValueKey('q$i-${tr.id}'),
              // Already played: dimmed
              opacity: i < player.index ? .5 : 1,
              child: TrackTile(
                track: tr,
                index: i + 1,
                onTap: () => player.jumpTo(i),
                trailing: current
                    ? const SizedBox(width: 32)
                    : ReorderableDragStartListener(
                        index: i,
                        child: const MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: SizedBox(width: 32, height: 32, child: Icon(Icons.drag_indicator_rounded, size: 18)),
                        ),
                      ),
              ),
            );
            if (current) return row;
            return Dismissible(
              key: ValueKey('d$i-${tr.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: AlignmentDirectional.centerEnd,
                padding: const EdgeInsetsDirectional.only(end: Studio.s5),
                child: const Mono('REMOVE', color: Studio.clip, weight: 650),
              ),
              onDismissed: (_) => player.removeAt(i),
              child: row,
            );
          },
        );
      },
    );
  }
}

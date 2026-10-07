import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../library/library.dart';
import '../../sc/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/track_tile.dart';

enum _Kind { remote, local, likes, history }

/// One page for all track lists: SoundCloud playlist, own playlist, likes, history.
class PlaylistPage extends StatefulWidget {
  const PlaylistPage.remote(ScPlaylist this.remote, {super.key}) : _kind = _Kind.remote, local = null;
  const PlaylistPage.local(LocalPlaylist this.local, {super.key}) : _kind = _Kind.local, remote = null;
  const PlaylistPage.likes({super.key}) : _kind = _Kind.likes, remote = null, local = null;
  const PlaylistPage.history({super.key}) : _kind = _Kind.history, remote = null, local = null;

  final _Kind _kind;
  final ScPlaylist? remote;
  final LocalPlaylist? local;

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  @override
  Widget build(BuildContext context) {
    if (widget.remote != null) {
      return Scaffold(
        body: AsyncView<ScPlaylist>(
          load: () => context.deps.sc.playlist(widget.remote!.id),
          loading: _body(context, widget.remote!.title, widget.remote!.art(), widget.remote!.user.username, null),
          builder: (c, p) => _body(c, p.title, p.art(), p.user.username, p.tracks),
        ),
      );
    }
    final lib = context.deps.library;
    return Scaffold(
      body: ListenableBuilder(
        listenable: lib,
        builder: (context, _) {
          final l = context.l10n;
          return switch (widget._kind) {
            _Kind.likes => _body(
              context,
              l.likedTracks,
              null,
              null,
              lib.likes,
              icon: Icons.favorite_rounded,
              empty: l.emptyLikes,
            ),
            _Kind.history => _body(
              context,
              l.history,
              null,
              null,
              lib.history,
              icon: Icons.history_rounded,
              empty: l.emptyHistory,
              actions: [
                if (lib.history.isNotEmpty)
                  IconButton(
                    tooltip: l.clearHistory,
                    icon: const Icon(Icons.delete_sweep_rounded),
                    onPressed: lib.clearHistory,
                  ),
              ],
            ),
            _ => _body(
              context,
              widget.local!.name,
              widget.local!.tracks.firstOrNull?.art(),
              null,
              widget.local!.tracks,
              icon: Icons.queue_music_rounded,
              empty: l.emptyPlaylist,
              local: widget.local,
              actions: [_localMenu(context, widget.local!)],
            ),
          };
        },
      ),
    );
  }

  Widget _localMenu(BuildContext context, LocalPlaylist p) {
    final l = context.l10n;
    final lib = context.deps.library;
    return PopupMenuButton<int>(
      onSelected: (v) async {
        if (v == 0) {
          final name = await askText(context, l.rename, l.rename, initial: p.name);
          if (name != null) lib.renamePlaylist(p, name);
        } else {
          final ok = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(l.deletePlaylistConfirm(p.name)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
                FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.delete)),
              ],
            ),
          );
          if (ok == true && context.mounted) {
            lib.deletePlaylist(p);
            Navigator.pop(context);
          }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 0, child: Text(l.rename)),
        PopupMenuItem(value: 1, child: Text(l.delete)),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    String title,
    String? art,
    String? subtitle,
    List<Track>? tracks, {
    IconData icon = Icons.album_rounded,
    String? empty,
    List<Widget> actions = const [],
    LocalPlaylist? local,
  }) {
    final t = Theme.of(context);
    final player = context.deps.player;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final artSize = wide ? 220.0 : 180.0;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Flex(
        direction: wide ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: wide ? CrossAxisAlignment.end : CrossAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: t.colorScheme.shadow.withValues(alpha: .30),
                  blurRadius: 36,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: art == null
                ? Container(
                    width: artSize,
                    height: artSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(colors: [t.colorScheme.primary, t.colorScheme.tertiary]),
                    ),
                    child: Icon(icon, size: artSize * .4, color: t.colorScheme.onPrimary),
                  )
                : Artwork(art, size: artSize, radius: 16),
          ),
          const SizedBox(width: 24, height: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: t.textTheme.headlineMedium,
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) Text(subtitle, style: t.textTheme.titleMedium),
                if (tracks != null) Text(context.l10n.tracksCount(tracks.length), style: t.textTheme.bodyMedium),
                const SizedBox(height: 16),
                if (tracks != null && tracks.isNotEmpty)
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => player.playQueue(tracks),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(context.l10n.play),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          final s = List.of(tracks)..shuffle();
                          player.playQueue(s);
                        },
                        icon: const Icon(Icons.shuffle_rounded),
                        label: Text(context.l10n.shuffle),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    Widget list;
    if (tracks == null) {
      list = SliverList.builder(
        itemCount: 8,
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Skeleton(width: 52, height: 52, radius: 3),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Skeleton(width: 180), SizedBox(height: 8), Skeleton(width: 110, height: 10)],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (tracks.isEmpty) {
      list = SliverFillRemaining(
        hasScrollBody: false,
        child: MessageView(icon: icon, text: empty ?? context.l10n.noResults),
      );
    } else if (local != null) {
      list = SliverReorderableList(
        itemCount: tracks.length,
        onReorderItem: (a, b) => context.deps.library.reorder(local, a, b),
        itemBuilder: (c, i) => ReorderableDelayedDragStartListener(
          key: ValueKey(tracks[i].id),
          index: i,
          child: TrackTile(track: tracks[i], playlist: local, onTap: () => player.playQueue(tracks, i)),
        ),
      );
    } else {
      list = SliverList.builder(
        itemCount: tracks.length,
        itemBuilder: (c, i) => StaggeredIn(
          index: i,
          child: TrackTile(track: tracks[i], onTap: () => player.playQueue(tracks, i)),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(pinned: true, actions: actions, title: _FadeTitle(title)),
        SliverToBoxAdapter(child: header),
        list,
        const SliverToBoxAdapter(child: SizedBox(height: 160)),
      ],
    );
  }
}

/// Only fade in the title in the app bar once the header has scrolled away.
class _FadeTitle extends StatefulWidget {
  const _FadeTitle(this.text);
  final String text;

  @override
  State<_FadeTitle> createState() => _FadeTitleState();
}

class _FadeTitleState extends State<_FadeTitle> {
  ScrollPosition? _pos;
  bool _show = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pos?.removeListener(_update);
    _pos = Scrollable.maybeOf(context)?.position?..addListener(_update);
  }

  void _update() {
    final s = (_pos?.pixels ?? 0) > 200;
    if (s != _show) setState(() => _show = s);
  }

  @override
  void dispose() {
    _pos?.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: _show ? 1 : 0,
    duration: Motion.short,
    child: AnimatedSlide(
      offset: _show ? Offset.zero : const Offset(0, .3),
      duration: Motion.medium,
      curve: Motion.decelerate,
      child: Text(widget.text, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}

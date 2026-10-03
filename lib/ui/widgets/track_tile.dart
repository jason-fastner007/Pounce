import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../core/platform.dart';
import '../../library/library.dart';
import '../../sc/models.dart';
import '../nav.dart';
import '../pages/artist_page.dart';
import '../theme.dart';
import 'common.dart';
import 'studio.dart';

/// Compact 48 px track row with fixed columns:
/// index · cover · title/artist · [hover actions] · status · duration.
class TrackTile extends StatelessWidget {
  const TrackTile({super.key, required this.track, required this.onTap, this.index, this.trailing, this.playlist});

  final Track track;
  final VoidCallback onTap;

  /// 1-based position; null = no index column.
  final int? index;
  final Widget? trailing;

  /// Set when the track is in one of the user's playlists (-> "Remove").
  final LocalPlaylist? playlist;

  @override
  Widget build(BuildContext context) {
    final d = context.deps;
    final l = context.l10n;
    final accent = Theme.of(context).colorScheme.primary;
    // Touch devices have no hover -> menu button only.
    final touch = !(Platform.isDesktop || Platform.isWeb);

    // Only rebuild on a track change (not on every play/pause/buffering).
    return ValueListenableBuilder<Track?>(
      valueListenable: d.player.currentTrack,
      builder: (context, current, _) {
        final active = current == track;
        return Hover(
          cursor: SystemMouseCursors.click,
          builder: (context, hover) => WarmOnTouch(
            track: track,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Only check on tap: DRM detection may finish after the build.
              onTap: () => track.playable
                  ? onTap()
                  : (ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(l.protectedHint)))),
              onLongPress: () {
                d.player.cool(track);
                showTrackActions(context, track, playlist: playlist);
              },
              onSecondaryTap: () => showTrackActions(context, track, playlist: playlist),
              child: AnimatedContainer(
                duration: Motion.short,
                height: Studio.row,
                margin: const EdgeInsets.symmetric(horizontal: Studio.s2, vertical: 1),
                padding: const EdgeInsetsDirectional.only(start: Studio.s2, end: Studio.s1),
                decoration: BoxDecoration(
                  borderRadius: Studio.br10,
                  color: active
                      ? accent.withValues(alpha: .12)
                      : (hover ? Colors.white.withValues(alpha: .04) : Colors.transparent),
                ),
                child: Opacity(
                  opacity: track.playable ? 1 : .45,
                  child: Row(
                    children: [
                      // Index, or equaliser for the playing track
                      if (index != null)
                        SizedBox(
                          width: 28,
                          child: AnimatedSwitcher(
                            duration: Motion.short,
                            child: active
                                ? ListenableBuilder(
                                    key: const ValueKey('eq'),
                                    listenable: d.player,
                                    builder: (_, _) =>
                                        EqualizerBars(playing: d.player.playing, size: 14, color: accent),
                                  )
                                : hover && track.playable
                                ? Icon(Icons.play_arrow_rounded, key: const ValueKey('p'), size: 20, color: Studio.text)
                                : Text(
                                    '$index',
                                    key: const ValueKey('i'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: Studio.sans,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Studio.text3,
                                    ),
                                  ),
                          ),
                        ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Artwork(track.art('t67x67'), size: 40, radius: 8),
                          if (index == null && active)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: ListenableBuilder(
                                  listenable: d.player,
                                  builder: (_, _) => EqualizerBars(playing: d.player.playing, size: 14, color: accent),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: Studio.s3),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: Studio.sans,
                                fontSize: 13.5,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                                color: active ? accent : Studio.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.user.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: Studio.sans,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Studio.text2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hover actions (touch: menu only)
                      if (!touch)
                        AnimatedOpacity(
                          opacity: hover ? 1 : 0,
                          duration: Motion.short,
                          child: IgnorePointer(
                            ignoring: !hover,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StudioIcon(
                                  Icons.queue_play_next_rounded,
                                  tooltip: l.playNext,
                                  onTap: track.playable ? () => d.player.playNext(track) : null,
                                ),
                                ListenableBuilder(
                                  listenable: d.library,
                                  builder: (_, _) {
                                    final liked = d.library.isLiked(track);
                                    return StudioIcon(
                                      liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      tooltip: liked ? l.unlike : l.like,
                                      active: liked,
                                      onTap: () => d.library.toggleLike(track),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (track.isProtected)
                        StatusTag('DRM', tooltip: track.playable ? l.protectedPlayable : l.protectedHint)
                      else if (track.isPreview)
                        StatusTag('30S', tooltip: l.preview),
                      SizedBox(
                        width: 48,
                        child: Mono(
                          fmtDuration(Duration(milliseconds: track.durationMs)),
                          align: TextAlign.end,
                          color: Studio.text3,
                        ),
                      ),
                      trailing ??
                          StudioIcon(
                            Icons.more_horiz_rounded,
                            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                            onTap: () => showTrackActions(context, track, playlist: playlist),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Kleines Status-Etikett in Monospace (z. B. DRM, 30S).
class StatusTag extends StatelessWidget {
  const StatusTag(this.text, {super.key, this.tooltip});
  final String text;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final w = Container(
      margin: const EdgeInsetsDirectional.only(start: Studio.s2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Studio.lineStrong),
      ),
      child: Mono(text, size: 9.5, color: Studio.text2, weight: 650),
    );
    return tooltip == null ? w : Tooltip(message: tooltip!, child: w);
  }
}

Future<void> showTrackActions(BuildContext context, Track track, {LocalPlaylist? playlist}) {
  final d = context.deps;
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  void toast(String s) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(s)));

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheet) {
      final liked = d.library.isLiked(track);
      Widget item(IconData i, String label, VoidCallback f) => ListTile(
        leading: Icon(i),
        title: Text(label),
        onTap: () {
          Navigator.pop(sheet);
          f();
        },
      );
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Artwork(track.art('t67x67'), size: 48, radius: 8),
                title: Text(track.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(track.user.username),
              ),
              const Divider(),
              item(Icons.queue_play_next_rounded, l.playNext, () {
                d.player.playNext(track);
                toast(l.addedToQueue);
              }),
              item(Icons.add_to_queue_rounded, l.addToQueue, () {
                d.player.addToQueue(track);
                toast(l.addedToQueue);
              }),
              item(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                liked ? l.unlike : l.like,
                () => d.library.toggleLike(track),
              ),
              item(Icons.playlist_add_rounded, l.addToPlaylist, () => showAddToPlaylist(context, track)),
              if (playlist != null)
                item(
                  Icons.playlist_remove_rounded,
                  l.removeFromPlaylist,
                  () => d.library.removeFromPlaylist(playlist, track),
                ),
              if (track.user.id != 0)
                item(Icons.person_rounded, l.goToArtist, () => pushPage(context, ArtistPage(user: track.user))),
              if (track.permalinkUrl != null)
                item(Icons.link_rounded, l.copyLink, () {
                  Clipboard.setData(ClipboardData(text: track.permalinkUrl!));
                  toast(l.linkCopied);
                }),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showAddToPlaylist(BuildContext context, Track track) async {
  final lib = context.deps.library;
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final picked = await showModalBottomSheet<LocalPlaylist>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.add_rounded),
            title: Text(l.newPlaylist),
            onTap: () async {
              final name = await askText(sheet, l.newPlaylist, l.create);
              if (name != null && sheet.mounted) Navigator.pop(sheet, lib.createPlaylist(name));
            },
          ),
          for (final p in lib.playlists)
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: Text(p.name),
              subtitle: Text(l.tracksCount(p.tracks.length)),
              onTap: () => Navigator.pop(sheet, p),
            ),
        ],
      ),
    ),
  );
  if (picked == null) return;
  final added = lib.addToPlaylist(picked, track);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(added ? l.addedToPlaylist(picked.name) : l.alreadyInPlaylist(picked.name))));
}

/// Simple text input dialog.
Future<String?> askText(BuildContext context, String title, String confirm, {String initial = ''}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (c) {
      void submit() {
        final v = ctrl.text.trim();
        if (v.isNotEmpty) Navigator.pop(c, v);
      }

      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: c.l10n.playlistName),
          onSubmitted: (_) => submit(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(c.l10n.cancel)),
          FilledButton(onPressed: submit, child: Text(confirm)),
        ],
      );
    },
  );
}

/// Warms up [track] as soon as a finger rests on it: resolve the stream URL and pre-buffer it on the
/// free deck. Raw on the pointer, because onTapDown would only come after 100 ms in scrollable lists.
/// If the finger moves to scroll, the pre-buffer is dropped again (saves data).
class WarmOnTouch extends StatefulWidget {
  const WarmOnTouch({super.key, required this.track, required this.child});

  final Track track;
  final Widget child;

  @override
  State<WarmOnTouch> createState() => _WarmOnTouchState();
}

class _WarmOnTouchState extends State<WarmOnTouch> {
  Offset? _down;

  void _cool() {
    if (_down == null) return;
    _down = null;
    context.deps.player.cool(widget.track);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (e) {
      _down = e.position;
      context.deps.player.warm(widget.track);
    },
    onPointerMove: (e) {
      final start = _down;
      if (start != null && (e.position - start).distance > kTouchSlop) _cool();
    },
    onPointerCancel: (_) => _cool(),
    onPointerUp: (_) => _down = null,
    child: widget.child,
  );
}

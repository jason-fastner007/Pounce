import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../sc/models.dart';
import '../nav.dart';
import '../pages/artist_page.dart';
import '../pages/playlist_page.dart';
import '../theme.dart';
import 'common.dart';
import 'studio.dart';

/// Card with a light "press" effect (scales on tap).
class PressableCard extends StatefulWidget {
  const PressableCard({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? .96 : (_hover ? 1.02 : 1),
        duration: _down ? Motion.micro : Motion.medium,
        curve: _down ? Curves.easeOut : Motion.spring,
        child: widget.child,
      ),
    ),
  );
}

class PlaylistCard extends StatelessWidget {
  const PlaylistCard(this.playlist, {super.key, this.width = 156});

  final ScPlaylist playlist;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: PressableCard(
        onTap: () => pushPage(context, PlaylistPage.remote(playlist)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Artwork(playlist.art('t300x300'), size: width, radius: 14),
            const SizedBox(height: 8),
            Text(
              playlist.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: Studio.sans,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Studio.text,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              playlist.user.username,
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
    );
  }
}

class ArtistCard extends StatelessWidget {
  const ArtistCard(this.user, {super.key, this.width = 120});

  final ScUser user;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: PressableCard(
      onTap: () => pushPage(context, ArtistPage(user: user)),
      child: Column(
        children: [
          Artwork(sized(user.avatarUrl, 't300x300'), size: width, circle: true),
          const SizedBox(height: 8),
          Text(
            user.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: Studio.sans,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Studio.text,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Horizontal row with staggered fade-in.
/// With a mouse: arrow buttons on hover, drag with the mouse button held, and Shift + mouse wheel.
class CardRow extends StatefulWidget {
  const CardRow({super.key, required this.height, required this.children});

  final double height;
  final List<Widget> children;

  @override
  State<CardRow> createState() => _CardRowState();
}

class _CardRowState extends State<CardRow> {
  final _scroll = ScrollController();
  bool _hover = false, _canBack = false, _canForward = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Only show arrows where there's more (rebuild only on change).
  void _sync() {
    if (!mounted || !_scroll.hasClients) return;
    final p = _scroll.position;
    final back = p.pixels > p.minScrollExtent + 1, forward = p.pixels < p.maxScrollExtent - 1;
    if (back != _canBack || forward != _canForward) {
      setState(() {
        _canBack = back;
        _canForward = forward;
      });
    }
  }

  /// About one screen width further; the last card stays visible as an anchor.
  void _page(int dir) {
    final p = _scroll.position;
    final to = (p.pixels + dir * p.viewportDimension * .8).clamp(p.minScrollExtent, p.maxScrollExtent);
    _scroll.animateTo(to, duration: Motion.long, curve: Motion.emphasized);
  }

  /// Shift + mouse wheel = horizontal (otherwise the wheel scrolls the page as usual).
  void _onSignal(PointerSignalEvent e) {
    if (e is! PointerScrollEvent || !_scroll.hasClients || !HardwareKeyboard.instance.isShiftPressed) return;
    final delta = e.scrollDelta.dx != 0 ? e.scrollDelta.dx : e.scrollDelta.dy;
    GestureBinding.instance.pointerSignalResolver.register(e, (_) {
      final p = _scroll.position;
      _scroll.jumpTo((p.pixels + delta).clamp(p.minScrollExtent, p.maxScrollExtent));
    });
  }

  Widget _arrow(bool forward, bool visible) => PositionedDirectional(
    start: forward ? null : 6,
    end: forward ? 6 : null,
    top: 56,
    child: IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Motion.short,
        child: Hover(
          cursor: SystemMouseCursors.click,
          builder: (context, hover) => GestureDetector(
            onTap: () => _page(forward ? 1 : -1),
            child: AnimatedContainer(
              duration: Motion.short,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hover ? Studio.surfaceHi : Studio.surfaceTop,
                border: Border.all(color: Studio.lineStrong),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 4))],
              ),
              child: Icon(
                forward ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                color: hover ? Studio.text : Studio.text2,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final list = ListView.separated(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.children.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, i) => StaggeredIn(index: i, axis: Axis.horizontal, child: widget.children[i]),
    );
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      height: widget.height,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Listener(
          onPointerSignal: _onSignal,
          child: Stack(
            children: [
              // The mouse may drag the row too (Flutter only allows this for touch by default).
              ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: (_) {
                    _sync();
                    return false;
                  },
                  child: list,
                ),
              ),
              _arrow(rtl, _hover && (rtl ? _canForward : _canBack)),
              _arrow(!rtl, _hover && (rtl ? _canBack : _canForward)),
            ],
          ),
        ),
      ),
    );
  }
}

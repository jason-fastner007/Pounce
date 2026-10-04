import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/physics.dart';

import '../../core/deps.dart';
import '../../dj/dj_flow_controller.dart';
import '../../player/player_controller.dart';
import '../../sc/models.dart';
import '../nav.dart';
import '../pages/artist_page.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/track_tile.dart';
import 'dj_deck_view.dart';
import 'dj_player.dart';
import 'lyrics_view.dart';
import 'queue_view.dart';
import 'controls.dart';
import 'scrubber.dart';
import 'spectrum.dart';
import 'status_line.dart';

enum _Pane { art, lyrics, queue, dj }

/// Controls the player sheet from outside (shell, keyboard shortcuts).
class PlayerSheetController extends ChangeNotifier {
  _PlayerSheetState? _state;
  void expand() => _state?._animateTo(1);
  void collapse() => _state?._animateTo(0);
  bool get expanded => (_state?._c.value ?? 0) > .5;

  /// Full-screen player fully open and at rest: covers everything behind it.
  bool get covering {
    final c = _state?._c;
    return c != null && c.value >= 1 && !c.isAnimating;
  }

  void notify() => notifyListeners();
}

/// Mini player that expands into the full-screen player by swipe/tap.
class PlayerSheet extends StatefulWidget {
  const PlayerSheet({
    super.key,
    required this.controller,
    this.bottomBar,
    this.bottomBarHeight = 0,
    this.showMini = true,
  });

  /// Desktop: no mini player (the master deck takes over), the sheet is only the focus view.
  final bool showMini;
  final PlayerSheetController controller;
  final Widget? bottomBar;
  final double bottomBarHeight;

  @override
  State<PlayerSheet> createState() => _PlayerSheetState();
}

class _PlayerSheetState extends State<PlayerSheet> with TickerProviderStateMixin {
  static const _miniH = 68.0, _margin = 8.0, _miniArt = 48.0;

  late final _c = AnimationController(vsync: this, duration: Motion.long);
  late final _enter = AnimationController(vsync: this, duration: Motion.long);
  final _bigSlot = GlobalKey(), _smallSlot = GlobalKey(), _root = GlobalKey();
  Rect? _fullArt;
  _Pane _pane = _Pane.art;

  late final PlayerController _player = context.deps.player;

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
    _player.addListener(_onPlayer);
    if (_player.current != null) _enter.value = 1;
    _c.addStatusListener((s) {
      if (s.isCompleted || s.isDismissed) _measureSoon();
      widget.controller.notify();
    });
  }

  @override
  void dispose() {
    widget.controller._state = null;
    _player.removeListener(_onPlayer);
    _c.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _onPlayer() {
    if (_player.current != null && _enter.value == 0) {
      _enter.animateTo(1, curve: Motion.decelerate);
    }
  }

  void _animateTo(double v, {double velocity = 0}) {
    _measure();
    final spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 420, ratio: .9);
    _c.animateWith(SpringSimulation(spring, _c.value, v, velocity));
    widget.controller.notify();
  }

  void _measureSoon() => WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

  /// Measure the position of the large cover in the full-screen layout (target of the flight animation).
  void _measure() {
    final slot = (_pane == _Pane.art ? _bigSlot : _smallSlot).currentContext?.findRenderObject() as RenderBox?;
    final root = _root.currentContext?.findRenderObject() as RenderBox?;
    if (slot == null || root == null || !slot.hasSize) return;
    final r = slot.localToGlobal(Offset.zero, ancestor: root) & slot.size;
    if (r != _fullArt) setState(() => _fullArt = r);
  }

  void _dragUpdate(DragUpdateDetails d, double travel) {
    _c.value -= d.primaryDelta! / travel;
  }

  void _dragEnd(DragEndDetails d, double travel) {
    final v = -d.primaryVelocity! / travel;
    final target = v.abs() > 1.2 ? (v > 0 ? 1.0 : 0.0) : (_c.value > .5 ? 1.0 : 0.0);
    _animateTo(target, velocity: v);
  }

  void _setPane(_Pane p) {
    setState(() => _pane = _pane == p ? _Pane.art : p);
    _measureSoon();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final barH = widget.bottomBarHeight;
        final travel = h - _miniH - barH;
        final rtl = Directionality.of(context) == TextDirection.rtl;

        return ListenableBuilder(
          // DJ Flow on/off switches between the normal player and the DJ player.
          listenable: Listenable.merge([_player, context.deps.dj]),
          builder: (context, _) {
            final track = _player.current;
            return AnimatedBuilder(
              animation: Listenable.merge([_c, _enter]),
              builder: (context, _) {
                final p = _c.value.clamp(0.0, 1.0);
                final enter = Curves.easeOutCubic.transform(_enter.value);
                final collapsedTop = widget.showMini
                    ? h - barH - _miniH - _margin + (1 - enter) * (_miniH + 24)
                    : h + 24;
                final top = lerpDouble(collapsedTop, 0, p)!;
                final sheetH = lerpDouble(_miniH, h, p)!;
                final bar = widget.bottomBar;

                return Stack(
                  children: [
                    // Dim the page behind.
                    if (p > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ColoredBox(color: Colors.black.withValues(alpha: .35 * p)),
                        ),
                      ),
                    if (track != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: top,
                        height: sheetH,
                        child: PopScope(
                          canPop: p == 0,
                          onPopInvokedWithResult: (didPop, _) {
                            if (!didPop) _animateTo(0);
                          },
                          child: Builder(builder: (context) => _sheet(context, track, p, w, h, travel, rtl)),
                        ),
                      ),
                    if (bar != null) Positioned(left: 0, right: 0, bottom: -barH * p, height: barH, child: bar),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _sheet(BuildContext context, Track track, double p, double w, double h, double travel, bool rtl) {
    final m = lerpDouble(_margin, 0, p)!;
    final radius = lerpDouble(16, 0, p)!;
    final miniOpacity = (1 - p * 3).clamp(0.0, 1.0);
    final fullOpacity = ((p - .35) / .65).clamp(0.0, 1.0);

    final miniArt = Rect.fromLTWH(rtl ? w - m - 10 - _miniArt : m + 10, (_miniH - _miniArt) / 2, _miniArt, _miniArt);
    final target = _fullArt ?? Rect.fromLTWH((w - min(w, h) * .7) / 2, h * .15, min(w, h) * .7, min(w, h) * .7);
    final artRect = Rect.lerp(miniArt, target, Motion.emphasized.transform(p))!;
    final showFloating = p < 1 || _c.isAnimating;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background: mini = card, full = cover gradient.
        Positioned.fill(
          left: m,
          right: m,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Color.lerp(Studio.surface, Studio.bg0, p)!),
                // 1 px edge on the mini player with a soft shadow
                if (p < 1)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: Studio.lineStrong.withValues(alpha: .15 * (1 - p))),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .45 * (1 - p)),
                          blurRadius: 22,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                if (p > 0)
                  Opacity(
                    opacity: p,
                    child: _Backdrop(track: track),
                  ),
              ],
            ),
          ),
        ),
        // Full-screen layout (always laid out at full size so the measurement is stable).
        Positioned(
          left: 0,
          top: 0,
          width: w,
          height: sheetH(p, h),
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: h,
              maxHeight: h,
              child: IgnorePointer(
                ignoring: p < .95,
                child: TickerMode(
                  enabled: p > 0,
                  child: Opacity(
                    opacity: fullOpacity,
                    child: KeyedSubtree(key: _root, child: _full(context, track, w, h, travel, p)),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Mini-Player.
        if (miniOpacity > 0)
          Positioned(
            left: m,
            right: m,
            top: 0,
            height: _miniH,
            child: Opacity(opacity: miniOpacity, child: _mini(context, track, travel)),
          ),
        // Flying cover between mini and full screen.
        if (showFloating)
          Positioned.fromRect(
            rect: artRect,
            child: IgnorePointer(
              child: _ArtBox(url: track.art(), radius: lerpDouble(10, 24, p)!, shadow: p),
            ),
          ),
      ],
    );
  }

  double sheetH(double p, double h) => lerpDouble(_miniH, h, p)!;

  /// Next: in DJ mode with a transition (and learned as a skip), otherwise normal.
  void _skip(BuildContext context) {
    final dj = context.deps.dj;
    dj.state.isActive ? dj.triggerMixNow(skip: true) : _player.next();
  }

  Widget _mini(BuildContext context, Track track, double travel) {
    final l = context.l10n;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _animateTo(1),
      onVerticalDragStart: (_) => _measure(),
      onVerticalDragUpdate: (d) => _dragUpdate(d, travel),
      onVerticalDragEnd: (d) => _dragEnd(d, travel),
      // Swipe sideways = next/previous track.
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() < 300) return;
        final forward = (v < 0) != (Directionality.of(context) == TextDirection.rtl);
        forward ? _skip(context) : _player.previous();
      },
      child: Stack(
        children: [
          // Live spectrum behind title and buttons: shows what's audible right now. Fixed area,
          // so no layout shift; IgnorePointer so tap/swipe stay unchanged.
          const PositionedDirectional(
            start: 10 + _miniArt + 6,
            end: 12,
            top: 10,
            bottom: 6,
            child: IgnorePointer(child: SpectrumBars(height: 52, bars: 40, opacity: .22)),
          ),
          Row(
            children: [
              const SizedBox(width: 10 + _miniArt + 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.medium,
                  layoutBuilder: (cur, prev) =>
                      Stack(alignment: AlignmentDirectional.centerStart, children: [...prev, ?cur]),
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, .4),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: a, curve: Motion.decelerate)),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(track.id),
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: Studio.sans,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Studio.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      NowArtist(
                        track: track,
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
              ),
              _PlayPauseIcon(player: _player, tooltipPlay: l.play, tooltipPause: l.pause),
              IconButton(tooltip: l.next, onPressed: () => _skip(context), icon: const Icon(Icons.skip_next_rounded)),
              const SizedBox(width: 4),
            ],
          ),
          // Thin progress line.
          PositionedDirectional(
            start: 16,
            end: 16,
            bottom: 0,
            height: 3,
            child: ValueListenableBuilder<Duration>(
              valueListenable: _player.position,
              builder: (_, pos, _) {
                final total = _player.duration.inMilliseconds;
                return LinearProgressIndicator(
                  value: total == 0 ? 0 : (pos.inMilliseconds / total).clamp(0, 1),
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                  backgroundColor: Colors.transparent,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _full(BuildContext context, Track track, double w, double h, double travel, double p) {
    final pad = MediaQuery.viewPaddingOf(context);
    final wide = w >= 840;
    Widget collapseGesture(Widget child) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => _measure(),
      onVerticalDragUpdate: (d) => _dragUpdate(d, travel),
      onVerticalDragEnd: (d) => _dragEnd(d, travel),
      child: child,
    );
    final showArtInSlot = p >= 1 && !_c.isAnimating;

    final topBar = collapseGesture(
      Padding(
        padding: EdgeInsets.only(top: pad.top),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 4),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => _animateTo(0),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
              ),
              Expanded(
                child: Text(
                  context.l10n.nowPlaying,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ListenableBuilder(
                listenable: context.deps.dj,
                builder: (context, _) {
                  final dj = context.deps.dj;
                  return IconButton(
                    tooltip: 'DJ Flow Deck',
                    onPressed: () => _setPane(_pane == _Pane.dj ? _Pane.art : _Pane.dj),
                    icon: Icon(
                      Icons.album_rounded,
                      color: _pane == _Pane.dj || dj.state.isActive
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                onPressed: () => showTrackActions(context, track),
                icon: const Icon(Icons.more_vert_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );

    Widget bigArt(BoxConstraints c) {
      final size = min(c.maxWidth - 48, c.maxHeight - 24).clamp(120.0, 560.0);
      return Center(
        child: AnimatedScale(
          // Paused: cover slightly smaller (like "taking a breath").
          scale: _player.playing ? 1 : .88,
          duration: Motion.long,
          curve: Motion.spring,
          child: SizedBox.square(
            key: _bigSlot,
            dimension: size,
            child: showArtInSlot ? EnergyGlow(radius: 20, child: _ArtBox(url: track.art(), radius: 20, shadow: 1)) : null,
          ),
        ),
      );
    }

    final info = _TrackInfo(
      track: track,
      smallArt: !wide && _pane != _Pane.art
          ? SizedBox.square(
              key: _smallSlot,
              dimension: 56,
              child: showArtInSlot ? _ArtBox(url: track.art('t300x300'), radius: 10, shadow: 0) : null,
            )
          : null,
      onArtist: () {
        _animateTo(0);
        pushPage(context, ArtistPage(user: track.user));
      },
    );

    final controls = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        info,
        ListenableBuilder(
          listenable: context.deps.dj,
          builder: (context, _) {
            final dj = context.deps.dj;
            final state = dj.state;
            if (!state.isActive || _pane == _Pane.dj) return const SizedBox(height: 16);
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: GestureDetector(
                onTap: () => _setPane(_Pane.dj),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: .3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BeatPulseDot(
                        player: context.deps.player,
                        bpm: state.currentBpm > 0 ? state.currentBpm : 125.0,
                        firstBeatOffsetMs:
                            dj.currentBeatInfo?.downbeatOffsetMs ?? dj.currentBeatInfo?.firstBeatOffsetMs ?? 0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<BeatClock>(
                        valueListenable: dj.beat,
                        builder: (context, b, _) => Text(
                          '${state.currentBpm > 0 ? state.currentBpm.toStringAsFixed(1) : "--"} BPM · ${state.currentKey?.code ?? "Key"} · Takt ${b.bar}/4 (Beat ${b.beatInBar})',
                          style: TextStyle(
                            fontFamily: Studio.mono,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: Studio.text3),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: track.isLive ? const LiveBar() : Scrubber(track: track, style: ScrubStyle.squiggly, height: 32),
        ),
        const SizedBox(height: 12),
        const Transport(playSize: 68, iconSize: 44),
        const SizedBox(height: 12),
        const LoudnessControl(width: 168),
      ],
    );

    // DJ mode: instead of the normal player only the DJ player (pause, skip with transition, learning).
    // Radio is live – no transition, no seeking: the normal player with the LIVE badge there.
    if (context.deps.dj.state.isActive && !track.isLive) {
      return DjPlayer(
        track: track,
        onCollapse: () => _animateTo(0),
        art: collapseGesture(LayoutBuilder(builder: (_, c) => bigArt(c))),
      );
    }

    final actions = _BottomActions(pane: _pane, showPanes: !wide, onPane: _setPane, player: _player);

    if (wide) {
      return Column(
        children: [
          topBar,
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: collapseGesture(LayoutBuilder(builder: (_, c) => bigArt(c)))),
                      controls,
                      actions,
                      SizedBox(height: pad.bottom + 16),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 24, 24),
                    child: _SidePanel(track: track),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        topBar,
        Expanded(
          child: AnimatedSwitcher(
            duration: Motion.medium,
            switchInCurve: Motion.decelerate,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(scale: Tween(begin: .96, end: 1.0).animate(a), child: child),
            ),
            child: switch (_pane) {
              _Pane.art => collapseGesture(LayoutBuilder(key: const ValueKey('art'), builder: (_, c) => bigArt(c))),
              _Pane.lyrics => LyricsView(key: const ValueKey('lyrics'), track: track),
              _Pane.queue => const QueueView(key: ValueKey('queue')),
              _Pane.dj => DjDeckView(key: const ValueKey('dj'), track: track),
            },
          ),
        ),
        controls,
        actions,
        SizedBox(height: pad.bottom + 12),
      ],
    );
  }
}

/// Soft, slowly moving background from the cover (tiny image scaled up = cheap blur).
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.track});
  final Track track;

  @override
  Widget build(BuildContext context) {
    // 16×16 straight from SoundCloud instead of downscaling on the client: same colour haze,
    // 480 bytes, and no cacheWidth (Skwasm in Firefox scales decoded images wrongly).
    final url = track.art('mini');
    return Stack(
      fit: StackFit.expand,
      children: [
        BeatBackdrop(intensity: context.deps.settings.beatLevel.intensity * 1.6),
        // Tiny cover scaled up = soft colour haze without blur cost.
        if (url != null)
          Opacity(
            opacity: .35,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 900),
              layoutBuilder: (cur, prev) => Stack(fit: StackFit.expand, children: [...prev, ?cur]),
              child: Image.network(
                url,
                key: ValueKey(url),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x66060709), Color(0xB3060709), Color(0xF2060709)],
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtBox extends StatelessWidget {
  const _ArtBox({required this.url, required this.radius, required this.shadow});
  final String? url;
  final double radius;
  final double shadow;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        if (shadow > 0)
          BoxShadow(
            color: Colors.black.withValues(alpha: .35 * shadow),
            blurRadius: 40 * shadow,
            offset: Offset(0, 16 * shadow),
          ),
      ],
    ),
    child: Artwork(url, radius: radius),
  );
}

class _TrackInfo extends StatelessWidget {
  const _TrackInfo({required this.track, required this.onArtist, this.smallArt});
  final Track track;
  final VoidCallback onArtist;
  final Widget? smallArt;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final lib = context.deps.library;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
      child: Row(
        children: [
          AnimatedSize(
            duration: Motion.medium,
            curve: Motion.emphasized,
            child: smallArt == null
                ? const SizedBox()
                : Padding(padding: const EdgeInsetsDirectional.only(end: 12), child: smallArt),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: Motion.medium,
              child: Column(
                key: ValueKey(track.id),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: Studio.sans,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: Studio.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: onArtist,
                    borderRadius: BorderRadius.circular(8),
                    child: NowArtist(
                      track: track,
                      style: const TextStyle(
                        fontFamily: Studio.sans,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Studio.text2,
                      ),
                    ),
                  ),
                  const SizedBox(height: Studio.s2),
                  StatusLine(track: track),
                  PreviewNotice(track: track),
                ],
              ),
            ),
          ),
          ListenableBuilder(
            listenable: lib,
            builder: (context, _) {
              final liked = lib.isLiked(track);
              return IconButton(
                iconSize: 28,
                tooltip: liked ? context.l10n.unlike : context.l10n.like,
                onPressed: () => lib.toggleLike(track),
                icon: AnimatedSwitcher(
                  duration: Motion.medium,
                  transitionBuilder: (c, a) => ScaleTransition(
                    scale: CurvedAnimation(parent: a, curve: Motion.spring),
                    child: c,
                  ),
                  child: Icon(
                    liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey(liked),
                    color: liked ? t.colorScheme.primary : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlayPauseIcon extends StatelessWidget {
  const _PlayPauseIcon({required this.player, required this.tooltipPlay, required this.tooltipPause});
  final PlayerController player;
  final String tooltipPlay, tooltipPause;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: player.playing ? tooltipPause : tooltipPlay,
    onPressed: player.toggle,
    icon: AnimatedSwitcher(
      duration: Motion.short,
      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
      child: player.loading
          ? const SizedBox.square(key: ValueKey('l'), dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
          : Icon(
              player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(player.playing),
              size: 30,
            ),
    ),
  );
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.pane, required this.showPanes, required this.onPane, required this.player});
  final _Pane pane;
  final bool showPanes;
  final ValueChanged<_Pane> onPane;
  final PlayerController player;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = Theme.of(context).colorScheme;
    Widget btn(IconData i, String tip, bool active, VoidCallback f) => IconButton(
      tooltip: tip,
      isSelected: active,
      style: IconButton.styleFrom(
        backgroundColor: active ? s.secondaryContainer : null,
        foregroundColor: active ? s.onSecondaryContainer : s.onSurfaceVariant,
      ),
      onPressed: f,
      icon: Icon(i),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (showPanes) btn(Icons.lyrics_rounded, l.lyrics, pane == _Pane.lyrics, () => onPane(_Pane.lyrics)),
          if (showPanes) btn(Icons.album_rounded, 'DJ Deck', pane == _Pane.dj, () => onPane(_Pane.dj)),
          btn(
            Icons.bedtime_rounded,
            player.sleepAt == null ? l.sleepTimer : l.sleepIn(_minutesLeft(player.sleepAt!)),
            player.sleepAt != null,
            () => _sleepSheet(context, player),
          ),
          TextButton(
            onPressed: () => _speedSheet(context, player),
            child: Text('${player.speed.toStringAsFixed(player.speed % 1 == 0 ? 0 : 2)}×'),
          ),
          if (showPanes) btn(Icons.queue_music_rounded, l.queue, pane == _Pane.queue, () => onPane(_Pane.queue)),
        ],
      ),
    );
  }

  static int _minutesLeft(DateTime at) => max(1, at.difference(DateTime.now()).inMinutes + 1);

  static void _sleepSheet(BuildContext context, PlayerController player) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.sleepTimer, style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final m in const [15, 30, 45, 60, 90])
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text(l.minutes(m)),
                onTap: () {
                  player.setSleepTimer(Duration(minutes: m));
                  Navigator.pop(c);
                },
              ),
            if (player.sleepAt != null)
              ListTile(
                leading: const Icon(Icons.timer_off_outlined),
                title: Text(l.sleepOff),
                onTap: () {
                  player.setSleepTimer(null);
                  Navigator.pop(c);
                },
              ),
          ],
        ),
      ),
    );
  }

  static void _speedSheet(BuildContext context, PlayerController player) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${c.l10n.speed} · ${player.speed.toStringAsFixed(2)}×', style: Theme.of(c).textTheme.titleLarge),
                Slider(
                  value: player.speed,
                  min: .5,
                  max: 2,
                  divisions: 30,
                  onChanged: (v) {
                    player.setSpeed(double.parse(v.toStringAsFixed(2)));
                    set(() {});
                  },
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final v in const [.75, 1.0, 1.25, 1.5])
                      ChoiceChip(
                        label: Text('$v×'),
                        selected: player.speed == v,
                        onSelected: (_) {
                          player.setSpeed(v);
                          set(() {});
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wide view: lyrics and queue as a sidebar next to the player.
class _SidePanel extends StatefulWidget {
  const _SidePanel({required this.track});
  final Track track;

  @override
  State<_SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<_SidePanel> {
  bool _queue = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: .6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, icon: const Icon(Icons.lyrics_rounded), label: Text(l.lyrics)),
                ButtonSegment(value: true, icon: const Icon(Icons.queue_music_rounded), label: Text(l.queue)),
              ],
              selected: {_queue},
              onSelectionChanged: (v) => setState(() => _queue = v.first),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: Motion.medium,
              child: _queue
                  ? const QueueView(key: ValueKey('q'))
                  : LyricsView(key: const ValueKey('l'), track: widget.track),
            ),
          ),
        ],
      ),
    );
  }
}

class _BeatPulseDot extends StatelessWidget {
  const _BeatPulseDot({
    required this.player,
    required this.bpm,
    required this.firstBeatOffsetMs,
    required this.color,
  });

  final PlayerController player;
  final double bpm;
  final int firstBeatOffsetMs;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 10,
    child: CustomPaint(painter: _DotPainter(SpectrumScope.of(context), player, bpm, firstBeatOffsetMs, color)),
  );
}

/// Dot that lights up on every beat (downbeat stronger) – at the frame rate of the spectrum bus.
class _DotPainter extends CustomPainter {
  _DotPainter(this.bus, this.player, this.bpm, this.anchorMs, this.color) : super(repaint: bus);
  final SpectrumBus bus;
  final PlayerController player;
  final double bpm;
  final int anchorMs;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final periodMs = 60000.0 / (bpm > 0 ? bpm : 125.0);
    final elapsed = player.livePosition.inMicroseconds / 1000 - anchorMs;
    var decay = 0.0;
    var downbeat = false;
    if (elapsed >= 0 && player.playing) {
      downbeat = (elapsed / periodMs).floor() % 4 == 0;
      final phase = (elapsed % periodMs) / periodMs;
      decay = pow((1.0 - phase / 0.40).clamp(0.0, 1.0), 2.5).toDouble();
    }
    final alpha = downbeat ? 0.3 + 0.7 * decay : 0.2 + 0.3 * decay;
    final c = size.center(Offset.zero);
    if (downbeat && decay > .2) {
      canvas.drawCircle(c, 5 + 3 * decay, Paint()..color = color.withValues(alpha: .35 * decay));
    }
    canvas.drawCircle(c, 4, Paint()..color = color.withValues(alpha: alpha));
  }

  @override
  bool shouldRepaint(_DotPainter o) => o.bpm != bpm || o.anchorMs != anchorMs || o.color != color;
}

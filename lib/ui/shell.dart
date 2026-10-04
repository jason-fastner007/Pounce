import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/deps.dart';
import '../sc/models.dart';
import 'pages/home_page.dart';
import 'pages/dj_page.dart';
import 'updates.dart';
import 'pages/library_page.dart';
import 'pages/search_page.dart';
import 'pages/settings_page.dart';
import 'player/inspector.dart';
import 'player/master_deck.dart';
import 'player/player_sheet.dart';
import 'player/scrubber.dart';
import 'player/spectrum.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/studio.dart';

/// App frame.
/// Phone:   tabs · mini player · full-screen player · navigation bar.
/// Desktop: rail (64/220) · workspace · inspector (320) · master deck (80).
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with TickerProviderStateMixin {
  int _tab = 0;
  final _navKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());
  final _sheet = PlayerSheetController();
  final _searchFocus = FocusNode();
  late final _spectrum = SpectrumBus(
    _player,
    this,
    (t) => waveformOf(context.deps.sc, t),
    grid: () => context.deps.dj.currentBeatInfo,
  );

  late final _pages = <Widget>[
    const HomePage(),
    SearchPage(focus: _searchFocus),
    const DjPage(),
    const LibraryPage(),
    const SettingsPage(),
  ];

  String? _shownError;
  late final _player = context.deps.player;
  late final _settings = context.deps.settings;

  @override
  void initState() {
    super.initState();
    // Updates: only when enabled, at most daily, after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Updates.autoCheck(context);
    });
    _player.addListener(_onPlayer);
  }

  Track? _lastTrack;

  /// Briefly report playback errors as a snackbar.
  void _onPlayer() {
    final e = _player.error;
    if (e != null && e != _shownError && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.playbackError)));
    }
    _shownError = e;
    if ((_lastTrack == null) != (_player.current == null) && mounted) {
      setState(() => _lastTrack = _player.current);
    }
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayer);
    _spectrum.dispose();
    _searchFocus.dispose();
    _sheet.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _tab) {
      // Selected again: back to the tab's root.
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
    }
    _sheet.collapse();
    setState(() => _tab = i);
    if (i == 1) _searchFocus.requestFocus();
  }

  void _focusSearch() {
    _select(1);
    _searchFocus.requestFocus();
  }

  List<(IconData, IconData, String)> _destinations(BuildContext context) {
    final l = context.l10n;
    return [
      (Icons.home_outlined, Icons.home_rounded, l.navHome),
      (Icons.search_rounded, Icons.saved_search_rounded, l.navSearch),
      (Icons.album_outlined, Icons.album_rounded, l.navDj),
      (Icons.library_music_outlined, Icons.library_music_rounded, l.navLibrary),
      (Icons.tune_outlined, Icons.tune_rounded, l.navSettings),
    ];
  }

  Widget get _tabs => RepaintBoundary(
    child: IndexedStack(
      index: _tab,
      children: [
        for (var i = 0; i < _pages.length; i++)
          Navigator(
            key: _navKeys[i],
            onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _pages[i]),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < Studio.phone;

    final body = phone ? _phone(context) : _desktop(context, width);

    return SpectrumScope(
      bus: _spectrum,
      child: Shortcuts(
        shortcuts: {
          const SingleActivator(LogicalKeyboardKey.space): VoidCallbackIntent(_player.toggle),
          const SingleActivator(LogicalKeyboardKey.mediaPlayPause): VoidCallbackIntent(_player.toggle),
          const SingleActivator(LogicalKeyboardKey.arrowRight, control: true): VoidCallbackIntent(_player.next),
          const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): VoidCallbackIntent(_player.previous),
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): VoidCallbackIntent(_focusSearch),
          const SingleActivator(LogicalKeyboardKey.slash): VoidCallbackIntent(_focusSearch),
          const SingleActivator(LogicalKeyboardKey.keyI, control: true): VoidCallbackIntent(
            () => _settings.inspectorOpen = !_settings.inspectorOpen,
          ),
          const SingleActivator(LogicalKeyboardKey.escape): VoidCallbackIntent(_sheet.collapse),
        },
        child: Actions(
          actions: {VoidCallbackIntent: _UnlessTyping()},
          child: Focus(
            autofocus: true,
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                // An open player collapses itself (own PopScope).
                if (didPop || _sheet.expanded) return;
                final nav = _navKeys[_tab].currentState;
                if (nav != null && nav.canPop()) {
                  nav.pop();
                } else if (_tab != 0) {
                  setState(() => _tab = 0);
                } else {
                  SystemNavigator.pop();
                }
              },
              child: Scaffold(
                backgroundColor: Studio.bg0,
                body: Stack(
                  children: [
                    // Beat background at the very bottom; content above in its own layers.
                    Positioned.fill(
                      child: ListenableBuilder(
                        // An open full-screen player covers everything (own background): don't paint here.
                        listenable: Listenable.merge([_settings, _sheet]),
                        builder: (_, _) => BeatBackdrop(
                          intensity: _settings.beatLevel.intensity,
                          enabled: !_sheet.covering,
                        ),
                      ),
                    ),
                    Positioned.fill(child: body),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Handy ----------

  Widget _phone(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    const navContentHeight = 60.0;
    final barH = navContentHeight + bottomInset;
    final hasTrack = _player.current != null;
    final contentBottom = barH + (hasTrack ? 76.0 : 0.0);

    final nav = _PhoneNavBar(
      selectedIndex: _tab,
      onDestinationSelected: _select,
      destinations: _destinations(context),
      bottomInset: bottomInset,
      contentHeight: navContentHeight,
    );

    return _withSnackInset(
      contentBottom + 8.0,
      Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: contentBottom),
              child: MediaQuery.removePadding(context: context, removeBottom: true, child: _tabs),
            ),
          ),
          Positioned.fill(
            child: PlayerSheet(
              controller: _sheet,
              bottomBar: nav,
              bottomBarHeight: barH,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Desktop / Tablet ----------

  Widget _desktop(BuildContext context, double width) {
    final docked = width >= Studio.wide;
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final open = _settings.inspectorOpen;
        return _withSnackInset(
          Studio.deck + 12,
          Row(
            children: [
              RepaintBoundary(
                child: _Rail(
                  expanded: _settings.railExpanded && width >= Studio.compact,
                  selected: _tab,
                  destinations: _destinations(context),
                  onSelect: _select,
                  onToggle: () => _settings.railExpanded = !_settings.railExpanded,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _tabs),
                              // Docked inspector (wide)
                              AnimatedContainer(
                                duration: Motion.medium,
                                curve: Motion.emphasized,
                                width: docked && open ? Studio.inspector : 0,
                                child: ClipRect(
                                  child: OverflowBox(
                                    alignment: AlignmentDirectional.centerStart,
                                    minWidth: Studio.inspector,
                                    maxWidth: Studio.inspector,
                                    child: docked
                                        ? RepaintBoundary(
                                            child: Inspector(onClose: () => _settings.inspectorOpen = false),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Overlay inspector (compact)
                          if (!docked) ...[
                            IgnorePointer(
                              ignoring: !open,
                              child: AnimatedOpacity(
                                opacity: open ? 1 : 0,
                                duration: Motion.medium,
                                child: GestureDetector(
                                  onTap: () => _settings.inspectorOpen = false,
                                  child: const ColoredBox(color: Color(0x88000000), child: SizedBox.expand()),
                                ),
                              ),
                            ),
                            AnimatedPositionedDirectional(
                              duration: Motion.medium,
                              curve: Motion.emphasized,
                              top: 0,
                              bottom: 0,
                              end: open ? 0 : -Studio.inspector - 8,
                              width: Studio.inspector,
                              child: Inspector(onClose: () => _settings.inspectorOpen = false),
                            ),
                          ],
                          // Focus view (large cover, wave, lyrics)
                          Positioned.fill(child: PlayerSheet(controller: _sheet, showMini: false)),
                        ],
                      ),
                    ),
                    RepaintBoundary(
                      child: MasterDeck(
                        compact: width < Studio.wide,
                        inspectorOpen: open,
                        onToggleInspector: () => _settings.inspectorOpen = !open,
                        onExpand: () => _sheet.expanded ? _sheet.collapse() : _sheet.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Let snackbars float above the deck or mini player.
  Widget _withSnackInset(double bottom, Widget child) => Theme(
    data: Theme.of(context).copyWith(
      snackBarTheme: Theme.of(context).snackBarTheme.copyWith(insetPadding: EdgeInsets.fromLTRB(16, 0, 16, bottom)),
    ),
    child: child,
  );
}

/// Slim navigation rail (64 px), expandable to 220 px.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.expanded,
    required this.selected,
    required this.destinations,
    required this.onSelect,
    required this.onToggle,
  });

  final bool expanded;
  final int selected;
  final List<(IconData, IconData, String)> destinations;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final account = context.deps.account;
    final l = context.l10n;
    return AnimatedContainer(
      duration: Motion.medium,
      curve: Motion.emphasized,
      width: expanded ? Studio.railWide : Studio.railSlim,
      decoration: const BoxDecoration(
        color: Color(0xD90B0D12),
        border: BorderDirectional(end: BorderSide(color: Studio.line)),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: AlignmentDirectional.topStart,
          minWidth: Studio.railWide,
          maxWidth: Studio.railWide,
          child: Column(
            children: [
              // Logo / Wortmarke
              SizedBox(
                height: 64,
                child: Row(
                  children: [
                    SizedBox(
                      width: Studio.railSlim,
                      child: Icon(Icons.graphic_eq_rounded, color: accent, size: 26),
                    ),
                    AnimatedOpacity(
                      opacity: expanded ? 1 : 0,
                      duration: Motion.short,
                      child: const Mono('POUNCE', size: 12, color: Studio.text, weight: 700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Studio.s2),
              for (final (i, (o, s, label)) in destinations.indexed)
                _RailItem(
                  icon: i == selected ? s : o,
                  label: label,
                  active: i == selected,
                  expanded: expanded,
                  shortcut: '0${i + 1}',
                  onTap: () => onSelect(i),
                ),
              const Spacer(),
              // Konto-Anzeige
              ListenableBuilder(
                listenable: account,
                builder: (context, _) {
                  final me = account.me;
                  if (!account.loggedIn || me == null) return const SizedBox.shrink();
                  return Tooltip(
                    message: l.loggedInAs(me.username),
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          SizedBox(
                            width: Studio.railSlim,
                            child: Center(child: Artwork(sized(me.avatarUrl, 't67x67'), size: 28, circle: true)),
                          ),
                          Expanded(
                            child: AnimatedOpacity(
                              opacity: expanded ? 1 : 0,
                              duration: Motion.short,
                              child: Text(
                                me.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Studio.bodyDim,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    SizedBox(
                      width: Studio.railSlim,
                      child: Center(
                        child: StudioIcon(
                          expanded
                              ? Icons.keyboard_double_arrow_left_rounded
                              : Icons.keyboard_double_arrow_right_rounded,
                          tooltip: expanded ? l.collapseRail : l.expandRail,
                          onTap: onToggle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Studio.s2),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.expanded,
    required this.shortcut,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active, expanded;
  final String shortcut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final item = Hover(
      cursor: SystemMouseCursors.click,
      builder: (context, hover) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Stack(
            // Expand so the highlight fills the row and lines up with the centred marker.
            fit: StackFit.expand,
            children: [
              // Active marker: accent bar at the edge
              AnimatedPositionedDirectional(
                duration: Motion.medium,
                curve: Motion.spring,
                start: 0,
                top: active ? 10 : 22,
                bottom: active ? 10 : 22,
                width: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: active ? accent : Colors.transparent,
                    borderRadius: const BorderRadiusDirectional.horizontal(end: Studio.r2),
                    boxShadow: active ? [BoxShadow(color: accent.withValues(alpha: .6), blurRadius: 8)] : const [],
                  ),
                ),
              ),
              AnimatedContainer(
                duration: Motion.short,
                margin: const EdgeInsets.symmetric(horizontal: Studio.s2, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: Studio.br10,
                  color: active
                      ? accent.withValues(alpha: .10)
                      : (hover ? Colors.white.withValues(alpha: .05) : Colors.transparent),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: Studio.railSlim - Studio.s4,
                      child: AnimatedScale(
                        scale: hover && !active ? 1.1 : 1,
                        duration: Motion.short,
                        curve: Motion.spring,
                        child: Icon(icon, size: 21, color: active ? accent : (hover ? Studio.text : Studio.text2)),
                      ),
                    ),
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: expanded ? 1 : 0,
                        duration: Motion.short,
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Studio.body.copyWith(
                            color: active ? Studio.text : Studio.text2,
                            fontVariations: [FontVariation.weight(active ? 600 : 480)],
                          ),
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: expanded ? 1 : 0,
                      duration: Motion.short,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: Studio.s3),
                        child: Mono(shortcut, size: 10, color: active ? accent : Studio.text3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return expanded ? item : Tooltip(message: label, preferBelow: false, child: item);
  }
}


/// Keyboard shortcuts only when no text field has focus.
class _UnlessTyping extends VoidCallbackAction {
  @override
  bool isEnabled(VoidCallbackIntent intent) {
    final ctx = FocusManager.instance.primaryFocus?.context;
    return ctx == null || ctx.findAncestorWidgetOfExactType<EditableText>() == null;
  }
}

/// Slim, ergonomic navigation bar for phones (sits safely above the Android gesture bar).
class _PhoneNavBar extends StatelessWidget {
  const _PhoneNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.bottomInset,
    required this.contentHeight,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<(IconData, IconData, String)> destinations;
  final double bottomInset;
  final double contentHeight;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      height: contentHeight + bottomInset,
      decoration: const BoxDecoration(
        color: Color(0xF20B0D12),
        border: Border(top: BorderSide(color: Studio.line, width: 1)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < destinations.length; i++)
            Expanded(
              child: _PhoneNavBarItem(
                icon: i == selectedIndex ? destinations[i].$2 : destinations[i].$1,
                label: destinations[i].$3,
                selected: i == selectedIndex,
                accent: accent,
                onTap: () => onDestinationSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhoneNavBarItem extends StatelessWidget {
  const _PhoneNavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withValues(alpha: .12),
        highlightColor: Colors.white.withValues(alpha: .04),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: Motion.short,
              curve: Motion.spring,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? accent.withValues(alpha: .18) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedScale(
                scale: selected ? 1.05 : 1.0,
                duration: Motion.short,
                curve: Motion.spring,
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? accent : Studio.text2,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: Motion.short,
              style: TextStyle(
                fontFamily: Studio.sans,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? accent : Studio.text3,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}


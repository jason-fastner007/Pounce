import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../sc/models.dart';
import '../../sc/soundcloud.dart';
import '../nav.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/radio_widgets.dart';
import '../widgets/track_tile.dart';
import 'artist_page.dart';
import 'playlist_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.focus});

  /// Triggered by keyboard shortcuts (Ctrl+F, /).
  final FocusNode? focus;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  late final _focus = widget.focus ?? FocusNode();
  Timer? _debounce;
  List<String> _suggestions = [];
  String? _query;
  _Source _source = _Source.all;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    if (widget.focus == null) _focus.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final s = await context.deps.sc.suggestions(q.trim());
        if (mounted && _ctrl.text == q) setState(() => _suggestions = s);
      } catch (_) {}
    });
  }

  Future<void> _submit(String q) async {
    q = q.trim();
    if (q.isEmpty) return;
    _debounce?.cancel();
    _ctrl.text = q;
    _focus.unfocus();
    // Open shared links directly.
    if (RegExp(r'(soundcloud\.com|on\.soundcloud\.com)/').hasMatch(q)) {
      return _openLink(q);
    }
    context.deps.library.addSearch(q);
    setState(() {
      _query = q;
      _suggestions = [];
    });
  }

  Future<void> _openLink(String url) async {
    final d = context.deps;
    try {
      final r = await d.sc.resolve(url.startsWith('http') ? url : 'https://$url');
      if (!mounted) return;
      switch (r) {
        case ResolvedTrack(:final track):
          d.player.playTrack(track);
        case ResolvedPlaylist(:final playlist):
          pushPage(context, PlaylistPage.remote(playlist));
        case ResolvedUser(:final user):
          pushPage(context, ArtistPage(user: user));
        case null:
          throw ScException('unknown');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errorLoading)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchBar(
                controller: _ctrl,
                focusNode: _focus,
                hintText: l.searchHint,
                leading: const Icon(Icons.search_rounded),
                elevation: const WidgetStatePropertyAll(0),
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: _submit,
                trailing: [
                  ListenableBuilder(
                    listenable: _ctrl,
                    builder: (_, _) => AnimatedScale(
                      scale: _ctrl.text.isEmpty ? 0 : 1,
                      duration: Motion.short,
                      curve: Motion.spring,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
                        onPressed: () {
                          _ctrl.clear();
                          setState(() {
                            _query = null;
                            _suggestions = [];
                          });
                          _focus.requestFocus();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sources: All | SoundCloud | Web radio (only when web radio is enabled).
            ListenableBuilder(
              listenable: context.deps.settings,
              builder: (context, _) {
                final radioOn = context.deps.settings.radioEnabled;
                final source = radioOn ? _source : _Source.soundcloud;
                return Expanded(
                  child: Column(
                    children: [
                      if (radioOn)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: SegmentedButton<_Source>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(value: _Source.all, label: Text(l.srcAll)),
                              const ButtonSegment(value: _Source.soundcloud, label: Text('SoundCloud')),
                              ButtonSegment(
                                value: _Source.radio,
                                label: Text(l.srcRadio),
                                icon: const Icon(Icons.radio_rounded, size: 18),
                              ),
                            ],
                            selected: {source},
                            onSelectionChanged: (s) => setState(() => _source = s.first),
                          ),
                        ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: Motion.medium,
                          switchInCurve: Motion.decelerate,
                          child: _suggestions.isNotEmpty && _focus.hasFocus
                              ? _SuggestionList(key: const ValueKey('s'), items: _suggestions, onPick: _submit)
                              : _query == null
                              ? (source == _Source.radio
                                    ? const RadioHome(key: ValueKey('rh'))
                                    : _Recent(key: const ValueKey('r'), onPick: _submit))
                              : source == _Source.radio
                              ? RadioResults(key: ValueKey('radio:$_query'), query: _query!)
                              : _Results(
                                  key: ValueKey('$source:$_query'),
                                  query: _query!,
                                  // "All": the best stations above the SoundCloud hits (loaded in parallel).
                                  header: source == _Source.all
                                      ? RadioResults(
                                          query: _query!,
                                          compact: true,
                                          onMore: () => setState(() => _source = _Source.radio),
                                        )
                                      : null,
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({super.key, required this.items, required this.onPick});
  final List<String> items;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: items.length,
    itemBuilder: (_, i) => StaggeredIn(
      index: i,
      child: ListTile(
        leading: const Icon(Icons.north_west_rounded),
        title: Text(items[i]),
        onTap: () => onPick(items[i]),
      ),
    ),
  );
}

class _Recent extends StatelessWidget {
  const _Recent({super.key, required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final lib = context.deps.library;
    return ListenableBuilder(
      listenable: lib,
      builder: (context, _) {
        if (lib.searches.isEmpty) {
          return MessageView(icon: Icons.graphic_eq_rounded, text: context.l10n.searchEmptyTitle);
        }
        return ListView(
          children: [
            SectionHeader(context.l10n.searchRecent),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (i, q) in lib.searches.indexed)
                    StaggeredIn(
                      index: i,
                      axis: Axis.horizontal,
                      child: InputChip(
                        label: Text(q),
                        onPressed: () => onPick(q),
                        onDeleted: () => lib.removeSearch(q),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _Source { all, soundcloud, radio }

enum _Tab { tracks, playlists, albums, artists }

class _Results extends StatefulWidget {
  const _Results({super.key, required this.query, this.header});
  final String query;

  /// Above the tabs, e.g. the best stations in "All".
  final Widget? header;

  @override
  State<_Results> createState() => _ResultsState();
}

class _ResultsState extends State<_Results> {
  _Tab _tab = _Tab.tracks;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = {
      _Tab.tracks: l.tabTracks,
      _Tab.playlists: l.tabPlaylists,
      _Tab.albums: l.tabAlbums,
      _Tab.artists: l.tabArtists,
    };
    return Column(
      children: [
        ?widget.header,
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final t in _Tab.values)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(labels[t]!),
                    selected: _tab == t,
                    onSelected: (_) => setState(() => _tab = t),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: Motion.medium,
            child: switch (_tab) {
              _Tab.tracks => _Paged<Track>(
                key: const ValueKey(_Tab.tracks),
                first: (sc) => sc.searchTracks(widget.query),
                parse: Track.fromJson,
                itemBuilder: (c, items, i) =>
                    TrackTile(track: items[i], onTap: () => c.deps.player.playQueue(items, i)),
              ),
              _Tab.playlists || _Tab.albums => _Paged<ScPlaylist>(
                key: ValueKey(_tab),
                first: (sc) => _tab == _Tab.albums ? sc.searchAlbums(widget.query) : sc.searchPlaylists(widget.query),
                parse: ScPlaylist.fromJson,
                itemBuilder: (c, items, i) {
                  final p = items[i];
                  return ListTile(
                    leading: Artwork(p.art('t67x67'), size: 56, radius: 4),
                    title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${p.user.username} · ${c.l10n.tracksCount(p.trackCount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => pushPage(c, PlaylistPage.remote(p)),
                  );
                },
              ),
              _Tab.artists => _Paged<ScUser>(
                key: const ValueKey(_Tab.artists),
                first: (sc) => sc.searchUsers(widget.query),
                parse: ScUser.fromJson,
                itemBuilder: (c, items, i) {
                  final u = items[i];
                  return ListTile(
                    leading: Artwork(sized(u.avatarUrl, 't67x67'), size: 52, circle: true),
                    title: Row(
                      children: [
                        Flexible(child: Text(u.username, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (u.verified) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified_rounded, size: 16, color: Theme.of(c).colorScheme.primary),
                        ],
                      ],
                    ),
                    subtitle: Text(c.l10n.followers(fmtCompact(c, u.followers))),
                    onTap: () => pushPage(c, ArtistPage(user: u)),
                  );
                },
              ),
            },
          ),
        ),
      ],
    );
  }
}

/// Endless list that loads more at the end.
class _Paged<T> extends StatefulWidget {
  const _Paged({super.key, required this.first, required this.parse, required this.itemBuilder});

  final Future<ScPage<T>> Function(SoundCloud) first;
  final T Function(Map<String, dynamic>) parse;
  final Widget Function(BuildContext, List<T>, int) itemBuilder;

  @override
  State<_Paged<T>> createState() => _PagedState<T>();
}

class _PagedState<T> extends State<_Paged<T>> {
  final _items = <T>[];
  String? _next;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load(() => widget.first(context.deps.sc));
  }

  Future<void> _load(Future<ScPage<T>> Function() f) async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final p = await f();
      if (!mounted) return;
      setState(() {
        _items.addAll(p.items);
        _next = p.next;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      return MessageView(
        icon: _error ? Icons.cloud_off_rounded : Icons.search_off_rounded,
        text: _error ? context.l10n.errorLoading : context.l10n.noResults,
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 600 && !_loading && _next != null && !_error) {
          final href = _next!;
          _load(() => context.deps.sc.next(href, widget.parse));
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 160),
        itemCount: _items.length + (_next != null ? 1 : 0),
        itemBuilder: (c, i) => i == _items.length
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : StaggeredIn(index: i, child: widget.itemBuilder(c, _items, i)),
      ),
    );
  }
}

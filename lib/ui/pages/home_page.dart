import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../theme.dart';
import '../../library/account.dart';
import '../../modules/source_module.dart';
import '../../sc/models.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<_HomeData> _data = _load();
  late final _modules = context.deps.modules;
  late String _active;
  Account? _account;
  bool _wasLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _active = _activeIds;
    _modules.addListener(_onModules);
    _bindAccount();
  }

  @override
  void dispose() {
    _modules.removeListener(_onModules);
    _account?.removeListener(_onAccount);
    super.dispose();
  }

  String get _activeIds => _modules.sources.map((m) => m.id).join(',');

  /// A source module was switched on or off: other rows, maybe another account.
  void _onModules() {
    if (_activeIds == _active) return;
    _active = _activeIds;
    _bindAccount();
    _refresh();
  }

  void _bindAccount() {
    _account?.removeListener(_onAccount);
    _account = context.deps.soundcloud?.account?..addListener(_onAccount);
    _wasLoggedIn = _account?.loggedIn ?? false;
  }

  void _onAccount() {
    final loggedIn = _account?.loggedIn ?? false;
    if (loggedIn != _wasLoggedIn) {
      _wasLoggedIn = loggedIn;
      _refresh();
    }
  }

  Future<_HomeData> _load() async {
    final d = context.deps;
    final sc = d.soundcloud;
    final seed = d.library.history.where((t) => !t.isLive).firstOrNull ?? d.library.likes.where((t) => !t.isLive).firstOrNull;
    final r = await (
      sc?.sc.selections() ?? Future.value(<Selection>[]),
      seed == null ? Future.value(<Track>[]) : d.modules.related(seed, limit: 12).catchError((_) => <Track>[]),
      sc != null && sc.account.loggedIn ? sc.sc.feed().catchError((_) => <Track>[]) : Future.value(<Track>[]),
      // Rows of all other source modules.
      Future.wait([
        for (final m in d.modules.sources)
          if (m != sc) m.home().catchError((Object _) => <HomeSection>[]),
      ]).then((rows) => [for (final r in rows) ...r.where((s) => s.tracks.isNotEmpty)]),
    ).wait;
    return _HomeData(r.$1, seed, r.$2, r.$3.where((t) => t.playable).toList(), r.$4, d.modules.sources.isNotEmpty);
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() => _data = f);
    await f;
  }

  /// e.g. "Wednesday, 30 September" – a warm, natural date stamp.
  String _stamp(BuildContext c) {
    final now = DateTime.now();
    final lang = c.lang;
    return DateFormat('EEEE, d. MMMM', lang).format(now);
  }

  String _greeting(BuildContext c) {
    final h = DateTime.now().hour;
    final l = c.l10n;
    return h < 12 ? l.greetingMorning : (h < 18 ? l.greetingAfternoon : l.greetingEvening);
  }

  @override
  Widget build(BuildContext context) {
    final lib = context.deps.library;
    return Scaffold(
      body: ListenableBuilder(
        listenable: lib,
        builder: (context, _) => RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: StudioHeader(kicker: _stamp(context), title: _greeting(context)),
              ),
              if (lib.history.isNotEmpty) ...[
                SliverToBoxAdapter(child: SectionHeader(context.l10n.homeContinue)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisExtent: 64,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: lib.history.length.clamp(0, 6),
                    itemBuilder: (context, i) {
                      final tr = lib.history[i];
                      return StaggeredIn(
                        index: i,
                        child: PressableCard(
                          onTap: () => context.deps.player.playQueue(lib.history.take(30).toList(), i),
                          child: Material(
                            color: Studio.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius: Studio.br12,
                              side: BorderSide(color: Studio.line),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Artwork(tr.art('t67x67'), size: 54, radius: 8),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tr.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: Studio.sans,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Studio.text,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: FutureBuilder<_HomeData>(
                  future: _data,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return MessageView(
                        icon: Icons.cloud_off_rounded,
                        text: context.l10n.errorLoading,
                        action: FilledButton.tonal(onPressed: _refresh, child: Text(context.l10n.retry)),
                      );
                    }
                    final d = snap.data;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: d == null ? const _HomeSkeleton() : _HomeContent(d),
                    );
                  },
                ),
              ),
              // End of page: ASCII logo instead of empty space.
              const SliverToBoxAdapter(child: AsciiSignature()),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeData {
  _HomeData(this.selections, this.seed, this.related, this.feed, this.sections, this.hasSources);
  final List<Selection> selections;
  final List<Track> feed;
  final Track? seed;
  final List<Track> related;
  final List<HomeSection> sections;

  /// false: no source module active – only web radio and the local library.
  final bool hasSources;
}

class _HomeContent extends StatelessWidget {
  const _HomeContent(this.d);
  final _HomeData d;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (d.feed.isNotEmpty) ...[SectionHeader(context.l10n.homeStream), _TrackRow(d.feed)],
        if (d.related.isNotEmpty) ...[
          SectionHeader(context.l10n.homeBecauseYouPlayed(d.seed!.title)),
          _TrackRow(d.related),
        ],
        for (final s in d.selections) ...[
          SectionHeader(s.title),
          CardRow(height: 226, children: [for (final p in s.playlists) PlaylistCard(p)]),
        ],
        for (final s in d.sections) ...[SectionHeader(s.title), _TrackRow(s.tracks)],
        if (!d.hasSources)
          MessageView(icon: Icons.extension_rounded, text: context.l10n.homeNoSources),
      ],
    );
  }
}

/// Horizontal row of track cards; tapping plays from that point.
class _TrackRow extends StatelessWidget {
  const _TrackRow(this.tracks);
  final List<Track> tracks;

  @override
  Widget build(BuildContext context) {
    return CardRow(
      height: 216,
      children: [
        for (final (i, tr) in tracks.indexed)
          SizedBox(
            width: 148,
            child: PressableCard(
              onTap: () => context.deps.player.playQueue(tracks, i),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Artwork(tr.art('t300x300'), size: 148, radius: 14),
                  const SizedBox(height: 8),
                  Text(
                    tr.title,
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
                  Text(
                    tr.user.username,
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
          ),
      ],
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var r = 0; r < 3; r++) ...[
        const Padding(padding: EdgeInsets.fromLTRB(16, 28, 16, 12), child: Skeleton(width: 200, height: 20, radius: 10)),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (var i = 0; i < 6; i++)
                const Padding(
                  padding: EdgeInsetsDirectional.only(end: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Skeleton(width: 156, height: 156, radius: 14), SizedBox(height: 8), Skeleton(width: 120, radius: 6)],
                  ),
                ),
            ],
          ),
        ),
      ],
    ],
  );
}

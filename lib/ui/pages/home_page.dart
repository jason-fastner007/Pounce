import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../theme.dart';
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
  late final _account = context.deps.account;
  late bool _wasLoggedIn = _account.loggedIn;

  @override
  void initState() {
    super.initState();
    _account.addListener(_onAccount);
  }

  @override
  void dispose() {
    _account.removeListener(_onAccount);
    super.dispose();
  }

  void _onAccount() {
    if (_account.loggedIn != _wasLoggedIn) {
      _wasLoggedIn = _account.loggedIn;
      _refresh();
    }
  }

  Future<_HomeData> _load() async {
    final d = context.deps;
    final seed = d.library.history.firstOrNull ?? d.library.likes.firstOrNull;
    final r = await (
      d.sc.selections(),
      seed == null ? Future.value(<Track>[]) : d.sc.related(seed.id, limit: 12).catchError((_) => <Track>[]),
      d.account.loggedIn ? d.sc.feed().catchError((_) => <Track>[]) : Future.value(<Track>[]),
    ).wait;
    return _HomeData(r.$1, seed, r.$2, r.$3.where((t) => t.playable).toList());
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
  _HomeData(this.selections, this.seed, this.related, this.feed);
  final List<Selection> selections;
  final List<Track> feed;
  final Track? seed;
  final List<Track> related;
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
        const Padding(padding: EdgeInsetsDirectional.fromSTEB(16, 28, 16, 12), child: Skeleton(width: 200, height: 20, radius: 10)),
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

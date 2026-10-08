import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../sc/models.dart';
import '../../sc/soundcloud.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import '../widgets/track_tile.dart';

class ArtistPage extends StatelessWidget {
  const ArtistPage({super.key, required this.user});

  final ScUser user;

  Future<(ScUser, List<Track>, List<Track>, List<ScPlaylist>)> _load(SoundCloud sc) async {
    final r = await (
      sc.user(user.id),
      sc.userTopTracks(user.id),
      sc.userTracks(user.id),
      sc.userPlaylists(user.id).catchError((_) => const ScPage<ScPlaylist>([], null)),
    ).wait;
    return (r.$1, r.$2.items, r.$3.items, r.$4.items);
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.deps.soundcloud?.sc;
    final player = context.deps.player;
    final l = context.l10n;
    if (sc == null) return Scaffold(body: MessageView(icon: Icons.extension_off_rounded, text: l.moduleUnavailable));
    final t = Theme.of(context);

    return Scaffold(
      body: AsyncView(
        load: () => _load(sc),
        loading: _header(context, user, null),
        builder: (context, data) {
          final (u, top, all, lists) = data;
          return _header(context, u, [
            if (top.isNotEmpty) ...[
              SliverToBoxAdapter(child: SectionHeader(l.popularTracks)),
              SliverList.builder(
                itemCount: top.length.clamp(0, 5),
                itemBuilder: (_, i) => StaggeredIn(
                  index: i,
                  child: TrackTile(track: top[i], onTap: () => player.playQueue(top, i)),
                ),
              ),
            ],
            if (lists.isNotEmpty) ...[
              SliverToBoxAdapter(child: SectionHeader(l.playlists)),
              SliverToBoxAdapter(child: CardRow(height: 220, children: [for (final p in lists) PlaylistCard(p)])),
            ],
            if (all.isNotEmpty) ...[
              SliverToBoxAdapter(child: SectionHeader(l.tabTracks)),
              SliverList.builder(
                itemCount: all.length,
                itemBuilder: (_, i) => TrackTile(track: all[i], onTap: () => player.playQueue(all, i)),
              ),
            ],
            if (u.description?.isNotEmpty ?? false)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card.filled(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(u.description!, style: t.textTheme.bodyMedium),
                    ),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }

  Widget _header(BuildContext context, ScUser u, List<Widget>? content) {
    final t = Theme.of(context);
    final l = context.l10n;
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          expandedHeight: 280,
          title: Text(u.username),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (u.bannerUrl != null)
                  Image.network(u.bannerUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [t.colorScheme.surface.withValues(alpha: .2), t.colorScheme.surface],
                    ),
                  ),
                ),
                Align(
                  alignment: const AlignmentDirectional(-.85, .15),
                  child: Artwork(sized(u.avatarUrl, 't300x300'), size: 112, circle: true),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (u.verified) Icon(Icons.verified_rounded, color: t.colorScheme.primary, size: 20),
                Chip(
                  avatar: const Icon(Icons.people_alt_rounded),
                  label: Text(l.followers(fmtCompact(context, u.followers))),
                ),
                if (u.trackCount > 0)
                  Chip(avatar: const Icon(Icons.music_note_rounded), label: Text(l.tracksCount(u.trackCount))),
                if (u.city?.isNotEmpty ?? false) Chip(avatar: const Icon(Icons.place_rounded), label: Text(u.city!)),
              ],
            ),
          ),
        ),
        if (content == null)
          const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
        else
          ...content,
        const SliverToBoxAdapter(child: SizedBox(height: 160)),
      ],
    );
  }
}

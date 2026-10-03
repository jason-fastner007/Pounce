import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../theme.dart';
import '../nav.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import '../widgets/track_tile.dart';
import 'playlist_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = context.deps.library;
    final l = context.l10n;
    final t = Theme.of(context);

    Widget bigTile(int i, IconData icon, String title, String sub, List<Color> _, Widget page) => StaggeredIn(
      index: i,
      child: PressableCard(
        onTap: () => pushPage(context, page),
        child: Container(
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: Studio.panel(radius: Studio.br16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: t.colorScheme.primary.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.colorScheme.primary.withValues(alpha: .30)),
                ),
                child: Icon(icon, color: t.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: Studio.sans,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Studio.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
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
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () async {
            final name = await askText(context, l.newPlaylist, l.create);
            if (name != null) lib.createPlaylist(name);
          },
          icon: const Icon(Icons.add_rounded),
          label: Text(l.newPlaylist),
        ),
      ),
      body: ListenableBuilder(
        listenable: lib,
        builder: (context, _) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: StudioHeader(title: l.navLibrary),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 96,
                ),
                delegate: SliverChildListDelegate([
                  bigTile(0, Icons.favorite_rounded, l.likedTracks, l.tracksCount(lib.likes.length), [
                    t.colorScheme.primary,
                    t.colorScheme.tertiary,
                  ], const PlaylistPage.likes()),
                  bigTile(1, Icons.history_rounded, l.history, l.tracksCount(lib.history.length), [
                    t.colorScheme.secondary,
                    t.colorScheme.primary,
                  ], const PlaylistPage.history()),
                ]),
              ),
            ),
            // Playlists of the SoundCloud account
            SliverToBoxAdapter(
              child: ListenableBuilder(
                listenable: context.deps.account,
                builder: (context, _) {
                  final remote = context.deps.account.playlists;
                  if (remote.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader(l.scPlaylists),
                      CardRow(height: 226, children: [for (final p in remote) PlaylistCard(p)]),
                    ],
                  );
                },
              ),
            ),
            SliverToBoxAdapter(child: SectionHeader(l.playlists)),
            if (lib.playlists.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l.emptyPlaylists, textAlign: TextAlign.center, style: t.textTheme.bodyMedium),
                ),
              )
            else
              SliverList.builder(
                itemCount: lib.playlists.length,
                itemBuilder: (c, i) {
                  final p = lib.playlists[i];
                  return StaggeredIn(
                    index: i,
                    child: ListTile(
                      leading: p.tracks.isEmpty
                          ? Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: t.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(Icons.queue_music_rounded, color: t.colorScheme.onSecondaryContainer),
                            )
                          : Artwork(p.tracks.first.art('t67x67'), size: 56, radius: 4),
                      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(l.tracksCount(p.tracks.length)),
                      onTap: () => pushPage(c, PlaylistPage.local(p)),
                    ),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 180)),
          ],
        ),
      ),
    );
  }
}

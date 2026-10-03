import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../radio/radio_browser.dart';
import '../theme.dart';
import 'common.dart';
import 'studio.dart';

/// A station row: logo, name, country/quality, favourite. Tapping starts the stream.
class StationTile extends StatelessWidget {
  const StationTile({super.key, required this.station, required this.list});

  final RadioStation station;

  /// Becomes the queue: next/previous switches the station.
  final List<RadioStation> list;

  @override
  Widget build(BuildContext context) {
    final radio = context.deps.radio;
    final accent = Theme.of(context).colorScheme.primary;
    return ListenableBuilder(
      listenable: radio,
      builder: (context, _) {
        final fav = radio.isFavorite(station);
        return ListTile(
          leading: Artwork(station.favicon, size: 48, radius: 10),
          title: Text(station.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Mono(
            [station.flag, if (station.quality.isNotEmpty) station.quality, ...station.tags.take(2)].join(' · '),
            size: 11,
          ),
          trailing: IconButton(
            tooltip: context.l10n.radioFavorites,
            onPressed: () => radio.toggleFavorite(station),
            icon: Icon(fav ? Icons.star_rounded : Icons.star_border_rounded, color: fav ? accent : null),
          ),
          onTap: () => radio.play(station, list),
        );
      },
    );
  }
}

/// Station hits for a search. [compact]: only the best three (in "All"), with a link to all.
class RadioResults extends StatefulWidget {
  const RadioResults({super.key, required this.query, this.compact = false, this.onMore});

  final String query;
  final bool compact;
  final VoidCallback? onMore;

  @override
  State<RadioResults> createState() => _RadioResultsState();
}

class _RadioResultsState extends State<RadioResults> {
  late final Future<List<RadioStation>> _hits = context.deps.radio.search(widget.query);

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _hits,
    builder: (context, snap) {
      final list = snap.data ?? const <RadioStation>[];
      if (widget.compact) {
        // In "All" only show what's really there – no spinner, no placeholder.
        if (list.isEmpty) return const SizedBox.shrink();
        final top = list.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(context.l10n.radioSection.toUpperCase()),
            for (final s in top) StationTile(station: s, list: list),
            if (list.length > 3 && widget.onMore != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(onPressed: widget.onMore, child: Text(context.l10n.radioAll)),
              ),
          ],
        );
      }
      if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return MessageView(icon: Icons.wifi_off_rounded, text: context.l10n.errorLoading);
      if (list.isEmpty) return MessageView(icon: Icons.radio_rounded, text: context.l10n.noResults);
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 140),
        itemCount: list.length,
        itemBuilder: (_, i) => StaggeredIn(index: i, child: StationTile(station: list[i], list: list)),
      );
    },
  );
}

/// Web radio without a search term: favourite stations (instantly from the database) and most played.
class RadioHome extends StatefulWidget {
  const RadioHome({super.key});

  @override
  State<RadioHome> createState() => _RadioHomeState();
}

class _RadioHomeState extends State<RadioHome> {
  late final Future<List<RadioStation>> _top = context.deps.radio.topClick();

  @override
  Widget build(BuildContext context) {
    final radio = context.deps.radio;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: radio,
      builder: (context, _) => FutureBuilder(
        future: _top,
        builder: (context, snap) {
          final top = snap.data ?? const <RadioStation>[];
          return ListView(
            padding: const EdgeInsets.only(bottom: 140),
            children: [
              if (radio.favorites.isNotEmpty) ...[
                SectionHeader(l.radioFavorites),
                for (final s in radio.favorites) StationTile(station: s, list: radio.favorites),
              ],
              SectionHeader(l.radioTop),
              if (snap.connectionState != ConnectionState.done)
                const Padding(padding: EdgeInsets.all(Studio.s5), child: Center(child: CircularProgressIndicator()))
              else if (snap.hasError)
                MessageView(icon: Icons.wifi_off_rounded, text: l.errorLoading)
              else
                for (final (i, s) in top.indexed) StaggeredIn(index: i, child: StationTile(station: s, list: top)),
            ],
          );
        },
      ),
    );
  }
}

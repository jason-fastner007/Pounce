import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/store.dart';
import '../library/library.dart';
import '../player/player_controller.dart';
import '../modules/source_module.dart';
import 'dj_flow_controller.dart';
import 'taste.dart';

/// A category in the DJ tab: how Pounce recognises matching songs and what it searches for.
class DjCategory {
  const DjCategory(this.id, this.label, this.keywords, this.search, {this.minBpm, this.maxBpm});

  final String id;
  final String label;

  /// Matches in the genre tag or title (lower case).
  final List<String> keywords;

  /// Search term for new songs of this category.
  final String search;

  /// Expected tempo range (for already analysed likes without a matching tag).
  final double? minBpm, maxBpm;

  bool matches(Track t, {double? bpm}) {
    final text = '${t.genre ?? ''} ${t.title}'.toLowerCase();
    if (keywords.any(text.contains)) return true;
    return bpm != null && minBpm != null && maxBpm != null && bpm >= minBpm! && bpm <= maxBpm!;
  }

  static const all = [
    DjCategory('techno', 'Techno', ['techno', 'peak time', 'industrial'], 'techno', minBpm: 125, maxBpm: 142),
    DjCategory(
      'hardtechno',
      'Hard Techno',
      ['hard techno', 'hardtechno', 'hardtekk', 'tekk', 'schranz'],
      'hard techno',
      minBpm: 145,
      maxBpm: 170,
    ),
    DjCategory('house', 'House', ['house', 'tech house', 'jackin'], 'tech house', minBpm: 118, maxBpm: 130),
    DjCategory(
      'melodic',
      'Melodic & Deep',
      ['melodic', 'deep house', 'progressive', 'organic'],
      'melodic techno',
      minBpm: 115,
      maxBpm: 126,
    ),
    DjCategory('afro', 'Afro House', ['afro', 'amapiano'], 'afro house'),
    DjCategory(
      'dnb',
      'Drum & Bass',
      ['drum and bass', 'drum & bass', 'dnb', 'd&b', 'jungle', 'neurofunk'],
      'drum and bass',
      minBpm: 165,
      maxBpm: 180,
    ),
    DjCategory('trance', 'Trance', ['trance', 'psytrance', 'psy'], 'trance', minBpm: 130, maxBpm: 148),
    DjCategory('hiphop', 'Hip-Hop & Rap', ['hip hop', 'hip-hop', 'hiphop', 'rap', 'trap', 'deutschrap'], 'deutschrap'),
    DjCategory('remix', 'Bootlegs & Remixe', ['bootleg', 'remix', 'edit', 'flip'], 'techno bootleg'),
    DjCategory('chill', 'Chill', ['chill', 'lofi', 'lo-fi', 'ambient', 'downtempo'], 'chill', minBpm: 70, maxBpm: 112),
  ];
}

/// Builds a DJ mix from categories: seed songs from your own likes, extended via
/// "similar tracks" and a category search. [discovery] controls the ratio of familiar
/// to new. DJ Flow then keeps ordering the result by key, tempo and energy.
class MixBuilder extends ChangeNotifier {
  MixBuilder({
    required this.sources,
    required this.library,
    required this.player,
    required this.dj,
    required this.store,
    required this.taste,
  });

  final TrackSource sources;
  final Library library;
  final PlayerController player;
  final DjFlowController dj;
  final Store store;
  final TasteModel taste;

  /// Selected categories (persisted).
  Set<String> get selected => {...?store.get<List>('dj_categories')?.cast<String>()};
  set selected(Set<String> v) {
    store.set('dj_categories', v.toList());
    notifyListeners();
  }

  void toggle(String id) {
    final s = selected;
    s.contains(id) ? s.remove(id) : s.add(id);
    selected = s;
  }

  /// 0 = favourites only … 1 = new only (default 0.6).
  double get discovery => (store.get<num>('dj_discovery') ?? .6).toDouble();
  set discovery(double v) {
    store.set('dj_discovery', v);
    notifyListeners();
  }

  bool building = false;
  String? error;

  /// Length of a mix.
  static const size = 50;

  /// Builds the mix and starts it with DJ Flow. Returns the number of songs (0 = nothing found).
  Future<int> start() async {
    final cats = DjCategory.all.where((c) => selected.contains(c.id)).toList();
    if (cats.isEmpty || building) return 0;
    building = true;
    error = null;
    notifyListeners();
    try {
      final tracks = await build(cats);
      if (tracks.isEmpty) return 0;
      if (!dj.state.isActive) dj.toggleDjFlow();
      await player.playQueue(tracks);
      return tracks.length;
    } catch (e) {
      error = '$e';
      return 0;
    } finally {
      building = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  Future<List<Track>> build(List<DjCategory> cats) async {
    final rnd = math.Random();
    bool fits(Track t) => cats.any((c) => c.matches(t, bpm: dj.analyzer.peek(t)?.bpm));
    // Don't repeat recently played songs right away.
    final recent = {for (final t in library.history.take(30)) t.id};

    // What was learned: songs skipped early never; otherwise by preference – with some randomness so
    // the mix isn't always the same and new things get a chance (experimenting).
    final prefs = <int, double>{};
    double pref(Track t) => prefs[t.id] ??= taste.score(t, dj.analyzer.peek(t)) + rnd.nextDouble() * .35;
    bool ok(Track t) => usable(t) && !taste.isBanned(t);

    final favorites = library.likes.where((t) => ok(t) && fits(t)).toList()..shuffle(rnd);
    favorites.sort((a, b) => pref(b).compareTo(pref(a)));

    // New: "similar tracks" for a few favourites, plus the search per category.
    final seeds = favorites.take(6).toList();
    final results = await Future.wait([
      for (final s in seeds) sources.related(s, limit: 25).catchError((Object _) => <Track>[]),
      for (final c in cats) sources.search(c.search).catchError((Object _) => <Track>[]),
    ]);
    final liked = {for (final t in library.likes) t.id};
    final fresh = <int, Track>{};
    for (final list in results) {
      for (final t in list) {
        if (ok(t) && !liked.contains(t.id) && !recent.contains(t.id)) fresh[t.id] = t;
      }
    }
    // New songs of the category first; similar ones without a matching tag only if there are too few.
    final freshList = fresh.values.toList();
    double rank(Track t) => (fits(t) ? 1 : 0) + pref(t);
    freshList.sort((a, b) => rank(b).compareTo(rank(a)));

    return mix(favorites.where((t) => !recent.contains(t.id)).toList(), freshList, discovery, size);
  }

  /// Usable for a DJ mix: complete songs (1:30–6:00), no previews, no mixes.
  static bool usable(Track t) =>
      t.playable && !t.isLive && !t.isPreview && t.durationMs >= 90000 && t.durationMs <= 6 * 60000;

  /// Interleaves favourites and new songs in the ratio [discovery] (share of new), starting with a
  /// favourite – the first song should feel familiar.
  static List<Track> mix(List<Track> favorites, List<Track> fresh, double discovery, int size) {
    final out = <Track>[];
    var f = 0, n = 0;
    while (out.length < size && (f < favorites.length || n < fresh.length)) {
      final wantFresh =
          out.isNotEmpty && n < fresh.length && (f >= favorites.length || n < (out.length + 1) * discovery);
      if (wantFresh) {
        out.add(fresh[n++]);
      } else if (f < favorites.length) {
        out.add(favorites[f++]);
      } else {
        out.add(fresh[n++]);
      }
    }
    return out;
  }
}

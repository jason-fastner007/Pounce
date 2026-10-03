import 'package:flutter/foundation.dart';

import '../core/store.dart';
import '../sc/models.dart';

class LocalPlaylist {
  LocalPlaylist({required this.id, required this.name, List<Track>? tracks}) : tracks = tracks ?? [];

  final String id;
  String name;
  final List<Track> tracks;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tracks': [for (final t in tracks) t.toJson()],
  };

  factory LocalPlaylist.fromJson(Map<String, dynamic> j) =>
      LocalPlaylist(id: j['id'] as String, name: j['name'] as String, tracks: _tracks(j['tracks']));
}

List<Track> _tracks(Object? raw) => [
  for (final e in (raw as List? ?? const [])) Track.fromJson((e as Map).cast<String, dynamic>()),
];

/// Local library: likes, history, own playlists, search history.
/// No account needed – everything stays on the device.
class Library extends ChangeNotifier {
  Library(this._store)
    : likes = _tracks(_store.get<List>('lib.likes')),
      history = _tracks(_store.get<List>('lib.history')),
      playlists = [
        for (final e in _store.get<List>('lib.playlists') ?? const [])
          LocalPlaylist.fromJson((e as Map).cast<String, dynamic>()),
      ],
      searches = [for (final e in _store.get<List>('lib.searches') ?? const []) e as String];

  final Store _store;
  final List<Track> likes;
  final List<Track> history;
  final List<LocalPlaylist> playlists;
  final List<String> searches;

  static const _maxHistory = 300;

  /// Called on every (un)like, e.g. for the account sync.
  void Function(Track track, bool liked)? onLikeChanged;
  final List<void Function(Track track, bool liked)> _likeListeners = [];
  final List<void Function(Track track)> _historyListeners = [];

  void addLikeListener(void Function(Track track, bool liked) l) => _likeListeners.add(l);
  void removeLikeListener(void Function(Track track, bool liked) l) => _likeListeners.remove(l);
  void addHistoryListener(void Function(Track track) l) => _historyListeners.add(l);
  void removeHistoryListener(void Function(Track track) l) => _historyListeners.remove(l);

  bool isLiked(Track t) => likes.any((e) => e.id == t.id);

  void toggleLike(Track t) {
    final liked = !likes.remove(t);
    if (liked) likes.insert(0, t);
    _save('lib.likes', likes);
    onLikeChanged?.call(t, liked);
    for (final l in List.of(_likeListeners)) {
      l(t, liked);
    }
  }

  /// Replace likes completely (after reconciling with the account).
  void replaceLikes(List<Track> list) {
    likes
      ..clear()
      ..addAll(list.toSet());
    _save('lib.likes', likes);
  }

  void addHistory(Track t) {
    history
      ..remove(t)
      ..insert(0, t);
    if (history.length > _maxHistory) history.removeRange(_maxHistory, history.length);
    _save('lib.history', history);
    for (final l in List.of(_historyListeners)) {
      l(t);
    }
  }

  void clearHistory() {
    history.clear();
    _save('lib.history', history);
  }

  void addSearch(String q) {
    searches
      ..remove(q)
      ..insert(0, q);
    if (searches.length > 12) searches.removeLast();
    _store.set('lib.searches', searches);
    notifyListeners();
  }

  void removeSearch(String q) {
    searches.remove(q);
    _store.set('lib.searches', searches);
    notifyListeners();
  }

  LocalPlaylist createPlaylist(String name) {
    final p = LocalPlaylist(id: DateTime.now().microsecondsSinceEpoch.toRadixString(36), name: name);
    playlists.insert(0, p);
    _savePlaylists();
    return p;
  }

  void renamePlaylist(LocalPlaylist p, String name) {
    p.name = name;
    _savePlaylists();
  }

  void deletePlaylist(LocalPlaylist p) {
    playlists.remove(p);
    _savePlaylists();
  }

  /// true = added, false = was already in it.
  bool addToPlaylist(LocalPlaylist p, Track t) {
    if (p.tracks.contains(t)) return false;
    p.tracks.add(t);
    _savePlaylists();
    return true;
  }

  void removeFromPlaylist(LocalPlaylist p, Track t) {
    p.tracks.remove(t);
    _savePlaylists();
  }

  void reorder(LocalPlaylist p, int from, int to) {
    final t = p.tracks.removeAt(from);
    p.tracks.insert(to, t);
    _savePlaylists();
  }

  void _save(String key, List<Track> list) {
    _store.set(key, [for (final t in list) t.toJson()]);
    notifyListeners();
  }

  void _savePlaylists() {
    _store.set('lib.playlists', [for (final p in playlists) p.toJson()]);
    notifyListeners();
  }
}

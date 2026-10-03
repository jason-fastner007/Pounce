import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/platform.dart';
import '../core/settings.dart';
import '../core/store.dart';
import '../player/player_controller.dart';
import 'radio_browser.dart';

/// Region for the start list: language (Radio Browser `language`) or country (ISO code).
@immutable
class RadioRegion {
  const RadioRegion(this.id, this.label, this.flag, {this.language, this.country});

  final String id;
  final String label;
  final String flag;
  final String? language;
  final String? country;

  static const all = [
    RadioRegion('de', 'Deutsch', '🇩🇪', language: 'german'),
    RadioRegion('en', 'English', '🇬🇧', language: 'english'),
    RadioRegion('us', 'USA', '🇺🇸', country: 'US'),
    RadioRegion('ru', 'Русский', '🇷🇺', language: 'russian'),
    RadioRegion('fr', 'Français', '🇫🇷', language: 'french'),
    RadioRegion('es', 'Español', '🇪🇸', language: 'spanish'),
    RadioRegion('it', 'Italiano', '🇮🇹', language: 'italian'),
    RadioRegion('nl', 'Nederlands', '🇳🇱', language: 'dutch'),
    RadioRegion('pl', 'Polski', '🇵🇱', language: 'polish'),
    RadioRegion('tr', 'Türkçe', '🇹🇷', language: 'turkish'),
    RadioRegion('uk', 'Українська', '🇺🇦', language: 'ukrainian'),
    RadioRegion('hu', 'Magyar', '🇭🇺', language: 'hungarian'),
    RadioRegion('vi', 'Tiếng Việt', '🇻🇳', language: 'vietnamese'),
    RadioRegion('ar', 'العربية', '🇸🇦', language: 'arabic'),
  ];

  static RadioRegion? byId(String id) => all.where((r) => r.id == id).firstOrNull;
}

/// Radio: regions, top lists (cached in memory), search, favourites (database).
class RadioService extends ChangeNotifier {
  RadioService(this._api, this._store, this._settings, this._player) {
    _loadFavorites();
  }

  final RadioBrowser _api;
  final Store _store;
  final Settings _settings;
  final PlayerController _player;

  /// Selected regions (empty = not set up yet → choice on first open).
  List<RadioRegion> get regions => [
    for (final id in _store.get<List>('radio.regions') ?? const []) ?RadioRegion.byId(id as String),
  ];

  bool get configured => _store.get<List>('radio.regions') != null;

  set regions(List<RadioRegion> v) {
    _store.set('radio.regions', [for (final r in v) r.id]);
    _top.clear();
    notifyListeners();
  }

  /// Suggestion for the first choice, based on the app language.
  List<RadioRegion> suggestedRegions(String languageCode) {
    final r = RadioRegion.byId(languageCode);
    return [?r, if (r?.id != 'en') RadioRegion.all[1]];
  }

  final _top = <String, Future<List<RadioStation>>>{};

  Future<List<RadioStation>> top(RadioRegion r) => _top[r.id] ??= (r.country != null
          ? _api.topByCountry(r.country!)
          : _api.topByLanguage(r.language!))
      .catchError((Object e) {
        _top.remove(r.id); // don't cache errors
        throw e;
      });

  Future<List<RadioStation>> search(String q) => _api.search(q);

  Future<List<RadioStation>>? _topClick;

  /// Most played stations worldwide (loaded once per session).
  Future<List<RadioStation>> topClick() => _topClick ??= _api.topClick().catchError((Object e) {
    _topClick = null; // don't cache errors
    throw e;
  });

  // ---------- Favoriten ----------

  final favorites = <RadioStation>[];

  Future<void> _loadFavorites() async {
    final rows = await _store.db.all(Table.radio);
    final list = <(int, RadioStation)>[];
    for (final v in rows.values) {
      try {
        final j = jsonDecode(v) as Map<String, dynamic>;
        list.add(((j['order'] as num?)?.toInt() ?? 0, RadioStation.fromJson(j)));
      } catch (_) {}
    }
    list.sort((a, b) => a.$1.compareTo(b.$1));
    favorites
      ..clear()
      ..addAll(list.map((e) => e.$2));
    notifyListeners();
  }

  bool isFavorite(RadioStation s) => favorites.any((f) => f.uuid == s.uuid);

  void toggleFavorite(RadioStation s) {
    final had = isFavorite(s);
    if (had) {
      favorites.removeWhere((f) => f.uuid == s.uuid);
      _store.db.write(Table.radio, {s.uuid: null});
    } else {
      favorites.insert(0, s);
      _saveOrder();
    }
    notifyListeners();
  }

  void reorderFavorites(int from, int to) {
    favorites.insert(to, favorites.removeAt(from));
    _saveOrder();
    notifyListeners();
  }

  void _saveOrder() => _store.db.write(Table.radio, {
    for (final (i, f) in favorites.indexed) f.uuid: jsonEncode({...f.toJson(), 'order': i}),
  });

  // ---------- Playback ----------

  /// Plays [station]; [list] becomes the queue (next/previous switches the station).
  Future<void> play(RadioStation station, List<RadioStation> list) {
    final i = list.indexWhere((s) => s.uuid == station.uuid);
    unawaited(_api.click(station.uuid));
    return _player.playQueue([for (final s in list) s.toTrack(streamUrl: _streamUrl)], i < 0 ? 0 : i);
  }

  /// In the browser, https pages block http streams ("mixed content"): route them through the proxy,
  /// otherwise hope for https (many stations support both).
  String _streamUrl(String url) {
    if (!Platform.isWeb || !url.startsWith('http://')) return url;
    final proxy = _settings.proxy;
    if (proxy.isNotEmpty) return Uri.base.resolve('$proxy${Uri.encodeComponent(url)}&radio=1').toString();
    return url.replaceFirst('http://', 'https://');
  }
}

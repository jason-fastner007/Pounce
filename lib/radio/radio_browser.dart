import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/platform.dart';
import 'mirrors_io.dart' if (dart.library.js_interop) 'mirrors_web.dart';
import '../sc/models.dart';

/// A station from the Radio Browser directory (radio-browser.info).
class RadioStation {
  const RadioStation({
    required this.uuid,
    required this.name,
    required this.url,
    this.favicon,
    this.homepage,
    this.tags = const [],
    this.countryCode,
    this.language,
    this.codec,
    this.bitrate = 0,
    this.hls = false,
    this.votes = 0,
    this.clicks = 0,
  });

  final String uuid;
  final String name;

  /// Directly playable stream URL (`url_resolved`).
  final String url;
  final String? favicon;
  final String? homepage;
  final List<String> tags;
  final String? countryCode;
  final String? language;
  final String? codec;
  final int bitrate;
  final bool hls;
  final int votes;
  final int clicks;

  /// z. B. "MP3 · 128k"
  String get quality => [if (codec != null && codec!.isNotEmpty) codec!, if (bitrate > 0) '${bitrate}k'].join(' · ');

  /// Flag from the country code (DE -> 🇩🇪).
  String get flag {
    final c = countryCode;
    if (c == null || c.length != 2) return '📻';
    return String.fromCharCodes(c.toUpperCase().codeUnits.map((u) => 0x1F1E6 + u - 65));
  }

  factory RadioStation.fromJson(Map<String, dynamic> j) {
    String? str(String k) {
      final v = (j[k] as String?)?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    final resolved = str('url_resolved') ?? str('url') ?? '';
    return RadioStation(
      uuid: j['stationuuid'] as String? ?? resolved,
      name: (str('name') ?? 'Radio').replaceAll(RegExp(r'\s+'), ' '),
      url: resolved,
      favicon: str('favicon'),
      homepage: str('homepage'),
      tags: [
        for (final t in (str('tags') ?? '').split(','))
          // Some entries literally have "undefined"/"null" as a tag.
          if (t.trim().isNotEmpty && !const {'undefined', 'null'}.contains(t.trim().toLowerCase())) t.trim(),
      ],
      countryCode: str('countrycode'),
      language: str('language'),
      codec: str('codec'),
      bitrate: (j['bitrate'] as num?)?.toInt() ?? 0,
      hls: j['hls'] == 1 || j['hls'] == true,
      votes: (j['votes'] as num?)?.toInt() ?? 0,
      clicks: (j['clickcount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'stationuuid': uuid,
    'name': name,
    'url_resolved': url,
    'favicon': favicon,
    'homepage': homepage,
    'tags': tags.join(','),
    'countrycode': countryCode,
    'language': language,
    'codec': codec,
    'bitrate': bitrate,
    'hls': hls ? 1 : 0,
    'votes': votes,
    'clickcount': clicks,
  };

  /// Stable (negative) ID so stations in queue/history don't collide with SoundCloud IDs.
  int get trackId {
    var h = 0x811C9DC5;
    for (final c in uuid.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7FFFFFFF;
    }
    return -(h + 1);
  }

  /// As a playable live "track" for player, queue and media controls.
  Track toTrack({String Function(String url)? streamUrl}) => Track(
    id: trackId,
    title: name,
    user: ScUser(id: 0, username: [if (countryCode != null) flag, ...tags.take(2)].join(' · ')),
    durationMs: 0,
    artworkUrl: favicon,
    permalinkUrl: homepage,
    genre: tags.firstOrNull,
    streamUrl: streamUrl?.call(url) ?? url,
    source: Track.radio,
  );
}

/// Lean client for the free Radio Browser API (CORS allowed, no keys).
class RadioBrowser {
  RadioBrowser(this._http, {Future<List<String>> Function()? mirrors}) : _mirrors = mirrors ?? discoverMirrors;
  final http.Client _http;
  final Future<List<String>> Function() _mirrors;

  /// Fallback if the DNS lookup fails (or in the browser).
  static const _fallback = [
    'de1.api.radio-browser.info',
    'de2.api.radio-browser.info',
    'fi1.api.radio-browser.info',
    'all.api.radio-browser.info',
  ];
  List<String> _servers = _fallback;
  Future<void>? _discovery;
  var _server = 0;

  /// Determine mirrors once via DNS (only on the first request – no radio, no lookup).
  Future<void> _discover() => _discovery ??= _mirrors()
      .then((found) {
        if (found.isNotEmpty) _servers = [...found, ..._fallback.where((h) => !found.contains(h))];
      })
      .catchError((Object _) {});

  Future<List<RadioStation>> _stations(String path, Map<String, String> query) async {
    await _discover();
    Object? last;
    for (var attempt = 0; attempt < _servers.length; attempt++) {
      final host = _servers[(_server + attempt) % _servers.length];
      try {
        final res = await _http
            .get(
              Uri.https(host, path, {'hidebroken': 'true', ...query}),
              headers: {if (!Platform.isWeb) 'User-Agent': 'Pounce/0.2 (GPL-3.0)'},
            )
            .timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
        _server = (_server + attempt) % _servers.length; // remember the working server
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        return [
          for (final e in list)
            if (e is Map<String, dynamic> && ((e['url_resolved'] as String?)?.isNotEmpty ?? false))
              RadioStation.fromJson(e),
        ];
      } catch (e) {
        last = e;
      }
    }
    throw Exception('Radio Browser unreachable: $last');
  }

  /// Most popular stations of a language (e.g. "german").
  Future<List<RadioStation>> topByLanguage(String language, {int limit = 40}) => _stations('/json/stations/search', {
    'language': language,
    'languageExact': 'true',
    'order': 'clickcount',
    'reverse': 'true',
    'limit': '$limit',
  });

  /// Most popular stations of a country (ISO code, e.g. "DE").
  Future<List<RadioStation>> topByCountry(String code, {int limit = 40}) => _stations('/json/stations/search', {
    'countrycode': code,
    'order': 'clickcount',
    'reverse': 'true',
    'limit': '$limit',
  });

  /// Search by name or tag.
  Future<List<RadioStation>> search(String q, {int limit = 50}) async {
    final byName = _stations('/json/stations/search', {
      'name': q,
      'order': 'clickcount',
      'reverse': 'true',
      'limit': '$limit',
    });
    final byTag = _stations('/json/stations/search', {
      'tag': q.toLowerCase(),
      'order': 'clickcount',
      'reverse': 'true',
      'limit': '20',
    }).catchError((_) => <RadioStation>[]);
    final r = await (byName, byTag).wait;
    final seen = <String>{};
    return [
      for (final s in [...r.$1, ...r.$2])
        if (seen.add(s.uuid)) s,
    ];
  }

  /// Most played stations worldwide.
  Future<List<RadioStation>> topClick({int limit = 50}) => _stations('/json/stations/topclick/$limit', const {});

  /// Stations with exactly this tag (e.g. "techno"), most popular first.
  Future<List<RadioStation>> byTag(String tag, {int limit = 50}) => _stations(
    '/json/stations/bytag/${Uri.encodeComponent(tag.toLowerCase())}',
    {'order': 'clickcount', 'reverse': 'true', 'limit': '$limit'},
  );

  /// Stations of a country (exact ISO code), most popular first.
  Future<List<RadioStation>> byCountryCodeExact(String code, {int limit = 50}) => _stations(
    '/json/stations/bycountrycodeexact/${code.toUpperCase()}',
    {'order': 'clickcount', 'reverse': 'true', 'limit': '$limit'},
  );

  /// For the global search: a few hits by name, most voted first.
  Future<List<RadioStation>> searchByName(String q, {int limit = 10}) =>
      _stations('/json/stations/search', {'name': q, 'order': 'votes', 'reverse': 'true', 'limit': '$limit'});

  /// Reports a click (that's how Radio Browser counts popularity). Errors don't matter.
  Future<void> click(String uuid) async {
    try {
      await _http
          .get(Uri.https(_servers[_server], '/json/url/$uuid'),
              headers: {if (!Platform.isWeb) 'User-Agent': 'Pounce/0.2 (GPL-3.0)'})
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }
}

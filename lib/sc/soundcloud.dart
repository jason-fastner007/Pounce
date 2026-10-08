import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/platform.dart';
import '../core/proxy.dart';
import '../core/settings.dart';
import '../core/store.dart';
import 'auth.dart';
import '../player/stream_info.dart';
import 'models.dart';

export '../player/stream_info.dart';

class ScException implements Exception {
  ScException(this.message, [this.status]);
  final String message;
  final int? status;
  @override
  String toString() => 'ScException($status): $message';
}

/// Page with a cursor for endless lists.
class ScPage<T> {
  const ScPage(this.items, this.next);
  final List<T> items;
  final String? next;
}

/// Lean SoundCloud client (api-v2). Guest mode or signed in via [auth].
class SoundCloud {
  SoundCloud(this._store, this._settings, {http.Client? client}) : _http = client ?? http.Client();

  static const _api = 'https://api-v2.soundcloud.com';
  static const _ua =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/140.0 Safari/537.36';
  static const _idTtl = Duration(hours: 12);

  final Store _store;
  final Settings _settings;
  final http.Client _http;
  Future<String>? _idJob;

  /// Set = requests run with the user's account.
  ScAuth? auth;

  /// Language for localised content (home page etc.).
  String language = 'en';

  // ---------- Transport ----------

  /// Web: route the request through the CORS proxy.
  Uri wrap(Uri uri) => corsProxy(_settings)(uri);

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    // Browsers set the User-Agent themselves.
    if (!Platform.isWeb) 'User-Agent': _ua,
  };

  Future<String> clientId({bool refresh = false}) {
    if (!refresh) {
      final cached = _store.get<String>('sc.cid');
      final at = _store.get<int>('sc.cidAt') ?? 0;
      final fresh = DateTime.now().millisecondsSinceEpoch - at < _idTtl.inMilliseconds;
      if (cached != null && fresh) return Future.value(cached);
    }
    return _idJob ??= _scrapeClientId().whenComplete(() => _idJob = null);
  }

  /// Fetches the current web client ID from soundcloud.com's JS bundles.
  Future<String> _scrapeClientId() async {
    final page = await _http.get(wrap(Uri.parse('https://soundcloud.com/')), headers: _headers);
    final scripts = RegExp(r'https://a-v2\.sndcdn\.com/assets/[^"]+\.js')
        .allMatches(page.body)
        .map((m) => m.group(0)!)
        .toList()
        .reversed; // the ID is usually in the last bundles.
    final idRe = RegExp(r'client_id\s*[:=]\s*"([A-Za-z0-9]{32})"');
    for (final src in scripts) {
      final js = await _http.get(wrap(Uri.parse(src)), headers: _headers);
      final m = idRe.firstMatch(js.body);
      if (m != null) {
        final id = m.group(1)!;
        _store
          ..set('sc.cid', id)
          ..set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);
        return id;
      }
    }
    throw ScException('client_id not found');
  }

  Future<dynamic> _get(String pathOrUrl, [Map<String, Object?>? query]) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final token = await auth?.token();
      // Signed in: official app client + OAuth, otherwise the web client ID.
      final id = token != null ? auth!.requestClientId : await clientId(refresh: attempt > 0);
      final base = Uri.parse(pathOrUrl.startsWith('http') ? pathOrUrl : '$_api$pathOrUrl');
      final uri = base.replace(
        queryParameters: {
          ...base.queryParameters,
          for (final e in (query ?? const {}).entries)
            if (e.value != null) e.key: '${e.value}',
          'client_id': id,
          'app_locale': language,
        },
      );
      final res = await _http.get(
        wrap(uri),
        headers: {..._headers, if (token != null) 'Authorization': 'OAuth $token'},
      );
      if ((res.statusCode == 401 || res.statusCode == 403) && attempt == 0) {
        // Token or client ID expired -> refresh and retry.
        if (token != null) await auth!.refresh();
        continue;
      }
      if (res.statusCode >= 400) {
        throw ScException(res.reasonPhrase ?? 'HTTP', res.statusCode);
      }
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    throw ScException('unauthorized', 401);
  }

  Future<ScPage<T>> _page<T>(String path, T Function(Map<String, dynamic>) map, [Map<String, Object?>? query]) async {
    final j = await _get(path, query) as Map<String, dynamic>;
    final items = <T>[];
    for (final e in (j['collection'] as List? ?? const [])) {
      try {
        items.add(map(e as Map<String, dynamic>));
      } catch (_) {
        /* skip unknown format */
      }
    }
    return ScPage(items, j['next_href'] as String?);
  }

  /// Schreibende Anfrage an api-mobile (Likes). Nur angemeldet.
  Future<void> _mobile(String path, Map<String, Object?> body) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final token = await auth?.token();
      if (token == null) throw ScException('not_logged_in', 401);
      final res = await _http.post(
        wrap(Uri.parse('https://api-mobile.soundcloud.com$path')),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'OAuth $token',
          if (!Platform.isWeb) 'User-Agent': 'SoundCloud/2025.12.10-release (Android 14; Pixel)',
          'App-Version': '330120',
          'UDID': auth!.deviceId,
        },
        body: jsonEncode(body),
      );
      if (res.statusCode == 401 && attempt == 0) {
        await auth!.refresh();
        continue;
      }
      if (res.statusCode >= 400) throw ScException(res.reasonPhrase ?? 'HTTP', res.statusCode);
      return;
    }
  }

  Future<ScPage<T>> next<T>(String href, T Function(Map<String, dynamic>) map) => _page(href, map);

  // ---------- Endpunkte ----------

  Future<ScPage<Track>> searchTracks(String q) => _page('/search/tracks', Track.fromJson, {'q': q, 'limit': 30});

  Future<ScPage<ScPlaylist>> searchPlaylists(String q) =>
      _page('/search/playlists_without_albums', ScPlaylist.fromJson, {'q': q, 'limit': 20});

  Future<ScPage<ScPlaylist>> searchAlbums(String q) =>
      _page('/search/albums', ScPlaylist.fromJson, {'q': q, 'limit': 20});

  Future<ScPage<ScUser>> searchUsers(String q) => _page('/search/users', ScUser.fromJson, {'q': q, 'limit': 20});

  Future<List<String>> suggestions(String q) async {
    final j = await _get('/search/queries', {'q': q, 'limit': 8});
    return [for (final e in (j['collection'] as List? ?? const [])) e['output'] as String];
  }

  Future<List<Selection>> selections() async {
    final j = await _get('/mixed-selections', {'limit': 10});
    final out = <Selection>[];
    for (final s in (j['collection'] as List? ?? const [])) {
      final items = (s['items']?['collection'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .where((e) => e['kind'] == 'playlist' || e['kind'] == 'system-playlist')
          .where((e) => e['id'] is int)
          .map(ScPlaylist.fromJson)
          .toList();
      if (items.isNotEmpty) {
        out.add(Selection(title: s['title'] as String? ?? '', playlists: items));
      }
    }
    return out;
  }

  Future<List<Track>> related(int trackId, {int limit = 20}) async =>
      (await _page('/tracks/$trackId/related', Track.fromJson, {'limit': limit})).items;

  Future<Track> track(int id) async => Track.fromJson(await _get('/tracks/$id') as Map<String, dynamic>);

  /// Loads tracks by ID (the API allows at most 50 per request).
  Future<List<Track>> tracks(List<int> ids) async {
    final byId = <int, Track>{};
    for (var i = 0; i < ids.length; i += 50) {
      final chunk = ids.sublist(i, (i + 50).clamp(0, ids.length));
      final j = await _get('/tracks', {'ids': chunk.join(',')}) as List;
      for (final e in j) {
        final t = Track.fromJson(e as Map<String, dynamic>);
        byId[t.id] = t;
      }
    }
    return [for (final id in ids) ?byId[id]];
  }

  Future<ScPlaylist> playlist(int id) async {
    final p = ScPlaylist.fromJson(await _get('/playlists/$id') as Map<String, dynamic>);
    final stubs = p.tracks.where((t) => t.isStub).map((t) => t.id).toList();
    if (stubs.isEmpty) return p;
    final full = {for (final t in await tracks(stubs)) t.id: t};
    return p.copyWith(
      tracks: [for (final t in p.tracks) t.isStub ? full[t.id] ?? t : t].where((t) => !t.isStub).toList(),
    );
  }

  Future<ScUser> user(int id) async => ScUser.fromJson(await _get('/users/$id') as Map<String, dynamic>);

  Future<ScPage<Track>> userTracks(int id) => _page('/users/$id/tracks', Track.fromJson, {'limit': 30});

  Future<ScPage<Track>> userTopTracks(int id) => _page('/users/$id/toptracks', Track.fromJson, {'limit': 10});

  Future<ScPage<ScPlaylist>> userPlaylists(int id) =>
      _page('/users/$id/playlists_without_albums', ScPlaylist.fromJson, {'limit': 20});

  /// soundcloud.com link -> track/playlist/user.
  Future<Resolved?> resolve(String url) async {
    final j = await _get('/resolve', {'url': url}) as Map<String, dynamic>;
    return switch (j['kind']) {
      'track' => ResolvedTrack(Track.fromJson(j)),
      'playlist' => ResolvedPlaylist(await playlist(j['id'] as int)),
      'user' => ResolvedUser(ScUser.fromJson(j)),
      _ => null,
    };
  }

  /// Waveforms of recently used tracks (seek bar, visualisation and mix points share them).
  final _waves = <int, Future<List<double>>>{};

  /// Waveform (0..1) for the seek bar. Errors return an empty list.
  Future<List<double>> waveform(Track t) {
    final hit = _waves.remove(t.id);
    if (hit != null) return _waves[t.id] = hit; // ans Ende = zuletzt benutzt
    if (_waves.length >= 48) _waves.remove(_waves.keys.first);
    return _waves[t.id] = _loadWaveform(t).catchError((_) => <double>[]);
  }

  Future<List<double>> _loadWaveform(Track t) async {
    final url = t.waveformUrl;
    if (url == null) return const [];
    final res = await _http.get(wrap(Uri.parse(url.replaceFirst('.png', '.json'))));
    if (res.statusCode != 200) return const [];
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final h = (j['height'] as num?)?.toDouble() ?? 140;
    return [for (final s in j['samples'] as List) (s as num) / h];
  }

  // ---------- Konto ----------

  Future<ScUser> me() async => ScUser.fromJson(await _get('/me') as Map<String, dynamic>);

  /// All likes of the account (newest first).
  Future<List<Track>> myLikes(int userId, {int max = 1000}) async {
    final out = <Track>[];
    String? next = '/users/$userId/track_likes?limit=200&linked_partitioning=1';
    while (next != null && out.length < max) {
      final p = await _page(next, (j) => Track.fromJson(j['track'] as Map<String, dynamic>));
      out.addAll(p.items);
      next = p.next;
    }
    return out;
  }

  /// Own + liked playlists.
  Future<List<ScPlaylist>> myPlaylists(int userId) async {
    final r = await (
      userPlaylists(userId),
      _page('/users/$userId/playlist_likes', (j) => ScPlaylist.fromJson(j['playlist'] as Map<String, dynamic>), {
        'limit': 50,
      }).catchError((_) => const ScPage<ScPlaylist>([], null)),
    ).wait;
    return [...r.$1.items, ...r.$2.items];
  }

  /// "Your stream": tracks and reposts from followed artists.
  Future<List<Track>> feed() async {
    final p = await _page('/stream', (j) => Track.fromJson(j['track'] as Map<String, dynamic>), {'limit': 40});
    return p.items;
  }

  Future<void> setLiked(Track t, bool liked) async {
    final a = auth;
    // Web client: api-v2 like soundcloud.com itself.
    if (a != null && a.usesWebClient && a.me != null) {
      final token = await a.token();
      final uri = Uri.parse('$_api/users/${a.me!.id}/track_likes/${t.id}?client_id=${a.requestClientId}');
      final headers = {'Authorization': 'OAuth $token', 'Accept': 'application/json'};
      final res = liked
          ? await _http.put(wrap(uri), headers: headers)
          : await _http.delete(wrap(uri), headers: headers);
      if (res.statusCode >= 400) throw ScException(res.reasonPhrase ?? 'HTTP', res.statusCode);
      return;
    }
    return _mobileLike(t, liked);
  }

  Future<void> _mobileLike(Track t, bool liked) => _mobile('/likes/tracks/${liked ? 'create' : 'delete'}', {
    'likes': [
      {'target_urn': 'soundcloud:tracks:${t.id}'},
    ],
  });

  // ---------- Streams ----------

  /// Stream URLs live much longer at SoundCloud; 3 min is enough for "play right away"
  /// and stays safely ahead of the signed CDN links expiring.
  static const _streamTtl = Duration(minutes: 3);
  final _streams = <String, (DateTime, Future<StreamInfo>)>{};

  /// Returns a directly playable URL (progressive MP3 or HLS).
  ///
  /// Cached: if a resolution is already running (e.g. from [prefetchStream] on touch),
  /// the call joins it instead of sending a second request.
  ///
  /// [fast]: for a tap-to-play start prefer the progressive MP3 (128 kbit/s) – a single
  /// request instead of HLS playlist + init + segment one after another. Pre-buffered tracks
  /// don't need this and get the configured quality.
  Future<StreamInfo> stream(Track track, {bool fast = false}) {
    final key = '${track.id}|${_settings.quality.name}|${auth != null}|${Track.drmPlayback}|$fast';
    final now = DateTime.now();
    final hit = _streams[key];
    if (hit != null && now.difference(hit.$1) < _streamTtl) return hit.$2;
    _streams.removeWhere((_, v) => now.difference(v.$1) >= _streamTtl);
    final job = _resolveStream(track, fast: fast);
    _streams[key] = (now, job);
    // Don't cache errors: the next attempt should ask again.
    job.then<void>(
      (_) {},
      onError: (Object _) {
        if (identical(_streams[key]?.$2, job)) _streams.remove(key);
      },
    );
    return job;
  }

  /// Resolve the stream URL ahead of time (finger down, next queue track). Errors don't matter.
  void prefetchStream(Track track, {bool fast = false}) => stream(track, fast: fast).ignore();

  Future<StreamInfo> _resolveStream(Track track, {bool fast = false}) async {
    var t = track;
    if (t.transcodings.isEmpty || t.trackAuthorization == null) {
      t = await this.track(track.id);
    }
    if (t.isBlocked) throw ScException('blocked', 451);
    for (final tc in _rank(t.transcodings, drm: t.isProtected && Track.drmPlayback, fast: fast)) {
      try {
        final j = await _get(tc.url, {'track_authorization': t.trackAuthorization});
        final url = j['url'] as String?;
        if (url == null) continue;
        if (!tc.isEncrypted) return StreamInfo(url, hls: tc.isHls, mime: tc.mime, preset: tc.preset);
        // Encrypted: without a license token the browser can't request a license.
        final token = j['licenseAuthToken'] as String?;
        if (token != null) return StreamInfo(url, hls: true, mime: tc.mime, preset: tc.preset, licenseToken: token);
      } on ScException {
        continue;
      }
    }
    throw ScException('no stream available', 404);
  }

  /// URL of the progressive MP3 (128 kbit/s CBR) for analysis via HTTP range, null = none.
  Future<String?> progressiveMp3(Track track) async {
    var t = track;
    if (t.transcodings.isEmpty || t.trackAuthorization == null) t = await this.track(track.id);
    final tc = t.transcodings
        .where((c) => c.protocol == 'progressive' && c.mime.contains('mpeg') && !c.snipped)
        .firstOrNull;
    if (tc == null) return null;
    final j = await _get(tc.url, {'track_authorization': t.trackAuthorization});
    return j['url'] as String?;
  }

  /// Loads bytes [start]..[end] (inclusive) of a file. SoundCloud's CDNs allow
  /// range and CORS – so no proxy is needed in the browser.
  Future<Uint8List> range(String url, int start, int end) async {
    final res = await _http.get(Uri.parse(url), headers: {'Range': 'bytes=$start-$end'});
    if (res.statusCode != 206 && res.statusCode != 200) throw ScException('range', res.statusCode);
    final b = res.bodyBytes;
    // A server without range support returns everything: cut it out ourselves.
    if (res.statusCode == 200 && b.length > end - start + 1) {
      return Uint8List.sublistView(b, start.clamp(0, b.length), (end + 1).clamp(0, b.length));
    }
    return b;
  }

  /// [drm]: encrypted cenc streams (Widevine/PlayReady) first – SoundCloud doesn't serve the
  /// unencrypted entries of protected tracks (404).
  List<Transcoding> _rank(List<Transcoding> all, {bool drm = false, bool fast = false}) {
    final ok = all
        .where((t) => t.protocol == 'hls' || t.protocol == 'progressive' || (drm && t.protocol == 'ctr-encrypted-hls'))
        .toList();
    int score(Transcoding t) =>
        (t.snipped ? 10 : 0) +
        (t.isEncrypted ? -5 : 0) +
        (fast && t.protocol == 'progressive' && t.mime.contains('mpeg') ? -4 : _quality(t));
    return ok..sort((a, b) => score(a).compareTo(score(b)));
  }

  /// Full version before preview, then by quality.
  int _quality(Transcoding t) {
    final aac160 = t.preset.startsWith('aac_160');
    final mp3Prog = t.protocol == 'progressive';
    final aac = t.mime.contains('mp4');
    // Web: progressive MP3 first (plays everywhere without hls.js).
    if (Platform.isWeb) return mp3Prog ? 0 : (aac160 ? 1 : 2);
    return switch (_settings.quality) {
      StreamQuality.high => aac160 ? 0 : (mp3Prog ? 1 : (aac ? 2 : 3)),
      StreamQuality.saver => t.preset.startsWith('aac_96') ? 0 : (mp3Prog ? 1 : 2),
    };
  }
}

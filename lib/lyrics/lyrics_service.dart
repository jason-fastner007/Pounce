import 'package:http/http.dart' as http;

import '../sc/models.dart';
import 'kugou.dart';
import 'lrc.dart';
import 'lrclib.dart';

/// Looks up lyrics across several sources; the result is cached in memory.
class LyricsService {
  /// [wrap]: proxy for sources without CORS (KuGou) in the browser.
  LyricsService(http.Client client, {Uri Function(Uri)? wrap})
    : _lrclib = LrcLib(client),
      _kugou = KuGou(client, wrap);

  final LrcLib _lrclib;
  final KuGou _kugou;
  final _cache = <int, Future<Lyrics?>>{};

  Future<Lyrics?> forTrack(Track t) => _cache[t.id] ??= _load(t);

  Future<Lyrics?> _load(Track t) async {
    final (title, artist) = cleanMeta(t);
    final sec = t.durationMs ~/ 1000;
    // Both sources in parallel (saves one round of waiting), LRCLIB takes precedence.
    final sources = [_lrclib.find(title, artist, sec), _kugou.find(title, artist, sec)];
    Lyrics? plain;
    for (final src in sources) {
      try {
        final l = await src;
        if (l == null) continue;
        if (l.synced) return l;
        plain ??= l;
      } catch (_) {}
    }
    return plain;
  }

  /// SoundCloud titles are often "Artist - Title (Remix) [Free DL]".
  static (String, String) cleanMeta(Track t) {
    var title = t.title;
    // Label metadata beats the uploader name ("Channel XY" instead of the artist).
    var artist = t.artist ?? t.user.username;
    final dash = RegExp(r'\s[-–—]\s').firstMatch(title);
    if (dash != null) {
      if (t.artist == null) artist = title.substring(0, dash.start).trim();
      title = title.substring(dash.end).trim();
    }
    title = title
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .replaceAll(RegExp(r'\((free|official|lyric|audio|video)[^)]*\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return (title, artist);
  }
}

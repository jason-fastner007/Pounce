import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/platform.dart';
import 'lrc.dart';

/// lrclib.net – open lyrics database (CORS-friendly).
class LrcLib {
  LrcLib(this._http);
  final http.Client _http;

  Future<Lyrics?> find(String title, String artist, int durationSec) async {
    // 1) title + artist separately, 2) free text (uploader names often differ), 3) title only.
    // Hits only count with a matching length (±3 s) – so no wrong song ends up in the player.
    final queries = [
      {'track_name': title, 'artist_name': artist},
      {'q': '$title $artist'},
      if (title.length >= 6) {'q': title}, // very short titles ("Intro") would be too ambiguous
    ];
    Lyrics? plain;
    for (final q in queries) {
      final list = await _search(q);
      int diff(Map<String, dynamic> e) => ((e['duration'] as num? ?? 0) - durationSec).abs().round();
      final match = list.where((e) => diff(e) <= 3).toList()..sort((a, b) => diff(a).compareTo(diff(b)));
      final synced = match.where((e) => e['syncedLyrics'] != null).firstOrNull;
      if (synced != null) return Lyrics.parse(synced['syncedLyrics'] as String, 'LRCLIB');
      final p = match.where((e) => e['plainLyrics'] != null).firstOrNull;
      if (p != null) plain ??= Lyrics.parse(p['plainLyrics'] as String, 'LRCLIB');
    }
    return plain;
  }

  Future<List<Map<String, dynamic>>> _search(Map<String, String> query) async {
    final uri = Uri.https('lrclib.net', '/api/search', query);
    // Browser: lrclib rejects User-Agent in the CORS preflight (Firefox really sends it,
    // Chrome silently ignores it) – there the app identifies itself via the allowed "Lrclib-Client".
    final res = await _http.get(uri, headers: {(Platform.isWeb ? 'Lrclib-Client' : 'User-Agent'): 'Pounce (GPL-3.0)'});
    if (res.statusCode != 200) return const [];
    return (jsonDecode(utf8.decode(res.bodyBytes)) as List).cast<Map<String, dynamic>>();
  }
}

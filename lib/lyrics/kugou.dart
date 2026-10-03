import 'dart:convert';

import 'package:http/http.dart' as http;

import 'lrc.dart';

/// KuGou – large lyrics source, especially for Asian titles.
class KuGou {
  KuGou(this._http, [this._wrap]);
  final http.Client _http;

  /// Browser: KuGou sends no CORS headers -> goes through the app proxy.
  final Uri Function(Uri)? _wrap;

  static final _accepted = RegExp(r'^\[(\d\d):(\d\d)\.(\d{2,3})\].*');
  static final _credits = RegExp(r'.+\].+[:：].+');

  Future<Lyrics?> find(String title, String artist, int durationSec) async {
    final keyword = '${_title(title)} - ${_artist(artist)}';

    // 1) look up the song hash, 2) lyrics by hash, otherwise by keyword.
    final songs = await _json(
      Uri.https('mobileservice.kugou.com', '/api/v3/search/song', {
        'version': '9108',
        'plat': '0',
        'pagesize': '8',
        'showtype': '0',
        'keyword': keyword,
      }),
    );
    for (final s in (songs?['data']?['info'] as List? ?? const [])) {
      if (((s['duration'] as num) - durationSec).abs() > 8) continue;
      final c = await _candidate({'hash': s['hash'] as String});
      if (c != null) return _download(c);
    }
    final c = await _candidate({'keyword': keyword, 'duration': '${durationSec * 1000}'});
    return c == null ? null : _download(c);
  }

  Future<Map<String, dynamic>?> _candidate(Map<String, String> q) async {
    final j = await _json(Uri.https('lyrics.kugou.com', '/search', {'ver': '1', 'man': 'yes', 'client': 'pc', ...q}));
    final list = j?['candidates'] as List?;
    return list == null || list.isEmpty ? null : list.first as Map<String, dynamic>;
  }

  Future<Lyrics?> _download(Map<String, dynamic> c) async {
    final j = await _json(
      Uri.https('lyrics.kugou.com', '/download', {
        'fmt': 'lrc',
        'charset': 'utf8',
        'client': 'pc',
        'ver': '1',
        'id': '${c['id']}',
        'accesskey': c['accesskey'] as String,
      }),
    );
    final content = j?['content'] as String?;
    if (content == null) return null;
    var lines = utf8
        .decode(base64.decode(content), allowMalformed: true)
        .replaceAll('&apos;', "'")
        .split('\n')
        .where(_accepted.hasMatch)
        .toList();
    // Cut off credits (composer, lyricist …) at the start.
    for (var i = (lines.length - 1).clamp(0, 30); i >= 0; i--) {
      if (i < lines.length && _credits.hasMatch(lines[i])) {
        lines = lines.sublist(i + 1);
        break;
      }
    }
    if (lines.isEmpty || lines.first.contains('纯音乐')) return null;
    return Lyrics.parse(lines.join('\n'), 'KuGou');
  }

  Future<Map<String, dynamic>?> _json(Uri uri) async {
    try {
      final res = await _http.get(_wrap?.call(uri) ?? uri);
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static String _title(String t) => t.replaceAll(RegExp(r'[(（「『<《〈＜].*?[)）」』>》〉＞]'), '').trim();

  static String _artist(String a) =>
      a.replaceAll(', ', '、').replaceAll(' & ', '、').replaceAll('.', '').replaceAll(RegExp(r'[(（].*?[)）]'), '').trim();
}

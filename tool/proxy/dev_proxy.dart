// Local development server: CORS proxy + optionally the web app.
//
//   Proxy only:  dart run tool/proxy/dev_proxy.dart
//   With app:    flutter build web --wasm --dart-define=SC_PROXY=/proxy?url=
//                dart run tool/proxy/dev_proxy.dart --web build/web --host 0.0.0.0
import 'dart:io';

final _allowed = RegExp(
  r'^https://((api-v2|api-mobile|api-auth)\.soundcloud\.com|soundcloud\.com|a-v2\.sndcdn\.com|wave\.sndcdn\.com'
  r'|mobileservice\.kugou\.com|lyrics\.kugou\.com)/',
);

/// Radio (&radio=1): arbitrary streams, but only with audio content (not an open proxy).
final _audio = RegExp(r'^(audio/|application/(ogg|vnd\.apple\.mpegurl|x-mpegurl)|video/mp2t)', caseSensitive: false);

const _types = {
  'html': 'text/html; charset=utf-8',
  'js': 'text/javascript',
  'mjs': 'text/javascript',
  'wasm': 'application/wasm',
  'json': 'application/json',
  'css': 'text/css',
  'png': 'image/png',
  'ico': 'image/x-icon',
  'ttf': 'font/ttf',
  'otf': 'font/otf',
  'bin': 'application/octet-stream',
  'svg': 'image/svg+xml',
};

Future<void> main(List<String> args) async {
  String? opt(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final web = opt('web');
  final host = opt('host') ?? '127.0.0.1';
  final port = int.parse(opt('port') ?? '8787');
  final client = HttpClient();
  final server = await HttpServer.bind(host, port);
  stdout.writeln('Läuft auf http://$host:$port  (Proxy: /proxy?url=)');

  await for (final req in server) {
    final target = req.uri.queryParameters['url'];
    if (target != null) {
      await _proxy(client, req, target);
    } else if (web != null) {
      await _static(web, req);
    } else {
      req.response.statusCode = 404;
      await req.response.close();
    }
  }
}

Future<void> _proxy(HttpClient client, HttpRequest req, String target) async {
  req.response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
    ..set('Access-Control-Allow-Headers', 'Accept, Content-Type, Authorization, App-Version, UDID, Range')
    ..set('Access-Control-Expose-Headers', 'Content-Range, Content-Length');
  if (req.method == 'OPTIONS') return req.response.close();
  final radio = req.uri.queryParameters['radio'] == '1';
  final ok = radio ? RegExp(r'^https?://').hasMatch(target) && req.method == 'GET' : _allowed.hasMatch(target);
  if (!ok) {
    req.response.statusCode = 403;
    return req.response.close();
  }
  try {
    final up = await client.openUrl(req.method, Uri.parse(target));
    up.headers.set('User-Agent', 'Mozilla/5.0');
    for (final h in const ['content-type', 'authorization', 'app-version', 'udid', 'accept', 'range']) {
      final v = req.headers.value(h);
      if (v != null) up.headers.set(h, v);
    }
    if (req.method == 'POST' || req.method == 'PUT') await up.addStream(req);
    final res = await up.close();
    if (radio && !_audio.hasMatch(res.headers.contentType?.mimeType ?? '')) {
      req.response.statusCode = 415;
      await req.response.close();
      return;
    }
    req.response.statusCode = res.statusCode;
    final range = res.headers.value('content-range');
    if (range != null) req.response.headers.set('Content-Range', range);
    final type = res.headers.contentType;
    if (type != null) req.response.headers.contentType = type;
    await res.pipe(req.response);
  } catch (_) {
    req.response.statusCode = 502;
    await req.response.close();
  }
}

Future<void> _static(String root, HttpRequest req) async {
  var path = Uri.decodeComponent(req.uri.path);
  if (path.contains('..')) path = '/';
  var file = File('$root${path == '/' ? '/index.html' : path}');
  if (!await file.exists()) file = File('$root/index.html'); // SPA-Fallback
  final ext = file.path.split('.').last;
  req.response.headers
    ..set('Content-Type', _types[ext] ?? 'application/octet-stream')
    ..set('Cache-Control', 'no-cache')
    // Cross-origin isolation: lets Flutter render multi-threaded (HTTPS/localhost only).
    ..set('Cross-Origin-Opener-Policy', 'same-origin')
    ..set('Cross-Origin-Embedder-Policy', 'credentialless');
  await file.openRead().pipe(req.response);
}

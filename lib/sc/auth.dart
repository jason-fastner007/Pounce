import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/store.dart';
import 'models.dart';

/// SoundCloud sign-in via OAuth 2 + PKCE through the official login page.
/// The app never sees the password, only access/refresh tokens.
class ScAuth extends ChangeNotifier {
  ScAuth(this._store, this._http, this._wrap) {
    me = switch (_store.get<Map>('auth.me')) {
      final Map m => ScUser.fromJson(m.cast<String, dynamic>()),
      null => null,
    };
  }

  // Client of the official Android app (as in the original KittyTune).
  static const clientId = 'QOFuKCOeAXIph267vzqj3B1wb65cZVAQ';
  static const _secret = 'EhBDsGIj9EbuBbRf0QkhH9Fq9BX3yN4B';
  static const redirectUri = 'sc://auth';

  /// Browsers can't intercept sc:// -> web client of soundcloud.com,
  /// whose redirect ends up visibly in the address bar.
  static const webRedirectUri = 'https://soundcloud.com/signin/callback';
  static const _appId = 3152;
  static const _tokenUrl = 'https://api-auth.soundcloud.com/oauth/token';

  final Store _store;
  final http.Client _http;
  final Uri Function(Uri) _wrap;
  Future<String?>? _refreshJob;

  ScUser? me;

  bool get loggedIn => _store.get<String>('auth.access') != null;

  /// Web login = public web client (no secret).
  bool get _web => _store.get<String>('auth.client') != null;

  /// Client ID the token is bound to.
  String get requestClientId => _store.get<String>('auth.client') ?? clientId;

  bool get usesWebClient => _web;

  /// Stable device ID (SoundCloud expects it at login).
  String get deviceId {
    var id = _store.get<String>('auth.device');
    if (id == null) {
      id = _randomString(32, '0123456789abcdef');
      _store.set('auth.device', id);
    }
    return id;
  }

  /// Signature = base64url(sha256("id:secret")), like the official app.
  static String get signature =>
      base64Url.encode(sha256.convert(utf8.encode('$clientId:$_secret')).bytes).replaceAll('=', '');

  // ---------- PKCE ----------

  static String _randomString(int n, String chars) {
    final r = Random.secure();
    return String.fromCharCodes(List.generate(n, (_) => chars.codeUnitAt(r.nextInt(chars.length))));
  }

  static String challengeFor(String verifier) =>
      base64Url.encode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', '');

  /// Starts the login: creates a verifier (kept in storage in case the app is
  /// killed in between) and returns the login page URL.
  /// [webClientId] set = browser flow with the web client.
  Uri beginLogin({required String language, bool signup = false, String? webClientId}) {
    final verifier = _randomString(64, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~');
    _store
      ..set('auth.verifier', verifier)
      ..set('auth.pendingClient', webClientId);
    return Uri.https('secure.soundcloud.com', '/web-auth', {
      'client_id': webClientId ?? clientId,
      if (webClientId == null) 'app_id': '$_appId',
      'device_id': deviceId,
      'start_view': signup ? 'create_account' : 'sign_in',
      'redirect_uri': webClientId == null ? redirectUri : webRedirectUri,
      'response_type': 'code',
      'code_challenge': challengeFor(verifier),
      'code_challenge_method': 'S256',
      'ui_evo': 'true',
      'stand_alone': 'true',
      'tracking': 'local',
      'show_confirmation': 'true',
      'theme': 'dark',
      'locale': language,
    });
  }

  /// Accepts the redirect (sc://auth?code=…) or just the code.
  static String? codeFrom(String input) {
    final s = input.trim();
    final uri = Uri.tryParse(s);
    final code = uri?.queryParameters['code'];
    if (code != null && code.isNotEmpty) return code;
    return RegExp(r'^[A-Za-z0-9._~-]{8,}$').hasMatch(s) ? s : null;
  }

  /// Completes the login with the redirect URL.
  Future<void> complete(String callback) async {
    final code = codeFrom(callback);
    final verifier = _store.get<String>('auth.verifier');
    if (code == null) throw const AuthException('invalid_callback');
    if (verifier == null) throw const AuthException('no_pending_login');
    final web = _store.get<String>('auth.pendingClient');
    await _token({
      'grant_type': 'authorization_code',
      'client_id': web ?? clientId,
      'code': code,
      'redirect_uri': web == null ? redirectUri : webRedirectUri,
      'code_verifier': verifier,
    }, webClient: web);
    _store
      ..set('auth.verifier', null)
      ..set('auth.pendingClient', null);
  }

  /// Valid access token (refreshed automatically shortly before expiry).
  Future<String?> token() async {
    final access = _store.get<String>('auth.access');
    if (access == null) return null;
    final exp = _store.get<int>('auth.expires') ?? 0;
    final soon = DateTime.now().millisecondsSinceEpoch + 60000 >= exp;
    if (exp > 0 && soon) return refresh();
    return access;
  }

  /// Refresh the token (only once when called in parallel). null = session invalid.
  Future<String?> refresh() => _refreshJob ??= () async {
    final rt = _store.get<String>('auth.refresh');
    if (rt == null) return null;
    try {
      await _token({
        'grant_type': 'refresh_token',
        'client_id': requestClientId,
        'refresh_token': rt,
      }, webClient: _store.get<String>('auth.client'));
      return _store.get<String>('auth.access');
    } on AuthException catch (e) {
      // Only sign out when the token is clearly rejected, not on network errors.
      if (e.code == 'invalid_grant') logout();
      return null;
    }
  }().whenComplete(() => _refreshJob = null);

  Future<void> _token(Map<String, String> form, {String? webClient}) async {
    final res = await _http.post(
      _wrap(Uri.parse(_tokenUrl)),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        // Only the app client has a secret; the web client is public (PKCE).
        if (webClient == null) 'Authorization': signature,
      },
      body: form,
    );
    final j = res.body.isEmpty ? const {} : jsonDecode(res.body) as Map<String, dynamic>;
    final access = j['access_token'] as String?;
    if (res.statusCode >= 400 || access == null || access.isEmpty) {
      throw AuthException(j['error'] as String? ?? 'http_${res.statusCode}');
    }
    final expiresIn = (j['expires_in'] as num?)?.toInt() ?? 0;
    _store
      ..set('auth.client', webClient)
      ..set('auth.access', access)
      ..set('auth.refresh', (j['refresh_token'] as String?) ?? _store.get<String>('auth.refresh'))
      ..set('auth.expires', expiresIn > 0 ? DateTime.now().millisecondsSinceEpoch + expiresIn * 1000 : 0);
    notifyListeners();
  }

  void setMe(ScUser? user) {
    me = user;
    _store.set('auth.me', user?.toJson());
    notifyListeners();
  }

  void logout() {
    for (final k in ['auth.access', 'auth.refresh', 'auth.expires', 'auth.me', 'auth.verifier', 'auth.client']) {
      _store.set(k, null);
    }
    me = null;
    notifyListeners();
  }
}

class AuthException implements Exception {
  const AuthException(this.code);
  final String code;
  @override
  String toString() => 'AuthException($code)';
}

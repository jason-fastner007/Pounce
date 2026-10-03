import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/sc/auth.dart';
import 'package:pounce/sc/soundcloud.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _TmpPaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationSupportPath() async => (await Directory.systemTemp.createTemp('kf')).path;
}

void main() {
  setUp(() => PathProviderPlatform.instance = _TmpPaths());

  test('PKCE challenge = base64url(sha256(verifier)) (reference: Python hashlib)', () {
    expect(
      ScAuth.challengeFor('dBjftJeZ4CVP-mJ92kqIUAdmN4b8vgBgGd0vSZ4oLp0'),
      'RLaEXgopa87-TkWj5jPUc0RFHMHgl_6PU4i4MTH8VdE',
    );
  });

  test('signature like the official app', () {
    expect(ScAuth.signature, 'ztQ_RKaMCPavrjcXvMT6t0STPQ0vU2cY4YKGVeLU6Iw');
  });

  test('code from the redirect or directly', () {
    expect(ScAuth.codeFrom('sc://auth?code=abc123XYZ&state=1'), 'abc123XYZ');
    expect(ScAuth.codeFrom('  abcdefgh1234  '), 'abcdefgh1234');
    expect(ScAuth.codeFrom('sc://auth?error=access_denied'), isNull);
  });

  test('login URL contains PKCE and redirect', () async {
    final store = Store.memory();
    final auth = ScAuth(store, http.Client(), (u) => u);
    final url = auth.beginLogin(language: 'de');
    expect(url.host, 'secure.soundcloud.com');
    expect(url.queryParameters['redirect_uri'], 'sc://auth');
    expect(url.queryParameters['code_challenge_method'], 'S256');
    expect(url.queryParameters['locale'], 'de');
    expect(ScAuth.challengeFor(store.get<String>('auth.verifier')!), url.queryParameters['code_challenge']);
  });

  test('token exchange, OAuth on the API, refresh, sign-out on invalid_grant', () async {
    final store = Store.memory();
    var tokenCalls = 0;
    String? apiAuthHeader;
    String? apiClientId;
    final client = MockClient((req) async {
      if (req.url.host == 'api-auth.soundcloud.com') {
        tokenCalls++;
        expect(req.headers['Authorization'], ScAuth.signature);
        final form = Uri.splitQueryString(req.body);
        if (form['grant_type'] == 'authorization_code') {
          expect(form['code'], 'CODE123456');
          expect(form['code_verifier'], isNotEmpty);
          return http.Response(jsonEncode({'access_token': 'A1', 'refresh_token': 'R1', 'expires_in': 3600}), 200);
        }
        if (form['refresh_token'] == 'R1') {
          return http.Response(jsonEncode({'access_token': 'A2', 'refresh_token': 'R2', 'expires_in': 3600}), 200);
        }
        return http.Response(jsonEncode({'error': 'invalid_grant'}), 400);
      }
      if (req.url.path == '/me') {
        apiAuthHeader = req.headers['Authorization'];
        apiClientId = req.url.queryParameters['client_id'];
        return http.Response(jsonEncode({'id': 7, 'username': 'me'}), 200);
      }
      return http.Response('{}', 404);
    });
    final sc = SoundCloud(store, Settings(store), client: client);
    final auth = ScAuth(store, client, sc.wrap);
    sc.auth = auth;

    auth.beginLogin(language: 'en');
    await auth.complete('sc://auth?code=CODE123456');
    expect(auth.loggedIn, isTrue);

    final me = await sc.me();
    expect(me.username, 'me');
    expect(apiAuthHeader, 'OAuth A1');
    expect(apiClientId, ScAuth.clientId);

    expect(await auth.refresh(), 'A2');
    expect(await auth.refresh(), isNull); // R2 is invalid -> sign out
    expect(auth.loggedIn, isFalse);
    expect(tokenCalls, 3);
  });

  test('web flow: public web client, redirect via soundcloud.com', () async {
    final store = Store.memory();
    final client = MockClient((req) async {
      if (req.url.host == 'api-auth.soundcloud.com') {
        expect(req.headers.containsKey('Authorization'), isFalse); // no secret
        final form = Uri.splitQueryString(req.body);
        expect(form['client_id'], 'WEBCLIENT');
        expect(form['redirect_uri'], ScAuth.webRedirectUri);
        return http.Response(jsonEncode({'access_token': 'W1', 'refresh_token': 'WR', 'expires_in': 3600}), 200);
      }
      expect(req.url.queryParameters['client_id'], 'WEBCLIENT');
      return http.Response(jsonEncode({'id': 1, 'username': 'web'}), 200);
    });
    final sc = SoundCloud(store, Settings(store), client: client);
    final auth = ScAuth(store, client, sc.wrap);
    sc.auth = auth;
    final url = auth.beginLogin(language: 'de', webClientId: 'WEBCLIENT');
    expect(url.queryParameters['redirect_uri'], ScAuth.webRedirectUri);
    expect(url.queryParameters.containsKey('app_id'), isFalse);
    await auth.complete('https://soundcloud.com/signin/callback?code=WEBCODE999&state=');
    expect(auth.usesWebClient, isTrue);
    expect((await sc.me()).username, 'web');
  });
}

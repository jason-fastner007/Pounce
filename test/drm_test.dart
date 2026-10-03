import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/sc/models.dart';
import 'package:pounce/sc/soundcloud.dart';

Transcoding _tc(String preset, String protocol, String mime) => Transcoding(
  url: 'https://api/media/$preset/$protocol',
  preset: preset,
  protocol: protocol,
  mime: mime,
  snipped: false,
);

/// Like a major-label track: cenc/cbcs encrypted, MP3 entries listed but not served.
final _protected = Track(
  id: 7,
  title: 'Kayra',
  user: const ScUser(id: 1, username: 'u'),
  durationMs: 184509,
  trackAuthorization: 'auth',
  transcodings: [
    _tc('aac_96k', 'ctr-encrypted-hls', 'audio/mp4; codecs="mp4a.40.2"'),
    _tc('aac_160k', 'cbc-encrypted-hls', 'audio/mp4; codecs="mp4a.40.2"'),
    _tc('aac_160k', 'ctr-encrypted-hls', 'audio/mp4; codecs="mp4a.40.2"'),
    _tc('mp3_1_0', 'hls', 'audio/mpeg'),
    _tc('mp3_1_0', 'progressive', 'audio/mpeg'),
  ],
);

void main() {
  late SoundCloud sc;
  final requested = <String>[];

  setUp(() {
    requested.clear();
    final store = Store.memory()
      ..set('sc.cid', 'id')
      ..set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);
    final client = MockClient((req) async {
      final path = req.url.path;
      requested.add(path);
      if (path.endsWith('encrypted-hls')) {
        return http.Response('{"url":"https://playback/${path.split('/')[2]}.m3u8","licenseAuthToken":"jwt"}', 200);
      }
      return http.Response('', 404);
    });
    sc = SoundCloud(store, Settings(store), client: client);
  });

  tearDown(() => Track.drmPlayback = false);

  test('not playable without DRM support', () {
    Track.drmPlayback = false;
    expect(_protected.isProtected, isTrue);
    expect(_protected.playable, isFalse);
  });

  test('with DRM: cenc in best quality incl. license token, no detour via the 404 MP3s', () async {
    Track.drmPlayback = true;
    expect(_protected.playable, isTrue);
    final s = await sc.stream(_protected);
    expect(s.drm, isTrue);
    expect(s.hls, isTrue);
    expect(s.licenseToken, 'jwt');
    expect(s.preset, 'aac_160k');
    expect(s.url, 'https://playback/aac_160k.m3u8');
    expect(s.label, 'AAC · 160k · HLS · DRM');
    // FairPlay (cbcs) isn't requested, nor are the MP3 entries (cenc already worked).
    expect(requested, ['/media/aac_160k/ctr-encrypted-hls']);
  });

  test('without DRM support only unencrypted streams', () async {
    Track.drmPlayback = false;
    await expectLater(sc.stream(_protected), throwsA(isA<ScException>()));
    expect(requested.where((p) => p.contains('encrypted')), isEmpty);
  });
}

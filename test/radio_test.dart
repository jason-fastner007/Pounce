import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pounce/radio/radio_browser.dart';

Map<String, Object?> station(String name, {String url = 'http://stream/x'}) => {
  'stationuuid': 'id-$name',
  'name': name,
  'url_resolved': url,
  'codec': 'MP3',
  'bitrate': 192,
  'countrycode': 'DE',
  'tags': 'pop,hits',
};

void main() {
  test('mirror from the DNS lookup first, next one on error', () async {
    final hosts = <String>[];
    final api = RadioBrowser(
      MockClient((r) async {
        hosts.add(r.url.host);
        if (r.url.host == 'tot.api.radio-browser.info') return http.Response('kaputt', 503);
        return http.Response(jsonEncode([station('Ostseewelle')]), 200);
      }),
      mirrors: () async => ['tot.api.radio-browser.info'],
    );
    final hits = await api.searchByName('ostseewelle');
    expect(hits.single.name, 'Ostseewelle');
    expect(hosts.first, 'tot.api.radio-browser.info');
    expect(hosts.last, 'de1.api.radio-browser.info'); // fallback to the fixed list
  });

  test('endpoints, sorting and broken entries', () async {
    final paths = <Uri>[];
    final api = RadioBrowser(
      MockClient((r) async {
        paths.add(r.url);
        return http.Response(jsonEncode([station('A'), station('ohne URL', url: '')]), 200);
      }),
      mirrors: () async => [],
    );
    expect((await api.topClick()).length, 1, reason: 'Sender ohne Stream-URL fliegen raus');
    await api.byTag('Techno');
    await api.byCountryCodeExact('de');
    await api.searchByName('x');
    expect(paths.map((u) => u.path), [
      '/json/stations/topclick/50',
      '/json/stations/bytag/techno',
      '/json/stations/bycountrycodeexact/DE',
      '/json/stations/search',
    ]);
    expect(paths.last.queryParameters['order'], 'votes');
    expect(paths.every((u) => u.queryParameters['hidebroken'] == 'true'), isTrue);
  });

  test('station becomes a live track', () {
    final s = RadioStation.fromJson(station('Ostseewelle'));
    final t = s.toTrack();
    expect(t.isLive, isTrue);
    expect(t.id, isNegative, reason: 'keine Kollision mit SoundCloud-IDs');
    expect(s.quality, 'MP3 · 192k');
  });
}

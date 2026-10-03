import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pounce/lyrics/lrc.dart';
import 'package:pounce/lyrics/lrclib.dart';
import 'package:pounce/lyrics/lyrics_service.dart';
import 'package:pounce/sc/models.dart';

void main() {
  group('Lyrics.parse', () {
    test('synced LRC incl. multiple tags', () {
      final l = Lyrics.parse('[00:01.50]Eins\n[00:03.00][00:10.2]Zwei\n[ar:Egal]', 't')!;
      expect(l.synced, isTrue);
      expect(l.lines.map((e) => e.text), ['Eins', 'Zwei', 'Zwei']);
      expect(l.lines[0].time, const Duration(seconds: 1, milliseconds: 500));
      expect(l.lines[2].time, const Duration(seconds: 10, milliseconds: 200));
    });

    test('without timestamps = unsynced', () {
      final l = Lyrics.parse('Zeile A\nZeile B', 't')!;
      expect(l.synced, isFalse);
      expect(l.lines.length, 2);
    });

    test('indexAt finds the active line', () {
      final l = Lyrics.parse('[00:01.00]a\n[00:05.00]b\n[00:09.00]c', 't')!;
      expect(l.indexAt(Duration.zero), -1);
      expect(l.indexAt(const Duration(seconds: 1)), 0);
      expect(l.indexAt(const Duration(seconds: 7)), 1);
      expect(l.indexAt(const Duration(minutes: 5)), 2);
    });
  });

  test('cleanMeta splits "Artist - Title [Free DL]"', () {
    const t = Track(
      id: 1,
      title: 'Daft Punk - One More Time (Official Audio) [Free DL]',
      user: ScUser(id: 1, username: 'uploader'),
      durationMs: 0,
    );
    expect(LyricsService.cleanMeta(t), ('One More Time', 'Daft Punk'));
  });

  test('cleanMeta takes the label artist instead of the uploader', () {
    const t = Track(
      id: 1,
      title: 'Blinding Lights',
      user: ScUser(id: 1, username: 'XO Records Channel'),
      durationMs: 0,
      artist: 'The Weeknd',
    );
    expect(LyricsService.cleanMeta(t), ('Blinding Lights', 'The Weeknd'));
    expect(
      Track.fromJson({
        'id': 2,
        'publisher_metadata': {'artist': 'The Weeknd'},
      }).artist,
      'The Weeknd',
    );
  });

  test('LRCLIB: free-text search when title+artist finds nothing; length must match', () async {
    final queries = <Map<String, String>>[];
    final client = MockClient((req) async {
      queries.add(req.url.queryParameters);
      if (!req.url.queryParameters.containsKey('q')) return http.Response('[]', 200);
      return http.Response(
        jsonEncode([
          {'duration': 300, 'syncedLyrics': '[00:01.00]falscher Song'},
          {'duration': 202, 'syncedLyrics': '[00:01.00]richtig'},
        ]),
        200,
      );
    });
    final l = await LrcLib(client).find('Blinding Lights', 'uploader', 201);
    expect(l!.lines.single.text, 'richtig');
    expect(queries.length, 2);
    expect(queries[1]['q'], 'Blinding Lights uploader');
  });

  test('sized replaces the artwork size', () {
    expect(
      sized('https://i1.sndcdn.com/artworks-x-large.jpg', 't500x500'),
      'https://i1.sndcdn.com/artworks-x-t500x500.jpg',
    );
  });
}

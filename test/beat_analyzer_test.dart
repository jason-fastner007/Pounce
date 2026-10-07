import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/dj/beat_analyzer.dart';
import 'package:pounce/dj/camelot_key.dart';
import 'package:pounce/sc/models.dart';
import 'package:pounce/sc/soundcloud.dart';

Track _track({
  required int id,
  required String title,
  double? bpm,
  String? genre,
  int durationMs = 180000,
  String? waveformUrl,
}) => Track(
  id: id,
  title: title,
  user: const ScUser(id: 1, username: 'artist'),
  durationMs: durationMs,
  bpm: bpm,
  genre: genre,
  waveformUrl: waveformUrl,
  transcodings: const [
    Transcoding(url: 'https://api/x', preset: 'mp3', protocol: 'progressive', mime: 'audio/mpeg', snipped: false),
  ],
);

void main() {
  group('BeatAnalyzer.extractBpmHint', () {
    test('uses track.bpm if present and within 60..200 range', () {
      final t = _track(id: 1, title: 'Test Track', bpm: 128.0);
      expect(BeatAnalyzer.extractBpmHint(t), 128.0);
    });

    test('ignores invalid track.bpm and extracts bpm from title regex', () {
      final t1 = _track(id: 2, title: 'Tekk Track 160 BPM', bpm: 50.0);
      expect(BeatAnalyzer.extractBpmHint(t1), 160.0);

      final t2 = _track(id: 3, title: 'Chill Out (128.5 bpm)');
      expect(BeatAnalyzer.extractBpmHint(t2), 128.5);
    });

    test('detects genre/title keywords like tekk, dnb, psytrance', () {
      final tekk = _track(id: 4, title: 'Hardtekk Madness');
      expect(BeatAnalyzer.extractBpmHint(tekk), 160.0);

      final dnb = _track(id: 5, title: 'Heavy Roller', genre: 'Drum and Bass');
      expect(BeatAnalyzer.extractBpmHint(dnb), 174.0);

      final psy = _track(id: 6, title: 'Psy Trance Journey');
      expect(BeatAnalyzer.extractBpmHint(psy), 142.0);
    });

    test('returns null if no hint found', () {
      final plain = _track(id: 7, title: 'Normal Pop Song');
      expect(BeatAnalyzer.extractBpmHint(plain), isNull);
    });

    test('extracts bpm from various title regex formats', () {
      final t1 = _track(id: 8, title: 'Fast Track 175bpm');
      expect(BeatAnalyzer.extractBpmHint(t1), 175.0);

      final t2 = _track(id: 9, title: 'Techno 140.5 bpm');
      expect(BeatAnalyzer.extractBpmHint(t2), 140.5);

      final t3 = _track(id: 10, title: 'House Track 124 BPM');
      expect(BeatAnalyzer.extractBpmHint(t3), 124.0);
    });
  });

  group('BeatInfo serialization', () {
    test('BeatInfo toJson and fromJson roundtrip', () {
      const info = BeatInfo(
        bpm: 128.0,
        firstBeatOffsetMs: 250,
        confidence: 0.95,
        phraseOffsetMs: 500,
        downbeatOffsetMs: 250,
        cueMs: 4000,
        dropMs: 32000,
        key: CamelotKey.key8A,
        source: BeatSource.pcm,
      );

      final json = info.toJson();
      final restored = BeatInfo.fromJson(json);

      expect(restored, isNotNull);
      expect(restored!.bpm, 128.0);
      expect(restored.firstBeatOffsetMs, 250);
      expect(restored.confidence, 0.95);
      expect(restored.cueMs, 4000);
      expect(restored.dropMs, 32000);
      expect(restored.key, CamelotKey.key8A);
      expect(restored.source, BeatSource.pcm);
    });
  });

  group('BeatAnalyzer analysis & caching', () {
    late Store store;
    late Settings settings;
    late SoundCloud sc;
    late BeatAnalyzer analyzer;

    setUp(() {
      store = Store.memory();
      settings = Settings(store);
      final client = MockClient((req) async {
        if (req.url.path.contains('.json')) {
          return http.Response(jsonEncode({
            'height': 140,
            'samples': List.generate(100, (i) => (i % 20) * 5),
          }), 200);
        }
        return http.Response('{"url":"https://cdn/stream.mp3"}', 200);
      });
      sc = SoundCloud(store, settings, client: client);
      analyzer = BeatAnalyzer(sc, store);
    });

    test('analyze reads stored analysis from database table', () async {
      final t = _track(id: 10, title: 'Cached Track');
      const cachedInfo = BeatInfo(
        bpm: 124.0,
        firstBeatOffsetMs: 100,
        confidence: 0.8,
        source: BeatSource.pcm,
      );
      await store.db.write(Table.beat, {'10': jsonEncode(cachedInfo.toJson())});

      final result = await analyzer.analyze(t);
      expect(result, isNotNull);
      expect(result!.bpm, 124.0);
      expect(result.source, BeatSource.pcm);
      expect(analyzer.peek(t)?.bpm, 124.0);
    });

    test('fallback to waveform/hint estimation when audio engine is absent', () async {
      final t = _track(
        id: 11,
        title: 'Waveform Track 128 BPM',
        waveformUrl: 'https://wave.sndcdn.com/test.png',
      );

      final result = await analyzer.analyze(t);
      expect(result, isNotNull);
      expect(result!.bpm, 128.0); // Hint applied to fallback
      expect(analyzer.peek(t), isNotNull);
    });

    test('live streams return null without attempting analysis', () async {
      final liveTrack = Track(
        id: 99,
        title: 'Live Radio',
        user: const ScUser(id: 1, username: 'radio'),
        durationMs: 0,
        streamUrl: 'https://radio.stream/live',
      );

      final result = await analyzer.analyze(liveTrack);
      expect(result, isNull);
    });
  });
}

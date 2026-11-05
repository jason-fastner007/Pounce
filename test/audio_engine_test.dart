import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pounce/player/audio_engine.dart';

void main() {
  group('AudioEngine and helper models unit tests', () {
    test('EngineState copyWith updates position and retains other fields', () {
      const state = EngineState(
        status: EngineStatus.ready,
        playing: true,
        position: Duration(seconds: 10),
        duration: Duration(seconds: 100),
        buffered: Duration(seconds: 50),
        error: 'some_error',
      );

      final updated = state.copyWith(position: const Duration(seconds: 20));
      expect(updated.status, EngineStatus.ready);
      expect(updated.playing, true);
      expect(updated.position, const Duration(seconds: 20));
      expect(updated.duration, const Duration(seconds: 100));
      expect(updated.buffered, const Duration(seconds: 50));
      expect(updated.error, 'some_error');
    });

    test('LoudMode enum lufs values', () {
      expect(LoudMode.off.lufs, isNull);
      expect(LoudMode.quiet.lufs, -19);
      expect(LoudMode.normal.lufs, -14);
      expect(LoudMode.loud.lufs, -11);
    });

    test('logBandEdges computes 65 boundary indices clamped within FFT size', () {
      final edges = logBandEdges(44100, 2048);
      expect(edges.length, SpectrumSource.bands + 1);
      expect(edges.first, greaterThanOrEqualTo(1));
      expect(edges.last, lessThanOrEqualTo(1023));
      for (var i = 1; i < edges.length; i++) {
        expect(edges[i], greaterThanOrEqualTo(edges[i - 1]));
      }
    });

    test('PcmClip length calculated from samples and sampleRate', () {
      final samples = Float32List(44100 * 2); // 2 seconds mono
      final clip = PcmClip(samples, 44100, const Duration(seconds: 5));
      expect(clip.start, const Duration(seconds: 5));
      expect(clip.sampleRate, 44100);
      expect(clip.samples.length, 88200);
      expect(clip.length, const Duration(seconds: 2));
    });

    test('MediaMeta toMap formats properly', () {
      const meta = MediaMeta(
        id: 'track_123',
        title: 'Song Title',
        artist: 'Artist Name',
        artUrl: 'https://cdn/art.jpg',
        duration: Duration(seconds: 180),
      );

      final map = meta.toMap();
      expect(map['id'], 'track_123');
      expect(map['title'], 'Song Title');
      expect(map['artist'], 'Artist Name');
      expect(map['artUrl'], 'https://cdn/art.jpg');
      expect(map['durationMs'], 180000);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pounce/dj/beat_analyzer.dart';
import 'package:pounce/dj/camelot_key.dart';
import 'package:pounce/dj/dj_flow_controller.dart';
import 'package:pounce/dj/harmonic_mixer.dart';
import 'package:pounce/sc/models.dart';

Track mockTrack(int id, {String title = 'Test Track'}) => Track.fromJson({
      'id': id,
      'title': title,
      'duration': 180000,
      'user': {'id': 1, 'username': 'Artist'},
    });

void main() {
  group('CamelotKey tests', () {
    test('fromCode parses valid keys and handles whitespace/case', () {
      expect(CamelotKey.fromCode('8A'), CamelotKey.key8A);
      expect(CamelotKey.fromCode(' 12b '), CamelotKey.key12B);
      expect(CamelotKey.fromCode('invalid'), isNull);
    });

    test('fromPitchClass converts pitch class and minor/major flag correctly', () {
      // 9 = A. Minor = 8A
      expect(CamelotKey.fromPitchClass(9, true), CamelotKey.key8A);
      // 0 = C. Major = 8B
      expect(CamelotKey.fromPitchClass(0, false), CamelotKey.key8B);
      // Negative or wraparound pitch classes
      expect(CamelotKey.fromPitchClass(-3, true), CamelotKey.fromPitchClass(9, true));
    });

    test('wheelDiff calculates shortest circular distance on 12-hour wheel', () {
      expect(CamelotKey.key1A.wheelDiff(CamelotKey.key1A), 0);
      expect(CamelotKey.key1A.wheelDiff(CamelotKey.key2A), 1);
      expect(CamelotKey.key1A.wheelDiff(CamelotKey.key12A), 1);
      expect(CamelotKey.key1A.wheelDiff(CamelotKey.key7A), 6);
    });

    test('distanceTo and relationship helper methods', () {
      // Identical
      expect(CamelotKey.key8A.distanceTo(CamelotKey.key8A), 0);
      expect(CamelotKey.key8A.isExactMatch(CamelotKey.key8A), isTrue);

      // Relative major/minor
      expect(CamelotKey.key8A.distanceTo(CamelotKey.key8B), 1);
      expect(CamelotKey.key8A.isRelativeMajorMinor(CamelotKey.key8B), isTrue);

      // Adjacent on wheel
      expect(CamelotKey.key8A.distanceTo(CamelotKey.key9A), 1);
      expect(CamelotKey.key8A.isAdjacentOnWheel(CamelotKey.key9A), isTrue);

      // Diagonal
      expect(CamelotKey.key8A.distanceTo(CamelotKey.key9B), 2);

      // Harmonic compatibility threshold (distance <= 1)
      expect(CamelotKey.key8A.isHarmonicWith(CamelotKey.key8B), isTrue);
      expect(CamelotKey.key8A.isHarmonicWith(CamelotKey.key9A), isTrue);
      expect(CamelotKey.key8A.isHarmonicWith(CamelotKey.key10A), isFalse);
    });

    test('compatibilityScore assigns proper weights', () {
      expect(CamelotKey.key8A.compatibilityScore(CamelotKey.key8A), 1.0);
      expect(CamelotKey.key8A.compatibilityScore(CamelotKey.key8B), 0.95);
      expect(CamelotKey.key8A.compatibilityScore(CamelotKey.key9A), 0.90);
      expect(CamelotKey.key8A.compatibilityScore(CamelotKey.key9B), 0.65);
      expect(CamelotKey.key8A.compatibilityScore(CamelotKey.key11A), 0.30);
      expect(CamelotKey.key8A.compatibilityScore(CamelotKey.key4A), 0.0);
    });
  });

  group('HarmonicMixer tests', () {
    test('normalizeBpm shifts BPM into [90..180] range', () {
      expect(HarmonicMixer.normalizeBpm(0), 0);
      expect(HarmonicMixer.normalizeBpm(-10), 0);
      expect(HarmonicMixer.normalizeBpm(70), 140);
      expect(HarmonicMixer.normalizeBpm(128), 128);
      expect(HarmonicMixer.normalizeBpm(200), 100);
    });

    test('EnergyMode.fromString parses verschiedene Eingaben', () {
      expect(EnergyMode.fromString('buildup'), EnergyMode.buildUp);
      expect(EnergyMode.fromString('BUILD_UP'), EnergyMode.buildUp);
      expect(EnergyMode.fromString('aufbauen'), EnergyMode.buildUp);
      expect(EnergyMode.fromString('winddown'), EnergyMode.windDown);
      expect(EnergyMode.fromString('abkühlen'), EnergyMode.windDown);
      expect(EnergyMode.fromString('hold'), EnergyMode.hold);
      expect(EnergyMode.fromString('unknown'), EnergyMode.hold);
      expect(EnergyMode.fromString(null), EnergyMode.hold);
    });

    test('scoreCandidate exact key and BPM match gives high score', () {
      final tr = mockTrack(1);
      final match = HarmonicMixer.scoreCandidate(
        currentBpm: 124.0,
        currentKey: CamelotKey.key8A,
        candidateTrack: tr,
        candidateBpm: 124.0,
        candidateKey: CamelotKey.key8A,
        mode: EnergyMode.hold,
      );

      expect(match.score, greaterThan(90.0));
      expect(match.isHarmonic, isTrue);
      expect(match.harmonicDistance, 0);
      expect(match.matchDescription, contains('Same key (8A)'));
      expect(match.transitionStyle, TransitionStyle.harmonicClubBlend);
    });

    test('scoreCandidate penalizes BPM differences > 8%', () {
      final tr = mockTrack(2);
      final match = HarmonicMixer.scoreCandidate(
        currentBpm: 120.0,
        currentKey: CamelotKey.key8A,
        candidateTrack: tr,
        candidateBpm: 140.0, // > 8% difference
        candidateKey: CamelotKey.key8A,
        mode: EnergyMode.hold,
      );

      expect(match.score, lessThanOrEqualTo(20.0));
      expect(match.bpmPercentDelta, greaterThan(0.08));
    });

    test('scoreCandidate evaluates EnergyMode.buildUp and EnergyMode.windDown', () {
      final tr = mockTrack(3);

      final buildMatch = HarmonicMixer.scoreCandidate(
        currentBpm: 124.0,
        currentKey: CamelotKey.key8A,
        candidateTrack: tr,
        candidateBpm: 126.0, // slight increase
        candidateKey: CamelotKey.key8A,
        mode: EnergyMode.buildUp,
      );

      final windMatch = HarmonicMixer.scoreCandidate(
        currentBpm: 124.0,
        currentKey: CamelotKey.key8A,
        candidateTrack: tr,
        candidateBpm: 120.0, // slight decrease
        candidateKey: CamelotKey.key8A,
        mode: EnergyMode.windDown,
      );

      expect(buildMatch.score, greaterThan(80.0));
      expect(windMatch.score, greaterThan(80.0));
    });
  });

  group('DjFlowController components & mixEntry tests', () {
    test('BeatClock equality and hashCode', () {
      const clock1 = BeatClock(bar: 2, beatInBar: 1, beatInPhrase: 5, beatsUntilTransition: 16);
      const clock2 = BeatClock(bar: 2, beatInBar: 1, beatInPhrase: 5, beatsUntilTransition: 16);
      const clock3 = BeatClock(bar: 3, beatInBar: 2, beatInPhrase: 6, beatsUntilTransition: 12);

      expect(clock1, equals(clock2));
      expect(clock1.hashCode, equals(clock2.hashCode));
      expect(clock1, isNot(equals(clock3)));
      expect(clock1.isDownbeat, isTrue);
      expect(clock3.isDownbeat, isFalse);
    });

    test('mixEntry falls back when info is null or grid is missing', () {
      final resNull = mixEntry(info: null, fadeMs: 8000, tempo: 1.0, fallbackMs: 2000);
      expect(resNull.startMs, 2000);
      expect(resNull.fadeMs, 8000);

      const infoNoGrid = BeatInfo(
        bpm: 128,
        firstBeatOffsetMs: 0,
        confidence: 0.1,
        phraseOffsetMs: 0,
        downbeatOffsetMs: 0,
        source: BeatSource.waveform,
      );
      final resNoGrid = mixEntry(info: infoNoGrid, fadeMs: 8000, tempo: 1.0, fallbackMs: 1500);
      expect(resNoGrid.startMs, 1500);
    });

    test('mixEntry calculates entry with known drop and cue points', () {
      const info = BeatInfo(
        bpm: 128,
        firstBeatOffsetMs: 0,
        confidence: 0.8,
        phraseOffsetMs: 0,
        downbeatOffsetMs: 0,
        cueMs: 3000,
        dropMs: 20000,
        source: BeatSource.pcm,
      );

      final res = mixEntry(info: info, fadeMs: 8000, tempo: 1.0, fallbackMs: 0);
      // inNew = 8000 ms. drop (20000) - inNew (8000) = 12000 ms >= cueBar (3750 ms)
      expect(res.startMs, 12000);
      expect(res.fadeMs, 8000);
    });
  });
}

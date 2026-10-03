import 'dart:math' as math;

import '../sc/models.dart';
import 'camelot_key.dart';

enum EnergyMode {
  buildUp('Build up', 'Raise tempo and energy dynamically'),
  hold('Hold', 'Consistent club tempo and seamless flow'),
  windDown('Cool down', 'Relaxed wind-down with decreasing tempo');

  const EnergyMode(this.label, this.description);
  final String label;
  final String description;

  static EnergyMode fromString(String? s) => switch (s?.toLowerCase()) {
    'buildup' || 'build_up' || 'aufbauen' => EnergyMode.buildUp,
    'winddown' || 'wind_down' || 'abkühlen' => EnergyMode.windDown,
    _ => EnergyMode.hold,
  };
}

enum TransitionStyle {
  harmonicClubBlend('Harmonic Club Blend', 16, '16 beats • smooth frequency blend for harmonic keys'),
  energyDropCut('Energy Drop Cut', 8, '8 beats • dynamic build-up cut right onto the drop'),
  powerSwap('Downbeat Power Swap', 4, '4 beats • quick cut right on bar 1'),
  extendedFlow('Extended 32-Beat Mix', 32, '32 Beats • Tiefe, langsame Club-Verschmelzung'),
  smartBassCross('Bass-Ducked Transition', 16, '16 beats • bass swap without frequency overlap');

  const TransitionStyle(this.title, this.defaultPhraseBeats, this.description);
  final String title;
  final int defaultPhraseBeats;
  final String description;
}

class TrackMatch {
  const TrackMatch({
    required this.track,
    required this.score,
    required this.bpm,
    this.key,
    required this.bpmDelta,
    required this.bpmPercentDelta,
    required this.harmonicDistance,
    required this.isHarmonic,
    required this.matchDescription,
    this.mixInPointMs,
    this.mixOutPointMs,
    this.energyLevel = 5,
    this.transitionStyle = TransitionStyle.harmonicClubBlend,
  });

  final Track track;
  final double score; // 0.0 .. 100.0
  final double bpm;
  final CamelotKey? key;
  final double bpmDelta;
  final double bpmPercentDelta;
  final int harmonicDistance;
  final bool isHarmonic;
  final String matchDescription;
  final int? mixInPointMs;
  final int? mixOutPointMs;
  final int energyLevel; // 1 .. 10
  final TransitionStyle transitionStyle;
}

/// Harmonic and tempo scoring engine for DJ Flow.
abstract final class HarmonicMixer {
  static const maxBpmToleranceRatio = 0.08; // +/- 8% Standard-Pitchbereich

  /// Normalises the tempo into the canonical electronic range [90..180 BPM].
  static double normalizeBpm(double bpm) {
    if (bpm <= 0) return 0;
    var b = bpm;
    while (b < 90) {
      b *= 2;
    }
    while (b > 180) {
      b /= 2;
    }
    return b;
  }

  /// Scores a follow-up candidate against the currently playing track.
  static TrackMatch scoreCandidate({
    required double currentBpm,
    required CamelotKey? currentKey,
    required Track candidateTrack,
    required double candidateBpm,
    required CamelotKey? candidateKey,
    EnergyMode mode = EnergyMode.hold,
    int? mixInPointMs,
    int? mixOutPointMs,
    int? candidateEnergy,
    int? currentEnergy,
  }) {
    final hasBpm = currentBpm > 0 && candidateBpm > 0;
    final hasKey = currentKey != null && candidateKey != null;

    final normCurrentBpm = normalizeBpm(currentBpm);
    final normCandidateBpm = normalizeBpm(candidateBpm);

    final ratio = hasBpm ? normCandidateBpm / normCurrentBpm : 1.0;
    final deltaPct = ratio - 1.0;
    final absDeltaPct = deltaPct.abs();

    // 1. BPM score (0..40 points)
    double bpmScore;
    if (!hasBpm) {
      bpmScore = 20.0;
    } else if (absDeltaPct <= maxBpmToleranceRatio) {
      bpmScore = 40.0 * (1.0 - (absDeltaPct / maxBpmToleranceRatio) * 0.75);
    } else {
      bpmScore = 0.0;
    }

    // 2. Harmonic key score (0..40 points)
    final harmonicDist = hasKey ? currentKey.distanceTo(candidateKey) : 3;
    final isHarmonic = hasKey && currentKey.isHarmonicWith(candidateKey);

    double harmonicScore;
    if (!hasKey) {
      harmonicScore = 20.0;
    } else {
      if (currentKey.isExactMatch(candidateKey)) {
        harmonicScore = 40.0;
      } else if (currentKey.isRelativeMajorMinor(candidateKey)) {
        harmonicScore = 38.0;
      } else if (currentKey.isAdjacentOnWheel(candidateKey)) {
        harmonicScore = 36.0;
      } else if (harmonicDist == 2) {
        harmonicScore = 24.0;
      } else if (harmonicDist == 3) {
        harmonicScore = 10.0;
      } else {
        harmonicScore = 0.0;
      }
    }

    // 3. Energy mode alignment (0..20 points)
    double energyScore;
    if (!hasBpm) {
      energyScore = 10.0;
    } else {
      switch (mode) {
        case EnergyMode.buildUp:
          if (deltaPct >= 0.005 && deltaPct <= 0.035) {
            energyScore = 20.0;
          } else if (deltaPct >= 0.0 && deltaPct < 0.005) {
            energyScore = 15.0;
          } else if (deltaPct > 0.035 && deltaPct <= maxBpmToleranceRatio) {
            energyScore = 12.0;
          } else if (deltaPct < 0.0) {
            energyScore = math.max(0.0, 8.0 + deltaPct * 150.0);
          } else {
            energyScore = 0.0;
          }
        case EnergyMode.hold:
          if (absDeltaPct <= 0.015) {
            energyScore = 20.0;
          } else if (absDeltaPct <= 0.04) {
            energyScore = 15.0;
          } else if (absDeltaPct <= maxBpmToleranceRatio) {
            energyScore = math.max(5.0, 20.0 * (1.0 - (absDeltaPct / maxBpmToleranceRatio)));
          } else {
            energyScore = 0.0;
          }
        case EnergyMode.windDown:
          if (deltaPct >= -0.035 && deltaPct <= -0.005) {
            energyScore = 20.0;
          } else if (deltaPct <= 0.0 && deltaPct > -0.005) {
            energyScore = 15.0;
          } else if (deltaPct < -0.035 && deltaPct >= -maxBpmToleranceRatio) {
            energyScore = 12.0;
          } else if (deltaPct > 0.0) {
            energyScore = math.max(0.0, 8.0 - deltaPct * 150.0);
          } else {
            energyScore = 0.0;
          }
      }
    }

    // Measured energy (1..10) shifts the score to suit the mode (±8 points).
    if (candidateEnergy != null && currentEnergy != null) {
      final d = (candidateEnergy - currentEnergy).toDouble();
      energyScore += switch (mode) {
        EnergyMode.buildUp => (d * 3).clamp(-8.0, 8.0),
        EnergyMode.windDown => (-d * 3).clamp(-8.0, 8.0),
        EnergyMode.hold => (4 - d.abs() * 2).clamp(-8.0, 4.0),
      };
    }

    var total = (bpmScore + harmonicScore + energyScore).clamp(0.0, 100.0);

    // Strict guard: if the tempo differs by > 8 %, dampen the score heavily
    if (hasBpm && absDeltaPct > maxBpmToleranceRatio) {
      total = math.min(total * 0.25, 20.0);
    }

    // Determine a fitting transition style
    final style = switch (harmonicDist) {
      0 when absDeltaPct < 0.02 => TransitionStyle.harmonicClubBlend,
      1 => TransitionStyle.smartBassCross,
      2 when deltaPct > 0.01 => TransitionStyle.energyDropCut,
      _ => absDeltaPct < 0.03 ? TransitionStyle.powerSwap : TransitionStyle.harmonicClubBlend,
    };

    final rawBpmDelta = hasBpm ? (normCandidateBpm - normCurrentBpm) : 0.0;

    final descParts = <String>[];
    if (hasKey) {
      if (currentKey.isExactMatch(candidateKey)) {
        descParts.add('Same key (${candidateKey.code})');
      } else if (currentKey.isRelativeMajorMinor(candidateKey)) {
        descParts.add('Relative key (${currentKey.code}→${candidateKey.code})');
      } else if (currentKey.isAdjacentOnWheel(candidateKey)) {
        descParts.add('Harmonic (${currentKey.code}→${candidateKey.code})');
      } else {
        descParts.add('Key change (${currentKey.code}→${candidateKey.code})');
      }
    } else if (candidateKey != null) {
      descParts.add('Key ${candidateKey.code}');
    }

    if (hasBpm) {
      final sign = rawBpmDelta >= 0 ? '+' : '';
      descParts.add('$sign${rawBpmDelta.toStringAsFixed(1)} BPM');
    }

    final explanation = descParts.isNotEmpty ? descParts.join(' • ') : 'Candidate';

    final baseEnergy =
        candidateEnergy ??
        (candidateBpm > 0
            ? (((candidateBpm - 70.0) / 10.0).clamp(1.0, 8.0) +
                      (candidateKey != null && !candidateKey.isMinor ? 1.5 : 0.5))
                  .round()
                  .clamp(1, 10)
            : 5);

    return TrackMatch(
      track: candidateTrack,
      score: total,
      bpm: normCandidateBpm,
      key: candidateKey,
      bpmDelta: rawBpmDelta,
      bpmPercentDelta: deltaPct,
      harmonicDistance: harmonicDist,
      isHarmonic: isHarmonic,
      matchDescription: explanation,
      mixInPointMs: mixInPointMs,
      mixOutPointMs: mixOutPointMs,
      energyLevel: baseEnergy,
      transitionStyle: style,
    );
  }
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pounce/dj/beat_analyzer.dart';
import 'package:pounce/dj/dj_flow_controller.dart';

void main() {
  // 120 BPM: Beat 500 ms, Takt 2000 ms, Raster ab 0.
  BeatInfo info({int? cue, int? drop}) =>
      const BeatInfo(bpm: 120, firstBeatOffsetMs: 0, confidence: .9).withEvents(cue: cue, drop: drop, strength: .7);

  test('drop lands on the end of the crossfade', () {
    // 16 beats = 8 s crossfade, drop at 32 s → entry at 24 s.
    final e = mixEntry(info: info(cue: 300, drop: 32000), fadeMs: 8000, tempo: 1, fallbackMs: 0);
    expect(e, (startMs: 24000, fadeMs: 8000));
  });

  test('tempo matching shifts the entry', () {
    // New track runs 5 % faster: in 8 s of real time 8.4 s of its time pass.
    final e = mixEntry(info: info(cue: 0, drop: 32000), fadeMs: 8000, tempo: 1.05, fallbackMs: 0);
    expect(e.startMs, 32000 - 8400);
  });

  test('early drop: from the cue bar, crossfade stretched to the drop', () {
    // Cue 300 ms → first bar 2000 ms; drop 6000 ms → 4 s crossfade.
    final e = mixEntry(info: info(cue: 300, drop: 6000), fadeMs: 8000, tempo: 1, fallbackMs: 0);
    expect(e, (startMs: 2000, fadeMs: 4000));
  });

  test('no drop: first bar after the cue instead of silence', () {
    final e = mixEntry(info: info(cue: 1500), fadeMs: 8000, tempo: 1, fallbackMs: 0);
    expect(e, (startMs: 2000, fadeMs: 8000));
  });

  test('no analysis: old mix point', () {
    expect(mixEntry(info: null, fadeMs: 8000, tempo: 1, fallbackMs: 16000), (startMs: 16000, fadeMs: 8000));
  });

  test('cue/drop survive storage', () {
    final a = info(cue: 350, drop: 13220);
    final b = BeatInfo.fromJson(jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>)!;
    expect((b.cueMs, b.dropMs, b.eventsScanned), (350, 13220, true));
    final old = BeatInfo.fromJson(
      jsonDecode(jsonEncode(const BeatInfo(bpm: 120, firstBeatOffsetMs: 0, confidence: .9).toJson()))
          as Map<String, dynamic>,
    )!;
    expect((old.cueMs, old.eventsScanned), (null, false));
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/dj/beat_analyzer.dart';
import 'package:pounce/dj/camelot_key.dart';
import 'package:pounce/sc/models.dart';
import 'package:pounce/sc/soundcloud.dart';

void main() {
  test('stored analysis comes back from the database', () async {
    final store = Store.memory();
    final sc = SoundCloud(store, Settings(store));
    const info = BeatInfo(bpm: 128, firstBeatOffsetMs: 120, confidence: .9, key: CamelotKey.key8A);
    await store.db.write(Table.beat, {'42': jsonEncode(info.toJson())});
    final a = BeatAnalyzer(sc, store);
    const t = Track(
      id: 42,
      title: 'x',
      user: ScUser(id: 1, username: 'u'),
      durationMs: 200000,
    );
    final got = await a.analyze(t, priority: true).timeout(const Duration(seconds: 5));
    expect(got?.bpm, 128);
    expect(got?.key, CamelotKey.key8A);
  });
}

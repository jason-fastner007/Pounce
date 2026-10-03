import 'package:flutter_test/flutter_test.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/dj/beat_analyzer.dart';
import 'package:pounce/dj/taste.dart';
import 'package:pounce/sc/models.dart';

Track t(int id, String artist, {String title = 'Song'}) => Track(
  id: id,
  title: title,
  user: ScUser(id: id, username: artist),
  durationMs: 240000,
);
const fast = BeatInfo(bpm: 150, firstBeatOffsetMs: 0, confidence: .9);
const slow = BeatInfo(bpm: 122, firstBeatOffsetMs: 0, confidence: .9);

void main() {
  test('early skip bans the song, ♥ lifts the ban', () {
    final m = TasteModel(Store.memory());
    m.record(t(1, 'a'), null, Outcome.earlySkip);
    expect(m.isBanned(t(1, 'a')), isTrue);
    m.record(t(1, 'a'), null, Outcome.like);
    expect(m.isBanned(t(1, 'a')), isFalse);
  });

  test('skips lower artist and tempo, full listens raise them', () {
    final m = TasteModel(Store.memory());
    for (var i = 0; i < 4; i++) {
      m.record(t(10 + i, 'skipper'), fast, Outcome.skip);
      m.record(t(20 + i, 'liebling'), slow, Outcome.complete);
    }
    expect(m.score(t(99, 'skipper'), fast), lessThan(-.3));
    expect(m.score(t(98, 'liebling'), slow), greaterThan(.3));
    // Unknown artist at the skipped tempo: slightly negative; at the liked one: slightly positive.
    expect(m.score(t(97, 'neu'), fast), lessThan(0));
    expect(m.score(t(96, 'neu'), slow), greaterThan(0));
    expect(m.score(t(95, 'neu'), null), 0);
  });

  test('learned taste survives a restart', () {
    final store = Store.memory();
    TasteModel(store)
      ..record(t(1, 'x'), fast, Outcome.earlySkip)
      ..record(t(2, 'x'), fast, Outcome.skip);
    final again = TasteModel(store);
    expect(again.isBanned(t(1, 'x')), isTrue);
    expect(again.score(t(3, 'x'), fast), lessThan(0));
  });
}

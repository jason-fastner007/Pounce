import 'package:flutter/foundation.dart';

import '../core/store.dart';
import '../sc/models.dart';
import 'beat_analyzer.dart';
import 'mix_builder.dart';

/// How a song was left in DJ mode.
enum Outcome {
  /// Skipped early (< 30 s or < 15 %): disliked – won't appear in mixes again.
  earlySkip,

  /// Skipped later: probably not.
  skip,

  /// Listened to the end or crossfaded by DJ Flow.
  complete,

  /// Mit ♥ markiert.
  like,
}

/// Learns from skips and fully played songs what you like in DJ mode: artist, category,
/// tempo range and energy. Each feature collects pluses and minuses; older signals fade
/// (every new rating damps all of them by 2 %), so taste is allowed to change over time.
class TasteModel extends ChangeNotifier {
  TasteModel(this.store) {
    final raw = store.get<Map>('dj_taste');
    if (raw != null) {
      for (final e in ((raw['f'] as Map?) ?? const {}).entries) {
        final v = (e.value as List).cast<num>();
        _features[e.key as String] = (v[0].toDouble(), v[1].toDouble());
      }
      _banned.addAll(((raw['b'] as List?) ?? const []).cast<int>());
    }
  }

  final Store store;
  final _features = <String, (double, double)>{};
  final _banned = <int>{};

  /// Recently learned (for display in the DJ player), newest first.
  final recent = <String>[];

  static const _decay = .98;
  static const _maxBanned = 3000;

  bool isBanned(Track t) => _banned.contains(t.id);

  /// Features of a song: artist, categories, tempo (10 BPM ranges), energy.
  static List<String> features(Track t, BeatInfo? info) => [
    'artist:${(t.artist ?? t.user.username).toLowerCase()}',
    for (final c in DjCategory.all)
      if (c.matches(t, bpm: info?.bpm)) 'cat:${c.id}',
    if (info != null && info.bpm > 0) 'bpm:${(info.bpm / 10).floor() * 10}',
    if (info != null && info.source == BeatSource.pcm) 'energy:${info.energyLevel}',
  ];

  /// Weight per feature kind in [score].
  static double _weight(String feature) => switch (feature.split(':').first) {
    'artist' => .4,
    'bpm' => .25,
    'cat' => .2,
    _ => .15,
  };

  /// Rates a song that was left.
  void record(Track t, BeatInfo? info, Outcome outcome) {
    final signal = switch (outcome) {
      Outcome.earlySkip => -1.0,
      Outcome.skip => -.5,
      Outcome.complete => .5,
      Outcome.like => 1.0,
    };
    for (final k in _features.keys.toList()) {
      final (p, n) = _features[k]!;
      _features[k] = (p * _decay, n * _decay);
    }
    _features.removeWhere((_, v) => v.$1 + v.$2 < .05);
    for (final f in features(t, info)) {
      final (p, n) = _features[f] ?? (0.0, 0.0);
      _features[f] = signal > 0 ? (p + signal, n) : (p, n - signal);
    }
    if (outcome == Outcome.earlySkip) {
      _banned.add(t.id);
      if (_banned.length > _maxBanned) _banned.remove(_banned.first);
    } else if (outcome == Outcome.like) {
      _banned.remove(t.id);
    }
    _note(t, info, outcome);
    _save();
    notifyListeners();
  }

  /// Preference for a song, −1 … +1 (0 = unknown). Uncertain features count less
  /// (smoothed with 2 pseudo-ratings).
  double score(Track t, BeatInfo? info) {
    var s = 0.0;
    for (final f in features(t, info)) {
      final v = _features[f];
      if (v == null) continue;
      s += _weight(f) * (v.$1 - v.$2) / (v.$1 + v.$2 + 2);
    }
    return s.clamp(-1.0, 1.0);
  }

  /// Forget everything.
  void reset() {
    _features.clear();
    _banned.clear();
    recent.clear();
    _save();
    notifyListeners();
  }

  void _note(Track t, BeatInfo? info, Outcome o) {
    final who = t.artist ?? t.user.username;
    final what = switch (o) {
      Outcome.earlySkip => '✕ $who · ${t.title}',
      Outcome.skip => '− $who${info != null && info.bpm > 0 ? ' · ${info.bpm.round()} BPM' : ''}',
      Outcome.complete => '+ $who',
      Outcome.like => '♥ $who',
    };
    recent.insert(0, what);
    if (recent.length > 6) recent.removeLast();
  }

  void _save() => store.set('dj_taste', {
    'f': {
      for (final e in _features.entries) e.key: [e.value.$1, e.value.$2],
    },
    'b': _banned.toList(),
  });
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/store.dart';
import '../player/player_controller.dart';
import '../sc/models.dart';
import 'beat_analyzer.dart';
import 'camelot_key.dart';
import 'harmonic_mixer.dart';
import 'taste.dart';

enum TransitionPhase { idle, preparing, crossfading }

/// Position in the beat grid – changes once per beat (not per frame).
@immutable
class BeatClock {
  const BeatClock({this.bar = 1, this.beatInBar = 1, this.beatInPhrase = 1, this.beatsUntilTransition});

  final int bar; // 1 .. 4 (bar within the phrase)
  final int beatInBar; // 1 .. 4
  final int beatInPhrase; // 1 .. 16
  final int? beatsUntilTransition;

  bool get isDownbeat => beatInBar == 1;

  @override
  bool operator ==(Object other) =>
      other is BeatClock &&
      other.bar == bar &&
      other.beatInBar == beatInBar &&
      other.beatInPhrase == beatInPhrase &&
      other.beatsUntilTransition == beatsUntilTransition;

  @override
  int get hashCode => Object.hash(bar, beatInBar, beatInPhrase, beatsUntilTransition);
}

class DjFlowState {
  const DjFlowState({
    this.isActive = false,
    this.currentBpm = 0.0,
    this.currentKey,
    this.targetBpm = 0.0,
    this.targetKey,
    this.energyMode = EnergyMode.hold,
    this.transitionPhase = TransitionPhase.idle,
    this.nextTrackMatch,
    this.suggestedMatches = const [],
    this.isAutonomousEnabled = true,
    this.isAutoReorderEnabled = true,
    this.analyzing = false,
  });

  final bool isActive;
  final double currentBpm;
  final CamelotKey? currentKey;
  final double targetBpm;
  final CamelotKey? targetKey;
  final EnergyMode energyMode;
  final TransitionPhase transitionPhase;
  final TrackMatch? nextTrackMatch;
  final List<TrackMatch> suggestedMatches;
  final bool isAutonomousEnabled;
  final bool isAutoReorderEnabled;

  /// An audio analysis is currently running (for display).
  final bool analyzing;

  DjFlowState copyWith({
    bool? isActive,
    double? currentBpm,
    CamelotKey? Function()? currentKey,
    double? targetBpm,
    CamelotKey? Function()? targetKey,
    EnergyMode? energyMode,
    TransitionPhase? transitionPhase,
    TrackMatch? Function()? nextTrackMatch,
    List<TrackMatch>? suggestedMatches,
    bool? isAutonomousEnabled,
    bool? isAutoReorderEnabled,
    bool? analyzing,
  }) => DjFlowState(
    isActive: isActive ?? this.isActive,
    currentBpm: currentBpm ?? this.currentBpm,
    currentKey: currentKey != null ? currentKey() : this.currentKey,
    targetBpm: targetBpm ?? this.targetBpm,
    targetKey: targetKey != null ? targetKey() : this.targetKey,
    energyMode: energyMode ?? this.energyMode,
    transitionPhase: transitionPhase ?? this.transitionPhase,
    nextTrackMatch: nextTrackMatch != null ? nextTrackMatch() : this.nextTrackMatch,
    suggestedMatches: suggestedMatches ?? this.suggestedMatches,
    isAutonomousEnabled: isAutonomousEnabled ?? this.isAutonomousEnabled,
    isAutoReorderEnabled: isAutoReorderEnabled ?? this.isAutoReorderEnabled,
    analyzing: analyzing ?? this.analyzing,
  );
}

/// Main coordinator for DJ Flow & non-stop automix.
///
/// The transition starts via a precisely set timer on the phrase grid of the current
/// track (not via position polling). The next track enters at its mix-in point,
/// also a phrase boundary, with matched tempo – so the downbeats line up.
class DjFlowController extends ChangeNotifier {
  DjFlowController({required this.player, required this.analyzer, required this.store}) {
    _state = DjFlowState(
      isActive: store.get<bool>('dj_active') ?? false,
      energyMode: EnergyMode.fromString(store.get<String>('dj_energy')),
      isAutonomousEnabled: store.get<bool>('dj_autonomous') ?? true,
      isAutoReorderEnabled: store.get<bool>('dj_autoreorder') ?? true,
    );
    player.addListener(_onPlayer);
    player.position.addListener(_onPosition);
    player.djOwnsTransitions = _state.isActive;
  }

  // ---------- Vorausanalyse ----------

  /// This many upcoming songs are analysed in the background (20 or 50, ~0.5 MB per song).
  int get lookahead => store.get<int>('dj_lookahead') ?? 20;
  set lookahead(int v) {
    store.set('dj_lookahead', v);
    notifyListeners();
    _analyzeAhead();
  }

  /// Progress of the look-ahead analysis: (done, planned).
  final ahead = ValueNotifier<(int, int)>((0, 0));
  int _aheadToken = 0;
  Timer? _reevaluate;

  /// Analyses the next [lookahead] songs of the queue (cached: each only once). With every
  /// finished song the transition choice is re-evaluated – it then knows more candidates.
  Future<void> _analyzeAhead() async {
    final token = ++_aheadToken;
    if (!_state.isActive) {
      ahead.value = (0, 0);
      return;
    }
    final upcoming = player.queue
        .skip(math.max(0, player.index + 1))
        .where((t) => !t.isLive && t.playable)
        .take(lookahead)
        .toList();
    var done = upcoming.where((t) => analyzer.peek(t) != null).length;
    ahead.value = (done, upcoming.length);
    for (final t in upcoming) {
      if (token != _aheadToken || !_state.isActive) return;
      if (analyzer.peek(t) != null) continue;
      await analyzer.analyze(t);
      if (token != _aheadToken) return;
      ahead.value = (++done, upcoming.length);
      // Re-evaluate in batches (not after every single song).
      _reevaluate?.cancel();
      _reevaluate = Timer(const Duration(seconds: 2), () {
        if (_state.isActive && !_transitionTriggered) _evaluateQueue();
      });
    }
  }

  final PlayerController player;
  final BeatAnalyzer analyzer;

  /// Learned preferences (skips/likes); feed into the choice of the next song.
  TasteModel? taste;
  final Store store;

  late DjFlowState _state;
  DjFlowState get state => _state;

  /// Bar/beat position (updated once per beat).
  final beat = ValueNotifier(const BeatClock());

  Track? _lastTrack;
  BeatInfo? _currentBeatInfo;
  BeatInfo? get currentBeatInfo => _currentBeatInfo;
  bool _transitionTriggered = false;
  Timer? _mixTimer;
  bool _wasPlaying = false;
  int _evalToken = 0;

  /// Filter for candidates (AI block list).
  bool Function(Track t)? allow;

  void _set(DjFlowState s) {
    _state = s;
    notifyListeners();
  }

  void toggleDjFlow() {
    final next = !_state.isActive;
    store.set('dj_active', next);
    _set(_state.copyWith(isActive: next));
    // DJ Flow pre-buffers itself (at the mix point) – the player's auto-advance then stays out of it.
    player.djOwnsTransitions = next;
    if (next) {
      _evaluateCurrentAndQueue();
    } else {
      _mixTimer?.cancel();
    }
  }

  void setEnergyMode(EnergyMode mode) {
    store.set('dj_energy', mode.name);
    _set(_state.copyWith(energyMode: mode));
    _evaluateQueue();
  }

  void setAutonomous(bool enabled) {
    store.set('dj_autonomous', enabled);
    _set(_state.copyWith(isAutonomousEnabled: enabled));
    _scheduleMix();
  }

  void setAutoReorder(bool enabled) {
    store.set('dj_autoreorder', enabled);
    _set(_state.copyWith(isAutoReorderEnabled: enabled));
    if (enabled) _evaluateQueue();
  }

  void _onPlayer() {
    final current = player.current;
    if (current != _lastTrack) {
      _lastTrack = current;
      _transitionTriggered = false;
      _currentBeatInfo = null;
      _mixTimer?.cancel();
      _evaluateCurrentAndQueue();
    }
    if (player.playing != _wasPlaying) {
      _wasPlaying = player.playing;
      _scheduleMix();
    }
  }

  Future<void> _evaluateCurrentAndQueue() async {
    final current = player.current;
    if (current == null || current.isLive) {
      _set(
        _state.copyWith(currentBpm: 0, currentKey: () => null, nextTrackMatch: () => null, suggestedMatches: const []),
      );
      return;
    }
    // Analysis always runs (visualisation and AI use it) – only the transitions need DJ Flow.
    _set(_state.copyWith(analyzing: true));
    final info = await analyzer.analyze(current, priority: true);
    if (player.current?.id != current.id) return;
    _currentBeatInfo = info;
    _set(_state.copyWith(currentBpm: info?.bpm ?? 0, currentKey: () => info?.key, analyzing: false));
    _scheduleMix();
    if (_state.isActive) await _evaluateQueue();
    _analyzeAhead();
  }

  Future<void> _evaluateQueue() async {
    final current = player.current;
    if (current == null || !_state.isActive) return;
    final token = ++_evalToken;

    final currBpm = _state.currentBpm > 0 ? _state.currentBpm : 125.0;
    final currKey = _state.currentKey;
    final upcoming = player.queue
        .skip(math.max(0, player.index + 1))
        .where((t) => !t.isLive && (allow?.call(t) ?? true))
        .toList();
    // The next 6 in any case (analysing them now if necessary), plus everything the
    // look-ahead analysis already knows – the more candidates, the better the transition.
    final candidates = [
      ...upcoming.take(6),
      ...upcoming.skip(6).take(lookahead).where((t) => analyzer.peek(t) != null),
    ];
    if (candidates.isEmpty) {
      _set(_state.copyWith(nextTrackMatch: () => null, suggestedMatches: const []));
      return;
    }

    final matches = <TrackMatch>[];
    for (final cand in candidates) {
      final info = await analyzer.analyze(cand);
      if (token != _evalToken) return;
      matches.add(
        HarmonicMixer.scoreCandidate(
          currentBpm: currBpm,
          currentKey: currKey,
          candidateTrack: cand,
          candidateBpm: info?.bpm ?? currBpm,
          candidateKey: info?.key,
          mode: _state.energyMode,
          mixInPointMs: info?.mixInPointMs ?? info?.phraseOffsetMs,
          mixOutPointMs: info?.mixOutPointMs,
          candidateEnergy: info?.energyLevel,
          currentEnergy: _currentBeatInfo?.energyLevel,
        ),
      );
    }
    // Harmony/tempo (0–100) plus learned preference (±25): what you skip moves to the back.
    double rank(TrackMatch m) => m.score + 25 * (taste?.score(m.track, analyzer.peek(m.track)) ?? 0);
    matches.sort((a, b) => rank(b).compareTo(rank(a)));
    final best = matches.firstOrNull;
    _set(
      _state.copyWith(
        nextTrackMatch: () => best,
        suggestedMatches: matches,
        targetBpm: best?.bpm ?? 0,
        targetKey: () => best?.key,
      ),
    );
    if (best == null) return;
    // Pull the best transitions forward (only if wanted and the next one doesn't fit already).
    if (_state.isAutoReorderEnabled && player.queue.elementAtOrNull(player.index + 1) != best.track) {
      player.reorderUpcoming([for (final m in matches) m.track]);
    }
    // Pre-buffer the next track on the second deck: 0 ms latency at the mix.
    player.prebufferTrack(best.track, start: Duration(milliseconds: _plan(best).startMs));
    // Find cue/drop of the next track; then pre-buffer again with the more accurate entry.
    analyzer.events(best.track).then((_) {
      final m = _state.nextTrackMatch;
      if (m != null && m.track == best.track && !_transitionTriggered) {
        player.prebufferTrack(m.track, start: Duration(milliseconds: _plan(m).startMs));
        notifyListeners(); // display: entry/drop of the next track
      }
    });
  }

  /// Planned transition into the next track (for display), null = none.
  ({int startMs, int fadeMs, double tempo})? get nextPlan {
    final m = _state.nextTrackMatch;
    return m == null ? null : _plan(m);
  }

  /// Analysis of the next track incl. cue/drop, once known.
  BeatInfo? get nextInfo {
    final m = _state.nextTrackMatch;
    return m == null ? null : analyzer.peek(m.track);
  }

  /// Transition into [match]: entry point in the new track, fade length and tempo. Pre-buffering and
  /// triggering use the same plan – otherwise the crossfade would have to seek.
  ///
  /// If the new track's drop is known, it starts exactly as many beats before it as the
  /// crossfade lasts: when the old track has faded out, the drop hits. Otherwise entry at
  /// the first bar after the cue (no silence), as a last resort at the phrase mix point.
  ({int startMs, int fadeMs, double tempo}) _plan(TrackMatch match) {
    final bpm = _state.currentBpm;
    // Match the tempo when it fits musically (±8 %), otherwise original.
    final ratio = bpm > 0 && match.bpm > 0 ? HarmonicMixer.normalizeBpm(bpm) / match.bpm : 1.0;
    final tempo = (ratio - 1).abs() <= HarmonicMixer.maxBpmToleranceRatio ? ratio : 1.0;
    // Fade length = phrase length of the style (in beats), 3–16 s.
    final periodMs = 60000 / (bpm > 0 ? bpm : 125);
    final fadeMs = (match.transitionStyle.defaultPhraseBeats * periodMs).clamp(3000, 16000).round();
    final e = mixEntry(
      info: analyzer.peek(match.track),
      fadeMs: fadeMs,
      tempo: tempo,
      fallbackMs: match.mixInPointMs ?? 0,
    );
    return (startMs: e.startMs, fadeMs: e.fadeMs, tempo: tempo);
  }

  int get _mixOutMs {
    final durMs = player.duration.inMilliseconds;
    return _currentBeatInfo?.mixOutPointMs ?? (durMs > 10000 ? durMs - 8000 : durMs);
  }

  /// Sets the transition exactly on the mix-out phrase (instead of the next position tick).
  void _scheduleMix() {
    _mixTimer?.cancel();
    if (!_state.isActive || !_state.isAutonomousEnabled || _transitionTriggered || !player.playing) return;
    final durMs = player.duration.inMilliseconds;
    if (durMs <= 15000 || player.isLive) return;
    final wait = _mixOutMs - player.livePosition.inMilliseconds;
    if (wait < 0) return;
    _mixTimer = Timer(Duration(milliseconds: wait), () {
      if (_transitionTriggered || !player.playing) return;
      // Correction: seeks while waiting.
      final left = _mixOutMs - player.livePosition.inMilliseconds;
      if (left > 40) {
        _scheduleMix();
        return;
      }
      _transitionTriggered = true;
      triggerMixNow();
    });
  }

  int _lastPos = 0;

  void _onPosition() {
    final posMs = player.position.value.inMilliseconds;
    // Jump (seek) -> reset the timer.
    if ((posMs - _lastPos).abs() > 1500) _scheduleMix();
    _lastPos = posMs;
    if (!_state.isActive) return;

    final info = _currentBeatInfo;
    final bpm = _state.currentBpm > 0 ? _state.currentBpm : 125.0;
    final periodMs = 60000.0 / bpm;
    // Bar 1 counts from the detected downbeat or the phrase boundary.
    final anchor = info?.phraseOffsetMs ?? info?.firstBeatOffsetMs ?? 0;
    final elapsed = (posMs - anchor).toDouble();
    if (elapsed < 0) return;
    final total = (elapsed / periodMs).floor();
    final remaining = math.max(0, _mixOutMs - posMs);
    beat.value = BeatClock(
      bar: ((total ~/ 4) % 4) + 1,
      beatInBar: (total % 4) + 1,
      beatInPhrase: (total % 16) + 1,
      beatsUntilTransition: (remaining / periodMs).round(),
    );

    // Pre-buffer in time (12 s before the transition).
    final next = _state.nextTrackMatch?.track;
    final match = _state.nextTrackMatch;
    if (next != null && match != null && remaining >= 2000 && remaining <= 12000) {
      player.prebufferTrack(next, start: Duration(milliseconds: _plan(match).startMs));
    }
  }

  /// Triggers a harmonic, tempo-matched transition (equal power, no pause).
  ///
  /// [skip]: triggered by the user (skip in the DJ player) – counts as a skip for learning, but
  /// is still crossfaded cleanly.
  void triggerMixNow({bool skip = false}) {
    final match = _state.nextTrackMatch;
    if (match == null) {
      player.next(auto: !skip);
      return;
    }
    _transitionTriggered = true;
    _mixTimer?.cancel();
    final plan = _plan(match);
    final fadeMs = plan.fadeMs;

    _set(_state.copyWith(transitionPhase: TransitionPhase.crossfading));
    player.crossfadeTo(
      match.track,
      start: Duration(milliseconds: plan.startMs),
      crossfadeDuration: Duration(milliseconds: skip ? math.min(fadeMs, 4000) : fadeMs),
      tempoRatio: plan.tempo,
      skipped: skip,
    );
    Timer(Duration(milliseconds: fadeMs + 300), () => _set(_state.copyWith(transitionPhase: TransitionPhase.idle)));
  }

  @override
  void dispose() {
    _mixTimer?.cancel();
    _reevaluate?.cancel();
    ahead.dispose();
    beat.dispose();
    player.removeListener(_onPlayer);
    player.position.removeListener(_onPosition);
    super.dispose();
  }
}

/// Entry into the new track (ms on its timeline) and fade length (ms of real time).
///
/// [tempo]: playback speed of the new track during the crossfade (beat matching).
/// With a known drop it starts as many beats before it as the crossfade lasts – the drop lands
/// on the end of the crossfade. If the drop comes too early for that, entry is at the cue bar
/// and the crossfade is stretched up to the drop. Without a drop: first bar after the cue.
({int startMs, int fadeMs}) mixEntry({
  required BeatInfo? info,
  required int fadeMs,
  required double tempo,
  required int fallbackMs,
}) {
  if (info == null || !info.hasGrid) return (startMs: fallbackMs, fadeMs: fadeMs);
  final bar = info.periodMs * 4;
  final anchor = info.downbeatOffsetMs.toDouble();
  final cue = info.cueMs;
  // First bar start from the cue (skip silence at the start).
  final cueBar = cue == null ? null : math.max(0, (anchor + ((cue - anchor) / bar).ceil() * bar).round());
  final drop = info.dropMs;
  final inNew = fadeMs * tempo; // how far the new track plays during the crossfade
  if (drop != null && drop - inNew >= (cueBar ?? 0)) {
    return (startMs: (drop - inNew).round(), fadeMs: fadeMs);
  }
  if (drop != null && cueBar != null && (drop - cueBar) / tempo >= 3000) {
    return (startMs: cueBar, fadeMs: ((drop - cueBar) / tempo).round());
  }
  if (cueBar != null && cueBar > fallbackMs) return (startMs: cueBar, fadeMs: fadeMs);
  return (startMs: fallbackMs, fadeMs: fadeMs);
}

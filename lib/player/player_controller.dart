import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener, AppLifecycleState;

import '../core/settings.dart';
import '../core/store.dart';
import '../library/library.dart';
import '../sc/models.dart';
import '../sc/soundcloud.dart';
import 'audio_engine.dart';

enum LoopMode { off, all, one }

/// Queue + playback logic. Platform details live in [AudioEngine].
///
/// Notifies ([notifyListeners]) only on real state changes (track, play/pause,
/// loading, queue, duration). The position runs separately via [position] or [livePosition],
/// so lists and the player view aren't rebuilt ten times per second.
class PlayerController extends ChangeNotifier {
  PlayerController(this._engine, this._sc, this._settings, this._library, this._store) {
    _engine.states.listen(_onState);
    _engine.commands.listen(_onCommand);
    _engine.setVolume(_settings.volume);
    _engine.setLoudMode(_settings.loudMode);
    _settings.addListener(_onSettings);
    _restore();
    try {
      _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    } catch (_) {
      // Without a binding (pure logic tests) there is no lifecycle.
    }
  }

  final AudioEngine _engine;
  final SoundCloud _sc;
  final Settings _settings;
  final Library _library;
  final Store _store;
  AppLifecycleListener? _lifecycle;

  List<Track> _queue = [];
  List<Track>? _unshuffled;
  int _index = -1;
  int _loadToken = 0;
  bool _needsLoad = false;
  Duration _resumeAt = Duration.zero;

  EngineState _state = const EngineState();
  DateTime _stateAt = DateTime.now();

  LoopMode repeat = LoopMode.off;
  double speed = 1;
  String? error;

  Timer? _sleepTimer;
  DateTime? sleepAt;

  /// Current stream (codec/bitrate for telemetry).
  StreamInfo? stream;

  /// Time from loading to the first sound of the current track (status line in the player).
  final startLatency = ValueNotifier<Duration?>(null);
  DateTime? _loadAt;

  /// Filter for automatically chosen tracks (e.g. AI block list). false = skip.
  bool Function(Track t)? allow;

  ValueListenable<Loudness> get loudness => _engine.loudness;
  bool get supportsLoudness => _engine.supportsLoudness;
  SpectrumSource? get spectrum => _engine.spectrum;

  /// Title from the stream metadata (radio: ICY "StreamTitle").
  ValueListenable<String?> get streamTitle => _engine.streamTitle;

  /// Direct access to the engine (PCM decoding for analysis).
  AudioEngine get engine => _engine;

  late LoudMode _loudMode = _settings.loudMode;
  void _onSettings() {
    if (_settings.loudMode != _loudMode) {
      _loudMode = _settings.loudMode;
      _engine.setLoudMode(_loudMode);
    }
  }

  /// Master volume (linear 0..1), persisted.
  late final volume = ValueNotifier(_settings.volume);

  /// Current position, smoothly interpolated (20 Hz tick in the foreground, 2 Hz in the background).
  final position = ValueNotifier(Duration.zero);

  /// Current track – only changes on a track change (cheap for lists).
  final currentTrack = ValueNotifier<Track?>(null);

  Timer? _ticker;
  bool _foreground = true;

  List<Track> get queue => List.unmodifiable(_queue);
  int get index => _index;
  Track? get current => _index >= 0 && _index < _queue.length ? _queue[_index] : null;
  bool get shuffle => _unshuffled != null;
  bool get playing => _state.playing;
  bool get loading => _state.status == EngineStatus.loading && current != null;
  bool get isLive => current?.isLive ?? false;
  Duration get duration {
    if (isLive) return Duration.zero;
    return _state.duration > Duration.zero ? _state.duration : Duration(milliseconds: current?.durationMs ?? 0);
  }

  Duration get buffered => _state.buffered;
  bool get hasNext => _index < _queue.length - 1 || repeat == LoopMode.all;

  /// Position right now (extrapolated between two engine reports).
  /// For animations that draw every frame (beat grid, visualisation).
  Duration get livePosition {
    if (!_state.playing) return position.value;
    final p = _state.position + DateTime.now().difference(_stateAt) * speed;
    final d = duration;
    return d > Duration.zero && p > d ? d : p;
  }

  // ---------- Queue ----------

  bool _ok(Track t) =>
      t.playable &&
      (allow?.call(t) ?? true) &&
      !(_settings.skipPreviews && t.isPreview && !t.isLive) &&
      !(djOwnsTransitions && !djFits(t)) &&
      !(djOwnsTransitions && (djExclude?.call(t) ?? false));

  /// In DJ mode only complete, short songs: no 30 s previews, no mixes over 6 minutes.
  static bool djFits(Track t) => t.isLive || (!t.isPreview && t.durationMs <= 6 * 60000);

  Future<void> playQueue(List<Track> tracks, [int start = 0]) async {
    final list = tracks.where((t) => t.playable).toSet().toList();
    // Start at the chosen or next playable track.
    final first = tracks.skip(start).where((t) => t.playable).firstOrNull;
    if (list.isEmpty || first == null) return;
    _queue = list;
    _unshuffled = null;
    _index = list.indexOf(first);
    await _load();
  }

  Future<void> playTrack(Track t) => playQueue([t]);

  /// Resolve the stream URL before the track is started.
  void prefetch(Track t) {
    if (t.playable && !t.isLive) _sc.prefetchStream(t, fast: _settings.fastStart);
  }

  Track? _warmTrack;

  /// true while "ended" can only come from the previous track (see [_onState]).
  bool _staleEnded = false;

  /// A finger rests on a track row: resolve the URL and pre-buffer the track on the free
  /// deck. If it's then tapped, [_load] only swaps the decks.
  Future<void> warm(Track t) async {
    if (!t.playable || t.isLive || t == current) return;
    _warmTrack = t;
    try {
      final s = await _sc.stream(t, fast: _settings.fastStart);
      if (_warmTrack != t) return;
      // The free deck now belongs to this track – a DJ pre-buffer has to reload.
      _prebufferedTrack = null;
      _prebufferedStream = null;
      await _engine.prebuffer(s, _meta(t));
    } catch (_) {}
  }

  /// Not tapped after all (scrolled, long-pressed): discard the pre-buffer, saves data.
  void cool(Track t) {
    if (_warmTrack != t) return;
    _warmTrack = null;
    _engine.cancelPrebuffer().ignore();
  }

  /// Resolve the next queue track ahead of time: "next" and autoplay then start without an API round trip.
  void _prefetchNext() {
    final i = _index + 1;
    if (i < _queue.length) prefetch(_queue[i]);
  }

  void playNext(Track t) {
    if (current == null) {
      playTrack(t);
      return;
    }
    _queue
      ..remove(t)
      ..insert(_index + 1, t);
    _changed();
  }

  void addToQueue(Track t) {
    if (current == null) {
      playTrack(t);
      return;
    }
    if (!_queue.contains(t)) _queue.add(t);
    _changed();
  }

  void removeAt(int i) {
    if (i == _index) return;
    _queue.removeAt(i);
    if (i < _index) _index--;
    _changed();
  }

  void move(int from, int to) {
    final cur = current;
    _queue.insert(to, _queue.removeAt(from));
    _index = _queue.indexOf(cur!);
    _changed();
  }

  /// Reorders the queue after the current track (DJ Flow: best transitions first).
  void reorderUpcoming(List<Track> order) {
    if (_index < 0) return;
    final head = _queue.sublist(0, _index + 1);
    final rest = _queue.sublist(_index + 1);
    final sorted = [
      for (final t in order)
        if (rest.contains(t)) t,
      for (final t in rest)
        if (!order.contains(t)) t,
    ];
    _queue = [...head, ...sorted];
    _changed();
  }

  Future<void> jumpTo(int i) async {
    _index = i;
    await _load();
  }

  void toggleShuffle() {
    final cur = current;
    if (cur == null) return;
    if (_unshuffled == null) {
      _unshuffled = List.of(_queue);
      final rest = _queue.sublist(_index + 1)..shuffle();
      _queue = [..._queue.sublist(0, _index + 1), ...rest];
    } else {
      _queue = _unshuffled!;
      _unshuffled = null;
      _index = _queue.indexOf(cur);
    }
    _changed();
  }

  void cycleRepeat() {
    repeat = LoopMode.values[(repeat.index + 1) % LoopMode.values.length];
    notifyListeners();
  }

  // ---------- Transport ----------

  Future<void> toggle() => playing ? _engine.pause() : play();

  Future<void> play() async {
    if (_needsLoad) return _load(start: _resumeAt);
    await _engine.play();
  }

  Future<void> pause() => _engine.pause();

  Future<void> seek(Duration p) async {
    if (isLive) return;
    position.value = p;
    _stateAt = DateTime.now();
    _state = _state.copyWith(position: p);
    if (_needsLoad) {
      _resumeAt = p;
      return;
    }
    await _engine.seek(p);
  }

  /// Reports how a song was left (DJ learning): played time, duration, skipped by the user?
  void Function(Track track, Duration played, Duration duration, bool skipped)? onLeave;

  /// Additionally leave out in DJ mode (e.g. songs skipped early).
  bool Function(Track track)? djExclude;

  void _left({required bool skipped}) {
    final t = current;
    if (t == null || t.isLive) return;
    onLeave?.call(t, livePosition, duration, skipped);
  }

  /// Next song. [auto]: on its own (end, error, DJ) – otherwise the user skipped.
  Future<void> next({bool auto = false}) async {
    _left(skipped: !auto);
    var i = _index + 1;
    // Skip blocked tracks (AI filter).
    while (i < _queue.length && !_ok(_queue[i])) {
      i++;
    }
    if (i < _queue.length) {
      _index = i;
    } else if (repeat == LoopMode.all && _queue.isNotEmpty) {
      _index = 0;
    } else if (!await _extendWithRadio()) {
      return;
    } else {
      _index = i.clamp(0, _queue.length - 1);
    }
    await _load();
  }

  Future<void> previous() async {
    if (position.value > const Duration(seconds: 3) || _index == 0) {
      await seek(Duration.zero);
      return;
    }
    _index--;
    await _load();
  }

  Future<void> setVolume(double v) {
    volume.value = v;
    _settings.volume = v;
    return _engine.setVolume(v);
  }

  Future<void> setSpeed(double s) async {
    speed = s;
    await _engine.setSpeed(s);
    notifyListeners();
  }

  void setSleepTimer(Duration? d) {
    _sleepTimer?.cancel();
    sleepAt = d == null ? null : DateTime.now().add(d);
    if (d != null) {
      _sleepTimer = Timer(d, () {
        pause();
        sleepAt = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  /// Autoplay: append similar tracks when the queue ends.
  Future<bool> _extendWithRadio() async {
    final seed = current;
    if (!_settings.autoplay || seed == null || seed.isLive) return false;
    try {
      // Autoplay: don't append hour-long mixes or previews on its own (tapped, they still play).
      final more = (await _sc.related(seed.id))
          .where((t) => _ok(t) && !_queue.contains(t) && !t.isPreview && t.durationMs <= 15 * 60000)
          .toList();
      if (more.isEmpty) return false;
      _queue.addAll(more);
      return true;
    } catch (_) {
      return false;
    }
  }

  MediaMeta _meta(Track t) => MediaMeta(
    id: '${t.id}',
    title: t.title,
    artist: t.user.username,
    artUrl: t.art(),
    duration: Duration(milliseconds: t.durationMs),
  );

  /// Tapped/"next": start fast (MP3 instead of HLS, see [Settings.fastStart]).
  Future<StreamInfo> _streamFor(Track t) async => t.isLive
      ? StreamInfo(t.streamUrl!, hls: t.streamUrl!.contains('.m3u8'), live: true)
      : await _sc.stream(t, fast: _settings.fastStart);

  Future<void> _load({Duration start = Duration.zero}) async {
    final track = current;
    if (track == null) return;
    final token = ++_loadToken;
    _needsLoad = false;
    _warmTrack = null;
    _staleEnded = true;
    _loadAt = DateTime.now();
    startLatency.value = null;
    // The free deck is about to become the active one (by swapping) – the pre-buffer is used up.
    // Take over its stream (full quality) instead of resolving again (fast).
    final ready = _prebufferedTrack == track ? _prebufferedStream : null;
    if (_prebufferedTrack == track) {
      _prebufferedTrack = null;
      _prebufferedStream = null;
    }
    error = null;
    position.value = start;
    _state = EngineState(status: EngineStatus.loading, position: start);
    _changed();
    try {
      final s = ready ?? await _streamFor(track);
      if (token != _loadToken) return; // another track was chosen in the meantime
      stream = s;
      await _engine.load(s, _meta(track), start: start);
      await _engine.setSpeed(track.isLive ? 1 : speed);
      _prefetchNext();
      if (!track.isLive) _library.addHistory(track);
    } catch (e) {
      if (token != _loadToken) return;
      error = '$e';
      _state = const EngineState(status: EngineStatus.error);
      notifyListeners();
      // Not playable -> move on to the next one.
      if (_index < _queue.length - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (token == _loadToken) await next(auto: true);
      }
    }
  }

  StreamInfo? _prebufferedStream;
  Track? _prebufferedTrack;
  Duration _prebufferedStart = Duration.zero;

  /// Pre-buffers a target track on the second deck.
  Future<void> prebufferTrack(Track track, {Duration start = Duration.zero, bool autoAdvance = false}) async {
    // The same track at a different position (e.g. DJ mix point instead of 0:00) must pre-buffer
    // again, otherwise the crossfade would have to seek – that sounds harsh.
    if ((_prebufferedTrack?.id == track.id && _prebufferedStart == start) || track.isLive) return;
    _prebufferedTrack = track; // before the await: the position tick calls this several times per second
    _prebufferedStart = start;
    try {
      final s = await _sc.stream(track);
      if (_prebufferedTrack != track) return;
      _prebufferedStream = s;
      await _engine.prebuffer(s, _meta(track), start: start, autoAdvance: autoAdvance);
    } catch (_) {
      if (_prebufferedTrack == track) _prebufferedTrack = null;
    }
  }

  /// Performs a seamless DJ crossfade into the target track (no pause/silence).
  Future<void> crossfadeTo(
    Track targetTrack, {
    Duration start = Duration.zero,
    Duration crossfadeDuration = const Duration(milliseconds: 3000),
    double tempoRatio = 1,
    bool skipped = false,
  }) async {
    _left(skipped: skipped);
    // The fading-out deck can report "ended" during the crossfade – that's not meant for the new song.
    _staleEnded = true;
    final targetIndex = _queue.indexOf(targetTrack);
    if (targetIndex != -1) {
      _index = targetIndex;
    } else {
      _queue.insert(_index + 1, targetTrack);
      _index++;
    }

    final token = ++_loadToken;
    _needsLoad = false;
    error = null;

    try {
      final StreamInfo s;
      if (_prebufferedTrack?.id == targetTrack.id && _prebufferedStream != null) {
        s = _prebufferedStream!;
      } else {
        s = await _sc.stream(targetTrack);
      }
      if (token != _loadToken) return;
      stream = s;
      _prebufferedStream = null;
      _prebufferedTrack = null;

      await _engine.crossfade(s, _meta(targetTrack), start: start, duration: crossfadeDuration, tempoRatio: tempoRatio);
      _library.addHistory(targetTrack);
      _changed();
    } catch (e) {
      if (token != _loadToken) return;
      await _load(start: start);
    }
  }

  // ---------- Engine-Events ----------

  void _onState(EngineState s) {
    final old = _state;
    final wasEnded = old.status == EngineStatus.ended;
    _state = s;
    _stateAt = DateTime.now();
    if (s.playing && _loadAt != null) {
      startLatency.value = _stateAt.difference(_loadAt!);
      _loadAt = null;
    }
    position.value = s.position;
    // After a load, "ended" reports of the old track may still be in flight
    // (deck and MediaController both report) – only a fresh state releases again.
    if (s.status != EngineStatus.ended) _staleEnded = false;
    if (s.status == EngineStatus.ended && !wasEnded && !isLive && !_staleEnded) {
      _staleEnded = true;
      _onEnded();
    }
    _prebufferUpcoming();
    _syncTicker();
    if (old.playing && !s.playing) _persist();
    // Only report real changes – pure position/buffer updates go through [position].
    if (s.status != old.status || s.playing != old.playing || s.duration != old.duration || s.error != old.error) {
      notifyListeners();
    }
  }

  /// Set by DJ Flow: DJ Flow does the transitions (and their pre-buffer at the mix point) itself.
  bool djOwnsTransitions = false;

  /// Pre-buffer the next track on the free deck: "next" and auto-advance then only swap the
  /// decks (no loading, no pause). Only after 8 s of playback – quick skippers don't load anything
  /// needlessly – but at the latest 30 s before the end.
  void _prebufferUpcoming() {
    if (!_state.playing || isLive || djOwnsTransitions) return;
    final d = duration;
    final pos = _state.position;
    if (d <= Duration.zero) return;
    if (pos < const Duration(seconds: 8) && d - pos > const Duration(seconds: 30)) return;
    final i = _index + 1;
    final next = repeat != LoopMode.one && i < _queue.length && _ok(_queue[i]) && !_queue[i].isLive ? _queue[i] : null;
    if (next != null) {
      prebufferTrack(next, autoAdvance: true);
    } else if (_prebufferedTrack != null) {
      // Target is gone (repeat, end of queue): otherwise the deck would switch to the wrong track.
      _prebufferedTrack = null;
      _prebufferedStream = null;
      _engine.cancelPrebuffer().ignore();
    }
  }

  void _syncTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (!_state.playing) return;
    // In the background a coarse tick is enough (automix, sleep, history) – saves battery.
    final every = _foreground ? const Duration(milliseconds: 50) : const Duration(milliseconds: 500);
    _ticker = Timer.periodic(every, (_) => position.value = livePosition);
  }

  void _onLifecycle(AppLifecycleState s) {
    final fg = s == AppLifecycleState.resumed || s == AppLifecycleState.inactive;
    if (fg == _foreground) return;
    _foreground = fg;
    _syncTicker();
  }

  Future<void> _onEnded() async {
    if (repeat == LoopMode.one) {
      await _engine.seek(Duration.zero);
      await _engine.play();
    } else {
      await next(auto: true);
    }
  }

  void _onCommand(RemoteCommand c) => switch (c) {
    RemoteCommand.play => play(),
    RemoteCommand.pause => pause(),
    RemoteCommand.next => next(),
    RemoteCommand.previous => previous(),
  };

  // ---------- Persistenz ----------

  void _changed() {
    currentTrack.value = current;
    _persist();
    notifyListeners();
  }

  void _persist() {
    _store
      ..set('player.queue', [for (final t in _queue.take(200)) t.toJson()])
      ..set('player.index', _index)
      ..set('player.pos', position.value.inMilliseconds);
  }

  void _restore() {
    final raw = _store.get<List>('player.queue');
    if (raw == null || raw.isEmpty) return;
    _queue = [for (final e in raw) Track.fromJson((e as Map).cast<String, dynamic>())];
    _index = (_store.get<int>('player.index') ?? 0).clamp(0, _queue.length - 1);
    _resumeAt = Duration(milliseconds: _store.get<int>('player.pos') ?? 0);
    position.value = _resumeAt;
    currentTrack.value = current;
    _needsLoad = true;
  }

  @override
  void dispose() {
    _persist();
    _lifecycle?.dispose();
    _settings.removeListener(_onSettings);
    _ticker?.cancel();
    _sleepTimer?.cancel();
    _engine.dispose();
    super.dispose();
  }
}

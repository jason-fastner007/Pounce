import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import '../sc/soundcloud.dart';
import 'audio_engine.dart';

// --- libmpv C API (only what we need) ---

final class _Event extends Struct {
  @Int32()
  external int id;
  @Int32()
  external int error;
  @Uint64()
  external int userdata;
  external Pointer<Void> data;
}

final class _EventProperty extends Struct {
  external Pointer<Utf8> name;
  @Int32()
  external int format;
  external Pointer<Void> data;
}

final class _EventEndFile extends Struct {
  @Int32()
  external int reason;
  @Int32()
  external int error;
}

typedef _Handle = Pointer<Void>;

const _fmtFlag = 3, _fmtDouble = 5;
const _evStartFile = 6, _evEndFile = 7, _evFileLoaded = 8, _evProperty = 22;
const _endEof = 0, _endError = 4;

class _Mpv {
  _Mpv(DynamicLibrary l)
    : create = l.lookupFunction<_Handle Function(), _Handle Function()>('mpv_create'),
      initialize = l.lookupFunction<Int32 Function(_Handle), int Function(_Handle)>('mpv_initialize'),
      setOption = l
          .lookupFunction<
            Int32 Function(_Handle, Pointer<Utf8>, Pointer<Utf8>),
            int Function(_Handle, Pointer<Utf8>, Pointer<Utf8>)
          >('mpv_set_option_string'),
      setProperty = l
          .lookupFunction<
            Int32 Function(_Handle, Pointer<Utf8>, Pointer<Utf8>),
            int Function(_Handle, Pointer<Utf8>, Pointer<Utf8>)
          >('mpv_set_property_string'),
      command = l
          .lookupFunction<
            Int32 Function(_Handle, Pointer<Pointer<Utf8>>),
            int Function(_Handle, Pointer<Pointer<Utf8>>)
          >('mpv_command'),
      observe = l
          .lookupFunction<
            Int32 Function(_Handle, Uint64, Pointer<Utf8>, Int32),
            int Function(_Handle, int, Pointer<Utf8>, int)
          >('mpv_observe_property'),
      waitEvent = l
          .lookupFunction<Pointer<_Event> Function(_Handle, Double), Pointer<_Event> Function(_Handle, double)>(
            'mpv_wait_event',
          ),
      setWakeup = l
          .lookupFunction<
            Void Function(_Handle, Pointer<NativeFunction<Void Function(Pointer<Void>)>>, Pointer<Void>),
            void Function(_Handle, Pointer<NativeFunction<Void Function(Pointer<Void>)>>, Pointer<Void>)
          >('mpv_set_wakeup_callback'),
      destroy = l.lookupFunction<Void Function(_Handle), void Function(_Handle)>('mpv_terminate_destroy'),
      getString = l
          .lookupFunction<
            Pointer<Utf8> Function(_Handle, Pointer<Utf8>),
            Pointer<Utf8> Function(_Handle, Pointer<Utf8>)
          >('mpv_get_property_string'),
      free = l.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('mpv_free');

  final _Handle Function() create;
  final int Function(_Handle) initialize;
  final int Function(_Handle, Pointer<Utf8>, Pointer<Utf8>) setOption;
  final int Function(_Handle, Pointer<Utf8>, Pointer<Utf8>) setProperty;
  final int Function(_Handle, Pointer<Pointer<Utf8>>) command;
  final Pointer<Utf8> Function(_Handle, Pointer<Utf8>) getString;
  final void Function(Pointer<Void>) free;
  final int Function(_Handle, int, Pointer<Utf8>, int) observe;
  final Pointer<_Event> Function(_Handle, double) waitEvent;
  final void Function(_Handle, Pointer<NativeFunction<Void Function(Pointer<Void>)>>, Pointer<Void>) setWakeup;
  final void Function(_Handle) destroy;

  static DynamicLibrary open() {
    final names = Platform.isWindows ? const ['libmpv-2.dll', 'mpv-2.dll'] : const ['libmpv.so.2', 'libmpv.so'];
    for (final n in names) {
      try {
        return DynamicLibrary.open(n);
      } catch (_) {}
    }
    throw StateError('libmpv not found (${names.join(', ')})');
  }
}

/// One mpv instance with its own playback state (two of them make the crossfade decks).
class _Deck {
  _Deck(this.h);

  final _Handle h;
  var status = EngineStatus.idle;
  var paused = true;
  var buffering = false;
  var pos = Duration.zero, dur = Duration.zero, buf = Duration.zero;
  Duration? pendingStart;

  /// Crossfade gain 0..1, multiplied with the user volume.
  double gain = 1;
}

/// Linux/Windows: libmpv (system library) via dart:ffi.
///
/// Two decks like on Android: [crossfade] starts the new track on the free deck and blends
/// both with an equal-power curve; only the active deck reports state.
class MpvEngine extends AudioEngine {
  MpvEngine() {
    try {
      if (Platform.isLinux) _numericLocaleC();
      _mpv = _Mpv(_Mpv.open());
      // The wakeup comes from the mpv thread -> the listener forwards it into our isolate.
      _wakeup = NativeCallable<Void Function(Pointer<Void>)>.listener((Pointer<Void> _) => _drain());
      _decks = [_createDeck(), _createDeck()];
      _meter = Timer.periodic(const Duration(milliseconds: 250), (_) => _readMeter());
    } catch (e) {
      _initError = '$e';
      _mpv = null;
    }
  }

  _Deck _createDeck() {
    final h = _mpv!.create();
    if (h == nullptr) throw StateError('mpv_create fehlgeschlagen');
    for (final (k, v) in const [
      ('vid', 'no'),
      ('video', 'no'),
      ('terminal', 'no'),
      ('ytdl', 'no'),
      ('idle', 'yes'),
      ('audio-client-name', 'Pounce'),
      ('cache', 'yes'),
    ]) {
      _str2(h, _mpv!.setOption, k, v);
    }
    _str2(h, _mpv!.setOption, 'af', _filters(_mode));
    _mpv!.initialize(h);
    for (final (i, name, fmt) in const [
      (1, 'time-pos', _fmtDouble),
      (2, 'duration', _fmtDouble),
      (3, 'pause', _fmtFlag),
      (4, 'paused-for-cache', _fmtFlag),
      (5, 'demuxer-cache-time', _fmtDouble),
    ]) {
      using((a) => _mpv!.observe(h, i, name.toNativeUtf8(allocator: a), fmt));
    }
    _mpv!.setWakeup(h, _wakeup!.nativeFunction, nullptr);
    return _Deck(h);
  }

  /// libmpv refuses to start with a non-C LC_NUMERIC (decimal comma).
  static void _numericLocaleC() {
    const lcNumeric = 1; // glibc
    final setlocale = DynamicLibrary.process()
        .lookupFunction<Pointer<Utf8> Function(Int32, Pointer<Utf8>), Pointer<Utf8> Function(int, Pointer<Utf8>)>(
          'setlocale',
        );
    using((a) => setlocale(lcNumeric, 'C'.toNativeUtf8(allocator: a)));
  }

  _Mpv? _mpv;
  List<_Deck> _decks = const [];
  var _active = 0;
  NativeCallable<Void Function(Pointer<Void>)>? _wakeup;
  String? _initError;

  /// The deck that plays the current track and reports its state.
  _Deck get _d => _decks[_active];
  _Deck get _other => _decks[1 - _active];

  final _states = StreamController<EngineState>.broadcast();
  final _commands = StreamController<RemoteCommand>.broadcast();

  DateTime _lastEmit = DateTime(0);
  double _volume = 1;

  /// Playback speed chosen by the user; DJ tempo matching deviates from it only temporarily.
  double _speed = 1;
  Timer? _fade, _tempo;

  // ---------- Laut/Leise (FFmpeg-Filter in mpv) ----------

  final _loudness = ValueNotifier(Loudness.none);
  LoudMode _mode = LoudMode.off;
  Timer? _meter;

  @override
  ValueListenable<Loudness> get loudness => _loudness;
  @override
  bool get supportsLoudness => _mpv != null;
  @override
  SpectrumSource? get spectrum => null;

  /// Measurement (ebur128) always, normalisation (loudnorm, incl. true-peak limiter) optional.
  String _filters(LoudMode m) => [
    '@kfmeter:lavfi=[ebur128=metadata=1]',
    if (m.lufs != null) '@kfnorm:lavfi=[loudnorm=I=${m.lufs!.toInt()}:TP=-1.5:LRA=11,aresample=48000]',
  ].join(',');

  @override
  Future<void> setLoudMode(LoudMode mode) async {
    _mode = mode;
    if (_mpv == null) return;
    for (final d in _decks) {
      _str2(d.h, _mpv!.setProperty, 'af', _filters(mode));
    }
  }

  void _readMeter() {
    if (_mpv == null || _d.paused) return;
    final raw = using((a) => _mpv!.getString(_d.h, 'af-metadata/kfmeter'.toNativeUtf8(allocator: a)));
    if (raw == nullptr) return;
    final json = raw.toDartString();
    _mpv!.free(raw.cast());
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      double? v(String k) {
        final d = double.tryParse('${m['lavfi.r128.$k']}');
        return d == null || d <= -70 ? null : d;
      }

      final i = v('I');
      _loudness.value = Loudness(
        momentary: v('M'),
        integrated: i,
        gainDb: _mode.lufs != null && i != null ? (_mode.lufs! - i).clamp(-18.0, 12.0) : null,
      );
    } catch (_) {}
  }

  @override
  Stream<EngineState> get states => _states.stream;
  @override
  Stream<RemoteCommand> get commands => _commands.stream;

  void _str2(_Handle h, int Function(_Handle, Pointer<Utf8>, Pointer<Utf8>) fn, String k, String v) =>
      using((a) => fn(h, k.toNativeUtf8(allocator: a), v.toNativeUtf8(allocator: a)));

  void _set(_Deck d, String k, String v) => _str2(d.h, _mpv!.setProperty, k, v);

  void _cmd(_Deck d, List<String> args) => using((a) {
    final arr = a<Pointer<Utf8>>(args.length + 1);
    for (var i = 0; i < args.length; i++) {
      arr[i] = args[i].toNativeUtf8(allocator: a);
    }
    arr[args.length] = nullptr;
    _mpv!.command(d.h, arr);
  });

  void _drain() {
    if (_mpv == null) return;
    for (final d in _decks) {
      while (true) {
        final ev = _mpv!.waitEvent(d.h, 0).ref;
        if (ev.id == 0) break;
        switch (ev.id) {
          case _evStartFile:
            d.status = EngineStatus.loading;
          case _evFileLoaded:
            d.status = EngineStatus.ready;
            if (d.pendingStart case final s?) {
              _seekDeck(d, s);
              d.pendingStart = null;
            }
          case _evEndFile:
            final r = ev.data.cast<_EventEndFile>().ref.reason;
            if (r == _endEof) d.status = EngineStatus.ended;
            if (r == _endError) d.status = EngineStatus.error;
          case _evProperty:
            _onProperty(d, ev.data.cast<_EventProperty>().ref);
        }
        // The fading-out deck stays silent towards the app.
        if (identical(d, _d)) _emit(force: ev.id != _evProperty);
      }
    }
  }

  void _onProperty(_Deck d, _EventProperty p) {
    if (p.data == nullptr) return;
    Duration v() => Duration(microseconds: (p.data.cast<Double>().value * 1e6).round());
    final active = identical(d, _d);
    switch (p.name.toDartString()) {
      case 'time-pos':
        d.pos = v();
      case 'duration':
        d.dur = v();
      case 'demuxer-cache-time':
        d.buf = v();
      case 'pause':
        d.paused = p.data.cast<Int32>().value != 0;
        if (active) _emit(force: true);
      case 'paused-for-cache':
        d.buffering = p.data.cast<Int32>().value != 0;
        if (active) _emit(force: true);
    }
  }

  void _emit({bool force = false}) {
    // time-pos fires very often -> throttle to ~4/s.
    final now = DateTime.now();
    if (!force && now.difference(_lastEmit).inMilliseconds < 250) return;
    _lastEmit = now;
    final d = _d;
    final status = d.buffering && d.status == EngineStatus.ready ? EngineStatus.loading : d.status;
    _states.add(
      EngineState(
        status: status,
        playing: !d.paused && d.status == EngineStatus.ready,
        position: d.pos,
        duration: d.dur,
        buffered: d.buf > Duration.zero ? d.pos + d.buf : Duration.zero,
      ),
    );
  }

  void _applyVolume(_Deck d) => _set(d, 'volume', '${(_volume * d.gain * 100).round()}');

  /// Starts [stream] on deck [d] (state reset, title, pause flag, gain).
  void _start(_Deck d, StreamInfo stream, MediaMeta meta, {required bool play, required Duration start}) {
    d
      ..status = EngineStatus.loading
      ..pos = Duration.zero
      ..dur = meta.duration
      ..buf = Duration.zero
      ..pendingStart = start > Duration.zero ? start : null;
    _set(d, 'force-media-title', '${meta.artist} – ${meta.title}');
    _set(d, 'pause', play ? 'no' : 'yes');
    _applyVolume(d);
    _cmd(d, ['loadfile', stream.url, 'replace']);
  }

  /// Ends a running crossfade at once: the old deck is stopped, the new one at full gain.
  void _finishFade() {
    _fade?.cancel();
    _fade = null;
    final old = _other;
    if (old.status != EngineStatus.idle) {
      _cmd(old, ['stop']);
      old.status = EngineStatus.idle;
    }
    if (_d.gain != 1) {
      _d.gain = 1;
      _applyVolume(_d);
    }
  }

  @override
  Future<void> load(StreamInfo stream, MediaMeta meta, {bool play = true, Duration start = Duration.zero}) async {
    if (_mpv == null) {
      _states.add(EngineState(status: EngineStatus.error, error: _initError));
      return;
    }
    _finishFade();
    _tempo?.cancel();
    _tempo = null;
    _set(_d, 'speed', '$_speed');
    _start(_d, stream, meta, play: play, start: start);
  }

  @override
  Future<void> prebuffer(
    StreamInfo stream,
    MediaMeta meta, {
    Duration start = Duration.zero,
    bool autoAdvance = false,
  }) async {}

  @override
  Future<void> crossfade(
    StreamInfo stream,
    MediaMeta meta, {
    Duration start = Duration.zero,
    Duration duration = const Duration(milliseconds: 3000),
    double tempoRatio = 1,
  }) async {
    if (_mpv == null) return load(stream, meta, start: start);
    // Nothing audible to fade out (paused, ended, idle): a plain load is the same.
    if (_d.paused || _d.status != EngineStatus.ready || duration <= Duration.zero) {
      return load(stream, meta, start: start);
    }
    _finishFade();
    _tempo?.cancel();
    _tempo = null;
    final out = _d;
    _active = 1 - _active;
    final into = _d..gain = 0;
    final matched = _speed * tempoRatio.clamp(.9, 1.1);
    _set(into, 'speed', '$matched');
    _start(into, stream, meta, play: true, start: start);
    _emit(force: true);

    // Equal-power blend; the clock only runs once the new deck actually plays, so a slow
    // stream start doesn't eat the fade.
    var t = 0.0;
    const step = Duration(milliseconds: 30);
    _fade = Timer.periodic(step, (timer) {
      if (into.status != EngineStatus.ready || into.buffering) return;
      t += step.inMicroseconds / duration.inMicroseconds;
      if (t >= 1) {
        _finishFade();
        if (matched != _speed) _tempoBack(into, matched);
        return;
      }
      into.gain = math.sin(t * math.pi / 2);
      out.gain = math.cos(t * math.pi / 2);
      _applyVolume(into);
      _applyVolume(out);
    });
  }

  /// After the transition, inaudibly (8 s) bring the tempo back to the user's speed.
  void _tempoBack(_Deck d, double from) {
    var p = 0.0;
    _tempo = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      p = math.min(1, p + 1 / 80);
      _set(d, 'speed', '${from + (_speed - from) * p}');
      if (p >= 1) {
        timer.cancel();
        _tempo = null;
      }
    });
  }

  @override
  Future<void> play() async {
    if (_mpv == null) return;
    if (_d.status == EngineStatus.ended) seek(Duration.zero);
    _set(_d, 'pause', 'no');
  }

  @override
  Future<void> pause() async {
    if (_mpv == null) return;
    _finishFade();
    _set(_d, 'pause', 'yes');
  }

  void _seekDeck(_Deck d, Duration p) => _cmd(d, ['seek', (p.inMilliseconds / 1000).toStringAsFixed(3), 'absolute']);

  @override
  Future<void> seek(Duration p) async {
    if (_mpv == null) return;
    if (_d.status == EngineStatus.ended) _d.status = EngineStatus.ready;
    _seekDeck(_d, p);
    _d.pos = p;
    _emit(force: true);
  }

  @override
  Future<void> stop() async {
    if (_mpv == null) return;
    _finishFade();
    _cmd(_d, ['stop']);
    _d.status = EngineStatus.idle;
  }

  @override
  Future<void> setVolume(double v) async {
    _volume = v;
    if (_mpv == null) return;
    for (final d in _decks) {
      _applyVolume(d);
    }
  }

  @override
  Future<void> setSpeed(double s) async {
    _speed = s;
    _tempo?.cancel();
    _tempo = null;
    if (_mpv == null) return;
    for (final d in _decks) {
      _set(d, 'speed', '$s');
    }
  }

  @override
  void dispose() {
    _meter?.cancel();
    _fade?.cancel();
    _tempo?.cancel();
    if (_mpv != null) {
      for (final d in _decks) {
        _mpv!.setWakeup(d.h, nullptr, nullptr);
        _mpv!.destroy(d.h);
      }
    }
    _wakeup?.close();
    _states.close();
    _commands.close();
  }
}

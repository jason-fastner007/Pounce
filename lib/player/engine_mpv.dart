import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

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

/// Linux/Windows: libmpv (system library) via dart:ffi.
class MpvEngine extends AudioEngine {
  MpvEngine() {
    try {
      if (Platform.isLinux) _numericLocaleC();
      _mpv = _Mpv(_Mpv.open());
      _h = _mpv!.create();
      if (_h == nullptr) throw StateError('mpv_create fehlgeschlagen');
      for (final (k, v) in const [
        ('vid', 'no'),
        ('video', 'no'),
        ('terminal', 'no'),
        ('ytdl', 'no'),
        ('idle', 'yes'),
        ('audio-client-name', 'Pounce'),
        ('cache', 'yes'),
      ]) {
        _str2(_mpv!.setOption, k, v);
      }
      _str2(_mpv!.setOption, 'af', _filters(_mode));
      _mpv!.initialize(_h);
      _meter = Timer.periodic(const Duration(milliseconds: 250), (_) => _readMeter());
      for (final (i, name, fmt) in const [
        (1, 'time-pos', _fmtDouble),
        (2, 'duration', _fmtDouble),
        (3, 'pause', _fmtFlag),
        (4, 'paused-for-cache', _fmtFlag),
        (5, 'demuxer-cache-time', _fmtDouble),
      ]) {
        using((a) => _mpv!.observe(_h, i, name.toNativeUtf8(allocator: a), fmt));
      }
      // The wakeup comes from the mpv thread -> the listener forwards it into our isolate.
      _wakeup = NativeCallable<Void Function(Pointer<Void>)>.listener((Pointer<Void> _) => _drain());
      _mpv!.setWakeup(_h, _wakeup!.nativeFunction, nullptr);
    } catch (e) {
      _initError = '$e';
      _mpv = null;
    }
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
  _Handle _h = nullptr;
  NativeCallable<Void Function(Pointer<Void>)>? _wakeup;
  String? _initError;

  final _states = StreamController<EngineState>.broadcast();
  final _commands = StreamController<RemoteCommand>.broadcast();

  var _status = EngineStatus.idle;
  var _paused = true;
  var _buffering = false;
  var _pos = Duration.zero, _dur = Duration.zero, _buf = Duration.zero;
  Duration? _pendingStart;
  DateTime _lastEmit = DateTime(0);

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
    if (_mpv != null) _str2(_mpv!.setProperty, 'af', _filters(mode));
  }

  void _readMeter() {
    if (_mpv == null || _paused) return;
    final raw = using((a) => _mpv!.getString(_h, 'af-metadata/kfmeter'.toNativeUtf8(allocator: a)));
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

  void _str2(int Function(_Handle, Pointer<Utf8>, Pointer<Utf8>) fn, String k, String v) =>
      using((a) => fn(_h, k.toNativeUtf8(allocator: a), v.toNativeUtf8(allocator: a)));

  void _cmd(List<String> args) => using((a) {
    final arr = a<Pointer<Utf8>>(args.length + 1);
    for (var i = 0; i < args.length; i++) {
      arr[i] = args[i].toNativeUtf8(allocator: a);
    }
    arr[args.length] = nullptr;
    _mpv!.command(_h, arr);
  });

  void _drain() {
    if (_mpv == null) return;
    while (true) {
      final ev = _mpv!.waitEvent(_h, 0).ref;
      if (ev.id == 0) break;
      switch (ev.id) {
        case _evStartFile:
          _status = EngineStatus.loading;
        case _evFileLoaded:
          _status = EngineStatus.ready;
          if (_pendingStart case final s?) {
            seek(s);
            _pendingStart = null;
          }
        case _evEndFile:
          final r = ev.data.cast<_EventEndFile>().ref.reason;
          if (r == _endEof) _status = EngineStatus.ended;
          if (r == _endError) _status = EngineStatus.error;
        case _evProperty:
          _onProperty(ev.data.cast<_EventProperty>().ref);
      }
      _emit(force: ev.id != _evProperty);
    }
  }

  void _onProperty(_EventProperty p) {
    if (p.data == nullptr) return;
    Duration d() => Duration(microseconds: (p.data.cast<Double>().value * 1e6).round());
    switch (p.name.toDartString()) {
      case 'time-pos':
        _pos = d();
      case 'duration':
        _dur = d();
      case 'demuxer-cache-time':
        _buf = d();
      case 'pause':
        _paused = p.data.cast<Int32>().value != 0;
        _emit(force: true);
      case 'paused-for-cache':
        _buffering = p.data.cast<Int32>().value != 0;
        _emit(force: true);
    }
  }

  void _emit({bool force = false}) {
    // time-pos fires very often -> throttle to ~4/s.
    final now = DateTime.now();
    if (!force && now.difference(_lastEmit).inMilliseconds < 250) return;
    _lastEmit = now;
    final status = _buffering && _status == EngineStatus.ready ? EngineStatus.loading : _status;
    _states.add(
      EngineState(
        status: status,
        playing: !_paused && _status == EngineStatus.ready,
        position: _pos,
        duration: _dur,
        buffered: _buf > Duration.zero ? _pos + _buf : Duration.zero,
      ),
    );
  }

  @override
  Future<void> load(StreamInfo stream, MediaMeta meta, {bool play = true, Duration start = Duration.zero}) async {
    if (_mpv == null) {
      _states.add(EngineState(status: EngineStatus.error, error: _initError));
      return;
    }
    _pos = Duration.zero;
    _dur = meta.duration;
    _pendingStart = start > Duration.zero ? start : null;
    _str2(_mpv!.setProperty, 'force-media-title', '${meta.artist} – ${meta.title}');
    _str2(_mpv!.setProperty, 'pause', play ? 'no' : 'yes');
    _cmd(['loadfile', stream.url, 'replace']);
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
  }) => load(stream, meta, play: true, start: start);

  @override
  Future<void> play() async {
    if (_mpv == null) return;
    if (_status == EngineStatus.ended) seek(Duration.zero);
    _str2(_mpv!.setProperty, 'pause', 'no');
  }

  @override
  Future<void> pause() async {
    if (_mpv != null) _str2(_mpv!.setProperty, 'pause', 'yes');
  }

  @override
  Future<void> seek(Duration p) async {
    if (_mpv == null) return;
    if (_status == EngineStatus.ended) _status = EngineStatus.ready;
    _cmd(['seek', (p.inMilliseconds / 1000).toStringAsFixed(3), 'absolute']);
    _pos = p;
    _emit(force: true);
  }

  @override
  Future<void> stop() async {
    if (_mpv != null) _cmd(['stop']);
    _status = EngineStatus.idle;
  }

  @override
  Future<void> setVolume(double v) async {
    if (_mpv != null) _str2(_mpv!.setProperty, 'volume', '${(v * 100).round()}');
  }

  @override
  Future<void> setSpeed(double s) async {
    if (_mpv != null) _str2(_mpv!.setProperty, 'speed', '$s');
  }

  @override
  void dispose() {
    _meter?.cancel();
    if (_mpv != null) {
      _mpv!.setWakeup(_h, nullptr, nullptr);
      _mpv!.destroy(_h);
    }
    _wakeup?.close();
    _states.close();
    _commands.close();
  }
}

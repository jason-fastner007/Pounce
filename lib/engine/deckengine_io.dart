import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'deckengine.dart';

DeckEngine? get instance => _FfiEngine.probe();

/// Mirror of `DeTrackAnalysis` (deckengine/src/ffi.rs).
final class _DeTrackAnalysis extends ffi.Struct {
  @ffi.Double()
  external double firstBeatMs;
  @ffi.Double()
  external double downbeatMs;
  @ffi.Double()
  external double phraseMs;
  @ffi.Double()
  external double mixInMs;
  @ffi.Double()
  external double mixOutMs;
  @ffi.Double()
  external double windowStartMs;
  @ffi.Double()
  external double analyzedMs;
  @ffi.Float()
  external double bpm;
  @ffi.Float()
  external double bpmConfidence;
  @ffi.Float()
  external double downbeatConfidence;
  @ffi.Float()
  external double phraseConfidence;
  @ffi.Int32()
  external int keyPitch;
  @ffi.Int32()
  external int keyMinor;
  @ffi.Float()
  external double keyConfidence;
  @ffi.Float()
  external double lufs;
  @ffi.Float()
  external double peakDb;
  @ffi.Float()
  external double bass;
  @ffi.Float()
  external double mid;
  @ffi.Float()
  external double high;
  @ffi.Float()
  external double onsetDensity;
  @ffi.Float()
  external double energy;
  @ffi.Float()
  external double aiProbability;
  @ffi.Float()
  external double bassBodyDb;

  List<double> toList() => [
    firstBeatMs, downbeatMs, phraseMs, mixInMs, mixOutMs, windowStartMs, analyzedMs, //
    bpm, bpmConfidence, downbeatConfidence, phraseConfidence, keyPitch.toDouble(), keyMinor.toDouble(),
    keyConfidence, lufs, peakDb, bass, mid, high, onsetDensity, energy, aiProbability, bassBodyDb,
  ];
}

/// Mirror of `DeEvents` (deckengine/src/ffi.rs).
final class _DeEvents extends ffi.Struct {
  @ffi.Double()
  external double cueMs;
  @ffi.Double()
  external double dropMs;
  @ffi.Float()
  external double dropStrength;
  @ffi.Float()
  external double reserved;
}

/// `DeBeatEnergyAnalysis` of the old envelope analysis (fallback only).
final class _DeBeatEnergy extends ffi.Struct {
  @ffi.Float()
  external double bpm;
  @ffi.Int32()
  external int firstBeatOffsetMs;
  @ffi.Float()
  external double confidence;
  @ffi.Array(4)
  external ffi.Array<ffi.Uint8> keyCode;
  @ffi.Int32()
  external int mixIn;
  @ffi.Int32()
  external int mixOut;
  @ffi.Int32()
  external int downbeat;
  @ffi.Int32()
  external int phrase;
  @ffi.Float()
  external double downbeatConfidence;
  @ffi.Float()
  external double phraseConfidence;
  @ffi.Float()
  external double bass;
  @ffi.Float()
  external double mid;
  @ffi.Float()
  external double high;
  @ffi.Float()
  external double total;
}

typedef _ClipC =
    ffi.Int32 Function(
      ffi.Pointer<ffi.Uint8>,
      ffi.Size,
      ffi.Pointer<ffi.Uint8>,
      ffi.Size,
      ffi.Uint64,
      ffi.Double,
      ffi.Pointer<ffi.Float>,
      ffi.Size,
      ffi.Bool,
      ffi.Pointer<_DeTrackAnalysis>,
    );
typedef _ClipD =
    int Function(
      ffi.Pointer<ffi.Uint8>,
      int,
      ffi.Pointer<ffi.Uint8>,
      int,
      int,
      double,
      ffi.Pointer<ffi.Float>,
      int,
      bool,
      ffi.Pointer<_DeTrackAnalysis>,
    );
typedef _EventsC =
    ffi.Int32 Function(
      ffi.Pointer<ffi.Uint8>,
      ffi.Size,
      ffi.Pointer<ffi.Uint8>,
      ffi.Size,
      ffi.Uint64,
      ffi.Double,
      ffi.Double,
      ffi.Float,
      ffi.Bool,
      ffi.Pointer<_DeEvents>,
    );
typedef _EventsD =
    int Function(
      ffi.Pointer<ffi.Uint8>,
      int,
      ffi.Pointer<ffi.Uint8>,
      int,
      int,
      double,
      double,
      double,
      bool,
      ffi.Pointer<_DeEvents>,
    );
typedef _FakeC = ffi.Int32 Function(ffi.Pointer<ffi.Float>, ffi.Size, ffi.Uint32, ffi.Pointer<ffi.Float>);
typedef _FakeD = int Function(ffi.Pointer<ffi.Float>, int, int, ffi.Pointer<ffi.Float>);
typedef _WaveC = ffi.Int32 Function(ffi.Pointer<ffi.Float>, ffi.Size, ffi.Int64, ffi.Pointer<_DeBeatEnergy>);
typedef _WaveD = int Function(ffi.Pointer<ffi.Float>, int, int, ffi.Pointer<_DeBeatEnergy>);

/// Bindings – opened once per isolate (the system loads the .so itself only once).
class _Lib {
  _Lib(ffi.DynamicLibrary l)
    : clip = l.lookupFunction<_ClipC, _ClipD>('de_analyze_mp3_clip'),
      fake = l.lookupFunction<_FakeC, _FakeD>('de_fakeprint'),
      wave = l.lookupFunction<_WaveC, _WaveD>('de_analyze_waveform'),
      events = _optional(() => l.lookupFunction<_EventsC, _EventsD>('de_scan_events'));

  final _ClipD clip;
  final _FakeD fake;
  final _WaveD wave;

  /// null for an older library without cue/drop detection – everything else still works.
  final _EventsD? events;

  static T? _optional<T>(T Function() f) {
    try {
      return f();
    } catch (_) {
      return null;
    }
  }

  static _Lib? _cached;
  static bool _tried = false;

  static _Lib? get() {
    if (_tried) return _cached;
    _tried = true;
    for (final path in _candidates()) {
      try {
        return _cached = _Lib(ffi.DynamicLibrary.open(path));
      } catch (_) {}
    }
    return null;
  }

  static List<String> _candidates() {
    if (Platform.isAndroid) return ['libdeckengine.so'];
    if (Platform.isWindows) return ['deckengine.dll'];
    if (Platform.isMacOS || Platform.isIOS) return ['libdeckengine.dylib'];
    // Linux: next to the app in the bundle (lib/), otherwise the system path.
    final dir = File(Platform.resolvedExecutable).parent.path;
    return ['$dir/lib/libdeckengine.so', 'libdeckengine.so'];
  }
}

class _FfiEngine implements DeckEngine {
  static _FfiEngine? _instance;
  static bool _probed = false;

  static DeckEngine? probe() {
    if (!_probed) {
      _probed = true;
      if (_Lib.get() != null) _instance = _FfiEngine();
    }
    return _instance;
  }

  @override
  String get label => 'Rust · FFI';

  @override
  Future<ClipAnalysis?> analyzeMp3Clip(ClipRequest r) async {
    // Decoding + analysis take ~0.2–0.4 s on a phone: never on the UI isolate.
    final v = await Isolate.run(() => _clipSync(r));
    return v == null ? null : ClipAnalysis.fromList(v);
  }

  static List<double>? _clipSync(ClipRequest r) {
    final lib = _Lib.get();
    if (lib == null) return null;
    return using((arena) {
      final head = arena<ffi.Uint8>(r.head.length)..asTypedList(r.head.length).setAll(0, r.head);
      final clip = arena<ffi.Uint8>(r.clip.length)..asTypedList(r.clip.length).setAll(0, r.clip);
      final env = r.envelope;
      final envPtr = env == null || env.isEmpty
          ? ffi.nullptr.cast<ffi.Float>()
          : (arena<ffi.Float>(env.length)..asTypedList(env.length).setAll(0, env));
      final out = arena<_DeTrackAnalysis>();
      final rc = lib.clip(
        head,
        r.head.length,
        clip,
        r.clip.length,
        r.clipOffset,
        r.durationMs,
        envPtr,
        env?.length ?? 0,
        r.fakeprint,
        out,
      );
      return rc == 0 ? out.ref.toList() : null;
    });
  }

  @override
  Future<TrackEvents?> scanEvents(EventRequest r) async {
    final v = await Isolate.run(() => _eventsSync(r));
    return v == null ? null : TrackEvents.fromList(v);
  }

  static List<double>? _eventsSync(EventRequest r) {
    final events = _Lib.get()?.events;
    if (events == null) return null;
    return using((arena) {
      final head = arena<ffi.Uint8>(r.head.length)..asTypedList(r.head.length).setAll(0, r.head);
      final clip = arena<ffi.Uint8>(r.clip.length)..asTypedList(r.clip.length).setAll(0, r.clip);
      final out = arena<_DeEvents>();
      final rc = events(
        head,
        r.head.length,
        clip,
        r.clip.length,
        r.clipOffset,
        r.periodMs,
        r.downbeatMs,
        r.bassBodyDb ?? 0,
        r.wantCue,
        out,
      );
      return rc == 0 ? [out.ref.cueMs, out.ref.dropMs, out.ref.dropStrength] : null;
    });
  }

  @override
  Future<double?> fakeprint(Float32List pcm, int sampleRate) => Isolate.run(() {
    final lib = _Lib.get();
    if (lib == null) return null;
    return using((arena) {
      final p = arena<ffi.Float>(pcm.length)..asTypedList(pcm.length).setAll(0, pcm);
      final out = arena<ffi.Float>();
      if (lib.fake(p, pcm.length, sampleRate, out) != 0) return null;
      return out.value < 0 ? null : out.value;
    });
  });

  @override
  Future<List<double>?> analyzeWaveform(List<double> samples, int durationMs) async {
    final lib = _Lib.get();
    if (lib == null || samples.length < 32) return null;
    // Tiny input (~1800 values): directly, without an isolate.
    return using((arena) {
      final p = arena<ffi.Float>(samples.length);
      final view = p.asTypedList(samples.length);
      for (var i = 0; i < samples.length; i++) {
        view[i] = samples[i];
      }
      final out = arena<_DeBeatEnergy>();
      if (lib.wave(p, samples.length, durationMs, out) != 0) return null;
      final o = out.ref;
      return [o.bpm, o.firstBeatOffsetMs.toDouble(), o.confidence, o.mixIn.toDouble(), o.mixOut.toDouble()];
    });
  }
}

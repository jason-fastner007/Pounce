import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../sc/soundcloud.dart';
import 'audio_engine.dart';

/// Android (Media3) and iOS/macOS (AVPlayer) via platform channels.
class ChannelEngine extends AudioEngine {
  ChannelEngine() {
    _sub = _events.receiveBroadcastStream().listen(_onEvent);
  }

  static const _ch = MethodChannel('pounce/player');
  static const _events = EventChannel('pounce/player/events');
  static const _featureEvents = EventChannel('pounce/player/features');

  final _states = StreamController<EngineState>.broadcast();
  final _commands = StreamController<RemoteCommand>.broadcast();
  StreamSubscription<dynamic>? _sub;
  final _title = ValueNotifier<String?>(null);
  final _loudness = ValueNotifier(Loudness.none);
  late final _spectrum = _FeatureSpectrum(this);

  /// Last reported state, to extrapolate the audible position between reports.
  EngineState _last = const EngineState();
  DateTime _lastAt = DateTime.now();
  double _speed = 1;

  @override
  Stream<EngineState> get states => _states.stream;
  @override
  Stream<RemoteCommand> get commands => _commands.stream;
  @override
  ValueListenable<String?> get streamTitle => _title;

  void _onEvent(dynamic e) {
    final m = (e as Map).cast<String, Object?>();
    switch (m['type']) {
      case 'command':
        final c = RemoteCommand.values.asNameMap()[m['command']];
        if (c != null) _commands.add(c);
        return;
      case 'title':
        final t = (m['title'] as String?)?.trim();
        _title.value = t == null || t.isEmpty ? null : t;
        return;
    }
    Duration ms(String k) => Duration(milliseconds: (m[k] as num?)?.toInt() ?? 0);
    final s = EngineState(
      status: EngineStatus.values.asNameMap()[m['status']] ?? EngineStatus.idle,
      playing: m['playing'] == true,
      position: ms('position'),
      duration: ms('duration'),
      buffered: ms('buffered'),
      error: m['error'] as String?,
    );
    _last = s;
    _lastAt = DateTime.now();
    _states.add(s);
  }

  /// Audible position now (µs).
  int get _nowUs {
    final p = _last.position.inMicroseconds;
    if (!_last.playing) return p;
    return p + (DateTime.now().difference(_lastAt).inMicroseconds * _speed).round();
  }

  Map<String, Object?> _item(StreamInfo stream, MediaMeta meta) => {
    'url': stream.url,
    'hls': stream.hls,
    ...meta.toMap(),
  };

  @override
  Future<void> load(StreamInfo stream, MediaMeta meta, {bool play = true, Duration start = Duration.zero}) {
    _title.value = null;
    return _ch.invokeMethod('load', {..._item(stream, meta), 'play': play, 'startMs': start.inMilliseconds});
  }

  @override
  Future<void> prebuffer(
    StreamInfo stream,
    MediaMeta meta, {
    Duration start = Duration.zero,
    bool autoAdvance = false,
  }) => _ch.invokeMethod('prebuffer', {
    ..._item(stream, meta),
    'startMs': start.inMilliseconds,
    'autoAdvance': autoAdvance,
  });

  @override
  Future<void> cancelPrebuffer() => _ch.invokeMethod('cancelPrebuffer');

  @override
  Future<void> crossfade(
    StreamInfo stream,
    MediaMeta meta, {
    Duration start = Duration.zero,
    Duration duration = const Duration(milliseconds: 3000),
    double tempoRatio = 1,
  }) => _ch.invokeMethod('crossfade', {
    ..._item(stream, meta),
    'startMs': start.inMilliseconds,
    'durationMs': duration.inMilliseconds,
    'tempo': tempoRatio,
  });

  @override
  Future<void> play() => _ch.invokeMethod('play');
  @override
  Future<void> pause() => _ch.invokeMethod('pause');
  @override
  Future<void> seek(Duration p) => _ch.invokeMethod('seek', p.inMilliseconds);
  @override
  Future<void> stop() => _ch.invokeMethod('stop');
  @override
  Future<void> setVolume(double v) => _ch.invokeMethod('volume', v);
  @override
  Future<void> setSpeed(double s) {
    _speed = s;
    return _ch.invokeMethod('speed', s);
  }

  @override
  Future<void> setLoudMode(LoudMode mode) async {
    try {
      await _ch.invokeMethod('loudness', mode.lufs);
      _loudnessSupported = true;
    } on MissingPluginException {
      _loudnessSupported = false;
    } on PlatformException {
      _loudnessSupported = false;
    }
  }

  // iOS/macOS: the Swift side doesn't know normalisation (yet).
  bool _loudnessSupported = defaultTargetPlatform == TargetPlatform.android;

  @override
  bool get supportsLoudness => _loudnessSupported;

  @override
  ValueListenable<Loudness> get loudness => _loudness;

  @override
  SpectrumSource? get spectrum => defaultTargetPlatform == TargetPlatform.android ? _spectrum : null;

  @override
  void dispose() {
    _spectrum.listen(false);
    _sub?.cancel();
    _states.close();
    _commands.close();
  }
}

/// Spectrum/bass from the native analysis tap. Hops carry their media time; the hop shown
/// is the one belonging to the currently audible position (no fixed offset, no guessing).
class _FeatureSpectrum extends SpectrumSource {
  _FeatureSpectrum(this._e);
  final ChannelEngine _e;

  static const _ring = 256;
  static const _hopBytes = 8 + 4 + SpectrumSource.bands;
  final _time = Float64List(_ring); // µs
  final _bass = Float32List(_ring);
  final _bands = Uint8List(_ring * SpectrumSource.bands);
  var _count = 0; // hops written
  int? _gen;
  StreamSubscription<dynamic>? _sub;

  @override
  void listen(bool on) {
    if (on && _sub == null) {
      _sub = ChannelEngine._featureEvents.receiveBroadcastStream().listen(_onBatch, onError: (_) {});
    } else if (!on && _sub != null) {
      _sub!.cancel();
      _sub = null;
    }
  }

  void _onBatch(dynamic e) {
    final m = (e as Map).cast<String, Object?>();
    final gen = m['gen'] as int?;
    if (gen != _gen) {
      _gen = gen;
      _count = 0; // seek/new track: old hops belong to a different timeline.
    }
    final hops = m['hops'] as Uint8List?;
    if (hops != null) {
      final bd = ByteData.sublistView(hops);
      for (var off = 0; off + _hopBytes <= hops.length; off += _hopBytes) {
        final slot = _count % _ring;
        _time[slot] = bd.getInt64(off, Endian.little).toDouble();
        _bass[slot] = bd.getFloat32(off + 8, Endian.little);
        _bands.setRange(slot * SpectrumSource.bands, (slot + 1) * SpectrumSource.bands, hops, off + 12);
        _count++;
      }
    }
    double? n(String k) => (m[k] as num?)?.toDouble();
    final g = n('g');
    _e._loudness.value = Loudness(
      momentary: (n('m') ?? -100) > -70 ? n('m') : null,
      integrated: n('i'),
      gainDb: g,
      limiterDb: n('l') ?? 0,
      clipping: (n('l') ?? 0) < -3,
    );
  }

  /// Index of the newest hop with time ≤ [us], -1 = none fits.
  int _at(double us) {
    final n = math.min(_count, _ring);
    for (var k = 0; k < n; k++) {
      final slot = (_count - 1 - k) % _ring;
      if (_time[slot] <= us) return slot;
    }
    return -1;
  }

  @override
  bool readBands(Float32List out) {
    if (!_e._last.playing || _count == 0) return false;
    // +20 ms: the image only appears on the display one frame later.
    final now = _e._nowUs + 20000.0;
    final slot = _at(now);
    if (slot < 0 || now - _time[slot] > 150000) return false;
    final base = slot * SpectrumSource.bands;
    for (var b = 0; b < SpectrumSource.bands && b < out.length; b++) {
      out[b] = _bands[base + b] / 255;
    }
    return true;
  }

  @override
  double? bass() {
    if (!_e._last.playing || _count == 0) return null;
    final now = _e._nowUs + 20000.0;
    // Loudest hop of the last ~60 ms: at 60 fps no kick gets lost.
    var peak = -200.0;
    final n = math.min(_count, 8);
    for (var k = 0; k < n; k++) {
      final slot = (_count - 1 - k) % _ring;
      final t = _time[slot];
      if (t <= now && now - t < 60000 && _bass[slot] > peak) peak = _bass[slot];
    }
    if (peak <= -199) return null;
    return ((peak + 42) / 36).clamp(0.0, 1.0);
  }
}

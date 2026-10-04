import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import '../sc/soundcloud.dart';
import 'audio_engine.dart';

@JS('Hls')
extension type _Hls._(JSObject _) implements JSObject {
  external _Hls(JSObject config);
  external static bool isSupported();
  external void loadSource(String url);
  external void attachMedia(web.HTMLMediaElement media);
  external void on(String event, JSFunction callback);
  external void destroy();
}

@JS()
extension type _HlsError._(JSObject _) implements JSObject {
  external bool get fatal;
  external String get details;
}

@JS()
extension type _ActionDetails._(JSObject _) implements JSObject {
  external double? get seekTime;
}

/// Browser: native <audio> + Web Audio (loudness, limiter, spectrum) + Media Session.
///
/// Signal path:
///   audio → source ─┬→ normGain → limiter → master → analyserOut → output
///                   └→ K-filter (shelf + high-pass) → analyserK   (measurement only)
///
/// Two elements (decks) each feed the graph through their own gain, so [crossfade] can
/// blend the new track in while the old one fades out (equal power, like Android).
///
/// DRM tracks (cenc, Widevine/PlayReady) run through hls.js with EME on a separate
/// element without a graph: browsers don't pass decrypted audio on to Web Audio.
class WebEngine extends AudioEngine {
  WebEngine() {
    _decks.forEach(_listen);
    final session = _session;
    if (session == null) return;
    void on(String action, RemoteCommand cmd) =>
        session.setActionHandler(action, ((JSObject _) => _commands.add(cmd)).toJS);
    on('play', RemoteCommand.play);
    on('pause', RemoteCommand.pause);
    on('nexttrack', RemoteCommand.next);
    on('previoustrack', RemoteCommand.previous);
    session.setActionHandler(
      'seekto',
      ((_ActionDetails d) {
        seek(Duration(milliseconds: ((d.seekTime ?? 0) * 1000).round()));
      }).toJS,
    );
  }

  static const _events = [
    'timeupdate',
    'play',
    'pause',
    'playing',
    'waiting',
    'ended',
    'loadedmetadata',
    'durationchange',
    'progress',
    'error',
    'seeked',
  ];

  /// Only reports events of the currently active element.
  void _listen(web.HTMLAudioElement el) {
    for (final type in _events) {
      el.addEventListener(
        type,
        ((web.Event e) {
          if (identical(el, _el)) _emit(e.type);
        }).toJS,
      );
    }
  }

  // Analysis needs CORS; all SoundCloud CDNs send Access-Control-Allow-Origin: *.
  final _decks = [
    for (var i = 0; i < 2; i++)
      web.HTMLAudioElement()
        ..preload = 'auto'
        ..crossOrigin = 'anonymous',
  ];
  var _cur = 0;

  /// Deck of the current (non-DRM) track.
  web.HTMLAudioElement get _audio => _decks[_cur];

  /// Running crossfade: the fading-out deck's hls.js instance and the end/tempo timers.
  _Hls? _outHls;
  Timer? _fadeDone, _tempo;
  double _speed = 1;

  /// Element of the current DRM track; new per track (Firefox doesn't reliably switch
  /// MediaKeys on one element). null = normal track via [_audio].
  web.HTMLAudioElement? _drmAudio;
  web.HTMLAudioElement get _el => _drmAudio ?? _audio;

  static const _licenseHost = 'https://license.media-streaming.soundcloud.cloud';
  final _states = StreamController<EngineState>.broadcast();
  final _commands = StreamController<RemoteCommand>.broadcast();
  final _loudness = ValueNotifier(Loudness.none);
  _Hls? _hls;
  bool _loading = false;

  static Future<void>? _hlsScript;

  /// Media Session only exists in secure contexts (HTTPS/localhost).
  static web.MediaSession? get _session =>
      (web.window.navigator as JSObject).has('mediaSession') ? web.window.navigator.mediaSession : null;

  @override
  Stream<EngineState> get states => _states.stream;
  @override
  Stream<RemoteCommand> get commands => _commands.stream;
  @override
  ValueListenable<Loudness> get loudness => _loudness;
  @override
  bool get supportsLoudness => true;
  @override
  SpectrumSource? get spectrum => _graph == null ? null : _spectrum;

  // ---------- Web Audio graph ----------

  _Graph? _graph;
  late final _spectrum = _Spectrum(this);
  LoudMode _mode = LoudMode.off;
  double _volume = 1;
  Timer? _meter;
  final _meter400 = <double>[]; // energy of the last 4 blocks (~100 ms each)
  final _gated = <double>[]; // momentary energies of the track (for integrated)
  double _gainDb = 0;
  DateTime _trackStart = DateTime.now();
  DateTime _clipUntil = DateTime(0);

  /// Build the graph only when needed (AudioContext needs a user gesture).
  _Graph _ensureGraph() => _graph ??= _Graph(_decks)
    ..master.gain.value = _volume
    ..applyMode(_mode);

  void _startMeter() {
    _meter ??= Timer.periodic(const Duration(milliseconds: 100), (_) => _measure());
  }

  void _measure() {
    final g = _graph;
    if (g == null || _audio.paused) return;
    // Mean energy of the K-weighted signal (downmix -> +3 dB for stereo).
    g.analyserK.getFloatTimeDomainData(g.kBuf);
    final buf = g.kBuf.toDart;
    var sum = 0.0;
    for (var i = 0; i < buf.length; i++) {
      sum += buf[i] * buf[i];
    }
    final ms = 2 * sum / buf.length;
    _meter400.add(ms);
    if (_meter400.length > 4) _meter400.removeAt(0);
    final momentaryMs = _meter400.reduce((a, b) => a + b) / _meter400.length;
    final momentary = _lufs(momentaryMs);
    if (momentary > -70) _gated.add(momentaryMs);

    // Integrated loudness with relative gate (−10 LU).
    double? integrated;
    if (_gated.isNotEmpty) {
      final abs = _gated.reduce((a, b) => a + b) / _gated.length;
      final threshold = _energy(_lufs(abs) - 10);
      var s = 0.0, n = 0;
      for (final e in _gated) {
        if (e >= threshold) {
          s += e;
          n++;
        }
      }
      if (n > 0) integrated = _lufs(s / n);
    }

    // Track the normalisation: fast at the start, then calm.
    final target = _mode.lufs;
    final ref = integrated ?? (momentary > -70 ? momentary : null);
    if (target != null && ref != null) {
      _gainDb = (target - ref).clamp(-18.0, 12.0);
      final early = DateTime.now().difference(_trackStart).inSeconds < 6;
      g.norm.gain.setTargetAtTime(_dbToGain(_gainDb), g.ctx.currentTime, early ? .4 : 3);
    }

    // Detect clipping at the output (hold for 1 s).
    g.analyserOut.getFloatTimeDomainData(g.outBuf);
    final out = g.outBuf.toDart;
    var peak = 0.0;
    for (var i = 0; i < out.length; i++) {
      final v = out[i].abs();
      if (v > peak) peak = v;
    }
    if (peak >= .999) _clipUntil = DateTime.now().add(const Duration(seconds: 1));

    _loudness.value = Loudness(
      momentary: momentary > -70 ? momentary : null,
      integrated: integrated,
      gainDb: target == null ? null : _gainDb,
      limiterDb: g.limiter.reduction,
      clipping: DateTime.now().isBefore(_clipUntil),
    );
  }

  static double _lufs(double ms) => ms <= 0 ? -100 : -0.691 + 10 * math.log(ms) / math.ln10;
  static double _energy(double lufs) => math.pow(10, (lufs + 0.691) / 10).toDouble();
  static double _dbToGain(double db) => math.pow(10, db / 20).toDouble();

  @override
  Future<void> setLoudMode(LoudMode mode) async {
    _mode = mode;
    final g = _graph;
    if (g == null) return;
    g.applyMode(mode);
    if (mode.lufs == null) {
      g.norm.gain.setTargetAtTime(1, g.ctx.currentTime, .3);
      _gainDb = 0;
    }
  }

  // ---------- Transport ----------

  Duration _sec(num s) => s.isFinite ? Duration(milliseconds: (s * 1000).round()) : Duration.zero;

  void _emit(String type, {String? error}) {
    final el = _el;
    if (type == 'playing' || type == 'loadedmetadata') _loading = false;
    if (type == 'waiting') _loading = true;
    final buffered = el.buffered.length > 0 ? el.buffered.end(el.buffered.length - 1) : 0;
    final status = switch (type) {
      'error' => EngineStatus.error,
      'ended' => EngineStatus.ended,
      _ when _loading => EngineStatus.loading,
      _ => EngineStatus.ready,
    };
    _states.add(
      EngineState(
        status: status,
        playing: !el.paused && !el.ended,
        position: _sec(el.currentTime),
        duration: _sec(el.duration),
        buffered: _sec(buffered),
        error: type == 'error' ? (error ?? el.error?.message) : null,
      ),
    );
    final session = _session;
    if (session == null) return;
    session.playbackState = el.src.isEmpty && _hls == null ? 'none' : (el.paused ? 'paused' : 'playing');
    final d = el.duration;
    if (d.isFinite && d > 0 && type != 'timeupdate') {
      session.setPositionState(
        web.MediaPositionState(duration: d, position: el.currentTime.clamp(0, d), playbackRate: el.playbackRate),
      );
    }
  }

  Future<void> _ensureHlsJs() => _hlsScript ??= () {
    final done = Completer<void>();
    final s = web.HTMLScriptElement()
      ..src = 'https://cdn.jsdelivr.net/npm/hls.js@1/dist/hls.min.js'
      ..onload = ((web.Event _) => done.complete()).toJS
      ..onerror = ((web.Event _) => done.completeError('hls.js')).toJS;
    web.document.head!.append(s);
    return done.future;
  }();

  @override
  Future<void> load(StreamInfo stream, MediaMeta meta, {bool play = true, Duration start = Duration.zero}) async {
    _endFade();
    _tempo?.cancel();
    _audio.defaultPlaybackRate = _speed;
    await _loadInto(stream, meta, play: play, start: start);
  }

  /// Silences the fading-out deck and puts both deck gains back to full.
  void _endFade() {
    _fadeDone?.cancel();
    _fadeDone = null;
    final old = _decks[1 - _cur];
    if (old.src.isNotEmpty || _outHls != null) {
      old
        ..pause()
        ..removeAttribute('src')
        ..load();
    }
    _outHls?.destroy();
    _outHls = null;
    final g = _graph;
    if (g == null) return;
    for (final d in g.decks) {
      d.gain
        ..cancelScheduledValues(0)
        ..value = 1;
    }
  }

  @override
  Future<void> crossfade(
    StreamInfo stream,
    MediaMeta meta, {
    Duration start = Duration.zero,
    Duration duration = const Duration(milliseconds: 3000),
    double tempoRatio = 1,
  }) async {
    final g = _graph;
    // DRM runs outside the graph, and with nothing audible a fade has nothing to blend.
    if (g == null || stream.drm || _drmAudio != null || _audio.paused || duration <= Duration.zero) {
      return load(stream, meta, start: start);
    }
    _endFade();
    _tempo?.cancel();
    final out = _cur;
    _outHls = _hls;
    _hls = null;
    _cur = 1 - _cur;
    final into = _cur;
    g.decks[into].gain
      ..cancelScheduledValues(0)
      ..value = 0;
    final matched = _speed * tempoRatio.clamp(.9, 1.1);
    _audio.defaultPlaybackRate = matched;
    await _loadInto(stream, meta, play: true, start: start);
    if (_cur != into) return; // superseded meanwhile

    // Equal power: in = sin, out = cos – the sum stays equally loud.
    const n = 64;
    final secs = duration.inMilliseconds / 1000;
    final now = g.ctx.currentTime;
    JSArray<JSNumber> curve(double Function(double) f) => [for (var i = 0; i < n; i++) f(i / (n - 1)).toJS].toJS;
    g.decks[into].gain
      ..cancelScheduledValues(0)
      ..setValueCurveAtTime(curve((x) => math.sin(x * math.pi / 2)), now, secs);
    g.decks[out].gain
      ..cancelScheduledValues(0)
      ..setValueCurveAtTime(curve((x) => math.cos(x * math.pi / 2)), now, secs);
    _fadeDone = Timer(duration + const Duration(milliseconds: 100), () {
      if (_cur != into) return;
      _endFade();
      if (matched != _speed) _tempoBack(_audio, matched);
    });
  }

  /// After the transition, inaudibly (8 s) bring the tempo back to the user's speed.
  void _tempoBack(web.HTMLAudioElement el, double from) {
    var p = 0.0;
    _tempo = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      p = math.min(1, p + 1 / 80);
      el.playbackRate = from + (_speed - from) * p;
      if (p >= 1) {
        timer.cancel();
        el.defaultPlaybackRate = _speed;
      }
    });
  }

  Future<void> _loadInto(StreamInfo stream, MediaMeta meta, {required bool play, required Duration start}) async {
    _hls?.destroy();
    _hls = null;
    _releaseDrm();
    if (stream.drm) {
      // Silence the normal element, DRM track on a fresh element without a graph.
      _audio
        ..pause()
        ..removeAttribute('src')
        ..load();
      _drmAudio = _newDrmElement();
      _loudness.value = Loudness.none;
    }
    _loading = true;
    _emit('loading');
    // New measurement per track; gain continues smoothly from the last value.
    _meter400.clear();
    _gated.clear();
    _trackStart = DateTime.now();

    final el = _el;
    Completer<void>? drmReady;
    final nativeHls = _audio.canPlayType('application/vnd.apple.mpegurl').isNotEmpty;
    if (stream.drm) {
      await _ensureHlsJs();
      if (!globalContext.has('Hls') || !_Hls.isSupported()) throw StateError('DRM: hls.js/MSE not available');
      final ready = drmReady = Completer<void>();
      // "canplay" only fires once the license is there and audio can be decrypted.
      el.addEventListener(
        'canplay',
        ((web.Event _) {
          if (!ready.isCompleted) ready.complete();
        }).toJS,
      );
      _hls = _hlsFor(_drmConfig(stream.licenseToken!), ready)
        ..loadSource(stream.url)
        ..attachMedia(el);
    } else if (stream.hls && !nativeHls) {
      await _ensureHlsJs();
      if (globalContext.has('Hls') && _Hls.isSupported()) {
        _hls = _hlsFor(JSObject(), null)
          ..loadSource(stream.url)
          ..attachMedia(_audio);
      }
    } else {
      _audio.src = stream.url;
    }
    if (start > Duration.zero) el.currentTime = start.inMilliseconds / 1000;

    _session?.metadata = web.MediaMetadata(
      web.MediaMetadataInit(
        title: meta.title,
        artist: meta.artist,
        artwork: [if (meta.artUrl != null) web.MediaImage(src: meta.artUrl!, sizes: '500x500')].toJS,
      ),
    );
    if (drmReady != null) {
      // With DRM, play() waits for the license – don't block, wait for license/error instead,
      // so a failure is reported like any load error (the player moves on).
      if (play) unawaited(this.play());
      await drmReady.future.timeout(const Duration(seconds: 20));
      return;
    }
    if (play) await this.play();
  }

  /// hls.js instance; fatal errors go to [ready] while loading, afterwards out as an error state.
  _Hls _hlsFor(JSObject config, Completer<void>? ready) => _Hls(config)
    ..on(
      'hlsError',
      ((JSString _, _HlsError e) {
        if (!e.fatal) return;
        final msg = ready == null ? 'HLS: ${e.details}' : 'DRM: ${e.details}';
        if (ready != null && !ready.isCompleted) {
          ready.completeError(StateError(msg));
        } else {
          _emit('error', error: msg);
        }
      }).toJS,
    );

  /// EME configuration for SoundCloud's cenc streams. The browser's CDM fetches licenses directly
  /// from the SoundCloud license server (CORS open, no proxy); the token is only valid for this stream.
  static JSObject _drmConfig(String token) {
    final q = Uri.encodeQueryComponent(token);
    JSObject system(String name) => JSObject()..['licenseUrl'] = '$_licenseHost/playback/$name?license_token=$q'.toJS;
    return JSObject()
      ..['emeEnabled'] = true.toJS
      ..['drmSystems'] = (JSObject()
        ..['com.widevine.alpha'] = system('widevine')
        ..['com.microsoft.playready'] = system('playready'));
  }

  web.HTMLAudioElement _newDrmElement() {
    final el = web.HTMLAudioElement()
      ..preload = 'auto'
      ..volume = _volume;
    _listen(el);
    return el;
  }

  /// Stop and discard the DRM element (afterwards [_audio] plays again).
  void _releaseDrm() {
    final el = _drmAudio;
    if (el == null) return;
    _drmAudio = null;
    el
      ..pause()
      ..removeAttribute('src')
      ..load();
  }

  @override
  Future<void> prebuffer(
    StreamInfo stream,
    MediaMeta meta, {
    Duration start = Duration.zero,
    bool autoAdvance = false,
  }) async {}

  @override
  Future<void> play() async {
    try {
      final g = _ensureGraph();
      if (g.ctx.state == 'suspended') await g.ctx.resume().toDart;
      _startMeter();
      await _el.play().toDart;
    } catch (_) {
      /* autoplay block: the user has to tap */
    }
  }

  @override
  Future<void> pause() async {
    _endFade();
    _el.pause();
  }

  @override
  Future<void> seek(Duration p) async => _el.currentTime = p.inMilliseconds / 1000;

  @override
  Future<void> stop() async {
    _endFade();
    _tempo?.cancel();
    _audio.pause();
    _hls?.destroy();
    _hls = null;
    _releaseDrm();
    _audio.removeAttribute('src');
    _audio.load();
  }

  @override
  Future<void> setVolume(double v) async {
    _volume = v.clamp(0, 1);
    _drmAudio?.volume = _volume;
    final g = _graph;
    if (g != null) {
      g.master.gain.setTargetAtTime(_volume, g.ctx.currentTime, .02);
    } else {
      _audio.volume = _volume;
    }
  }

  @override
  Future<void> setSpeed(double s) async {
    _speed = s;
    _tempo?.cancel();
    for (final el in [..._decks, ?_drmAudio]) {
      el
        ..defaultPlaybackRate = s
        ..playbackRate = s;
    }
  }

  @override
  void dispose() {
    _meter?.cancel();
    _fadeDone?.cancel();
    _tempo?.cancel();
    stop();
    _graph?.ctx.close();
    _states.close();
    _commands.close();
  }
}

class _Graph {
  _Graph(List<web.HTMLAudioElement> elements) : ctx = web.AudioContext() {
    // Every deck feeds the same chain through its own crossfade gain.
    final source = ctx.createGain();
    decks = [
      for (final _ in elements)
        ctx.createGain()
          ..gain.value = 1
          ..connect(source),
    ];
    for (final (i, el) in elements.indexed) {
      // The graph takes over the volume; the element stays at 1.
      el.volume = 1;
      ctx.createMediaElementSource(el).connect(decks[i]);
    }
    norm = ctx.createGain();
    limiter = ctx.createDynamicsCompressor();
    master = ctx.createGain();
    analyserOut = ctx.createAnalyser()
      ..fftSize = 2048
      ..smoothingTimeConstant = .55;
    source.connect(norm);
    norm.connect(limiter);
    limiter.connect(master);
    master.connect(analyserOut);
    analyserOut.connect(ctx.destination);

    // K-weighting per ITU-R BS.1770: high shelf +4 dB from ~1.7 kHz, high-pass ~38 Hz.
    final shelf = ctx.createBiquadFilter()
      ..type = 'highshelf'
      ..frequency.value = 1681
      ..gain.value = 4;
    final hp = ctx.createBiquadFilter()
      ..type = 'highpass'
      ..frequency.value = 38
      ..Q.value = .5;
    analyserK = ctx.createAnalyser()..fftSize = 4096;
    source.connect(shelf);

    // Bass channel for the beat: 150 Hz low-pass, no smoothing (kicks stay sharp).
    final low = ctx.createBiquadFilter()
      ..type = 'lowpass'
      ..frequency.value = 150
      ..Q.value = .7;
    analyserBass = ctx.createAnalyser()
      ..fftSize =
          4096 // ~85 ms: no kick gets lost even at a low frame rate
      ..smoothingTimeConstant = 0;
    source.connect(low);
    low.connect(analyserBass);
    bassBuf = Float32List(analyserBass.fftSize).toJS;
    shelf.connect(hp);
    hp.connect(analyserK);

    kBuf = Float32List(analyserK.fftSize).toJS;
    outBuf = Float32List(analyserOut.fftSize).toJS;
    freq = Uint8List(analyserOut.frequencyBinCount).toJS;
  }

  final web.AudioContext ctx;
  late final List<web.GainNode> decks;
  late final web.GainNode norm, master;
  late final web.DynamicsCompressorNode limiter;
  late final web.AnalyserNode analyserOut, analyserK, analyserBass;
  late final JSFloat32Array kBuf, outBuf, bassBuf;
  late final JSUint8Array freq;

  /// Limiter only active with normalisation (peaks stay below −1.5 dBFS).
  void applyMode(LoudMode mode) {
    final on = mode.lufs != null;
    limiter.threshold.value = on ? -1.5 : 0;
    limiter.knee.value = 0;
    limiter.ratio.value = on ? 20 : 1;
    limiter.attack.value = .002;
    limiter.release.value = .12;
  }
}

class _Spectrum extends SpectrumSource {
  _Spectrum(this._e);
  final WebEngine _e;
  List<int>? _edges;

  @override
  bool readBands(Float32List out) {
    final g = _e._graph;
    if (g == null || _e._audio.paused) return false;
    g.analyserOut.getByteFrequencyData(g.freq);
    final data = g.freq.toDart;
    // Band edges from the device's real sample rate (44.1 or 48 kHz).
    final edges = _edges ??= logBandEdges(g.ctx.sampleRate, g.analyserOut.fftSize);
    for (var b = 0; b < SpectrumSource.bands && b < out.length; b++) {
      var peak = 0;
      final hi = math.max(edges[b], edges[b + 1] - 1);
      for (var i = edges[b]; i <= hi; i++) {
        if (data[i] > peak) peak = data[i];
      }
      out[b] = peak / 255;
    }
    return true;
  }

  @override
  double? bass() {
    final g = _e._graph;
    if (g == null || _e._audio.paused) return null;
    g.analyserBass.getFloatTimeDomainData(g.bassBuf);
    final b = g.bassBuf.toDart;
    // Loudest 10 ms block in the window (≈480 samples) = kick peak.
    const block = 480;
    var peak = 0.0;
    for (var start = 0; start + block <= b.length; start += block) {
      var sum = 0.0;
      for (var i = start; i < start + block; i++) {
        sum += b[i] * b[i];
      }
      if (sum > peak) peak = sum;
    }
    // RMS in dBFS, −42 … −6 dB mapped to 0..1
    final db = 10 * math.log(peak / block + 1e-12) / math.ln10;
    return ((db + 42) / 36).clamp(0.0, 1.0);
  }
}

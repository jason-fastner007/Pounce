import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../sc/soundcloud.dart';
import 'engine_factory_io.dart' if (dart.library.js_interop) 'engine_factory_web.dart' as impl;

enum EngineStatus { idle, loading, ready, ended, error }

/// Commands from system controls (notification, lock screen, keyboard).
enum RemoteCommand { play, pause, next, previous }

class EngineState {
  const EngineState({
    this.status = EngineStatus.idle,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = Duration.zero,
    this.error,
  });

  final EngineStatus status;
  final bool playing;
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final String? error;

  EngineState copyWith({Duration? position}) => EngineState(
    status: status,
    playing: playing,
    position: position ?? this.position,
    duration: duration,
    buffered: buffered,
    error: error,
  );
}

/// Loud/quiet mode: target loudness per ITU-R BS.1770 (LUFS).
enum LoudMode {
  off(null),
  quiet(-19),
  normal(-14),
  loud(-11);

  const LoudMode(this.lufs);
  final double? lufs;
}

/// Live loudness readings (null = unknown).
class Loudness {
  const Loudness({this.momentary, this.integrated, this.gainDb, this.limiterDb = 0, this.clipping = false});

  static const none = Loudness();

  /// Source loudness (LUFS, ~400 ms or integrated over the track).
  final double? momentary;
  final double? integrated;

  /// Applied normalisation and limiter gain reduction (dB).
  final double? gainDb;
  final double limiterDb;
  final bool clipping;
}

/// Frequency spectrum to poll per frame (no stream, no allocation).
abstract class SpectrumSource {
  /// Number of logarithmic bands (30 Hz … 16 kHz), the same everywhere.
  static const bands = 64;

  /// Fills [out] (length [bands]) with 0..1 per band – the way the audio sounds *now*.
  /// false = no data at the moment (paused, buffering).
  bool readBands(Float32List out);

  /// Current bass level (150 Hz low-pass, unsmoothed) 0..1, null = unknown.
  double? bass() => null;

  /// Analysis on/off (e.g. off while nothing is visible – saves battery).
  void listen(bool on) {}
}

/// Band edges (FFT bins) for [SpectrumSource.bands] logarithmic bands from 30 Hz to 16 kHz.
List<int> logBandEdges(double sampleRate, int fftSize) {
  final binHz = sampleRate / fftSize;
  return [
    for (var i = 0; i <= SpectrumSource.bands; i++)
      (30 * math.pow(16000 / 30, i / SpectrumSource.bands) / binHz).round().clamp(1, fftSize ~/ 2 - 1),
  ];
}

/// Decoded mono PCM of a stream excerpt (for BPM/key/AI analysis).
class PcmClip {
  const PcmClip(this.samples, this.sampleRate, this.start);

  final Float32List samples;
  final int sampleRate;

  /// Where the excerpt starts in the track.
  final Duration start;

  Duration get length => Duration(microseconds: samples.length * 1000000 ~/ sampleRate);
}

/// Metadata for the system media controls.
class MediaMeta {
  const MediaMeta({
    required this.id,
    required this.title,
    required this.artist,
    this.artUrl,
    this.duration = Duration.zero,
  });

  final String id;
  final String title;
  final String artist;
  final String? artUrl;
  final Duration duration;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'artist': artist,
    'artUrl': artUrl,
    'durationMs': duration.inMilliseconds,
  };
}

/// Platform-neutral playback. Implementations use the system API in each case:
/// Android Media3, Apple AVPlayer, web <audio>, desktop libmpv.
abstract class AudioEngine {
  static AudioEngine create() => impl.createEngine();

  Stream<EngineState> get states;
  Stream<RemoteCommand> get commands;

  Future<void> load(StreamInfo stream, MediaMeta meta, {bool play = true, Duration start = Duration.zero});

  /// Pre-buffers [stream] on the free deck. [autoAdvance]: at the end of the current track
  /// the platform starts it by itself (gapless, no round trip through Dart) and then reports "ended".
  Future<void> prebuffer(
    StreamInfo stream,
    MediaMeta meta, {
    Duration start = Duration.zero,
    bool autoAdvance = false,
  }) async {}

  /// Discards what [prebuffer] prepared (e.g. the finger moved to scroll).
  Future<void> cancelPrebuffer() async {}

  /// Crossfades into [stream]. [tempoRatio] adjusts the tempo of the new track
  /// (DJ beat matching, 1 = original tempo) – platforms without support ignore it.
  Future<void> crossfade(
    StreamInfo stream,
    MediaMeta meta, {
    Duration start = Duration.zero,
    Duration duration = const Duration(milliseconds: 3000),
    double tempoRatio = 1,
  }) async => load(stream, meta, play: true, start: start);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> setVolume(double volume);
  Future<void> setSpeed(double speed);

  /// Loud/quiet mode (loudness normalisation with limiter).
  Future<void> setLoudMode(LoudMode mode);

  /// false = the platform can't normalise (yet).
  bool get supportsLoudness => false;

  ValueListenable<Loudness> get loudness;

  /// Real FFT spectrum, if the platform provides it.
  SpectrumSource? get spectrum => null;

  /// Title from the stream metadata (radio: ICY "StreamTitle").
  ValueListenable<String?> get streamTitle => _noTitle;
  static final _noTitle = ValueNotifier<String?>(null);

  /// Decodes [length] from [from] as mono PCM (without playback, faster than real time).
  /// null = the platform can't do this; then the Dart/Rust decoder takes over.
  Future<PcmClip?> decodePcm(StreamInfo stream, {Duration from = Duration.zero, required Duration length}) async =>
      null;

  void dispose();
}

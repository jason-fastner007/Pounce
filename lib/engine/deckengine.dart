import 'dart:typed_data';

import 'deckengine_io.dart' if (dart.library.js_interop) 'deckengine_web.dart' as impl;

/// Input for analysing an MP3 excerpt (HTTP range from the progressive file).
class ClipRequest {
  const ClipRequest({
    required this.head,
    required this.clip,
    required this.clipOffset,
    required this.durationMs,
    this.envelope,
    this.fakeprint = true,
  });

  /// The first KB of the file (ID3, Info/LAME frame).
  final Uint8List head;

  /// The excerpt and where it starts in the file (byte).
  final Uint8List clip;
  final int clipOffset;

  final double durationMs;

  /// Amplitude envelope of the whole track (SoundCloud waveform) for mix points.
  final Float32List? envelope;

  /// Also compute the AI fingerprint.
  final bool fakeprint;
}

/// Result of the deckengine analysis (times in ms on the track's timeline).
class ClipAnalysis {
  const ClipAnalysis({
    required this.bpm,
    required this.bpmConfidence,
    required this.firstBeatMs,
    required this.downbeatMs,
    required this.phraseMs,
    required this.downbeatConfidence,
    required this.phraseConfidence,
    required this.keyPitch,
    required this.keyMinor,
    required this.keyConfidence,
    required this.mixInMs,
    required this.mixOutMs,
    required this.lufs,
    required this.peakDb,
    required this.bass,
    required this.mid,
    required this.high,
    required this.onsetDensity,
    required this.energy,
    required this.aiProbability,
    required this.windowStartMs,
    required this.analyzedMs,
    this.bassBodyDb,
  });

  final double bpm, bpmConfidence;
  final double firstBeatMs, downbeatMs, phraseMs;
  final double downbeatConfidence, phraseConfidence;

  /// 0 = C … 11 = B, null = no recognisable key.
  final int? keyPitch;
  final bool keyMinor;
  final double keyConfidence;
  final double? mixInMs, mixOutMs;
  final double lufs, peakDb;
  final double bass, mid, high, onsetDensity, energy;

  /// AI fingerprint 0..1, null = not computed.
  final double? aiProbability;
  final double windowStartMs, analyzedMs;

  /// Bass level (dBFS) of the analysed window from the middle of the track – reference for [DeckEngine.scanEvents].
  final double? bassBodyDb;

  /// From the raw values of the C struct (same order as `DeTrackAnalysis`).
  factory ClipAnalysis.fromList(List<double> v) => ClipAnalysis(
    firstBeatMs: v[0],
    downbeatMs: v[1],
    phraseMs: v[2],
    mixInMs: v[3] < 0 ? null : v[3],
    mixOutMs: v[4] < 0 ? null : v[4],
    windowStartMs: v[5],
    analyzedMs: v[6],
    bpm: v[7],
    bpmConfidence: v[8],
    downbeatConfidence: v[9],
    phraseConfidence: v[10],
    keyPitch: v[11] < 0 ? null : v[11].round(),
    keyMinor: v[12] != 0,
    keyConfidence: v[13],
    lufs: v[14],
    peakDb: v[15],
    bass: v[16],
    mid: v[17],
    high: v[18],
    onsetDensity: v[19],
    energy: v[20],
    aiProbability: v[21] < 0 ? null : v[21],
    bassBodyDb: v.length > 22 && v[22] < 0 ? v[22] : null,
  );
}

/// An MP3 excerpt that is searched for the cue point and the first drop.
class EventRequest {
  const EventRequest({
    required this.head,
    required this.clip,
    required this.clipOffset,
    required this.periodMs,
    required this.downbeatMs,
    this.bassBodyDb,
    this.wantCue = false,
  });

  final Uint8List head;
  final Uint8List clip;
  final int clipOffset;

  /// Beat grid from the analysis (to snap the drop).
  final double periodMs, downbeatMs;

  /// Bass level of the track body ([ClipAnalysis.bassBodyDb]); without it only the excerpt counts.
  final double? bassBodyDb;

  /// The excerpt starts at the beginning of the file: also look for the cue point.
  final bool wantCue;
}

/// Cue point and first drop (ms on the track timeline, null = not in the excerpt).
class TrackEvents {
  const TrackEvents({this.cueMs, this.dropMs, this.dropStrength = 0});

  final double? cueMs, dropMs;

  /// 0..1: how clearly the bass comes back.
  final double dropStrength;

  factory TrackEvents.fromList(List<double> v) =>
      TrackEvents(cueMs: v[0] < 0 ? null : v[0], dropMs: v[1] < 0 ? null : v[1], dropStrength: v[2]);
}

/// Rust library `deckengine`: natively via dart:ffi (in a background isolate),
/// in the browser as WebAssembly in a web worker – the UI thread never does the maths.
abstract class DeckEngine {
  /// null = not available on this platform (then the Dart fallbacks kick in).
  static DeckEngine? get instance => impl.instance;

  /// Short name for display ("Rust · FFI", "Rust · WASM").
  String get label;

  /// Decodes an MP3 excerpt and analyses tempo, grid, key, energy and AI traces.
  Future<ClipAnalysis?> analyzeMp3Clip(ClipRequest request);

  /// Searches an excerpt for the cue point (only at the start of the file) and the first drop.
  Future<TrackEvents?> scanEvents(EventRequest request);

  /// Only the AI fingerprint for mono PCM (0..1, null = silence/too short).
  Future<double?> fakeprint(Float32List pcm, int sampleRate);

  /// Old envelope estimate (fallback only, without an audio excerpt).
  Future<List<double>?> analyzeWaveform(List<double> samples, int durationMs);
}

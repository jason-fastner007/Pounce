import 'dart:async';
import 'dart:collection' show Queue;
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../core/store.dart';
import '../engine/deckengine.dart';
import '../sc/models.dart';
import '../sc/soundcloud.dart';
import 'camelot_key.dart';

/// Where an analysis comes from – determines how much it can be trusted.
enum BeatSource {
  /// Real audio (MP3 excerpt, deckengine): grid, key, loudness.
  pcm,

  /// SoundCloud waveform only (~10 values/s): rough tempo, no key.
  waveform,

  /// Metadata only ("175 BPM" in the title, genre).
  hint,
}

/// Analysis result for BPM, beat grid, key, energy and mix points.
class BeatInfo {
  const BeatInfo({
    required this.bpm,
    required this.firstBeatOffsetMs,
    required this.confidence,
    this.key,
    this.keyConfidence = 0,
    this.mixInPointMs,
    this.mixOutPointMs,
    this.downbeatOffsetMs = 0,
    this.phraseOffsetMs = 0,
    this.downbeatConfidence = 0.0,
    this.phraseConfidence = 0.0,
    this.bassEnergy = 0.0,
    this.midEnergy = 0.0,
    this.highEnergy = 0.0,
    this.totalEnergy = 0.0,
    this.lufs,
    this.onsetDensity = 0,
    this.aiProbability,
    this.source = BeatSource.pcm,
    this.bassBodyDb,
    this.cueMs,
    this.dropMs,
    this.dropStrength = 0,
    this.eventsScanned = false,
  });

  final double bpm;
  final int firstBeatOffsetMs;
  final double confidence;
  final CamelotKey? key;
  final double keyConfidence;
  final int? mixInPointMs;
  final int? mixOutPointMs;
  final int downbeatOffsetMs;
  final int phraseOffsetMs;
  final double downbeatConfidence;
  final double phraseConfidence;

  /// Share of spectral energy per band (sum ~1).
  final double bassEnergy;
  final double midEnergy;
  final double highEnergy;

  /// Energy level 0..1 (1 = peak time).
  final double totalEnergy;

  /// Integrated loudness of the excerpt (LUFS).
  final double? lufs;

  /// Onsets per second.
  final double onsetDensity;

  /// AI fingerprint of the audio (0..1), null = not measured.
  final double? aiProbability;
  final BeatSource source;

  /// Bass level (dBFS) from the middle of the track – reference for the drop search.
  final double? bassBodyDb;

  /// First sound after the silence at the start (ms), null = unknown.
  final int? cueMs;

  /// First drop: the bass returns after a breakdown, snapped to bar/beat (ms).
  final int? dropMs;

  /// 0..1: how pronounced the drop is.
  final double dropStrength;

  /// Cue/drop were searched for (even if no drop was found) – don't load again.
  final bool eventsScanned;

  double get periodMs => bpm > 0 ? (60000.0 / bpm) : 500.0;
  double get barMs => periodMs * 4;
  double get phraseMs => periodMs * 16;

  /// Energy as a level 1..10 for set planning.
  int get energyLevel => (1 + totalEnergy * 9).round().clamp(1, 10);

  bool get hasGrid => source == BeatSource.pcm && confidence >= .35;

  static const _version = 4;

  Map<String, dynamic> toJson() => {
    'v': _version,
    'bpm': bpm,
    'first': firstBeatOffsetMs,
    'conf': confidence,
    'key': key?.code,
    'keyConf': keyConfidence,
    'in': mixInPointMs,
    'out': mixOutPointMs,
    'down': downbeatOffsetMs,
    'phrase': phraseOffsetMs,
    'downConf': downbeatConfidence,
    'phraseConf': phraseConfidence,
    'bass': bassEnergy,
    'mid': midEnergy,
    'high': highEnergy,
    'energy': totalEnergy,
    'lufs': lufs,
    'onsets': onsetDensity,
    'ai': aiProbability,
    'src': source.name,
    if (bassBodyDb != null) 'bassBody': bassBodyDb,
    if (cueMs != null) 'cue': cueMs,
    if (dropMs != null) 'drop': dropMs,
    if (dropMs != null) 'dropStr': dropStrength,
    if (eventsScanned) 'ev': true,
  };

  static BeatInfo? fromJson(Map<String, dynamic>? j) {
    if (j == null || j['v'] != _version) return null;
    final bpm = (j['bpm'] as num?)?.toDouble() ?? 0;
    if (bpm <= 0) return null;
    double d(String k) => (j[k] as num?)?.toDouble() ?? 0;
    return BeatInfo(
      bpm: bpm,
      firstBeatOffsetMs: (j['first'] as num?)?.toInt() ?? 0,
      confidence: d('conf'),
      key: j['key'] == null ? null : CamelotKey.fromCode(j['key'] as String),
      keyConfidence: d('keyConf'),
      mixInPointMs: (j['in'] as num?)?.toInt(),
      mixOutPointMs: (j['out'] as num?)?.toInt(),
      downbeatOffsetMs: (j['down'] as num?)?.toInt() ?? 0,
      phraseOffsetMs: (j['phrase'] as num?)?.toInt() ?? 0,
      downbeatConfidence: d('downConf'),
      phraseConfidence: d('phraseConf'),
      bassEnergy: d('bass'),
      midEnergy: d('mid'),
      highEnergy: d('high'),
      totalEnergy: d('energy'),
      lufs: (j['lufs'] as num?)?.toDouble(),
      onsetDensity: d('onsets'),
      aiProbability: (j['ai'] as num?)?.toDouble(),
      source: BeatSource.values.asNameMap()[j['src']] ?? BeatSource.pcm,
      bassBodyDb: (j['bassBody'] as num?)?.toDouble(),
      cueMs: (j['cue'] as num?)?.toInt(),
      dropMs: (j['drop'] as num?)?.toInt(),
      dropStrength: d('dropStr'),
      eventsScanned: j['ev'] == true,
    );
  }

  BeatInfo withBpm(double v, double conf) => BeatInfo(
    bpm: v,
    firstBeatOffsetMs: firstBeatOffsetMs,
    confidence: conf,
    key: key,
    keyConfidence: keyConfidence,
    mixInPointMs: mixInPointMs,
    mixOutPointMs: mixOutPointMs,
    downbeatOffsetMs: downbeatOffsetMs,
    phraseOffsetMs: phraseOffsetMs,
    downbeatConfidence: downbeatConfidence,
    phraseConfidence: phraseConfidence,
    bassEnergy: bassEnergy,
    midEnergy: midEnergy,
    highEnergy: highEnergy,
    totalEnergy: totalEnergy,
    lufs: lufs,
    onsetDensity: onsetDensity,
    aiProbability: aiProbability,
    source: source,
    bassBodyDb: bassBodyDb,
    cueMs: cueMs,
    dropMs: dropMs,
    dropStrength: dropStrength,
    eventsScanned: eventsScanned,
  );

  /// With cue/drop from [BeatAnalyzer.events].
  BeatInfo withEvents({int? cue, int? drop, double strength = 0}) => BeatInfo(
    bpm: bpm,
    firstBeatOffsetMs: firstBeatOffsetMs,
    confidence: confidence,
    key: key,
    keyConfidence: keyConfidence,
    mixInPointMs: mixInPointMs,
    mixOutPointMs: mixOutPointMs,
    downbeatOffsetMs: downbeatOffsetMs,
    phraseOffsetMs: phraseOffsetMs,
    downbeatConfidence: downbeatConfidence,
    phraseConfidence: phraseConfidence,
    bassEnergy: bassEnergy,
    midEnergy: midEnergy,
    highEnergy: highEnergy,
    totalEnergy: totalEnergy,
    lufs: lufs,
    onsetDensity: onsetDensity,
    aiProbability: aiProbability,
    source: source,
    bassBodyDb: bassBodyDb,
    cueMs: cue,
    dropMs: drop,
    dropStrength: strength,
    eventsScanned: true,
  );
}

/// BPM, grid and key analysis for DJ Flow, automix, visualisation and the AI filter.
///
/// Per track only the file header and a 30 s excerpt of the progressive MP3 are loaded
/// (~500 KB instead of the whole file) and analysed in the Rust deckengine: natively in a
/// background isolate, in the browser in a web worker. Results land in the `beat` table
/// of the database and are never computed twice.
class BeatAnalyzer {
  BeatAnalyzer(this.sc, this.store, {DeckEngine? engine}) : _engine = engine ?? DeckEngine.instance;

  final SoundCloud sc;
  final Store store;
  final DeckEngine? _engine;

  /// Name of the analysis engine for display.
  String get engineLabel => _engine?.label ?? 'Dart';
  bool get hasEngine => _engine != null;

  static const _clipMs = 30000;
  static const _maxRows = 4000;
  static const _parallel = 2;

  final _mem = <int, BeatInfo?>{}; // LinkedHashMap: insertion order = LRU
  final _inflight = <int, Future<BeatInfo?>>{};
  final _queue = Queue<(bool, Completer<void>)>();
  var _running = 0;
  var _writes = 0;

  final _updates = StreamController<(Track, BeatInfo)>.broadcast();

  /// New analyses (e.g. to add BPM/key to lists).
  Stream<(Track, BeatInfo)> get updates => _updates.stream;

  /// Only what's already in memory (synchronous, no network).
  BeatInfo? peek(Track t) => _mem[t.id];

  /// Extracts BPM hints from metadata, title and genre (e.g. "160 BPM", "Tekk").
  static double? extractBpmHint(Track track) {
    if (track.bpm != null && track.bpm! >= 60 && track.bpm! <= 200) return track.bpm;
    final match = RegExp(r'\b(\d{2,3}(?:[.,]\d)?)\s*bpm\b', caseSensitive: false).firstMatch(track.title);
    if (match != null) {
      final v = double.tryParse(match.group(1)!.replaceAll(',', '.'));
      if (v != null && v >= 60 && v <= 220) return v;
    }
    final text = '${track.title} ${track.genre ?? ''}'.toLowerCase();
    if (text.contains('hardtekk') || text.contains('tekk')) return 160;
    if (text.contains('drum and bass') || text.contains('dnb') || text.contains('d&b')) return 174;
    if (text.contains('psytrance') || text.contains('psy trance')) return 142;
    return null;
  }

  /// Returns a track's analysis (memory → database → network).
  /// [priority]: queue ahead of waiting analyses (current track).
  Future<BeatInfo?> analyze(Track track, {bool priority = false}) {
    if (track.isLive) return Future.value();
    if (_mem.containsKey(track.id)) {
      final v = _mem.remove(track.id);
      _mem[track.id] = v; // zuletzt benutzt
      return Future.value(v);
    }
    // Block instead of arrow: remove() returns the future itself, and whenComplete would
    // wait for it – the future waited for itself and never completed.
    return _inflight[track.id] ??= _run(track, priority).whenComplete(() {
      _inflight.remove(track.id);
    });
  }

  final _eventsInflight = <int, Future<BeatInfo?>>{};

  /// Find a track's cue point and first drop (for DJ transitions; the result is stored).
  ///
  /// Loads 30 s sections of the progressive MP3 from the start until the first drop is found –
  /// at most up to half the track or 2:30. Typically 1–3 sections of ~480 KB, once per track.
  Future<BeatInfo?> events(Track track) {
    final running = _eventsInflight[track.id];
    if (running != null) return running;
    final job = _scanEvents(track)
        .timeout(const Duration(seconds: 60), onTimeout: () => _mem[track.id])
        .catchError((Object _) => _mem[track.id]);
    _eventsInflight[track.id] = job;
    job.whenComplete(() {
      _eventsInflight.remove(track.id);
    });
    return job;
  }

  Future<BeatInfo?> _scanEvents(Track track) async {
    final info = await analyze(track);
    final engine = _engine;
    if (info == null || info.eventsScanned || engine == null || info.source != BeatSource.pcm) return info;
    if (track.isProtected || track.durationMs < 20000) return info;
    final url = await sc.progressiveMp3(track);
    if (url == null) return info;
    var head = await sc.range(url, 0, 8191);
    final need = _headNeeds(head);
    if (need > head.length) head = await sc.range(url, 0, need - 1);
    final layout = _Mp3Layout.of(head);
    if (layout == null) return info;

    const chunkMs = 30000, stepMs = 26000; // 4 s overlap: a drop at the boundary isn't lost
    final dur = track.durationMs;
    final limit = math.min(dur * .5, 150000);
    int? cue;
    TrackEvents? drop;
    var scanned = false;
    for (var at = 0; at < limit; at += stepMs) {
      final from = layout.byteAt(at);
      final to = layout.byteAt(math.min(dur, at + chunkMs)) + 4 * 418;
      final clip = await sc.range(url, from, to);
      final e = await engine.scanEvents(
        EventRequest(
          head: head,
          clip: clip,
          clipOffset: from,
          periodMs: info.periodMs,
          downbeatMs: info.downbeatOffsetMs.toDouble(),
          bassBodyDb: info.bassBodyDb,
          wantCue: at == 0,
        ),
      );
      if (e == null) break; // engine without cue/drop detection, or a decode error
      scanned = true;
      if (at == 0) cue = e.cueMs?.round();
      if (e.dropMs != null) {
        drop = e;
        break;
      }
    }
    // Nothing evaluated: don't mark as "searched", try again later.
    if (!scanned) return info;
    final updated = info.withEvents(cue: cue, drop: drop?.dropMs?.round(), strength: drop?.dropStrength ?? 0);
    _remember(track.id, updated);
    _updates.add((track, updated));
    await store.db.write(Table.beat, {'${track.id}': jsonEncode(updated.toJson())});
    return updated;
  }

  void _remember(int id, BeatInfo? v) {
    _mem[id] = v;
    if (_mem.length > 400) _mem.remove(_mem.keys.first);
  }

  Future<BeatInfo?> _run(Track track, bool priority) async {
    final stored = await store.db.get(Table.beat, '${track.id}');
    if (stored != null) {
      try {
        final info = BeatInfo.fromJson(jsonDecode(stored) as Map<String, dynamic>);
        if (info != null) {
          _remember(track.id, info);
          return info;
        }
      } catch (_) {}
    }

    await _slot(priority);
    BeatInfo? info;
    try {
      // A hanging fetch must not block the queue permanently.
      info = await _analyzeAudio(track).timeout(const Duration(seconds: 40));
    } catch (_) {
      info = null;
    } finally {
      _release();
    }
    info ??= await _fallback(track).timeout(const Duration(seconds: 15), onTimeout: () => null);
    info = _applyHint(track, info);
    _remember(track.id, info);
    if (info != null) {
      _updates.add((track, info));
      // Only store real audio analyses permanently; estimates are replaced later.
      if (info.source == BeatSource.pcm) {
        await store.db.write(Table.beat, {'${track.id}': jsonEncode(info.toJson())});
        if (++_writes % 50 == 0) unawaited(store.db.trim(Table.beat, _maxRows));
      }
    }
    return info;
  }

  // ---------- Concurrency ----------

  Future<void> _slot(bool priority) {
    if (_running < _parallel) {
      _running++;
      return Future.value();
    }
    final c = Completer<void>();
    priority ? _queue.addFirst((true, c)) : _queue.addLast((false, c));
    return c.future;
  }

  void _release() {
    if (_queue.isNotEmpty) {
      _queue.removeFirst().$2.complete();
    } else {
      _running--;
    }
  }

  // ---------- Audio-Analyse ----------

  Future<BeatInfo?> _analyzeAudio(Track track) async {
    final engine = _engine;
    // DRM tracks: no unencrypted MP3 for analysis (SoundCloud returns 404).
    if (engine == null || track.durationMs < 8000 || track.isProtected) return null;
    final url = await sc.progressiveMp3(track);
    if (url == null) return null;

    var head = await sc.range(url, 0, 8191);
    final need = _headNeeds(head);
    if (need > head.length) head = await sc.range(url, 0, need - 1);
    final layout = _Mp3Layout.of(head);
    if (layout == null) return null;

    // 30 s from 35 % of the length: past the intro, usually before the big break.
    final dur = track.durationMs;
    final startMs = dur <= _clipMs + 10000 ? 0 : (dur * .35).round().clamp(0, dur - _clipMs);
    final from = layout.byteAt(startMs);
    final to = layout.byteAt(math.min(dur, startMs + _clipMs)) + 4 * 418;

    final results = await (sc.range(url, from, to), sc.waveform(track)).wait;
    final env = results.$2.isEmpty ? null : Float32List.fromList(results.$2);
    final a = await engine.analyzeMp3Clip(
      ClipRequest(head: head, clip: results.$1, clipOffset: from, durationMs: dur.toDouble(), envelope: env),
    );
    if (a == null) return null;
    return BeatInfo(
      bpm: double.parse(a.bpm.toStringAsFixed(2)),
      firstBeatOffsetMs: a.firstBeatMs.round(),
      confidence: a.bpmConfidence,
      key: a.keyPitch == null ? null : CamelotKey.fromPitchClass(a.keyPitch!, a.keyMinor),
      keyConfidence: a.keyConfidence,
      mixInPointMs: a.mixInMs?.round(),
      mixOutPointMs: a.mixOutMs?.round(),
      downbeatOffsetMs: a.downbeatMs.round(),
      phraseOffsetMs: a.phraseMs.round(),
      downbeatConfidence: a.downbeatConfidence,
      phraseConfidence: a.phraseConfidence,
      bassEnergy: a.bass,
      midEnergy: a.mid,
      highEnergy: a.high,
      totalEnergy: ((a.energy - 1) / 9).clamp(0.0, 1.0),
      lufs: a.lufs,
      onsetDensity: a.onsetDensity,
      aiProbability: a.aiProbability,
      bassBodyDb: a.bassBodyDb,
    );
  }

  /// Minimum bytes the header needs (ID3v2 can be large, e.g. with a cover).
  static int _headNeeds(Uint8List h) {
    if (h.length < 10 || h[0] != 0x49 || h[1] != 0x44 || h[2] != 0x33) return 0;
    final size = (h[6] & 0x7F) << 21 | (h[7] & 0x7F) << 14 | (h[8] & 0x7F) << 7 | (h[9] & 0x7F);
    return 10 + size + 4096;
  }

  // ---------- Fallbacks ----------

  /// Without audio: rough estimate from the waveform (no key – better none than a made-up one).
  Future<BeatInfo?> _fallback(Track track) async {
    final samples = await sc.waveform(track);
    if (samples.length < 32 || track.durationMs <= 0) return null;
    final native = await _engine?.analyzeWaveform(samples, track.durationMs);
    final est = native ?? _estimateFromWaveform(samples, track.durationMs);
    if (est == null) return null;
    final avg = samples.reduce((a, b) => a + b) / samples.length;
    return BeatInfo(
      bpm: double.parse(est[0].toStringAsFixed(1)),
      firstBeatOffsetMs: est[1].round(),
      confidence: math.min(est[2], .3),
      mixInPointMs: est[3] > 0 ? est[3].round() : null,
      mixOutPointMs: est[4] > 0 ? est[4].round() : null,
      downbeatOffsetMs: est[1].round(),
      phraseOffsetMs: est[1].round(),
      totalEnergy: avg.clamp(0.0, 1.0),
      source: BeatSource.waveform,
    );
  }

  /// Metadata hint against octave errors (80 instead of 160) and as a last resort.
  BeatInfo? _applyHint(Track track, BeatInfo? info) {
    final hint = extractBpmHint(track);
    if (hint == null) return info;
    if (info == null) {
      return BeatInfo(bpm: hint, firstBeatOffsetMs: 0, confidence: .2, source: BeatSource.hint);
    }
    if ((info.bpm - hint).abs() <= 3) return info;
    for (final f in const [2.0, .5, 1.5, 2 / 3]) {
      if ((info.bpm * f - hint).abs() <= 3) return info.withBpm(info.bpm * f, info.confidence);
    }
    // The title only overrides weak estimates.
    return info.source == BeatSource.pcm && info.confidence > .5 ? info : info.withBpm(hint, .4);
  }

  /// Envelope autocorrelation (only when neither audio nor Rust is available).
  static List<double>? _estimateFromWaveform(List<double> samples, int durationMs) {
    final n = samples.length;
    const rate = 200.0;
    final len = (durationMs * rate / 1000).round().clamp(128, 48000);
    final onsets = List<double>.filled(len, 0);
    double at(int i) {
      final x = i * (n - 1) / math.max(1, len - 1);
      final i0 = x.floor(), i1 = math.min(i0 + 1, n - 1);
      return samples[i0] * (1 - (x - i0)) + samples[i1] * (x - i0);
    }

    var prev = at(0);
    for (var i = 1; i < len; i++) {
      final v = at(i);
      if (v > prev) onsets[i] = v - prev;
      prev = v;
    }
    final minLag = (rate * 60 / 200).round(), maxLag = (rate * 60 / 60).round();
    if (len < maxLag * 2) return null;
    var bestLag = minLag;
    var best = -1.0;
    for (var lag = minLag; lag <= maxLag; lag++) {
      var c = 0.0;
      for (var i = len ~/ 10; i < len - maxLag; i++) {
        c += onsets[i] * onsets[i + lag];
      }
      if (c > best) {
        best = c;
        bestLag = lag;
      }
    }
    var bpm = rate * 60 / bestLag;
    while (bpm < 90) {
      bpm *= 2;
    }
    while (bpm >= 180) {
      bpm /= 2;
    }
    return [bpm, 0, .2, 0, 0];
  }
}

/// Minimal knowledge about a CBR MP3 to choose byte ranges (exact alignment to
/// frames and encoder delay is handled by deckengine).
class _Mp3Layout {
  const _Mp3Layout(this.audioStart, this.bytesPerSecond);
  final int audioStart;
  final double bytesPerSecond;

  int byteAt(int ms) => audioStart + (ms / 1000 * bytesPerSecond).round();

  static _Mp3Layout? of(Uint8List h) {
    var pos = 0;
    if (h.length > 10 && h[0] == 0x49 && h[1] == 0x44 && h[2] == 0x33) {
      pos = 10 + ((h[6] & 0x7F) << 21 | (h[7] & 0x7F) << 14 | (h[8] & 0x7F) << 7 | (h[9] & 0x7F));
    }
    for (var i = pos; i + 4 < h.length; i++) {
      if (h[i] != 0xFF || h[i + 1] & 0xE0 != 0xE0) continue;
      final version = (h[i + 1] >> 3) & 3, layer = (h[i + 1] >> 1) & 3;
      final br = h[i + 2] >> 4, sr = (h[i + 2] >> 2) & 3;
      if (version != 3 || layer != 1 || br == 0 || br == 15 || sr == 3) continue;
      const kbps = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320];
      final bps = kbps[br] * 125.0;
      final frame = 144000 * kbps[br] ~/ const [44100, 48000, 32000][sr];
      // An Info/Xing frame at the start contains no audio.
      return _Mp3Layout(i + frame, bps);
    }
    return null;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pounce/player/audio_engine.dart';
import 'package:pounce/sc/soundcloud.dart';

class _MinimalEngine extends AudioEngine {
  @override
  Stream<EngineState> get states => const Stream.empty();

  @override
  Stream<RemoteCommand> get commands => const Stream.empty();

  @override
  Future<void> load(StreamInfo stream, MediaMeta meta, {bool play = true, Duration start = Duration.zero}) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> setLoudMode(LoudMode mode) async {}

  @override
  ValueListenable<Loudness> get loudness => ValueNotifier(Loudness.none);

  @override
  void dispose() {}
}

class _TestSpectrumSource extends SpectrumSource {
  @override
  bool readBands(Float32List out) => false;
}

void main() {
  test('EngineState default values and copyWith', () {
    const s1 = EngineState();
    expect(s1.status, EngineStatus.idle);
    expect(s1.playing, isFalse);
    expect(s1.position, Duration.zero);
    expect(s1.duration, Duration.zero);
    expect(s1.buffered, Duration.zero);
    expect(s1.error, isNull);

    final s2 = s1.copyWith(position: const Duration(seconds: 15));
    expect(s2.position, const Duration(seconds: 15));
    expect(s2.status, EngineStatus.idle);
  });

  test('LoudMode target LUFS levels', () {
    expect(LoudMode.off.lufs, isNull);
    expect(LoudMode.quiet.lufs, -19);
    expect(LoudMode.normal.lufs, -14);
    expect(LoudMode.loud.lufs, -11);
  });

  test('Loudness model attributes', () {
    const l = Loudness(
      momentary: -14.2,
      integrated: -13.8,
      gainDb: -1.2,
      limiterDb: 0.5,
      clipping: true,
    );
    expect(l.momentary, -14.2);
    expect(l.integrated, -13.8);
    expect(l.gainDb, -1.2);
    expect(l.limiterDb, 0.5);
    expect(l.clipping, isTrue);
  });

  test('logBandEdges computes 65 band boundaries within valid FFT bins', () {
    final edges = logBandEdges(44100, 2048);
    expect(edges.length, SpectrumSource.bands + 1);
    expect(edges.first, greaterThanOrEqualTo(1));
    expect(edges.last, lessThanOrEqualTo(1023));
    for (var i = 0; i < edges.length - 1; i++) {
      expect(edges[i], lessThanOrEqualTo(edges[i + 1]));
    }
  });

  test('PcmClip length calculation', () {
    final samples = Float32List(44100 * 2);
    final clip = PcmClip(samples, 44100, const Duration(seconds: 5));
    expect(clip.start, const Duration(seconds: 5));
    expect(clip.sampleRate, 44100);
    expect(clip.length, const Duration(seconds: 2));
  });

  test('MediaMeta toMap serialization', () {
    const meta = MediaMeta(
      id: 'track_123',
      title: 'Echoes',
      artist: 'Pink Floyd',
      artUrl: 'https://cdn/art.jpg',
      duration: Duration(minutes: 23, seconds: 31),
    );
    final map = meta.toMap();
    expect(map['id'], 'track_123');
    expect(map['title'], 'Echoes');
    expect(map['artist'], 'Pink Floyd');
    expect(map['artUrl'], 'https://cdn/art.jpg');
    expect(map['durationMs'], 1411000);
  });

  test('AudioEngine base class default implementations', () async {
    final engine = _MinimalEngine();
    expect(engine.supportsLoudness, isFalse);
    expect(engine.spectrum, isNull);
    expect(engine.streamTitle.value, isNull);

    const stream = StreamInfo(
      'https://cdn/stream.mp3',
      hls: false,
      mime: 'audio/mpeg',
      preset: 'mp3_0',
    );
    const meta = MediaMeta(id: '1', title: 'T', artist: 'A');

    // Base prebuffer and cancelPrebuffer no-op
    await engine.prebuffer(stream, meta);
    await engine.cancelPrebuffer();

    // Base crossfade delegates to load
    await engine.crossfade(stream, meta);

    // Base decodePcm returns null
    final pcm = await engine.decodePcm(stream, length: const Duration(seconds: 1));
    expect(pcm, isNull);

    final source = _TestSpectrumSource();
    expect(source.bass(), isNull);
    source.listen(true);
    source.listen(false);
  });
}

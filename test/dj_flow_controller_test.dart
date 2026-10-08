import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/dj/beat_analyzer.dart';
import 'package:pounce/dj/dj_flow_controller.dart';
import 'package:pounce/dj/harmonic_mixer.dart';
import 'package:pounce/library/library.dart';
import 'package:pounce/player/audio_engine.dart';
import 'package:pounce/player/player_controller.dart';
import 'package:pounce/sc/models.dart';
import 'package:pounce/sc/soundcloud.dart';

import 'support/modules.dart';

class _FakeEngine extends AudioEngine {
  final loaded = <String>[];
  final crossfaded = <String>[];
  final _st = StreamController<EngineState>.broadcast();
  final _cmd = StreamController<RemoteCommand>.broadcast();

  @override
  Stream<EngineState> get states => _st.stream;
  @override
  Stream<RemoteCommand> get commands => _cmd.stream;

  @override
  Future<void> load(StreamInfo s, MediaMeta m, {bool play = true, Duration start = Duration.zero}) async {
    loaded.add(m.id);
  }

  @override
  Future<void> prebuffer(StreamInfo s, MediaMeta m, {Duration start = Duration.zero, bool autoAdvance = false}) async {}

  @override
  Future<void> crossfade(
    StreamInfo s,
    MediaMeta m, {
    Duration start = Duration.zero,
    Duration duration = const Duration(milliseconds: 3000),
    double tempoRatio = 1,
  }) async {
    crossfaded.add(m.id);
  }

  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration p) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> setVolume(double v) async {}
  @override
  Future<void> setSpeed(double s) async {}
  @override
  Future<void> setLoudMode(LoudMode mode) async {}
  @override
  bool get supportsLoudness => false;
  @override
  final ValueListenable<Loudness> loudness = ValueNotifier(Loudness.none);
  @override
  SpectrumSource? get spectrum => null;
  @override
  void dispose() {
    _st.close();
    _cmd.close();
  }
}

Track _t(int id, {double? bpm}) => Track(
  id: id,
  title: 'Track $id ${bpm != null ? "${bpm.round()} BPM" : ""}',
  user: const ScUser(id: 1, username: 'DJ'),
  durationMs: 180000,
  bpm: bpm,
  transcodings: const [
    Transcoding(url: 'https://api/x', preset: 'mp3', protocol: 'progressive', mime: 'audio/mpeg', snipped: false),
  ],
);

void main() {
  late Store store;
  late Settings settings;
  late SoundCloud sc;
  late PlayerController player;
  late BeatAnalyzer analyzer;
  late DjFlowController controller;

  setUp(() {
    store = Store.memory();
    settings = Settings(store);
    final client = MockClient((_) async => http.Response('{"url":"https://cdn/stream.mp3"}', 200));
    sc = SoundCloud(store, settings, client: client);
    final sources = registryWith(store, sc, client: client);
    player = PlayerController(_FakeEngine(), sources, settings, Library(store), store);
    analyzer = BeatAnalyzer(sources, store);
    controller = DjFlowController(player: player, analyzer: analyzer, store: store);
  });

  tearDown(() {
    controller.dispose();
    player.dispose();
  });

  test('Initial state loads preferences from Store', () {
    expect(controller.state.isActive, false);
    expect(controller.state.energyMode, EnergyMode.hold);
    expect(controller.state.isAutonomousEnabled, true);
    expect(controller.state.isAutoReorderEnabled, true);
  });

  test('toggleDjFlow updates state and player ownership', () {
    controller.toggleDjFlow();
    expect(controller.state.isActive, true);
    expect(player.djOwnsTransitions, true);
    expect(store.get<bool>('dj_active'), true);

    controller.toggleDjFlow();
    expect(controller.state.isActive, false);
    expect(player.djOwnsTransitions, false);
    expect(store.get<bool>('dj_active'), false);
  });

  test('setEnergyMode, setAutonomous, setAutoReorder persist changes', () {
    controller.setEnergyMode(EnergyMode.buildUp);
    expect(controller.state.energyMode, EnergyMode.buildUp);
    expect(store.get<String>('dj_energy'), 'buildUp');

    controller.setAutonomous(false);
    expect(controller.state.isAutonomousEnabled, false);
    expect(store.get<bool>('dj_autonomous'), false);

    controller.setAutoReorder(false);
    expect(controller.state.isAutoReorderEnabled, false);
    expect(store.get<bool>('dj_autoreorder'), false);
  });

  test('triggerMixNow advances to next track when match is present or absent', () async {
    final t1 = _t(1, bpm: 128.0);
    final t2 = _t(2, bpm: 128.0);
    await player.playQueue([t1, t2]);
    controller.toggleDjFlow();

    controller.triggerMixNow(skip: true);
    expect(player.current!.id, 2);
  });

  test('lookahead getter and setter updates lookahead and store', () {
    expect(controller.lookahead, 20);
    controller.lookahead = 30;
    expect(controller.lookahead, 30);
    expect(store.get<int>('dj_lookahead'), 30);
  });
}

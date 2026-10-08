import 'package:flutter/widgets.dart';

import '../dj/dj_flow_controller.dart';
import '../dj/mix_builder.dart';
import '../dj/taste.dart';
import '../library/library.dart';
import '../lyrics/lyrics_service.dart';
import '../player/player_controller.dart';
import '../radio/radio_service.dart';
import '../sc/soundcloud_module.dart';
import '../sync/sync_service.dart';
import '../modules/registry.dart';
import '../modules/updater/release_provider.dart';
import 'settings.dart';
import 'store.dart';

/// Simple dependency injection without an extra package.
class Deps extends InheritedWidget {
  const Deps({
    super.key,
    required this.settings,
    required this.modules,
    required this.lyrics,
    required this.library,
    required this.player,
    required this.dj,
    required this.mix,
    required this.taste,
    required this.radio,
    required this.store,
    required this.updates,
    required this.sync,
    required super.child,
  });

  final Settings settings;
  /// Source modules (SoundCloud, …) and installed designs.
  final ModuleRegistry modules;
  final LyricsService lyrics;
  final Library library;
  final PlayerController player;
  final DjFlowController dj;
  final MixBuilder mix;
  final TasteModel taste;
  final SyncService sync;
  final RadioService radio;
  final Store store;

  /// Update source of this build (GitHub, Play) – null: no updates (desktop, web, no repo configured).
  final Future<ReleaseProvider?> updates;

  static Deps of(BuildContext c) => c.getInheritedWidgetOfExactType<Deps>()!;

  @override
  bool updateShouldNotify(Deps old) => false;
}

extension DepsX on BuildContext {
  Deps get deps => Deps.of(this);
}

extension DepsModules on Deps {
  /// The SoundCloud module, null when it isn't part of this build or is switched off.
  SoundCloudModule? get soundcloud => modules.find<SoundCloudModule>();
}

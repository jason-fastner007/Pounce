import 'package:flutter/widgets.dart';

import '../dj/dj_flow_controller.dart';
import '../dj/mix_builder.dart';
import '../dj/taste.dart';
import '../library/account.dart';
import '../library/library.dart';
import '../lyrics/lyrics_service.dart';
import '../player/player_controller.dart';
import '../radio/radio_service.dart';
import '../sc/soundcloud.dart';
import '../sync/sync_service.dart';
import '../modules/updater/release_provider.dart';
import 'settings.dart';
import 'store.dart';

/// Simple dependency injection without an extra package.
class Deps extends InheritedWidget {
  const Deps({
    super.key,
    required this.settings,
    required this.sc,
    required this.lyrics,
    required this.library,
    required this.player,
    required this.account,
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
  final SoundCloud sc;
  final LyricsService lyrics;
  final Library library;
  final PlayerController player;
  final Account account;
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

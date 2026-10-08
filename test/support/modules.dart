import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:pounce/core/login_launcher.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/library/account.dart';
import 'package:pounce/library/library.dart';
import 'package:pounce/modules/registry.dart';
import 'package:pounce/sc/auth.dart';
import 'package:pounce/sc/soundcloud.dart';
import 'package:pounce/sc/soundcloud_module.dart';

/// A module registry with [sc] as its only source module, as in a regular (non-store) build.
ModuleRegistry registryWith(Store store, SoundCloud sc, {http.Client? client}) {
  final c = client ?? http.Client();
  final account = Account(ScAuth(store, c, sc.wrap), sc, Library(store), _NoLauncher());
  return ModuleRegistry(store, sources: [SoundCloudModule(sc, account)], client: c);
}

class _NoLauncher implements LoginLauncher {
  @override
  Stream<String> get callbacks => const Stream.empty();

  @override
  bool get automatic => true;

  @override
  Future<void> open(Uri url) async {}
}

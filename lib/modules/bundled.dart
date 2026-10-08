import 'package:http/http.dart' as http;

import '../core/settings.dart';
import '../core/store.dart';
import '../library/library.dart';
import '../sc/soundcloud_module.dart';
import 'registry.dart';

/// Source modules compiled into this build. A new source module is added here (see docs/MODULES.md).
///
/// Restricted modules sit behind the constant [storeBuild], so app store builds don't contain
/// their code at all – there is no hidden switch to turn them back on.
List<SourceModule> bundledSources(Store store, Settings settings, http.Client client, Library library) => [
  if (!storeBuild) SoundCloudModule.create(store, settings, client, library),
];

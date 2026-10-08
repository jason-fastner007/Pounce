import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/store.dart';
import 'catalog.dart';
import 'source_module.dart';
import 'theme_module.dart';

export 'catalog.dart' show CatalogEntry, ModuleCatalog;
export 'source_module.dart';
export 'theme_module.dart';

/// App store build (`--dart-define=POUNCE_STORE_BUILD=true`): modules marked
/// [ModuleManifest.storeRestricted] are not compiled in. A constant, so the compiler drops them.
const storeBuild = bool.fromEnvironment('POUNCE_STORE_BUILD');

/// All modules of this installation: the source modules compiled into this build and the
/// designs installed from a catalog. Remembers which ones the user switched off.
class ModuleRegistry extends ChangeNotifier implements TrackSource {
  ModuleRegistry(this._store, {List<SourceModule> sources = const [], http.Client? client})
    : _http = client ?? http.Client(),
      bundled = List.unmodifiable(sources) {
    assert(!storeBuild || !sources.any((m) => m.manifest.storeRestricted), 'store build bundles a restricted module');
    final ids = <String>{};
    for (final m in sources) {
      if (!ids.add(m.id)) throw ArgumentError('duplicate module id ${m.id}');
      if (isEnabled(m.id)) m.activate();
    }
    for (final raw in _store.get<List>('modules.themes') ?? const []) {
      try {
        themes.add(ThemeModule.fromJson((raw as Map).cast<String, dynamic>()));
      } catch (_) {
        /* drop entries a newer version wrote in a format we don't know */
      }
    }
  }

  final Store _store;
  final http.Client _http;

  /// Source modules compiled into this build, switched on or off.
  final List<SourceModule> bundled;

  /// Installed designs.
  final List<ThemeModule> themes = [];

  /// The module catalog (only fetched when the user opens it).
  late final catalog = ModuleCatalog(_http);

  // ---------- Sources ----------

  bool isEnabled(String id) => _store.get<bool>('module.$id.off') != true;

  void setEnabled(String id, bool on) {
    final m = bundled.where((m) => m.id == id).firstOrNull;
    if (m == null || isEnabled(id) == on) return;
    _store.set('module.$id.off', on ? null : true);
    on ? m.activate() : m.deactivate();
    notifyListeners();
  }

  /// Active source modules.
  Iterable<SourceModule> get sources => bundled.where((m) => isEnabled(m.id));

  /// The active module of type [T], e.g. `find<SoundCloudModule>()` for its own pages.
  T? find<T extends SourceModule>() => sources.whereType<T>().firstOrNull;

  SourceModule? sourceOf(Track t) => sources.where((m) => m.id == t.source).firstOrNull;

  set language(String code) {
    for (final m in bundled) {
      m.language = code;
    }
  }

  // ---------- Designs ----------

  ThemeModule? get activeTheme {
    final id = _store.get<String>('modules.theme');
    return id == null ? null : themes.where((t) => t.id == id).firstOrNull;
  }

  /// null = back to the accent chosen in the settings.
  void useTheme(String? id) {
    _store.set('modules.theme', id);
    notifyListeners();
  }

  void installTheme(ThemeModule theme) {
    themes
      ..removeWhere((t) => t.id == theme.id)
      ..add(theme);
    _saveThemes();
  }

  void uninstallTheme(String id) {
    themes.removeWhere((t) => t.id == id);
    if (_store.get<String>('modules.theme') == id) _store.set('modules.theme', null);
    _saveThemes();
  }

  void _saveThemes() {
    _store.set('modules.themes', [for (final t in themes) t.toJson()]);
    notifyListeners();
  }

  // ---------- TrackSource: route to the track's module ----------

  SourceModule _owner(Track t) => sourceOf(t) ?? (throw ModuleUnavailable(t.source));

  @override
  Future<StreamInfo> stream(Track track, {bool fast = false}) async => _owner(track).stream(track, fast: fast);

  @override
  void prefetchStream(Track track, {bool fast = false}) => sourceOf(track)?.prefetchStream(track, fast: fast);

  @override
  Future<List<Track>> related(Track seed, {int limit = 20}) async =>
      await sourceOf(seed)?.related(seed, limit: limit) ?? const [];

  @override
  Future<List<Track>> search(String query, {int limit = 30}) async {
    final all = await Future.wait([
      for (final m in sources.where((m) => m.supportsDj))
        m.search(query, limit: limit).catchError((Object _) => <Track>[]),
    ]);
    return [for (final list in all) ...list];
  }

  @override
  Future<String?> analysisUrl(Track track) async => await sourceOf(track)?.analysisUrl(track);

  @override
  Future<List<double>> waveform(Track track) async => await sourceOf(track)?.waveform(track) ?? const [];

  /// Loads bytes [start]..[end] (inclusive). Servers without range support send everything – cut it out.
  @override
  Future<Uint8List> range(String url, int start, int end) async {
    final res = await _http.get(Uri.parse(url), headers: {'Range': 'bytes=$start-$end'});
    if (res.statusCode != 206 && res.statusCode != 200) throw http.ClientException('range ${res.statusCode}');
    final b = res.bodyBytes;
    if (res.statusCode == 200 && b.length > end - start + 1) {
      return Uint8List.sublistView(b, start.clamp(0, b.length), (end + 1).clamp(0, b.length));
    }
    return b;
  }

  @override
  void dispose() {
    for (final m in bundled) {
      m.dispose();
    }
    super.dispose();
  }
}

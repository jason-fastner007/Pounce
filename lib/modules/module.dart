/// What a module adds to Pounce.
enum ModuleKind {
  /// A music source (search, streams, related tracks), written in Dart and compiled into the app.
  source,

  /// A design: pure data (colours), installable at runtime from a module catalog.
  theme,
}

/// Description of a module – the same fields in code and in a catalog's `index.json`.
class ModuleManifest {
  const ModuleManifest({
    required this.id,
    required this.name,
    required this.kind,
    required this.version,
    required this.author,
    this.description = '',
    this.homepage,
    this.storeRestricted = false,
  });

  /// Unique, lower-case, e.g. `soundcloud` or `theme.sunset`. Source modules store it in `Track.source`.
  final String id;
  final String name;
  final ModuleKind kind;
  final String version;
  final String author;
  final String description;
  final String? homepage;

  /// The module uses an API or content without the rights holder's permission for app distribution.
  /// Such modules are left out of app store builds (`--dart-define=POUNCE_STORE_BUILD=true`).
  final bool storeRestricted;

  static final _id = RegExp(r'^[a-z0-9][a-z0-9._-]{1,63}$');

  /// Throws [FormatException] for incomplete or invalid manifests (catalog data is untrusted).
  factory ModuleManifest.fromJson(Map<String, dynamic> j) {
    final id = j['id'];
    final kind = ModuleKind.values.asNameMap()[j['kind']];
    if (id is! String || !_id.hasMatch(id)) throw FormatException('invalid module id', id);
    if (kind == null) throw FormatException('unknown module kind', j['kind']);
    String text(String key, {int max = 80}) {
      final v = j[key];
      if (v is! String || v.trim().isEmpty) throw FormatException('missing $key', id);
      return v.trim().length > max ? v.trim().substring(0, max) : v.trim();
    }

    final homepage = j['homepage'];
    return ModuleManifest(
      id: id,
      name: text('name', max: 40),
      kind: kind,
      version: text('version', max: 20),
      author: text('author', max: 40),
      description: j['description'] is String ? text('description', max: 240) : '',
      homepage: homepage is String && Uri.tryParse(homepage)?.scheme == 'https' ? homepage : null,
      storeRestricted: j['storeRestricted'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'version': version,
    'author': author,
    if (description.isNotEmpty) 'description': description,
    'homepage': ?homepage,
    if (storeRestricted) 'storeRestricted': true,
  };
}

/// Base of every module. Lifecycle: created once at startup, [activate]/[deactivate] follow the
/// user's switch in the module manager, [dispose] when the app shuts down.
abstract class PounceModule {
  ModuleManifest get manifest;

  String get id => manifest.id;

  void activate() {}

  void deactivate() {}

  void dispose() {}
}

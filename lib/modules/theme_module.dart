import 'dart:ui' show Color;

import 'module.dart';

/// A design module: data only, so it can be installed from a catalog on every platform
/// (app stores forbid downloading code, not colours).
class ThemeModule extends PounceModule {
  ThemeModule(this.manifest, {required this.accent});

  @override
  final ModuleManifest manifest;

  /// The studio design's single accent colour.
  final Color accent;

  static final _hex = RegExp(r'^#([0-9a-fA-F]{6})$');

  /// Catalog entry: manifest fields plus `"theme": {"accent": "#RRGGBB"}`. Throws [FormatException].
  factory ThemeModule.fromJson(Map<String, dynamic> j) {
    final manifest = ModuleManifest.fromJson(j);
    if (manifest.kind != ModuleKind.theme) throw FormatException('not a theme', manifest.id);
    final theme = j['theme'];
    final m = theme is Map ? _hex.firstMatch('${theme['accent']}') : null;
    if (m == null) throw FormatException('theme.accent must be #RRGGBB', manifest.id);
    return ThemeModule(manifest, accent: Color(0xFF000000 | int.parse(m.group(1)!, radix: 16)));
  }

  Map<String, dynamic> toJson() => {
    ...manifest.toJson(),
    'theme': {'accent': '#${(accent.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}'},
  };
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'registry.dart';
import 'updater/updater.dart' show githubRepo;

/// One entry of a module catalog. Designs carry their data and install directly;
/// source modules are code and can only be listed (they ship inside an app build).
class CatalogEntry {
  const CatalogEntry(this.manifest, {this.theme});
  final ModuleManifest manifest;
  final ThemeModule? theme;
}

/// A module catalog: one JSON file (`modules/index.json` in the repository by default).
///
/// Only fetched when the user opens it – a single anonymous GET, nothing is sent along.
class ModuleCatalog {
  ModuleCatalog(this._http, {Uri? url}) : url = url ?? defaultUrl;

  static final defaultUrl = Uri.parse('https://raw.githubusercontent.com/$githubRepo/main/modules/index.json');

  static const _maxBytes = 512 * 1024;

  final http.Client _http;
  final Uri url;

  /// Invalid entries are skipped (catalog data is untrusted); restricted modules are hidden in
  /// app store builds.
  Future<List<CatalogEntry>> load() async {
    final res = await _http.get(url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw http.ClientException('catalog ${res.statusCode}', url);
    if (res.bodyBytes.length > _maxBytes) throw http.ClientException('catalog too large', url);
    return parse(utf8.decode(res.bodyBytes));
  }

  static List<CatalogEntry> parse(String json) {
    final root = jsonDecode(json);
    final list = root is Map ? root['modules'] : null;
    if (list is! List) throw const FormatException('catalog: "modules" list missing');
    final out = <CatalogEntry>[];
    final seen = <String>{};
    for (final raw in list) {
      if (raw is! Map) continue;
      try {
        final j = raw.cast<String, dynamic>();
        final m = ModuleManifest.fromJson(j);
        if (!seen.add(m.id) || (storeBuild && m.storeRestricted)) continue;
        out.add(CatalogEntry(m, theme: m.kind == ModuleKind.theme ? ThemeModule.fromJson(j) : null));
      } on FormatException {
        continue;
      }
    }
    return out;
  }
}

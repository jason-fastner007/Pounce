import 'db_io.dart' if (dart.library.js_interop) 'db_web.dart' as backend;

/// Tables of the local database.
///
/// `kv` holds the app state and is loaded completely at startup (see [Store]).
/// All others are row caches (one row per track or station) and are only read
/// on demand – a new entry writes only its own row.
enum Table { kv, beat, lyrics, ai, radio, sync }

/// Persistence: SQLite on Android/iOS/desktop, IndexedDB in the browser.
///
/// Values are strings (usually JSON). Writes are batches that land atomically
/// in one transaction.
abstract class Db {
  static Future<Db> open() => backend.open();

  /// All rows of a table (meant for small tables only).
  Future<Map<String, String>> all(Table t);

  Future<String?> get(Table t, String key);

  /// Writes [rows] in one transaction; `null` deletes the row.
  Future<void> write(Table t, Map<String, String?> rows);

  /// Keeps a cache table small: deletes the oldest rows beyond [max].
  Future<void> trim(Table t, int max);

  /// Contents of the old JSON store (before the database), if present.
  Future<String?> legacy();

  /// Remove the old JSON store after the import.
  Future<void> dropLegacy();
}

/// Tests only: in-memory database.
class MemoryDb implements Db {
  final _tables = {for (final t in Table.values) t: <String, (String, int)>{}};
  var _clock = 0;

  @override
  Future<Map<String, String>> all(Table t) async => {for (final e in _tables[t]!.entries) e.key: e.value.$1};

  @override
  Future<String?> get(Table t, String key) async => _tables[t]![key]?.$1;

  @override
  Future<void> write(Table t, Map<String, String?> rows) async {
    final table = _tables[t]!;
    for (final e in rows.entries) {
      final v = e.value;
      if (v == null) {
        table.remove(e.key);
      } else {
        table[e.key] = (v, _clock++);
      }
    }
  }

  @override
  Future<void> trim(Table t, int max) async {
    final table = _tables[t]!;
    if (table.length <= max) return;
    final oldest = table.entries.toList()..sort((a, b) => a.value.$2.compareTo(b.value.$2));
    for (final e in oldest.take(table.length - max)) {
      table.remove(e.key);
    }
  }

  @override
  Future<String?> legacy() async => null;

  @override
  Future<void> dropLegacy() async {}
}

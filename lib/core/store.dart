import 'dart:async';
import 'dart:convert';

import 'db.dart';

export 'db.dart' show Db, Table;

/// Key-value store for the app state (table `kv` of the [Db]).
///
/// Reads are synchronous from memory. Writes are batched and only the changed
/// keys go to the database – previously every change rewrote the entire state
/// as one big JSON file.
class Store {
  Store._(this.db, this._raw);

  /// For tests and tools: store without a file.
  factory Store.memory() => Store._(MemoryDb(), {});

  final Db db;

  /// Raw values (JSON) – decoded on first read.
  final Map<String, String> _raw;
  final _data = <String, Object?>{};
  final _dirty = <String>{};
  Timer? _flush;

  static Future<Store> open() async {
    final db = await Db.open();
    var rows = await db.all(Table.kv);
    if (rows.isEmpty) rows = await _migrate(db);
    return Store._(db, Map.of(rows));
  }

  /// One-time import from the old JSON store (a file or localStorage).
  static Future<Map<String, String>> _migrate(Db db) async {
    final legacy = await db.legacy();
    if (legacy == null || legacy.isEmpty) return {};
    Map<String, dynamic> data;
    try {
      data = jsonDecode(legacy) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
    final kv = <String, String>{
      for (final e in data.entries)
        // Old DJ analyses come from the waveform estimate -> don't take them over.
        if (!e.key.startsWith('beat_v')) e.key: jsonEncode(e.value),
    };
    await db.write(Table.kv, kv);
    await db.dropLegacy();
    return kv;
  }

  T? get<T>(String key) {
    final Object? v;
    if (_data.containsKey(key)) {
      v = _data[key];
    } else {
      final raw = _raw[key];
      if (raw == null) return null;
      try {
        v = jsonDecode(raw);
      } catch (_) {
        return null;
      }
      _data[key] = v;
    }
    return v is T ? v : null;
  }

  void set(String key, Object? value) {
    if (value == null) {
      _raw.remove(key);
    }
    _data[key] = value;
    _dirty.add(key);
    // Batch writes.
    _flush?.cancel();
    _flush = Timer(const Duration(milliseconds: 400), save);
  }

  /// Writes only the changed keys.
  Future<void> save() async {
    _flush?.cancel();
    if (_dirty.isEmpty) return;
    final rows = <String, String?>{};
    for (final k in _dirty) {
      final v = _data[k];
      final json = v == null ? null : jsonEncode(v);
      rows[k] = json;
      if (json != null) _raw[k] = json;
    }
    _dirty.clear();
    await db.write(Table.kv, rows);
  }
}

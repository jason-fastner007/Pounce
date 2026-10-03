import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import 'db.dart';

Future<Db> open() async {
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  await _renameLegacyDb(dir.path);
  return SqliteDb(sql.sqlite3.open('${dir.path}/pounce.db'), dir.path);
}

/// Take over the database from the Kittyfork era (incl. WAL files) as long as no new one exists.
Future<void> _renameLegacyDb(String dir) async {
  if (await File('$dir/pounce.db').exists()) return;
  for (final suffix in const ['', '-wal', '-shm']) {
    final old = File('$dir/kittyfork.db$suffix');
    if (await old.exists()) await old.rename('$dir/pounce.db$suffix');
  }
}

/// SQLite with WAL: writing doesn't block reading, a commit costs no fsync.
class SqliteDb implements Db {
  SqliteDb(this._db, this._dir) {
    _db
      ..execute('PRAGMA journal_mode = WAL')
      ..execute('PRAGMA synchronous = NORMAL')
      ..execute('PRAGMA temp_store = MEMORY');
    for (final t in Table.values) {
      _db
        ..execute('CREATE TABLE IF NOT EXISTS ${t.name} (k TEXT PRIMARY KEY NOT NULL, v TEXT NOT NULL, at INTEGER NOT NULL) WITHOUT ROWID')
        ..execute('CREATE INDEX IF NOT EXISTS ${t.name}_at ON ${t.name}(at)');
    }
  }

  final sql.Database _db;
  final String? _dir;

  final _upserts = <Table, sql.PreparedStatement>{};
  final _deletes = <Table, sql.PreparedStatement>{};
  final _gets = <Table, sql.PreparedStatement>{};

  sql.PreparedStatement _upsert(Table t) => _upserts[t] ??= _db.prepare(
    'INSERT INTO ${t.name} (k, v, at) VALUES (?, ?, ?) ON CONFLICT(k) DO UPDATE SET v = excluded.v, at = excluded.at',
  );

  @override
  Future<Map<String, String>> all(Table t) async => {
    for (final r in _db.select('SELECT k, v FROM ${t.name}')) r['k'] as String: r['v'] as String,
  };

  @override
  Future<String?> get(Table t, String key) async {
    final rows = (_gets[t] ??= _db.prepare('SELECT v FROM ${t.name} WHERE k = ?')).select([key]);
    return rows.isEmpty ? null : rows.first['v'] as String;
  }

  @override
  Future<void> write(Table t, Map<String, String?> rows) async {
    if (rows.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final del = _deletes[t] ??= _db.prepare('DELETE FROM ${t.name} WHERE k = ?');
    final up = _upsert(t);
    _db.execute('BEGIN');
    try {
      for (final e in rows.entries) {
        final v = e.value;
        v == null ? del.execute([e.key]) : up.execute([e.key, v, now]);
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<void> trim(Table t, int max) async {
    _db.execute(
      'DELETE FROM ${t.name} WHERE k IN (SELECT k FROM ${t.name} ORDER BY at DESC LIMIT -1 OFFSET ?)',
      [max],
    );
  }

  File? get _legacyFile => _dir == null ? null : File('$_dir/kittyfork.json');

  @override
  Future<String?> legacy() async {
    final f = _legacyFile;
    return f != null && await f.exists() ? f.readAsString() : null;
  }

  @override
  Future<void> dropLegacy() async {
    final f = _legacyFile;
    // Rename instead of delete: stays around as a backup.
    if (f != null && await f.exists()) await f.rename('${f.path}.migrated');
  }
}

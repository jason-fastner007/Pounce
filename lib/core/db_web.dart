import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'db.dart';

const _name = 'pounce';
const _legacyKey = 'kittyfork';

Future<Db> open() async {
  final req = web.window.indexedDB.open(_name, 1);
  req.onupgradeneeded = ((web.Event _) {
    final db = req.result as web.IDBDatabase;
    for (final t in Table.values) {
      if (!db.objectStoreNames.contains(t.name)) {
        db.createObjectStore(t.name).createIndex('at', 'at'.toJS);
      }
    }
  }).toJS;
  final db = await _done(req) as web.IDBDatabase;
  return IdbDb(db);
}

/// Waits for an IndexedDB request.
Future<JSAny?> _done(web.IDBRequest r) {
  final c = Completer<JSAny?>();
  r
    ..onsuccess = ((web.Event _) => c.complete(r.result)).toJS
    ..onerror = ((web.Event _) => c.completeError(r.error?.message ?? 'IndexedDB')).toJS;
  return c.future;
}

@JS()
extension type _Row._(JSObject _) implements JSObject {
  external factory _Row({String v, int at});
  external String get v;
}

/// IndexedDB: asynchronous, without localStorage's 5 MB limit and without
/// blocking the main thread with large writes.
class IdbDb implements Db {
  IdbDb(this._db);
  final web.IDBDatabase _db;

  web.IDBObjectStore _store(Table t, String mode) =>
      _db.transaction(t.name.toJS, mode).objectStore(t.name);

  @override
  Future<Map<String, String>> all(Table t) async {
    final s = _store(t, 'readonly');
    final keysReq = s.getAllKeys(), valsReq = s.getAll();
    final keys = (await _done(keysReq) as JSArray<JSString>).toDart;
    final vals = (await _done(valsReq) as JSArray<_Row>).toDart;
    return {for (var i = 0; i < keys.length && i < vals.length; i++) keys[i].toDart: vals[i].v};
  }

  @override
  Future<String?> get(Table t, String key) async {
    final r = await _done(_store(t, 'readonly').get(key.toJS));
    return r == null || r.isUndefinedOrNull ? null : (r as _Row).v;
  }

  @override
  Future<void> write(Table t, Map<String, String?> rows) async {
    if (rows.isEmpty) return;
    final tx = _db.transaction(t.name.toJS, 'readwrite');
    final s = tx.objectStore(t.name);
    final at = DateTime.now().millisecondsSinceEpoch;
    for (final e in rows.entries) {
      final v = e.value;
      v == null ? s.delete(e.key.toJS) : s.put(_Row(v: v, at: at), e.key.toJS);
    }
    final c = Completer<void>();
    tx
      ..oncomplete = ((web.Event _) => c.complete()).toJS
      ..onerror = ((web.Event _) => c.completeError(tx.error?.message ?? 'IndexedDB')).toJS;
    return c.future;
  }

  @override
  Future<void> trim(Table t, int max) {
    // Everything in callbacks of the same transaction (after an await it would already be finished).
    final tx = _db.transaction(t.name.toJS, 'readwrite');
    final s = tx.objectStore(t.name);
    final countReq = s.count();
    countReq.onsuccess = ((web.Event _) {
      final count = (countReq.result as JSNumber).toDartInt;
      if (count <= max) return;
      // Index by write time: oldest keys first.
      final keysReq = s.index('at').getAllKeys(null, count - max);
      keysReq.onsuccess = ((web.Event _) {
        for (final k in (keysReq.result as JSArray).toDart) {
          s.delete(k);
        }
      }).toJS;
    }).toJS;
    final c = Completer<void>();
    tx
      ..oncomplete = ((web.Event _) => c.complete()).toJS
      ..onerror = ((web.Event _) => c.completeError(tx.error?.message ?? 'IndexedDB')).toJS;
    return c.future;
  }

  @override
  Future<String?> legacy() async => web.window.localStorage.getItem(_legacyKey);

  @override
  Future<void> dropLegacy() async => web.window.localStorage.removeItem(_legacyKey);
}

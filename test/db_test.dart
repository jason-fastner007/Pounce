import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pounce/core/db_io.dart';
import 'package:pounce/core/store.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kfdb');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => dir.path,
    );
  });
  tearDown(() => dir.delete(recursive: true));

  Db open() => SqliteDb(sql.sqlite3.open('${dir.path}/pounce.db'), dir.path);

  test('SQLite: write, read, delete, trim oldest rows', () async {
    final db = open();
    await db.write(Table.beat, {for (var i = 0; i < 10; i++) '$i': '{"v":$i}'});
    expect(await db.get(Table.beat, '3'), '{"v":3}');
    await db.write(Table.beat, {'3': null});
    expect(await db.get(Table.beat, '3'), isNull);
    await db.trim(Table.beat, 4);
    expect((await db.all(Table.beat)).length, 4);
    // Tables are separate.
    expect(await db.all(Table.kv), isEmpty);
  });

  test('Store imports the old JSON store and writes only changed keys', () async {
    File('${dir.path}/kittyfork.json')
        .writeAsStringSync(jsonEncode({'accent': 'cyan', 'lib.likes': [], 'beat_v3_1': '{"bpm":80}'}));
    final db = open();
    final rows = await db.all(Table.kv);
    expect(rows, isEmpty);
    // Migration as in Store.open (without path_provider).
    final legacy = jsonDecode((await db.legacy())!) as Map<String, dynamic>;
    await db.write(Table.kv, {
      for (final e in legacy.entries)
        if (!e.key.startsWith('beat_v')) e.key: jsonEncode(e.value),
    });
    await db.dropLegacy();
    expect(File('${dir.path}/kittyfork.json').existsSync(), isFalse);
    expect(File('${dir.path}/kittyfork.json.migrated').existsSync(), isTrue);
    expect(await db.get(Table.kv, 'accent'), '"cyan"');
    expect(await db.get(Table.kv, 'beat_v3_1'), isNull);
  });

  test('Store: reads from memory, null deletes', () async {
    final s = Store.memory()
      ..set('a', 1)
      ..set('b', {'x': true});
    await s.save();
    expect(s.get<int>('a'), 1);
    expect(s.get<Map>('b'), {'x': true});
    s.set('a', null);
    await s.save();
    expect(s.get<int>('a'), isNull);
    expect(await s.db.get(Table.kv, 'a'), isNull);
    expect(await s.db.get(Table.kv, 'b'), '{"x":true}');
  });

  test('Store: handles type mismatch and invalid raw JSON gracefully', () async {
    final db = open();
    await db.write(Table.kv, {
      'badJson': '{invalid_json}',
      'strVal': '"hello"',
      'numVal': '123',
    });
    final s = await Store.open();
    // Invalid JSON returns null
    expect(s.get<Map>('badJson'), isNull);
    // Type mismatch returns null
    expect(s.get<int>('strVal'), isNull);
    // Correct type returns value
    expect(s.get<String>('strVal'), 'hello');
    expect(s.get<int>('numVal'), 123);
  });

  test('Store: handles legacy migration corrupted json', () async {
    final db = open();
    await db.write(Table.kv, {});
    File('${dir.path}/kittyfork.json').writeAsStringSync('{corrupted json format');
    final s = await Store.open();
    expect(s.get<String>('anything'), isNull);
  });
}

import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/modules/registry.dart';

/// Minimal source module: plays `https://fake/<id>.mp3`.
class _FakeSource extends SourceModule {
  _FakeSource(String id) : manifest = ModuleManifest(id: id, name: id, kind: ModuleKind.source, version: '1', author: 't');

  @override
  final ModuleManifest manifest;
  int activations = 0, deactivations = 0;

  @override
  void activate() => activations++;

  @override
  void deactivate() => deactivations++;

  @override
  Future<List<Track>> search(String query, {int limit = 30}) async => [track('$query-1')];

  @override
  Future<StreamInfo> stream(Track track, {bool fast = false}) async => StreamInfo('https://fake/${track.ref}.mp3', hls: false);

  @override
  bool get supportsDj => true;

  Track track(String ref) => Track(
    id: Track.idFor(id, ref),
    title: ref,
    user: const ScUser(id: 0, username: 'artist'),
    durationMs: 1000,
    source: id,
    ref: ref,
  );
}

Map<String, dynamic> _theme(String id, String accent) => {
  'id': id,
  'kind': 'theme',
  'name': 'Theme $id',
  'version': '1.0.0',
  'author': 'tester',
  'theme': {'accent': accent},
};

void main() {
  group('ModuleManifest', () {
    test('parses and round-trips', () {
      final m = ModuleManifest.fromJson({
        'id': 'theme.x',
        'kind': 'theme',
        'name': 'X',
        'version': '1.2.0',
        'author': 'Me',
        'homepage': 'https://example.com',
      });
      expect(m.kind, ModuleKind.theme);
      expect(ModuleManifest.fromJson(m.toJson()).toJson(), m.toJson());
    });

    test('rejects invalid ids, kinds and missing fields', () {
      final base = {'id': 'ok', 'kind': 'theme', 'name': 'n', 'version': '1', 'author': 'a'};
      expect(() => ModuleManifest.fromJson({...base, 'id': '../evil'}), throwsFormatException);
      expect(() => ModuleManifest.fromJson({...base, 'kind': 'plugin'}), throwsFormatException);
      expect(() => ModuleManifest.fromJson({...base}..remove('name')), throwsFormatException);
    });

    test('only keeps https homepages', () {
      final m = ModuleManifest.fromJson({
        'id': 'ok',
        'kind': 'theme',
        'name': 'n',
        'version': '1',
        'author': 'a',
        'homepage': 'javascript:alert(1)',
      });
      expect(m.homepage, isNull);
    });
  });

  group('ThemeModule', () {
    test('parses the accent and serialises it back', () {
      final t = ThemeModule.fromJson(_theme('theme.a', '#ff5f6d'));
      expect(t.accent, const Color(0xFFFF5F6D));
      expect(ThemeModule.fromJson(t.toJson()).accent, t.accent);
    });

    test('rejects bad colours and non-theme manifests', () {
      expect(() => ThemeModule.fromJson(_theme('theme.a', 'red')), throwsFormatException);
      expect(() => ThemeModule.fromJson({..._theme('theme.a', '#000000'), 'kind': 'source'}), throwsFormatException);
    });
  });

  group('ModuleCatalog', () {
    test('skips invalid and duplicate entries', () {
      final entries = ModuleCatalog.parse('''
        {"modules": [
          {"id": "theme.a", "kind": "theme", "name": "A", "version": "1", "author": "x", "theme": {"accent": "#112233"}},
          {"id": "theme.a", "kind": "theme", "name": "A again", "version": "2", "author": "x", "theme": {"accent": "#112233"}},
          {"id": "theme.bad", "kind": "theme", "name": "Bad", "version": "1", "author": "x", "theme": {"accent": "nope"}},
          {"id": "src", "kind": "source", "name": "Src", "version": "1", "author": "x"},
          "garbage"
        ]}''');
      expect(entries.map((e) => e.manifest.id), ['theme.a', 'src']);
      expect(entries.first.theme?.accent, const Color(0xFF112233));
      expect(entries.last.theme, isNull);
    });

    test('the catalog in the repository is valid', () {
      final json = File('modules/index.json').readAsStringSync();
      final entries = ModuleCatalog.parse(json);
      expect(entries, isNotEmpty);
      expect(entries.length, (RegExp(r'"id"').allMatches(json).length), reason: 'every entry must parse');
    });
  });

  group('ModuleRegistry', () {
    late Store store;
    late _FakeSource a, b;
    late ModuleRegistry registry;

    setUp(() {
      store = Store.memory();
      a = _FakeSource('alpha');
      b = _FakeSource('beta');
      registry = ModuleRegistry(store, sources: [a, b]);
    });

    test('routes streams to the module the track belongs to', () async {
      expect((await registry.stream(b.track('x'))).url, 'https://fake/x.mp3');
      expect(registry.sourceOf(a.track('y')), same(a));
    });

    test('tracks of unknown or disabled modules are unavailable', () async {
      final other = _FakeSource('gamma').track('z');
      await expectLater(registry.stream(other), throwsA(isA<ModuleUnavailable>()));

      registry.setEnabled('alpha', false);
      expect(a.deactivations, 1);
      expect(registry.sources, [b]);
      await expectLater(registry.stream(a.track('y')), throwsA(isA<ModuleUnavailable>()));
      expect(await registry.related(a.track('y')), isEmpty);
    });

    test('the on/off switch survives a restart', () {
      registry.setEnabled('beta', false);
      final again = ModuleRegistry(store, sources: [_FakeSource('alpha'), _FakeSource('beta')]);
      expect(again.sources.map((m) => m.id), ['alpha']);
    });

    test('activates enabled modules at startup', () {
      expect(a.activations, 1);
      expect(b.activations, 1);
    });

    test('DJ search merges all DJ-capable sources', () async {
      final r = await registry.search('q');
      expect(r.map((t) => t.source), ['alpha', 'beta']);
    });

    test('rejects duplicate module ids', () {
      expect(() => ModuleRegistry(store, sources: [_FakeSource('x'), _FakeSource('x')]), throwsArgumentError);
    });

    test('installs, activates and removes designs', () {
      final t = ThemeModule.fromJson(_theme('theme.a', '#123456'));
      registry
        ..installTheme(t)
        ..useTheme('theme.a');
      expect(registry.activeTheme?.accent, const Color(0xFF123456));

      final again = ModuleRegistry(store);
      expect(again.themes.single.id, 'theme.a');
      expect(again.activeTheme?.id, 'theme.a');

      again.uninstallTheme('theme.a');
      expect(again.themes, isEmpty);
      expect(again.activeTheme, isNull);
    });
  });

  group('Track sources', () {
    test('old stored tracks belong to SoundCloud, stations to radio', () {
      expect(Track.fromJson({'id': 1, 'title': 't'}).source, Track.soundcloud);
      expect(Track.fromJson({'id': -5, 'title': 'r', 'kf_live_url': 'http://x'}).source, Track.radio);
    });

    test('module tracks keep source and ref through storage', () {
      final t = _FakeSource('alpha').track('abc');
      final back = Track.fromJson(t.toJson());
      expect(back.source, 'alpha');
      expect(back.ref, 'abc');
      expect(back, t);
    });

    test('same id from different sources is a different track', () {
      const user = ScUser(id: 0, username: '');
      expect(
        const Track(id: 1, title: 'a', user: user, durationMs: 0),
        isNot(const Track(id: 1, title: 'a', user: user, durationMs: 0, source: 'other')),
      );
    });

    test('idFor is stable and stays out of SoundCloud\'s and radio\'s ranges', () {
      final id = Track.idFor('alpha', 'abc');
      expect(id, Track.idFor('alpha', 'abc'));
      expect(id, isNot(Track.idFor('beta', 'abc')));
      expect(id, greaterThanOrEqualTo(10000000000000));
      expect(id, lessThan(1 << 53), reason: 'must fit a JavaScript number');
      // Pinned value: the same on every platform (it's stored and synced between devices).
      expect(id, 72798572931967);
    });
  });
}

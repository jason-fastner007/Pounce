import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pounce/core/app_info.dart';
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/player/audio_engine.dart';

void main() {
  group('Settings and AppInfo unit tests', () {
    late Store store;
    late Settings settings;

    setUp(() {
      store = Store.memory();
      settings = Settings(store);
    });

    test('appVersion and isBeta metadata', () {
      expect(appVersion, isNotEmpty);
      expect(isBeta, isA<bool>());
    });

    test('Settings defaults are correct', () {
      expect(settings.accent, Accent.cyan);
      expect(settings.loudMode, LoudMode.normal);
      expect(settings.volume, 1.0);
      expect(settings.beatLevel, BeatLevel.light);
      expect(settings.beatBackground, isTrue);
      expect(settings.railExpanded, isFalse);
      expect(settings.inspectorOpen, isTrue);
      expect(settings.locale, isNull);
      expect(settings.quality, StreamQuality.high);
      expect(settings.autoplay, isTrue);
      expect(settings.autoCheckUpdates, isFalse);
      expect(settings.radioEnabled, isTrue);
      expect(settings.fastStart, isTrue);
      expect(settings.skipPreviews, isFalse);
      expect(settings.setupDone, isFalse);
      expect(settings.recognitionOptIn, isFalse);
    });

    test('Settings setters persist changes to Store and notify listeners', () {
      var notified = false;
      settings.addListener(() => notified = true);

      settings.accent = Accent.amber;
      expect(settings.accent, Accent.amber);
      expect(store.get<String>('accent'), 'amber');
      expect(notified, isTrue);

      notified = false;
      settings.loudMode = LoudMode.quiet;
      expect(settings.loudMode, LoudMode.quiet);
      expect(store.get<String>('loud'), 'quiet');
      expect(notified, isTrue);

      notified = false;
      settings.beatLevel = BeatLevel.off;
      expect(settings.beatLevel, BeatLevel.off);
      expect(settings.beatBackground, isFalse);
      expect(notified, isTrue);

      notified = false;
      settings.locale = const Locale('de');
      expect(settings.locale?.languageCode, 'de');
      expect(store.get<String>('locale'), 'de');
      expect(notified, isTrue);

      settings.locale = null;
      expect(settings.locale, isNull);

      notified = false;
      settings.quality = StreamQuality.saver;
      expect(settings.quality, StreamQuality.saver);
      expect(store.get<String>('quality'), 'saver');
      expect(notified, isTrue);

      notified = false;
      settings.proxy = '  http://proxy.local  ';
      expect(settings.proxy, 'http://proxy.local');
      expect(store.get<String>('proxy'), 'http://proxy.local');
      expect(notified, isTrue);
    });

    test('Settings volume persists value to Store', () {
      settings.volume = 0.5;
      expect(settings.volume, 0.5);
      expect(store.get<num>('volume'), 0.5);
    });

    test('Settings boolean toggle setters persist correctly', () {
      settings.autoplay = false;
      expect(settings.autoplay, isFalse);
      expect(store.get<bool>('autoplay'), isFalse);

      settings.autoCheckUpdates = true;
      expect(settings.autoCheckUpdates, isTrue);
      expect(store.get<bool>('autoCheckUpdates'), isTrue);

      settings.setupDone = true;
      expect(settings.setupDone, isTrue);
      expect(store.get<bool>('setupDone'), isTrue);
    });

    test('BeatLevel intensity values', () {
      expect(BeatLevel.off.intensity, 0.0);
      expect(BeatLevel.light.intensity, 0.35);
      expect(BeatLevel.medium.intensity, 0.65);
      expect(BeatLevel.strong.intensity, 1.0);
    });
  });
}

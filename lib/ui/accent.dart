import 'package:material_ui/material_ui.dart';

import '../core/settings.dart';
import '../player/player_controller.dart';

/// Provides the single accent colour: fixed (amber/cyan) or taken from the cover.
class AccentController extends ChangeNotifier {
  AccentController(this._settings, this._player) {
    _settings.addListener(_update);
    _player.addListener(_update);
    _update();
  }

  final Settings _settings;
  final PlayerController _player;
  final _cache = <String, Color>{};
  String? _artUrl;
  Color color = Accent.amber.color;

  Future<void> _update() async {
    if (_settings.accent != Accent.cover) {
      _set(_settings.accent.color);
      return;
    }
    final url = _player.current?.art('t67x67');
    if (url == null || url == _artUrl) return;
    _artUrl = url;
    try {
      final c = _cache[url] ??= _vivid(
        (await ColorScheme.fromImageProvider(
          provider: NetworkImage(url),
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
        )).primary,
      );
      if (_artUrl == url) _set(c);
    } catch (_) {}
  }

  /// Enough saturation and brightness for contrast on OLED black.
  static Color _vivid(Color c) {
    final h = HSLColor.fromColor(c);
    return h.withSaturation(h.saturation.clamp(.55, 1)).withLightness(h.lightness.clamp(.55, .68)).toColor();
  }

  void _set(Color c) {
    if (c == color) return;
    color = c;
    notifyListeners();
  }

  @override
  void dispose() {
    _settings.removeListener(_update);
    _player.removeListener(_update);
    super.dispose();
  }
}

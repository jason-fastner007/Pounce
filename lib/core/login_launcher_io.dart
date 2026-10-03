import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'login_launcher.dart';

LoginLauncher createLauncher() => Platform.isLinux || Platform.isWindows ? _DesktopLauncher() : _ChannelLauncher();

/// Android (Custom Tabs + intent) and iOS/macOS (ASWebAuthenticationSession).
class _ChannelLauncher implements LoginLauncher {
  static const _ch = MethodChannel('kittyfork/auth');
  static const _links = EventChannel('kittyfork/auth/links');

  @override
  late final Stream<String> callbacks = _links.receiveBroadcastStream().cast<String>();

  @override
  bool get automatic => true;

  @override
  Future<void> open(Uri url) async {
    try {
      await _ch.invokeMethod<String>('authenticate', {'url': url.toString(), 'scheme': 'sc'});
    } on PlatformException catch (e) {
      if (e.code != 'cancelled') rethrow;
    }
  }
}

/// Linux/Windows: register an sc:// handler with the system. It writes the
/// redirect to a file that we pick up here.
class _DesktopLauncher implements LoginLauncher {
  final _ctrl = StreamController<String>.broadcast();
  Timer? _poll;

  @override
  Stream<String> get callbacks => _ctrl.stream;

  @override
  bool get automatic => true;

  @override
  Future<void> open(Uri url) async {
    final dir = await getApplicationSupportDirectory();
    final inbox = File('${dir.path}${Platform.pathSeparator}auth_callback');
    if (await inbox.exists()) await inbox.delete();
    try {
      await (Platform.isLinux ? _registerLinux(dir.path, inbox.path) : _registerWindows(inbox.path));
    } catch (_) {
      // Without a handler, pasting by hand remains.
    }

    await (Platform.isLinux
        ? Process.run('xdg-open', [url.toString()])
        : Process.run('rundll32', ['url.dll,FileProtocolHandler', url.toString()]));

    // Wait 10 minutes for the redirect.
    _poll?.cancel();
    final until = DateTime.now().add(const Duration(minutes: 10));
    _poll = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (DateTime.now().isAfter(until)) return t.cancel();
      if (!await inbox.exists()) return;
      final link = (await inbox.readAsString()).trim();
      await inbox.delete();
      if (link.isEmpty) return;
      t.cancel();
      _ctrl.add(link);
    });
  }

  Future<void> _registerLinux(String dir, String inbox) async {
    final script = File('$dir/sc-handler.sh');
    await script.writeAsString('#!/bin/sh\nprintf \'%s\' "\$1" > "$inbox"\n');
    await Process.run('chmod', ['+x', script.path]);
    final apps = Directory('${Platform.environment['HOME']}/.local/share/applications');
    await apps.create(recursive: true);
    // Remove the entry from the Kittyfork era, otherwise two sc:// handlers linger around.
    final old = File('${apps.path}/kittyfork-auth.desktop');
    if (await old.exists()) await old.delete();
    await File('${apps.path}/pounce-auth.desktop').writeAsString(
      '[Desktop Entry]\nType=Application\nName=Pounce Login\nNoDisplay=true\n'
      'Exec="${script.path}" %u\nMimeType=x-scheme-handler/sc;\n',
    );
    await Process.run('xdg-mime', ['default', 'pounce-auth.desktop', 'x-scheme-handler/sc']);
  }

  Future<void> _registerWindows(String inbox) async {
    const key = r'HKCU\Software\Classes\sc';
    final cmd =
        'powershell.exe -NoProfile -WindowStyle Hidden -Command '
        '"Set-Content -NoNewline -LiteralPath \'$inbox\' -Value \'%1\'"';
    for (final args in [
      ['add', key, '/ve', '/d', 'URL:sc', '/f'],
      ['add', key, '/v', 'URL Protocol', '/d', '', '/f'],
      ['add', '$key\\shell\\open\\command', '/ve', '/d', cmd, '/f'],
    ]) {
      await Process.run('reg', args);
    }
  }
}

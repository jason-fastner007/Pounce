import 'package:web/web.dart' as web;

import 'login_launcher.dart';

LoginLauncher createLauncher() => _WebLauncher();

/// Browsers can't intercept sc:// -> the link is pasted.
class _WebLauncher implements LoginLauncher {
  @override
  Stream<String> get callbacks => const Stream.empty();
  @override
  bool get automatic => false;
  @override
  Future<void> open(Uri url) async => web.window.open(url.toString(), '_blank');
}

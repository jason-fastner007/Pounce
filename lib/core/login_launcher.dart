import 'login_launcher_io.dart' if (dart.library.js_interop) 'login_launcher_web.dart' as impl;

/// Opens the login page with the system's means and returns the
/// redirect (sc://auth?code=…) as soon as the system intercepts it.
abstract class LoginLauncher {
  static LoginLauncher create() => impl.createLauncher();

  Stream<String> get callbacks;

  /// false = the redirect has to be pasted by hand (web).
  bool get automatic;

  Future<void> open(Uri url);
}

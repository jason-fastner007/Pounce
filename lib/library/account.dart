import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/login_launcher.dart';
import '../sc/auth.dart';
import '../sc/models.dart';
import '../sc/soundcloud.dart';
import 'library.dart';

enum LoginState { idle, waiting, busy, error }

/// SoundCloud account: login flow, profile, like sync, the account's playlists.
class Account extends ChangeNotifier {
  Account(this.auth, this._sc, this._library, this._launcher) {
    _sc.auth = auth;
    _library.onLikeChanged = _pushLike;
    _launcher.callbacks.listen(complete);
    auth.addListener(notifyListeners);
    if (auth.loggedIn) unawaited(refresh());
  }

  final ScAuth auth;
  final SoundCloud _sc;
  final Library _library;
  final LoginLauncher _launcher;

  LoginState state = LoginState.idle;
  String? error;
  List<ScPlaylist> playlists = [];

  /// Local likes that don't exist in the account yet (offer to transfer them).
  List<Track> localOnly = [];

  bool get loggedIn => auth.loggedIn;
  ScUser? get me => auth.me;
  bool get automaticCallback => _launcher.automatic;

  Future<void> login({required String language, bool signup = false}) async {
    _set(LoginState.waiting);
    try {
      // Browser: web client (the redirect is copied from the address bar).
      final web = _launcher.automatic ? null : await _sc.clientId();
      await _launcher.open(auth.beginLogin(language: language, signup: signup, webClientId: web));
    } catch (e) {
      _fail('$e');
    }
  }

  /// Redirect from the system or pasted by hand.
  Future<void> complete(String callback) async {
    _set(LoginState.busy);
    try {
      await auth.complete(callback);
      await refresh();
      _set(LoginState.idle);
    } catch (e) {
      _fail(e is AuthException ? e.code : '$e');
    }
  }

  void cancel() => _set(LoginState.idle);

  /// Fetch profile + likes + playlists from the account.
  Future<void> refresh() async {
    try {
      final user = await _sc.me();
      auth.setMe(user);
      final r = await (_sc.myLikes(user.id), _sc.myPlaylists(user.id)).wait;
      final remote = r.$1;
      localOnly = _library.likes.where((t) => !remote.contains(t)).toList();
      _library.replaceLikes([...remote, ...localOnly]);
      playlists = r.$2;
      notifyListeners();
    } catch (e) {
      debugPrint('Konto-Sync fehlgeschlagen: $e');
    }
  }

  /// Transfer local-only likes to the account.
  Future<void> pushLocalLikes() async {
    final list = localOnly;
    localOnly = [];
    notifyListeners();
    for (final t in list) {
      await _pushLike(t, true);
    }
  }

  void dismissLocalLikes() {
    localOnly = [];
    notifyListeners();
  }

  Future<void> _pushLike(Track t, bool liked) async {
    if (!loggedIn) return;
    try {
      await _sc.setLiked(t, liked);
    } catch (e) {
      debugPrint('Like-Sync fehlgeschlagen: $e');
    }
  }

  void logout() {
    auth.logout();
    playlists = [];
    localOnly = [];
    notifyListeners();
  }

  void _set(LoginState s) {
    state = s;
    if (s != LoginState.error) error = null;
    notifyListeners();
  }

  void _fail(String e) {
    error = e;
    _set(LoginState.error);
  }

  @override
  void dispose() {
    auth.removeListener(notifyListeners);
    super.dispose();
  }
}

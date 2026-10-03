import 'dart:io';

/// Active Radio Browser servers via the official DNS lookup: `all.api.radio-browser.info`
/// returns the addresses of all mirrors, the reverse lookup their names (e.g. de1.api…).
Future<List<String>> discoverMirrors() async {
  final addrs = await InternetAddress.lookup('all.api.radio-browser.info').timeout(const Duration(seconds: 3));
  final names = <String>{};
  await Future.wait([
    for (final a in addrs)
      a
          .reverse()
          .timeout(const Duration(seconds: 2))
          .then((r) {
            if (r.host.endsWith('.api.radio-browser.info')) names.add(r.host);
          })
          .catchError((Object _) {}),
  ]);
  return names.toList()..shuffle();
}

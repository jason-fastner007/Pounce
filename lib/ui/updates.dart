import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/deps.dart';
import '../modules/updater/updater.dart';
import '../modules/updater/widgets/update_sheet.dart';
import 'widgets/common.dart';

/// Glue between app and updater module: check, show the dialog, daily auto-check (only if allowed).
abstract final class Updates {
  static const _lastKey = 'updates.lastCheck';

  /// [silent]: no message when there's nothing new (auto-check).
  static Future<void> check(BuildContext context, {bool silent = false}) async {
    final d = context.deps;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    void say(String s) {
      if (!silent) messenger.showSnackBar(SnackBar(content: Text(s)));
    }

    final provider = await d.updates;
    final app = await installedApp();
    if (provider == null || app == null) return say(l.updatesUnavailable);
    d.store.set(_lastKey, DateTime.now().millisecondsSinceEpoch);
    final info = await provider.checkForUpdate(currentVersion: app.version);
    if (!context.mounted) return;
    if (info == null) return say(l.updatesNone);
    await showUpdateSheet(
      context,
      info: info,
      provider: provider,
      openPage: (u) => launchUrl(u, mode: LaunchMode.externalApplication),
      texts: UpdateTexts(
        title: l.updateTitle,
        download: l.updateDownload,
        viaPlay: l.updateViaPlay,
        later: l.updateLater,
        releasePage: l.updateReleasePage,
        checksumFailed: l.updateChecksumFailed,
        needsPermission: l.updateNeedsPermission,
        failed: l.updateFailed,
      ),
    );
  }

  /// On startup: at most once a day, and only if the user turned it on.
  static Future<void> autoCheck(BuildContext context) async {
    final d = context.deps;
    if (!d.settings.autoCheckUpdates) return;
    final last = d.store.get<int>(_lastKey) ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - last < const Duration(hours: 24).inMilliseconds) return;
    await check(context, silent: true);
  }
}

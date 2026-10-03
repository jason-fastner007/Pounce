import 'package:material_ui/material_ui.dart';

import '../models/update_info.dart';
import '../release_provider.dart';

/// Texts of the update dialog (passed in translated by the app – the module knows no app strings).
class UpdateTexts {
  const UpdateTexts({
    required this.title,
    required this.download,
    required this.viaPlay,
    required this.later,
    required this.releasePage,
    required this.checksumFailed,
    required this.needsPermission,
    required this.failed,
  });

  final String Function(String version) title;
  final String Function(String mb) download;
  final String viaPlay, later, releasePage, checksumFailed, needsPermission, failed;
}

/// Shows an update (Material 3 bottom sheet). Nothing is downloaded until the button is
/// tapped – never in the background. [openPage] opens the release page (e.g. via url_launcher).
Future<void> showUpdateSheet(
  BuildContext context, {
  required UpdateInfo info,
  required ReleaseProvider provider,
  required UpdateTexts texts,
  void Function(Uri page)? openPage,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
  builder: (_) => _UpdateSheet(info: info, provider: provider, texts: texts, openPage: openPage),
);

class _UpdateSheet extends StatefulWidget {
  const _UpdateSheet({required this.info, required this.provider, required this.texts, this.openPage});

  final UpdateInfo info;
  final ReleaseProvider provider;
  final UpdateTexts texts;
  final void Function(Uri page)? openPage;

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> {
  double? _progress;
  String? _message;

  Future<void> _install() async {
    setState(() {
      _progress = 0;
      _message = null;
    });
    InstallResult r;
    try {
      r = await widget.provider.install(widget.info, onProgress: (p) => mounted ? setState(() => _progress = p) : null);
    } catch (_) {
      r = InstallResult.failed;
    }
    if (!mounted) return;
    final t = widget.texts;
    setState(() {
      _progress = null;
      _message = switch (r) {
        InstallResult.started => null,
        InstallResult.checksumMismatch => t.checksumFailed,
        InstallResult.needsPermission => t.needsPermission,
        InstallResult.failed => t.failed,
      };
    });
    if (r == InstallResult.started) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final t = widget.texts;
    final theme = Theme.of(context);
    final play = info.channel == UpdateChannel.play;
    final busy = _progress != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.title(info.version), style: theme.textTheme.headlineSmall),
            if (info.changelog.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(child: SelectableText(info.changelog.trim(), style: theme.textTheme.bodyMedium)),
              ),
            ],
            const SizedBox(height: 16),
            if (busy) ...[
              LinearProgressIndicator(value: _progress == 0 ? null : _progress, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 12),
            ],
            if (_message != null) ...[
              Text(_message!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: busy || (!play && !info.downloadable) ? null : _install,
              child: Text(play ? t.viaPlay : t.download((info.assetSize / 1e6).toStringAsFixed(1))),
            ),
            Row(
              children: [
                if (info.pageUrl != null && widget.openPage != null)
                  TextButton(onPressed: () => widget.openPage!(Uri.parse(info.pageUrl!)), child: Text(t.releasePage)),
                const Spacer(),
                TextButton(onPressed: busy ? null : () => Navigator.of(context).maybePop(), child: Text(t.later)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

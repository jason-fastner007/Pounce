import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../core/platform.dart';
import '../../core/settings.dart';
import '../../engine/deckengine.dart';
import '../../sync/sync_service.dart';
import '../../l10n/gen/app_localizations.dart';
import '../theme.dart';
import '../updates.dart';
import '../../sc/models.dart';
import '../../player/audio_engine.dart';
import '../player/controls.dart';
import '../widgets/common.dart';
import '../widgets/studio.dart';
import 'login_sheet.dart';
import '../../core/app_info.dart';
import 'setup_page.dart' show BetaBadge;

/// Language names – always in the language itself.
const _languageNames = {
  'en': 'English',
  'de': 'Deutsch',
  'fr': 'Français',
  'ru': 'Русский',
  'hu': 'Magyar',
  'vi': 'Tiếng Việt',
  'ar': 'العربية',
  'es': 'Español',
};

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.deps.settings;
    final l = context.l10n;
    return Scaffold(
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: StudioHeader(title: l.navSettings)),
              SliverList.list(
                children: [
                  const _AccountGroup(),
                  _Group(
                    title: l.appearance,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(Studio.s4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.accentColor,
                              style: const TextStyle(
                                fontFamily: Studio.sans,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Studio.text2,
                              ),
                            ),
                            const SizedBox(height: Studio.s3),
                            Row(
                              children: [
                                for (final a in Accent.values)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 3),
                                      child: _AccentOption(
                                        accent: a,
                                        label: switch (a) {
                                          Accent.amber => 'Amber',
                                          Accent.cyan => 'Cyan',
                                          Accent.cover => 'Cover',
                                        },
                                        selected: s.accent == a,
                                        onTap: () => s.accent = a,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.graphic_eq_rounded),
                        title: Text(l.beatBg),
                        subtitle: Text(l.beatBgDesc),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(Studio.s4, 0, Studio.s4, Studio.s4),
                        child: Segments<BeatLevel>(
                          height: 36,
                          values: BeatLevel.values,
                          selected: s.beatLevel,
                          label: (v) => switch (v) {
                            BeatLevel.off => l.loudOff.toUpperCase(),
                            BeatLevel.light => l.beatLight.toUpperCase(),
                            BeatLevel.medium => l.beatMedium.toUpperCase(),
                            BeatLevel.strong => l.beatStrong.toUpperCase(),
                          },
                          onChanged: (v) => s.beatLevel = v,
                        ),
                      ),
                    ],
                  ),
                  _Group(
                    title: l.loudTitle,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(Studio.s4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.loudDesc, style: Studio.bodyDim),
                            const SizedBox(height: Studio.s4),
                            const LoudnessControl(expanded: true),
                            const SizedBox(height: Studio.s3),
                            Wrap(
                              spacing: Studio.s4,
                              children: [
                                for (final m in LoudMode.values.where((m) => m.lufs != null))
                                  Mono(
                                    '${LoudnessControl.name(context, m)} ${m.lufs!.toInt()} LUFS',
                                    color: Studio.text3,
                                  ),
                              ],
                            ),
                            if (!context.deps.player.supportsLoudness) ...[
                              const SizedBox(height: Studio.s2),
                              Text(l.loudUnsupported, style: Studio.bodyDim.copyWith(color: Studio.clip)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  _Group(
                    title: l.language,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.translate_rounded),
                        title: Text(l.language),
                        subtitle: Text(
                          s.locale == null || s.locale!.languageCode.isEmpty
                              ? l.languageSystem
                              : (_languageNames[s.locale!.languageCode] ?? s.locale!.languageCode),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showLanguagePicker(context, s),
                      ),
                    ],
                  ),
                  _Group(
                    title: l.playback,
                    children: [
                      if (!Platform.isWeb)
                        Padding(
                          padding: const EdgeInsets.all(Studio.s4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.high_quality_rounded, size: 20, color: Studio.text2),
                                  const SizedBox(width: Studio.s2),
                                  Text(l.quality, style: Studio.body.copyWith(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: Studio.s3),
                              Segments<StreamQuality>(
                                height: 36,
                                values: StreamQuality.values,
                                selected: s.quality,
                                label: (v) => switch (v) {
                                  StreamQuality.high => l.qualityHigh,
                                  StreamQuality.saver => l.qualitySaver,
                                },
                                onChanged: (v) => s.quality = v,
                              ),
                            ],
                          ),
                        ),
                      if (!Platform.isWeb)
                        SwitchListTile(
                          secondary: const Icon(Icons.bolt_rounded),
                          title: Text(l.fastStart),
                          subtitle: Text(l.fastStartDesc),
                          value: s.fastStart,
                          onChanged: (v) => s.fastStart = v,
                        ),
                      SwitchListTile(
                        secondary: const Icon(Icons.radio_rounded),
                        title: Text(l.radioSource),
                        subtitle: Text(l.radioSourceDesc),
                        value: s.radioEnabled,
                        onChanged: (v) => s.radioEnabled = v,
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.all_inclusive_rounded),
                        title: Text(l.autoplay),
                        subtitle: Text(l.autoplayDesc),
                        value: s.autoplay,
                        onChanged: (v) => s.autoplay = v,
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.skip_next_rounded),
                        title: Text(l.skipPreviews),
                        subtitle: Text(l.skipPreviewsDesc),
                        value: s.skipPreviews,
                        onChanged: (v) => s.skipPreviews = v,
                      ),
                    ],
                  ),
                  if (Platform.isAndroid)
                    _Group(
                      title: l.updates,
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.update_rounded),
                          title: Text(l.updatesAuto),
                          subtitle: Text(l.updatesAutoDesc),
                          value: s.autoCheckUpdates,
                          onChanged: (v) => s.autoCheckUpdates = v,
                        ),
                        ListTile(
                          leading: const Icon(Icons.system_update_rounded),
                          title: Text(l.updatesCheck),
                          onTap: () => Updates.check(context),
                        ),
                      ],
                    ),
                  if (Platform.isWeb)
                    _Group(
                      title: l.network,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.dns_rounded),
                          title: Text(l.proxy),
                          subtitle: Text(s.proxy.isEmpty ? l.proxyDesc : s.proxy),
                          onTap: () => _editProxy(context, s),
                        ),
                      ],
                    ),
                  const _SyncGroup(),
                  const _RustEngineGroup(),
                  _Group(
                    title: l.about,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded),
                        title: Row(
                          children: [
                            Text(l.appName),
                            if (isBeta) ...[const SizedBox(width: 8), const BetaBadge()],
                          ],
                        ),
                        subtitle: Text('${l.aboutText}\n${l.version(appVersion)}'),
                        isThreeLine: true,
                      ),
                      ListTile(
                        leading: const Icon(Icons.restart_alt_rounded),
                        title: Text(l.setupAgain),
                        onTap: () => s.setupDone = false,
                      ),
                      ListTile(
                        leading: const Icon(Icons.gavel_rounded),
                        title: Text(l.licenses),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: l.appName,
                          applicationVersion: appVersion,
                          applicationIcon: Image.asset('assets/brand/pounce_mark.png', width: 72),
                          applicationLegalese: 'GPL-3.0 · Pounce contributors · inspired by KittyTune (alan7383)',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, Settings s) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 12),
                child: Text(l.language, style: Theme.of(c).textTheme.titleLarge),
              ),
              ListTile(
                title: Text(l.languageSystem),
                trailing: (s.locale == null || s.locale!.languageCode.isEmpty)
                    ? Icon(Icons.check_rounded, color: Theme.of(c).colorScheme.primary)
                    : null,
                onTap: () {
                  s.locale = null;
                  Navigator.pop(c);
                },
              ),
              const Divider(height: 1),
              for (final loc in AppLocalizations.supportedLocales)
                ListTile(
                  title: Text(_languageNames[loc.languageCode] ?? loc.languageCode),
                  trailing: s.locale?.languageCode == loc.languageCode
                      ? Icon(Icons.check_rounded, color: Theme.of(c).colorScheme.primary)
                      : null,
                  onTap: () {
                    s.locale = loc;
                    Navigator.pop(c);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editProxy(BuildContext context, Settings s) async {
    final ctrl = TextEditingController(text: s.proxy);
    final v = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.l10n.proxy),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.l10n.proxyDesc),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(hintText: 'https://…/?url='),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(c.l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(c, ctrl.text),
            child: Text(MaterialLocalizations.of(c).okButtonLabel),
          ),
        ],
      ),
    );
    if (v != null) s.proxy = v;
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(Studio.s4, Studio.s3, Studio.s4, Studio.s2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, Studio.s3, 0, Studio.s2),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: Studio.sans,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Studio.text2,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: Studio.br16,
          child: DecoratedBox(
            decoration: Studio.panel(radius: Studio.br16),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: Studio.line),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Accent choice as a small button with a colour swatch.
class _AccentOption extends StatelessWidget {
  const _AccentOption({required this.accent, required this.label, required this.selected, required this.onTap});
  final Accent accent;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tactile(
    onTap: onTap,
    active: selected,
    radius: Studio.br10,
    padding: const EdgeInsets.symmetric(horizontal: Studio.s2, vertical: Studio.s3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.spring,
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: selected ? Studio.text : Studio.lineStrong, width: selected ? 2 : 1),
            gradient: accent == Accent.cover
                ? const SweepGradient(
                    colors: [
                      Color(0xFFFF7A00),
                      Color(0xFFFF2D95),
                      Color(0xFF00F0FF),
                      Color(0xFF7CFF4F),
                      Color(0xFFFF7A00),
                    ],
                  )
                : null,
            color: accent == Accent.cover ? null : accent.color,
          ),
        ),
        const SizedBox(width: Studio.s2),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: Studio.sans,
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

/// Account: sign in, or profile + sign out.
class _AccountGroup extends StatelessWidget {
  const _AccountGroup();

  @override
  Widget build(BuildContext context) {
    final account = context.deps.account;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: account,
      builder: (context, _) {
        final me = account.me;
        return _Group(
          title: l.account,
          children: [
            AnimatedSwitcher(
              duration: Motion.medium,
              child: !account.loggedIn
                  ? ListTile(
                      key: const ValueKey('out'),
                      leading: const Icon(Icons.cloud_outlined),
                      title: Text(l.login),
                      subtitle: Text(l.loginSubtitle),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showLoginSheet(context),
                    )
                  : ListTile(
                      key: const ValueKey('in'),
                      leading: Artwork(sized(me?.avatarUrl, 't67x67'), size: 36, circle: true),
                      title: Text(me?.username ?? '…'),
                      subtitle: Text(me == null ? '' : l.loggedInAs(me.username)),
                      trailing: TextButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: Text(l.logout),
                              content: Text(l.logoutConfirm),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
                                FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.logout)),
                              ],
                            ),
                          );
                          if (ok == true) account.logout();
                        },
                        child: Text(l.logout),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SyncGroup extends StatelessWidget {
  const _SyncGroup();

  @override
  Widget build(BuildContext context) {
    final sync = context.deps.sync;

    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final l = context.l10n;
        return _Group(
          title: l.syncTitle,
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.sync_rounded),
              title: Text(l.syncBackground),
              subtitle: Text(sync.isListenerEnabled ? l.syncServerActive(sync.port) : l.syncDisabled),
              value: sync.isListenerEnabled,
              onChanged: (v) => sync.setListenerEnabled(v),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_rounded),
              title: Text(l.syncShowCode),
              subtitle: Text(l.syncShowCodeDesc),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final code = await sync.pairingCode();
                if (!context.mounted) return;
                showDialog<void>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(l.syncCodeTitle),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l.syncCodeHint),
                        const SizedBox(height: 12),
                        SelectableText(code, style: const TextStyle(fontFamily: Studio.mono, fontSize: 11)),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.syncCodeCopied)));
                          Navigator.pop(c);
                        },
                        child: Text(l.copy),
                      ),
                      FilledButton(onPressed: () => Navigator.pop(c), child: Text(l.done)),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: Text(l.syncPair),
              subtitle: Text(sync.peers.isEmpty ? l.syncNoPeers : l.syncPeers(sync.peers.length)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final ctrl = TextEditingController();
                final code = await showDialog<String>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(l.syncPair),
                    content: TextField(
                      controller: ctrl,
                      decoration: InputDecoration(labelText: l.syncPasteCode, hintText: 'eyJob3N0Ijog...'),
                      maxLines: 3,
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
                      FilledButton(onPressed: () => Navigator.pop(c, ctrl.text), child: Text(l.syncPairAction)),
                    ],
                  ),
                );
                if (code != null && code.trim().isNotEmpty) {
                  final ok = await sync.pairWithCode(code);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(ok ? l.syncPaired : l.syncPairFailed)));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: Text(l.syncNow),
              subtitle: Text(_syncStatus(l, sync)),
              trailing: FilledButton.tonal(
                onPressed: () async {
                  await sync.syncNow();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_syncStatus(l, sync))));
                },
                child: const Text('Sync'),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _syncStatus(AppLocalizations l, SyncService sync) => sync.peers.isEmpty
    ? l.syncNoPeers
    : sync.lastSyncedEvents == null
    ? l.syncNever
    : l.syncLast(sync.lastSyncedEvents!);

class _RustEngineGroup extends StatelessWidget {
  const _RustEngineGroup();

  @override
  Widget build(BuildContext context) {
    final engine = DeckEngine.instance;
    final rust = engine != null;

    final l = context.l10n;
    return _Group(
      title: l.engineTitle,
      children: [
        ListTile(
          leading: Icon(Icons.speed_rounded, color: rust ? const Color(0xFF00E676) : Studio.text3),
          title: const Text('Rust Audio Engine (deckengine)'),
          subtitle: Text(rust ? l.engineRustDesc(engine.label) : l.engineUnavailable),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: rust ? const Color(0xFF00E676).withValues(alpha: .15) : Studio.surfaceHi,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: rust ? const Color(0xFF00E676).withValues(alpha: .35) : Studio.line),
            ),
            child: Text(
              rust ? 'RUST' : 'DART',
              style: TextStyle(
                fontFamily: Studio.mono,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: rust ? const Color(0xFF00E676) : Studio.text3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

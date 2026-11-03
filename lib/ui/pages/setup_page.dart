import 'package:material_ui/material_ui.dart';

import '../../core/app_info.dart';
import '../../core/deps.dart';
import '../../core/platform.dart';
import '../../dj/mix_builder.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/studio.dart';
import 'dj_page.dart';
import 'login_sheet.dart';

/// First-run wizard: welcome (beta), sources, optional account, DJ styles, privacy opt-ins.
/// Every choice is written to [Settings] right away, so leaving early keeps what was picked.
class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _pages = PageController();
  var _index = 0;
  static const _count = 5;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (i >= _count) return _finish();
    _pages.animateToPage(i, duration: Motion.medium, curve: Motion.emphasized);
  }

  void _finish() => context.deps.settings.setupDone = true;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final accent = Theme.of(context).colorScheme.primary;
    final last = _index == _count - 1;
    return Scaffold(
      backgroundColor: Studio.bg0,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // Progress + skip
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 8, 0),
                  child: Row(
                    children: [
                      for (var i = 0; i < _count; i++)
                        AnimatedContainer(
                          duration: Motion.short,
                          margin: const EdgeInsetsDirectional.only(end: 6),
                          width: i == _index ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i <= _index ? accent : Studio.lineStrong,
                            borderRadius: Studio.br4,
                          ),
                        ),
                      const Spacer(),
                      if (!last) TextButton(onPressed: _finish, child: Text(l.setupSkip)),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pages,
                    onPageChanged: (i) => setState(() => _index = i),
                    children: const [_Welcome(), _Sources(), _AccountStep(), _DjStep(), _Privacy()],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Row(
                    children: [
                      if (_index > 0) TextButton(onPressed: () => _go(_index - 1), child: Text(l.setupBack)),
                      const Spacer(),
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(140, 52)),
                        onPressed: () => _go(_index + 1),
                        child: Text(_index == 0 ? l.setupStart : (last ? l.setupDone : l.setupNext)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared layout of one step: big title, short text, content.
class _Step extends StatelessWidget {
  const _Step({required this.title, required this.text, required this.children});

  final String title, text;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
    children: [
      Text(
        title,
        style: const TextStyle(
          fontFamily: Studio.sans,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Studio.text,
          height: 1.15,
        ),
      ),
      if (text.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(
          text,
          style: const TextStyle(fontFamily: Studio.sans, fontSize: 15, color: Studio.text2, height: 1.45),
        ),
      ],
      const SizedBox(height: 24),
      ...children,
    ],
  );
}

/// Bordered card used for toggles on the wizard pages.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    // Material (not a coloured box) so the tiles' ink ripples stay visible.
    child: Material(
      color: Studio.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: Studio.br16,
        side: BorderSide(color: Studio.line),
      ),
      child: child,
    ),
  );
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final accent = Theme.of(context).colorScheme.primary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Image.asset(
            'assets/brand/pounce_mark.png',
            width: 220,
            height: 220,
            filterQuality: FilterQuality.medium,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                l.setupWelcome,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: Studio.sans,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Studio.text,
                ),
              ),
            ),
            if (isBeta) ...[const SizedBox(width: 10), const BetaBadge()],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l.setupTagline,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: Studio.sans, fontSize: 16, color: Studio.text2, height: 1.45),
        ),
        if (isBeta) ...[
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .08),
              borderRadius: Studio.br14,
              border: Border.all(color: accent.withValues(alpha: .35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.science_rounded, color: accent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.betaNote,
                    style: const TextStyle(fontFamily: Studio.sans, fontSize: 13.5, color: Studio.text, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Sources extends StatelessWidget {
  const _Sources();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.deps.settings;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => _Step(
        title: l.setupSourcesTitle,
        text: '',
        children: [
          _Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_rounded),
              title: const Text('SoundCloud'),
              subtitle: Text(l.setupSoundcloudDesc),
              trailing: Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          _Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.radio_rounded),
              title: Text(l.radioSection),
              subtitle: Text(l.setupRadioDesc),
              value: s.radioEnabled,
              onChanged: (v) => s.radioEnabled = v,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountStep extends StatelessWidget {
  const _AccountStep();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final account = context.deps.account;
    return ListenableBuilder(
      listenable: account,
      builder: (context, _) => _Step(
        title: l.setupAccountTitle,
        text: l.setupAccountDesc,
        children: [
          if (account.loggedIn)
            _Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle_rounded, color: Studio.signal),
                title: Text(l.loggedInAs(account.me?.username ?? 'SoundCloud')),
              ),
            )
          else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                onPressed: () => showLoginSheet(context),
                icon: const Icon(Icons.login_rounded),
                label: Text(l.setupSignIn),
              ),
            ),
        ],
      ),
    );
  }
}

class _DjStep extends StatelessWidget {
  const _DjStep();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final mix = context.deps.mix;
    final accent = Theme.of(context).colorScheme.primary;
    return ListenableBuilder(
      listenable: mix,
      builder: (context, _) {
        final selected = mix.selected;
        return _Step(
          title: l.setupDjTitle,
          text: l.setupDjDesc,
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.9,
              children: [
                for (final c in DjCategory.all)
                  CategoryTile(
                    label: c.label,
                    icon: DjPage.icons[c.id] ?? Icons.album_rounded,
                    selected: selected.contains(c.id),
                    accent: accent,
                    onTap: () => mix.toggle(c.id),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Privacy extends StatelessWidget {
  const _Privacy();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.deps.settings;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => _Step(
        title: l.setupPrivacyTitle,
        text: l.setupPrivacyDesc,
        children: [
          if (Platform.isAndroid)
            _Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.system_update_rounded),
                title: Text(l.updatesAuto),
                subtitle: Text(l.updatesAutoDesc),
                value: s.autoCheckUpdates,
                onChanged: (v) => s.autoCheckUpdates = v,
              ),
            ),
          _Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.graphic_eq_rounded),
              title: Text(l.setupRecognition),
              subtitle: Text(l.setupRecognitionDesc),
              value: s.recognitionOptIn,
              onChanged: (v) => s.recognitionOptIn = v,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small "BETA" pill shown next to the app name.
class BetaBadge extends StatelessWidget {
  const BetaBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: accent),
        borderRadius: Studio.br6,
      ),
      child: Mono(context.l10n.beta.toUpperCase(), size: 11, color: accent, weight: 700),
    );
  }
}

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../library/account.dart';
import '../../sc/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Sign-in flow as a bottom sheet.
Future<void> showLoginSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => const _LoginSheet(),
);

class _LoginSheet extends StatefulWidget {
  const _LoginSheet();

  @override
  State<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<_LoginSheet> {
  final _paste = TextEditingController();
  late final Account _account = context.deps.account;
  bool _showPaste = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _account.addListener(_onAccount);
  }

  @override
  void dispose() {
    _account.removeListener(_onAccount);
    // Don't notify during teardown.
    if (!_account.loggedIn) Future.microtask(_account.cancel);
    _paste.dispose();
    super.dispose();
  }

  void _onAccount() {
    // After success show briefly, then close (except for the transfer offer).
    if (!_closing && _account.loggedIn && _account.localOnly.isEmpty && _account.me != null) {
      _closing = true;
      Future<void>.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
    }
  }

  void _login({bool signup = false}) {
    // Without an automatic redirect (web) show the paste field right away.
    setState(() => _showPaste = !_account.automaticCallback);
    _account.login(language: context.lang.split('-').first, signup: signup);
  }

  Future<void> _pasteFromClipboard() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    if (d?.text != null) _paste.text = d!.text!;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: ListenableBuilder(
        listenable: _account,
        builder: (context, _) => AnimatedSize(
          duration: Motion.medium,
          curve: Motion.emphasized,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: Motion.medium,
            switchInCurve: Motion.decelerate,
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(a),
                child: c,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(_step), child: _content(context)),
          ),
        ),
      ),
    );
  }

  String get _step => _account.loggedIn ? (_account.localOnly.isNotEmpty ? 'transfer' : 'done') : _account.state.name;

  Widget _content(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context);
    final a = _account;

    if (a.loggedIn) {
      final me = a.me;
      if (a.localOnly.isNotEmpty) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(me),
            const SizedBox(height: 16),
            Text(l.transferLikes(a.localOnly.length), textAlign: TextAlign.center, style: t.textTheme.titleLarge),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      a.dismissLocalLikes();
                      Navigator.pop(context);
                    },
                    child: Text(l.notNow),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      a.pushLocalLikes();
                      Navigator.pop(context);
                    },
                    child: Text(l.transfer),
                  ),
                ),
              ],
            ),
          ],
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Motion.long,
            curve: Motion.spring,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Icon(Icons.check_circle_rounded, size: 72, color: t.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(me == null ? '…' : l.loggedInAs(me.username), style: t.textTheme.titleLarge),
          const SizedBox(height: 16),
        ],
      );
    }

    switch (a.state) {
      case LoginState.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _CloudBadge(),
            const SizedBox(height: 16),
            Text(l.login, style: t.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l.loginSubtitle, textAlign: TextAlign.center, style: t.textTheme.bodyMedium),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(onPressed: _login, icon: const Icon(Icons.login_rounded), label: Text(l.login)),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => _login(signup: true), child: Text(l.signup)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: t.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.loginPrivacy,
                    style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        );
      case LoginState.busy:
        return const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        );
      case LoginState.waiting:
      case LoginState.error:
        final failed = a.state == LoginState.error;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (failed) ...[
              Icon(Icons.error_outline_rounded, size: 56, color: t.colorScheme.error),
              const SizedBox(height: 12),
              Text(l.loginFailed, textAlign: TextAlign.center, style: t.textTheme.titleLarge),
              if (a.error != null) Text(a.error!, textAlign: TextAlign.center, style: t.textTheme.bodySmall),
            ] else ...[
              const Center(child: EqualizerBars(playing: true, size: 40)),
              const SizedBox(height: 16),
              Text(l.loginWaiting, textAlign: TextAlign.center, style: t.textTheme.titleMedium),
            ],
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _login,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(l.loginReopen),
                ),
                if (!_showPaste)
                  TextButton(onPressed: () => setState(() => _showPaste = true), child: Text(l.loginPasteLabel)),
              ],
            ),
            AnimatedSize(
              duration: Motion.medium,
              curve: Motion.emphasized,
              child: !_showPaste
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            a.automaticCallback ? l.loginPasteHint : l.loginPasteHintWeb,
                            style: t.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _paste,
                            decoration: InputDecoration(
                              hintText: a.automaticCallback
                                  ? 'sc://auth?code=…'
                                  : 'https://soundcloud.com/signin/callback?code=…',
                              suffixIcon: IconButton(
                                tooltip: MaterialLocalizations.of(context).pasteButtonLabel,
                                icon: const Icon(Icons.content_paste_rounded),
                                onPressed: _pasteFromClipboard,
                              ),
                            ),
                            onSubmitted: a.complete,
                          ),
                          const SizedBox(height: 12),
                          ListenableBuilder(
                            listenable: _paste,
                            builder: (_, _) => FilledButton(
                              onPressed: _paste.text.trim().isEmpty ? null : () => a.complete(_paste.text),
                              child: Text(l.loginConfirm),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        );
    }
  }
}

/// Animated cloud logo.
class _CloudBadge extends StatelessWidget {
  const _CloudBadge();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .6, end: 1),
      duration: Motion.long,
      curve: Motion.spring,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(colors: [Color(0xFFFF7700), Color(0xFFFF3300)]),
          boxShadow: [BoxShadow(color: s.shadow.withValues(alpha: .2), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: const Icon(Icons.cloud_rounded, color: Colors.white, size: 44),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.user);
  final ScUser? user;

  @override
  Widget build(BuildContext context) => Artwork(sized(user?.avatarUrl, 't300x300'), size: 72, circle: true);
}

import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../library/account.dart';

/// Rebuilds when the SoundCloud module is switched on or off and when its account changes.
/// [builder] gets null while the module is missing.
class AccountBuilder extends StatelessWidget {
  const AccountBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, Account? account) builder;

  @override
  Widget build(BuildContext context) {
    final d = context.deps;
    return ListenableBuilder(
      listenable: d.modules,
      builder: (context, _) {
        final account = d.soundcloud?.account;
        if (account == null) return builder(context, null);
        return ListenableBuilder(listenable: account, builder: (context, _) => builder(context, account));
      },
    );
  }
}

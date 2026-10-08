import 'package:material_ui/material_ui.dart';

import 'core/deps.dart';
import 'l10n/gen/app_localizations.dart';
import 'ui/accent.dart';
import 'ui/pages/setup_page.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';

class PounceApp extends StatefulWidget {
  const PounceApp({super.key});

  @override
  State<PounceApp> createState() => _PounceAppState();
}

class _PounceAppState extends State<PounceApp> {
  late final _accent = AccentController(context.deps.settings, context.deps.player, context.deps.modules);

  @override
  void dispose() {
    _accent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.deps.settings;
    return ListenableBuilder(
      listenable: Listenable.merge([settings, _accent]),
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (c) => AppLocalizations.of(c).appName,
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: buildTheme(_accent.color),
        theme: buildTheme(_accent.color),
        // Cross-fade accent changes (e.g. a new cover) smoothly.
        themeAnimationDuration: Motion.long,
        themeAnimationCurve: Motion.emphasized,
        color: Studio.bg0,
        locale: settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        // Pass the language on to the source modules' content as well.
        builder: (context, child) {
          context.deps.modules.language = Localizations.localeOf(context).languageCode;
          return child!;
        },
        home: AnimatedSwitcher(
          duration: Motion.long,
          child: settings.setupDone ? const Shell() : const SetupPage(),
        ),
      ),
    );
  }
}

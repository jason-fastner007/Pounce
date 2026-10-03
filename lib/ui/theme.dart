import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransitionsBuilder;
import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

export 'tokens.dart';

/// Material components mapped onto the studio tokens (dark only).
ThemeData buildTheme(Color accent) {
  final onAccent = accent.computeLuminance() > .45 ? Studio.bg0 : Colors.white;
  final scheme = const ColorScheme.dark().copyWith(
    primary: accent,
    onPrimary: onAccent,
    primaryContainer: accent.withValues(alpha: .16),
    onPrimaryContainer: accent,
    secondary: accent,
    onSecondary: onAccent,
    secondaryContainer: accent.withValues(alpha: .14),
    onSecondaryContainer: accent,
    tertiary: Studio.text2,
    tertiaryContainer: Studio.surfaceTop,
    onTertiaryContainer: Studio.text,
    surface: Studio.bg0,
    onSurface: Studio.text,
    onSurfaceVariant: Studio.text2,
    surfaceContainerLowest: Studio.bg0,
    surfaceContainerLow: Studio.bg1,
    surfaceContainer: Studio.surface,
    surfaceContainerHigh: Studio.surfaceHi,
    surfaceContainerHighest: Studio.surfaceTop,
    outline: Studio.lineStrong,
    outlineVariant: Studio.line,
    error: Studio.clip,
    shadow: Colors.black,
    surfaceTint: Colors.transparent,
  );

  const shape12 = RoundedRectangleBorder(borderRadius: Studio.br12);
  final semi = [const FontVariation.weight(600)];
  final text = TextTheme(
    displayLarge: Studio.display,
    displayMedium: Studio.display,
    displaySmall: Studio.display,
    headlineLarge: Studio.display,
    headlineMedium: Studio.headline,
    headlineSmall: Studio.headline,
    titleLarge: Studio.headline.copyWith(fontSize: 18),
    titleMedium: Studio.title,
    titleSmall: Studio.body.copyWith(fontVariations: semi, fontWeight: FontWeight.w600),
    bodyLarge: Studio.body.copyWith(fontSize: 14),
    bodyMedium: Studio.body,
    bodySmall: Studio.bodyDim,
    labelLarge: Studio.body.copyWith(fontVariations: semi, fontWeight: FontWeight.w600),
    labelMedium: Studio.bodyDim,
    labelSmall: Studio.bodyDim.copyWith(fontSize: 11),
  );

  ButtonStyle button({Color? fg}) => ButtonStyle(
    shape: const WidgetStatePropertyAll(shape12),
    minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 8)),
    textStyle: WidgetStatePropertyAll(text.labelLarge),
    elevation: const WidgetStatePropertyAll(0),
    foregroundColor: fg == null ? null : WidgetStatePropertyAll(fg),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: Studio.sans,
    textTheme: text,
    // Transparent pages: the shell's (beat) background lies underneath.
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Studio.bg0,
    dividerColor: Studio.line,
    splashFactory: NoSplash.splashFactory,
    hoverColor: Colors.white.withValues(alpha: .04),
    highlightColor: Colors.white.withValues(alpha: .06),
    focusColor: accent.withValues(alpha: .18),
    visualDensity: VisualDensity.compact,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(backgroundColor: Colors.transparent),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(backgroundColor: Colors.transparent),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(backgroundColor: Colors.transparent),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xE6060709),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      titleTextStyle: Studio.headline,
      foregroundColor: Studio.text,
    ),
    cardTheme: const CardThemeData(
      color: Studio.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: Studio.br14,
        side: BorderSide(color: Studio.line),
      ),
    ),
    listTileTheme: ListTileThemeData(
      dense: false,
      minTileHeight: Studio.row,
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: Studio.s3),
      horizontalTitleGap: Studio.s3,
      shape: shape12,
      titleTextStyle: Studio.body.copyWith(fontSize: 13.5, fontVariations: const [FontVariation.weight(520)]),
      subtitleTextStyle: Studio.bodyDim,
      iconColor: Studio.text2,
      selectedColor: accent,
    ),
    dividerTheme: const DividerThemeData(color: Studio.line, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(style: button()),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: button(fg: Studio.text).copyWith(side: const WidgetStatePropertyAll(BorderSide(color: Studio.lineStrong))),
    ),
    textButtonTheme: TextButtonThemeData(style: button(fg: accent)),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(shape12),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? accent
              : (s.contains(WidgetState.hovered) ? Studio.text : Studio.text2),
        ),
        iconSize: const WidgetStatePropertyAll(22),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Studio.surface,
      selectedColor: accent.withValues(alpha: .16),
      side: const BorderSide(color: Studio.line),
      shape: const RoundedRectangleBorder(borderRadius: Studio.br10),
      labelStyle: Studio.body,
      checkmarkColor: accent,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(shape12),
        side: const WidgetStatePropertyAll(BorderSide(color: Studio.lineStrong)),
        textStyle: WidgetStatePropertyAll(Studio.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent.withValues(alpha: .16) : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : Studio.text2,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Studio.bg1,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: Studio.body.copyWith(color: Studio.text3),
      border: const OutlineInputBorder(
        borderRadius: Studio.br12,
        borderSide: BorderSide(color: Studio.line),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: Studio.br12,
        borderSide: BorderSide(color: Studio.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: Studio.br12,
        borderSide: BorderSide(color: accent),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: const WidgetStatePropertyAll(Studio.bg1),
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24)))),
      side: WidgetStateProperty.resolveWith(
        (s) => BorderSide(color: s.contains(WidgetState.focused) ? accent : Studio.line),
      ),
      constraints: const BoxConstraints(minHeight: 48),
      textStyle: WidgetStatePropertyAll(Studio.body.copyWith(fontSize: 14)),
      hintStyle: WidgetStatePropertyAll(Studio.body.copyWith(fontSize: 14, color: Studio.text3)),
    ),
    sliderTheme: SliderThemeData(
      // 2024 slider (the flag becomes the default later).
      // ignore: deprecated_member_use
      year2023: false,
      trackHeight: 3,
      activeTrackColor: accent,
      inactiveTrackColor: Studio.lineStrong,
      thumbColor: Studio.text,
      overlayShape: SliderComponentShape.noOverlay,
    ),
    // ignore: deprecated_member_use
    progressIndicatorTheme: ProgressIndicatorThemeData(year2023: false, color: accent),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Studio.bg0 : Studio.text2),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? accent : Studio.surfaceHi),
      trackOutlineColor: const WidgetStatePropertyAll(Studio.lineStrong),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? accent : Studio.text3),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Studio.bg1,
      surfaceTintColor: Colors.transparent,
      height: 64,
      elevation: 0,
      indicatorColor: accent.withValues(alpha: .14),
      indicatorShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(Studio.body.copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(size: 22, color: s.contains(WidgetState.selected) ? accent : Studio.text2),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Studio.bg1,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: Studio.lineStrong,
      dragHandleSize: Size(40, 4),
      constraints: BoxConstraints(maxWidth: 560),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Studio.line),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Studio.bg1,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: Studio.br20,
        side: BorderSide(color: Studio.line),
      ),
      titleTextStyle: Studio.title,
      contentTextStyle: Studio.body.copyWith(color: Studio.text2),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Studio.surfaceTop,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: Studio.br14,
        side: BorderSide(color: Studio.line),
      ),
      textStyle: Studio.body,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Studio.surfaceTop,
        borderRadius: Studio.br8,
        border: Border.all(color: Studio.lineStrong),
      ),
      textStyle: Studio.bodyDim.copyWith(color: Studio.text, fontSize: 11),
      waitDuration: const Duration(milliseconds: 400),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Studio.surfaceTop,
      contentTextStyle: Studio.body,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: Studio.br12,
        side: BorderSide(color: Studio.lineStrong),
      ),
    ),
    scrollbarTheme: const ScrollbarThemeData(
      thickness: WidgetStatePropertyAll(4),
      radius: Studio.r4,
      thumbColor: WidgetStatePropertyAll(Studio.lineStrong),
    ),
  );
}

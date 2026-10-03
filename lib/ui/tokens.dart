import 'package:material_ui/material_ui.dart';

/// "Studio" design tokens: OLED black, matte slate surfaces, 1 px edges,
/// one accent colour. All UI measurements come from here.
abstract final class Studio {
  // ---------- Surfaces ----------
  static const bg0 = Color(0xFF060709); // App-Hintergrund
  static const bg1 = Color(0xFF0B0D12); // Rail, Deck, Sheets
  static const surface = Color(0xFF13171F); // panels, cards
  static const surfaceHi = Color(0xFF1A1F29); // Hover / aktiv
  static const surfaceTop = Color(0xFF222834); // tooltip, menu

  // ---------- Edges (instead of shadows) ----------
  static const line = Color(0x14FFFFFF); // 8 %
  static const lineStrong = Color(0x26FFFFFF); // 15 %

  // ---------- Text ----------
  static const text = Color(0xFFE9EBEF);
  static const text2 = Color(0x9EE9EBEF); // 62 %
  static const text3 = Color(0x61E9EBEF); // 38 %

  // ---------- Status ----------
  static const clip = Color(0xFFFF3B30);
  static const signal = Color(0xFF34E08A);

  // ---------- Radii (modern, soft consumer geometry) ----------
  static const r2 = Radius.circular(2);
  static const r4 = Radius.circular(4);
  static const r6 = Radius.circular(6);
  static const r8 = Radius.circular(8);
  static const r10 = Radius.circular(10);
  static const r12 = Radius.circular(12);
  static const r14 = Radius.circular(14);
  static const r16 = Radius.circular(16);
  static const r20 = Radius.circular(20);
  static const r24 = Radius.circular(24);
  static const br4 = BorderRadius.all(r4);
  static const br6 = BorderRadius.all(r6);
  static const br8 = BorderRadius.all(r8);
  static const br10 = BorderRadius.all(r10);
  static const br12 = BorderRadius.all(r12);
  static const br14 = BorderRadius.all(r14);
  static const br16 = BorderRadius.all(r16);
  static const br20 = BorderRadius.all(r20);
  static const br24 = BorderRadius.all(r24);

  // ---------- Raster (4 px) ----------
  static const s1 = 4.0, s2 = 8.0, s3 = 12.0, s4 = 16.0, s5 = 24.0, s6 = 32.0;

  // ---------- Sizes ----------
  static const row = 54.0; // Trackzeile (touch-optimiert)
  static const deck = 80.0; // Master-Deck
  static const railSlim = 64.0;
  static const railWide = 220.0;
  static const inspector = 320.0;

  // ---------- Breakpoints ----------
  static const phone = 600.0; // below: phone layout
  static const compact = 960.0; // from here on: compact desktop
  static const wide = 1280.0; // from here on: inspector permanently docked

  // ---------- Typografie ----------
  static const sans = 'Inter';
  static const mono = 'JetBrainsMono';

  static TextStyle _s(double size, double weight, {double tracking = -.02, double height = 1.3, Color color = text}) =>
      TextStyle(
        fontFamily: sans,
        fontSize: size,
        height: height,
        color: color,
        letterSpacing: size * tracking,
        fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
        fontVariations: [FontVariation.weight(weight), FontVariation('opsz', size.clamp(14, 32))],
      );

  static final display = _s(28, 650, height: 1.15);
  static final headline = _s(20, 620, height: 1.2);
  static final title = _s(15, 580);
  static final body = _s(13, 440, tracking: -.01);
  static final bodyDim = _s(12, 440, tracking: -.005, color: text2);

  /// Uppercase heading with wide letter spacing.
  static final overline = _s(10.5, 600, tracking: .04, color: text3);

  /// Readings, times, indices – tabular figures, no jumping.
  static TextStyle monoStyle({double size = 11, Color color = text2, double weight = 500}) => TextStyle(
    fontFamily: mono,
    fontSize: size,
    height: 1.2,
    color: color,
    letterSpacing: 0,
    fontVariations: [FontVariation.weight(weight)],
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static Border get border => Border.all(color: line);

  static BoxDecoration panel({Color color = surface, BorderRadius radius = br14}) => BoxDecoration(
    color: color,
    borderRadius: radius,
    border: Border.all(color: line),
  );
}

/// Motion tokens: short, precise, springy.
abstract final class Motion {
  static const micro = Duration(milliseconds: 90);
  static const short = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);
  static const long = Duration(milliseconds: 460);
  static const emphasized = Curves.easeInOutCubicEmphasized;
  static const decelerate = Cubic(0.05, 0.7, 0.1, 1);
  static const spring = Cubic(0.34, 1.45, 0.64, 1);
}

import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../l10n/gen/app_localizations.dart';
import '../player/spectrum.dart';
import '../theme.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get lang => Localizations.localeOf(this).toLanguageTag();
}

String fmtDuration(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
}

/// 1,2 Mio. / 1.2M / 1,2 млн – depending on the language.
String fmtCompact(BuildContext c, int n) => NumberFormat.compact(locale: c.lang).format(n);

/// Cover with fade-in, placeholder and memory-friendly decoding.
class Artwork extends StatelessWidget {
  const Artwork(this.url, {super.key, this.size, this.radius = 12, this.circle = false});

  final String? url;
  final double? size;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Studio.surfaceHi, Studio.surface],
        ),
      ),
      child: Center(
        child: Icon(
          circle ? Icons.person_rounded : Icons.music_note_rounded,
          color: Studio.text3,
          size: size == null ? 40 : size! * .4,
        ),
      ),
    );
    final img = url == null
        ? placeholder
        : Image.network(
            url!,
            fit: BoxFit.cover,
            // Web: covers already come in a fitting size (t67/t300/t500); downscaled decoding
            // saves hardly anything there and makes Skwasm in Firefox show them zoomed/cropped.
            cacheWidth: size == null || kIsWeb ? null : (size! * dpr).round(),
            errorBuilder: (_, _, _) => placeholder,
            frameBuilder: (_, child, frame, sync) => sync
                ? child
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      placeholder,
                      AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: Motion.medium,
                        curve: Curves.easeOut,
                        child: child,
                      ),
                    ],
                  ),
          );
    // Hairline as a foreground edge (precision look).
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
          border: Border.all(color: Studio.line),
        ),
        child: circle ? ClipOval(child: img) : ClipRRect(borderRadius: BorderRadius.circular(radius), child: img),
      ),
    );
  }
}

/// Fades list entries in staggered (only the first ones, after that immediately).
class StaggeredIn extends StatelessWidget {
  const StaggeredIn({super.key, required this.index, required this.child, this.axis = Axis.vertical});

  final int index;
  final Widget child;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    if (index > 14 || MediaQuery.disableAnimationsOf(context)) return child;
    final delay = index * 45;
    final total = Motion.long.inMilliseconds + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Motion.decelerate),
      builder: (context, t, child) {
        final off = (1 - t) * 24;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: axis == Axis.vertical
                ? Offset(0, off)
                : Offset(off * (Directionality.of(context) == TextDirection.rtl ? -1 : 1), 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Shimmering placeholder while loading.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 14, this.radius = 8, this.circle = false});

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.circle ? null : BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1 + _c.value * 3, 0),
            end: Alignment(_c.value * 3, 0),
            colors: [s.surfaceContainerHigh, s.surfaceContainerHighest, s.surfaceContainerHigh],
          ),
        ),
      ),
    );
  }
}

/// Animated equaliser bars for the playing track.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({super.key, required this.playing, this.size = 18, this.color});

  final bool playing;
  final double size;
  final Color? color;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    if (widget.playing) _c.repeat();
  }

  @override
  void didUpdateWidget(EqualizerBars old) {
    super.didUpdateWidget(old);
    widget.playing ? _c.repeat() : _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    // While music plays, the bars show real levels from the shared tick.
    final scope = context.getInheritedWidgetOfExactType<SpectrumScope>();
    if (scope != null && widget.playing) {
      _c.stop();
      return RepaintBoundary(
        child: CustomPaint(size: Size.square(widget.size), painter: _LiveBarsPainter(scope.bus, color)),
      );
    }
    return RepaintBoundary(
      child: CustomPaint(size: Size.square(widget.size), painter: _BarsPainter(_c, color)),
    );
  }
}

class _LiveBarsPainter extends CustomPainter {
  _LiveBarsPainter(this.bus, this.color) : super(repaint: bus);
  final SpectrumBus bus;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final w = size.width / 5;
    // Bass / mids / highs
    for (final (i, b) in const [(0, 3), (1, 22), (2, 48)].indexed) {
      final h = size.height * (.2 + .8 * bus.levels[b.$2].clamp(0.0, 1.0));
      final x = i * 2 * w;
      canvas.drawRRect(RRect.fromLTRBR(x, size.height - h, x + w, size.height, Radius.circular(w / 2)), p);
    }
  }

  @override
  bool shouldRepaint(_LiveBarsPainter o) => o.color != color;
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.a, this.color) : super(repaint: a);
  final Animation<double> a;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const n = 3;
    final w = size.width / (n * 2 - 1);
    for (var i = 0; i < n; i++) {
      final t = a.value * 2 * pi * (i + 2) + i * 1.7;
      final h = size.height * (.3 + .7 * (.5 + .5 * sin(t)));
      canvas.drawRRect(
        RRect.fromLTRBR(i * 2 * w, size.height - h, i * 2 * w + w, size.height, Radius.circular(w / 2)),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.color != color;
}

/// Modern section header in consumer-streaming style (like Spotify / Apple Music).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(Studio.s4, Studio.s5, Studio.s4, Studio.s2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: Studio.sans,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: Studio.text,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Page header: clear, modern title with a soft kicker/subtitle.
class StudioHeader extends StatelessWidget {
  const StudioHeader({super.key, required this.title, this.kicker, this.actions = const []});

  final String title;
  final String? kicker;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        Studio.s4,
        topInset > 0 ? topInset + Studio.s3 : Studio.s6,
        Studio.s4,
        Studio.s2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kicker != null) ...[
                  Text(
                    kicker!,
                    style: TextStyle(
                      fontFamily: Studio.sans,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: Studio.sans,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.15,
                    color: Studio.text,
                  ),
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Empty state / error with a large icon.
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .6, end: 1),
              duration: Motion.long,
              curve: Motion.spring,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: Icon(icon, size: 64, color: t.colorScheme.primary.withValues(alpha: .7)),
            ),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: t.textTheme.titleMedium),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// FutureBuilder with an animated transition loading -> content/error.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({super.key, required this.load, required this.builder, this.loading});

  final Future<T> Function() load;
  final Widget Function(BuildContext, T) builder;
  final Widget? loading;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _f = widget.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _f,
    builder: (context, snap) {
      final Widget child;
      if (snap.hasError) {
        child = MessageView(
          key: const ValueKey('e'),
          icon: Icons.cloud_off_rounded,
          text: context.l10n.errorLoading,
          action: FilledButton.tonalIcon(
            onPressed: () => setState(() => _f = widget.load()),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.retry),
          ),
        );
      } else if (!snap.hasData) {
        child = KeyedSubtree(
          key: const ValueKey('l'),
          child: widget.loading ?? const Center(child: CircularProgressIndicator()),
        );
      } else {
        child = KeyedSubtree(key: const ValueKey('d'), child: widget.builder(context, snap.data as T));
      }
      return AnimatedSwitcher(duration: Motion.medium, switchInCurve: Motion.decelerate, child: child);
    },
  );
}

/// Page footer: Pounce as ASCII art. The cat blinks on hover/tap.
class AsciiSignature extends StatefulWidget {
  const AsciiSignature({super.key});

  @override
  State<AsciiSignature> createState() => _AsciiSignatureState();
}

class _AsciiSignatureState extends State<AsciiSignature> {
  bool _wink = false;

  // Lettering: figlet "small". ASCII only – safely contained in the subset JetBrains Mono.
  static const _logo = [
    r' ___   ___   _   _  _  _   ___  ___ ',
    r'| _ \ / _ \ | | | || \| | / __|| __|',
    r'|  _/| (_) || |_| || .` || (__ | _| ',
    r'|_|   \___/  \___/ |_|\_| \___||___|',
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final cat = [r'  /\_/\   ', _wink ? ' ( ^.^ )  ' : ' ( o.o )  ', r'  > ^ <   ', '          '];
    final mono = Studio.monoStyle(size: 13, color: Studio.text2, weight: 600).copyWith(height: 1.05);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Studio.s4, Studio.s6 + Studio.s4, Studio.s4, Studio.s6),
      child: Center(
        child: MouseRegion(
          onEnter: (_) => setState(() => _wink = true),
          onExit: (_) => setState(() => _wink = false),
          child: GestureDetector(
            onTap: () => setState(() => _wink = !_wink),
            // Narrow phones: rather shrink than wrap (ASCII art can't take a line break).
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  children: [
                    for (var i = 0; i < _logo.length; i++) ...[
                      TextSpan(text: cat[i], style: TextStyle(color: accent)),
                      TextSpan(text: _logo[i]),
                      if (i < _logo.length - 1) const TextSpan(text: '\n'),
                    ],
                  ],
                ),
                style: mono,
                softWrap: false,
                textDirection: TextDirection.ltr,
                semanticsLabel: 'Pounce',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

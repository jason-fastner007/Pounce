import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// Builds depending on the hover state (desktop/web). Always false on touch.
class Hover extends StatefulWidget {
  const Hover({super.key, required this.builder, this.cursor = MouseCursor.defer});

  final Widget Function(BuildContext context, bool hovered) builder;
  final MouseCursor cursor;

  @override
  State<Hover> createState() => _HoverState();
}

class _HoverState extends State<Hover> {
  bool _on = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: widget.cursor,
    onEnter: (_) => setState(() => _on = true),
    onExit: (_) => setState(() => _on = false),
    child: widget.builder(context, _on),
  );
}

/// Tactile button: hover surface, springy press, optionally active (accent).
class Tactile extends StatefulWidget {
  const Tactile({
    super.key,
    required this.child,
    required this.onTap,
    this.tooltip,
    this.active = false,
    this.size,
    this.radius = Studio.br10,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool active;
  final Size? size;
  final BorderRadius radius;
  final EdgeInsets padding;

  @override
  State<Tactile> createState() => _TactileState();
}

class _TactileState extends State<Tactile> {
  bool _hover = false, _down = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final enabled = widget.onTap != null;
    Widget w = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? .9 : 1,
          duration: _down ? Motion.micro : Motion.medium,
          curve: _down ? Curves.easeOut : Motion.spring,
          child: AnimatedContainer(
            duration: Motion.short,
            width: widget.size?.width,
            height: widget.size?.height,
            padding: widget.padding,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: widget.radius,
              color: widget.active
                  ? accent.withValues(alpha: .14)
                  : (_hover && enabled ? Colors.white.withValues(alpha: .06) : Colors.transparent),
            ),
            child: IconTheme.merge(
              data: IconThemeData(
                size: 20,
                color: !enabled
                    ? Studio.text3
                    : widget.active
                    ? accent
                    : (_hover ? Studio.text : Studio.text2),
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: widget.active ? accent : null),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.tooltip != null) w = Tooltip(message: widget.tooltip!, child: w);
    return Semantics(button: true, label: widget.tooltip, child: w);
  }
}

/// Square icon button (32 px default).
class StudioIcon extends StatelessWidget {
  const StudioIcon(this.icon, {super.key, required this.onTap, this.tooltip, this.active = false, this.size = 36});

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) => Tactile(
    onTap: onTap,
    tooltip: tooltip,
    active: active,
    size: Size.square(size),
    child: AnimatedSwitcher(
      duration: Motion.short,
      transitionBuilder: (c, a) => ScaleTransition(
        scale: a,
        child: FadeTransition(opacity: a, child: c),
      ),
      child: Icon(icon, key: ValueKey(icon), size: size * .6),
    ),
  );
}

/// Monospace value (time, LUFS, index) – tabular, doesn't jump.
class Mono extends StatelessWidget {
  const Mono(this.text, {super.key, this.size = 11, this.color, this.weight = 500, this.align});

  final String text;
  final double size;
  final Color? color;
  final double weight;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    maxLines: 1,
    overflow: TextOverflow.clip,
    style: Studio.monoStyle(size: size, color: color ?? Studio.text2, weight: weight),
  );
}

/// Status LED with a soft glow.
class Led extends StatelessWidget {
  const Led({super.key, required this.on, this.color, this.size = 6});

  final bool on;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: Motion.short,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? c : Studio.lineStrong,
        boxShadow: on ? [BoxShadow(color: c.withValues(alpha: .7), blurRadius: size * 1.6)] : const [],
      ),
    );
  }
}

/// Section header: "01 — TITLE" in hardware lettering.
class Overline extends StatelessWidget {
  const Overline(this.text, {super.key, this.index, this.trailing});

  final String text;
  final int? index;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(Studio.s4, Studio.s5, Studio.s2, Studio.s3),
    child: Row(
      children: [
        if (index != null) ...[
          Mono(index!.toString().padLeft(2, '0'), color: Theme.of(context).colorScheme.primary, weight: 600),
          const SizedBox(width: Studio.s2),
          Container(width: 12, height: 1, color: Studio.lineStrong),
          const SizedBox(width: Studio.s2),
        ],
        Expanded(
          child: Text(text.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: Studio.overline),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Compact segmented switch with a sliding marker (e.g. OFF/Q/N/L).
class Segments<T> extends StatelessWidget {
  const Segments({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.tooltip,
    this.height = 28,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final String Function(T)? tooltip;
  final ValueChanged<T>? onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final i = values.indexOf(selected).clamp(0, values.length - 1);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Studio.bg0,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Studio.line),
      ),
      padding: const EdgeInsets.all(2.5),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / values.length;
          return Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: Motion.medium,
                curve: Motion.spring,
                start: i * w,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withValues(alpha: .5)),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final v in values)
                    Expanded(
                      child: _MaybeTooltip(
                        message: tooltip?.call(v),
                        child: MouseRegion(
                          cursor: onChanged == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onChanged == null ? null : () => onChanged!(v),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: Motion.short,
                                style: TextStyle(
                                  fontFamily: Studio.sans,
                                  fontSize: 12,
                                  fontWeight: v == selected ? FontWeight.w700 : FontWeight.w500,
                                  color: v == selected ? accent : (onChanged == null ? Studio.text3 : Studio.text2),
                                ),
                                // Shrink long labels (e.g. "WARTESCHLANGE") instead of wrapping.
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(label(v), maxLines: 1, softWrap: false),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MaybeTooltip extends StatelessWidget {
  const _MaybeTooltip({required this.message, required this.child});
  final String? message;
  final Widget child;

  @override
  Widget build(BuildContext context) => message == null ? child : Tooltip(message: message!, child: child);
}

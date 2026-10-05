import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../lyrics/lrc.dart';
import '../../sc/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Synced lyrics: active line large, scrolls along smoothly.
/// Manual scrolling pauses the follow mode briefly. Tapping jumps to the line.
class LyricsView extends StatefulWidget {
  const LyricsView({super.key, required this.track, this.compact = false});

  final Track track;

  /// Smaller font (inspector column).
  final bool compact;

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  late Future<Lyrics?> _lyrics = context.deps.lyrics.forTrack(widget.track);

  @override
  void didUpdateWidget(LyricsView old) {
    super.didUpdateWidget(old);
    if (old.track.id != widget.track.id) {
      _lyrics = context.deps.lyrics.forTrack(widget.track);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Lyrics?>(
    future: _lyrics,
    builder: (context, snap) {
      final Widget child;
      if (snap.connectionState != ConnectionState.done) {
        child = const Center(key: ValueKey('l'), child: CircularProgressIndicator());
      } else if (snap.data == null) {
        child = MessageView(key: const ValueKey('n'), icon: Icons.lyrics_outlined, text: context.l10n.noLyrics);
      } else {
        child = _Lines(key: ValueKey(widget.track.id), lyrics: snap.data!, compact: widget.compact);
      }
      return AnimatedSwitcher(duration: Motion.medium, child: child);
    },
  );
}

class _Lines extends StatefulWidget {
  const _Lines({super.key, required this.lyrics, this.compact = false});
  final Lyrics lyrics;
  final bool compact;

  @override
  State<_Lines> createState() => _LinesState();
}

class _LinesState extends State<_Lines> {
  final _scroll = ScrollController();
  late final _keys = List.generate(widget.lyrics.lines.length, (_) => GlobalKey());
  int _active = -1;
  DateTime _userScrolledAt = DateTime(0);
  late final _player = context.deps.player;

  @override
  void initState() {
    super.initState();
    if (widget.lyrics.synced) _player.position.addListener(_onPos);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPos(jump: true));
  }

  @override
  void dispose() {
    _player.position.removeListener(_onPos);
    _scroll.dispose();
    super.dispose();
  }

  void _onPos({bool jump = false}) {
    // Switch slightly early, feels more in sync.
    final i = widget.lyrics.indexAt(_player.position.value + const Duration(milliseconds: 250));
    if (i == _active && !jump) return;
    setState(() => _active = i);
    if (i < 0 || DateTime.now().difference(_userScrolledAt).inSeconds < 3) return;
    final ctx = _keys[i].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: .35,
        duration: jump ? Duration.zero : Motion.long,
        curve: Motion.emphasized,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final base = (widget.compact ? Studio.title.copyWith(fontSize: 17) : Studio.headline.copyWith(fontSize: 26))
        .copyWith(height: 1.3);
    final lines = widget.lyrics.lines;
    final synced = widget.lyrics.synced;

    return NotificationListener<UserScrollNotification>(
      onNotification: (n) {
        if (n.direction != ScrollDirection.idle) _userScrolledAt = DateTime.now();
        return false;
      },
      child: ShaderMask(
        // Soft fade at top/bottom.
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
          stops: [0, .08, .85, 1],
        ).createShader(r),
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsetsDirectional.fromSTEB(24, 48, 24, 240),
          itemCount: lines.length + 1,
          itemBuilder: (context, i) {
            if (i == lines.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  context.l10n.lyricsSource(widget.lyrics.source),
                  style: t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                ),
              );
            }
            final line = lines[i];
            final active = !synced || i == _active;
            final past = synced && i < _active;
            return InkWell(
              key: _keys[i],
              borderRadius: BorderRadius.circular(12),
              onTap: synced
                  ? () {
                      _userScrolledAt = DateTime(0);
                      _player.seek(line.time);
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AnimatedScale(
                  scale: active && synced ? 1 : .94,
                  alignment: AlignmentDirectional.centerStart.resolve(Directionality.of(context)),
                  duration: Motion.medium,
                  curve: Motion.spring,
                  child: AnimatedDefaultTextStyle(
                    duration: Motion.medium,
                    curve: Motion.emphasized,
                    style: base.copyWith(
                      color: t.colorScheme.onSurface.withValues(alpha: active ? 1 : (past ? .45 : .3)),
                      fontVariations: [FontVariation.weight(active && synced ? 700 : 520)],
                    ),
                    child: Text(line.text.isEmpty ? '♪' : line.text),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

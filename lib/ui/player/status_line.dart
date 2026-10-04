import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/deps.dart';
import '../../sc/models.dart';
import '../../sc/soundcloud.dart' show StreamInfo;
import '../theme.dart';
import '../tokens.dart';
import '../widgets/common.dart';

/// Compact status line below title/artist: source · start time · BPM · key.
///
/// Fixed height and fixed badge slots: on a track change only the contents cross-fade,
/// nothing below jumps (no layout shifts).
class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final d = context.deps;
    final accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 22,
      child: ListenableBuilder(
        listenable: Listenable.merge([d.player, d.player.startLatency, d.dj]),
        builder: (context, _) {
          final s = d.player.stream;
          final dj = d.dj.state;
          final latency = d.player.startLatency.value;
          // Scale down instead of overflowing on narrow phones (all badges visible).
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              children: [
                if (track.isLive)
                  const _Badge('LIVE', color: Studio.clip)
                else if (track.isPreview)
                  _Badge(context.l10n.previewBadge.toUpperCase(), color: const Color(0xFFFFB020))
                else
                  _Badge(s == null ? 'SC' : 'SC-FULL · ${_codec(s)}', color: accent),
                _Fade(show: latency != null, child: _Badge(latency == null ? '' : '▶ ${latency.inMilliseconds} ms')),
                // With DJ Flow active, BPM and key are already shown in its pill below.
                _Fade(
                  show: dj.currentBpm > 0 && !dj.isActive,
                  child: _Badge('${dj.currentBpm.toStringAsFixed(dj.currentBpm % 1 == 0 ? 0 : 1)} BPM'),
                ),
                _Fade(
                  show: dj.currentKey != null && !dj.isActive,
                  child: _Badge(dj.currentKey?.code ?? '', color: _camelotColor(dj.currentKey?.number)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// "AAC 160", "MP3 128", "OPUS 64" from the SoundCloud preset.
  static String _codec(StreamInfo s) {
    final p = s.preset.toLowerCase();
    final kbps = RegExp(r'(\d{2,3})k').firstMatch(p)?.group(1);
    if (p.startsWith('aac')) return 'AAC ${kbps ?? ''}'.trim();
    if (p.startsWith('mp3')) return 'MP3 128';
    if (p.startsWith('opus')) return 'OPUS 64';
    return s.hls ? 'HLS' : 'PROG';
  }

  /// Camelot wheel as a colour circle: neighbouring (harmonically compatible) keys get similar colours.
  static Color? _camelotColor(int? number) =>
      number == null ? null : HSLColor.fromAHSL(1, (number - 1) * 30.0, .75, .62).toColor();
}

/// Notice for 30 s previews: say openly what's going on and show the way to the full version.
class PreviewNotice extends StatelessWidget {
  const PreviewNotice({super.key, required this.track});

  final Track track;

  Uri get _ytMusic {
    final who = track.artist ?? track.user.username;
    return Uri.https('music.youtube.com', '/search', {'q': '$who ${track.title}'});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AnimatedSize(
      duration: Motion.medium,
      curve: Motion.emphasized,
      child: !track.isPreview
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: Studio.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.previewHint, style: Studio.monoStyle(size: 11, color: Studio.text2).copyWith(height: 1.35)),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: Studio.s1),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => launchUrl(_ytMusic, mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(l.openInYtMusic),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Studio.text2;
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.withValues(alpha: .10),
        borderRadius: Studio.br6,
        border: Border.all(color: c.withValues(alpha: .28)),
      ),
      child: Text(text, maxLines: 1, style: Studio.monoStyle(size: 10.5, color: c, weight: 600)),
    );
  }
}

/// Fades a badge in/out without the line jerking when it appears.
class _Fade extends StatelessWidget {
  const _Fade({required this.show, required this.child});

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: Motion.short,
    curve: Motion.emphasized,
    child: AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: Motion.short,
      child: show ? child : const SizedBox.shrink(),
    ),
  );
}

/// Second line below the title: artist – for radio, the song currently playing from the stream (ICY).
class NowArtist extends StatelessWidget {
  const NowArtist({super.key, required this.track, required this.style});

  final Track track;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (!track.isLive) return Text(track.user.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    return ValueListenableBuilder<String?>(
      valueListenable: context.deps.player.streamTitle,
      builder: (_, title, _) => AnimatedSwitcher(
        duration: Motion.medium,
        child: Text(
          _song(title) ?? track.user.username,
          key: ValueKey(title),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}

/// Clean up ICY titles: " - Party-Hitmix" (empty artist) → "Party-Hitmix".
String? _song(String? icy) {
  final t = icy?.trim().replaceFirst(RegExp(r'^-\s*'), '').trim();
  return t == null || t.isEmpty ? null : t;
}

/// Instead of a seek bar for live streams: a pulsing LIVE badge (no end, no seeking).
class LiveBar extends StatefulWidget {
  const LiveBar({super.key});

  @override
  State<LiveBar> createState() => _LiveBarState();
}

class _LiveBarState extends State<LiveBar> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playing = context.deps.player.playing;
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: playing ? Tween(begin: .35, end: 1.0).animate(_pulse) : const AlwaysStoppedAnimation(.35),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: Studio.clip, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Text(context.l10n.live, style: Studio.monoStyle(size: 13, color: Studio.text, weight: 700)),
        ],
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';

import '../../core/deps.dart';
import '../../dj/harmonic_mixer.dart';
import '../../dj/mix_builder.dart';
import '../player/dj_deck_view.dart' show energyModeLabel;
import '../theme.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import '../widgets/studio.dart';

/// DJ tab: pick categories, set the blend, start a mix. Pounce builds the mix from likes and
/// similar tracks; DJ Flow orders and mixes it (key, tempo, energy, drops).
class DjPage extends StatelessWidget {
  const DjPage({super.key});

  static const icons = <String, IconData>{
    'techno': Icons.graphic_eq_rounded,
    'hardtechno': Icons.bolt_rounded,
    'house': Icons.house_rounded,
    'melodic': Icons.waves_rounded,
    'afro': Icons.music_note_rounded,
    'dnb': Icons.speed_rounded,
    'trance': Icons.auto_awesome_rounded,
    'hiphop': Icons.mic_rounded,
    'remix': Icons.autorenew_rounded,
    'chill': Icons.nightlight_round,
  };

  @override
  Widget build(BuildContext context) {
    final d = context.deps;
    final l = context.l10n;
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([d.mix, d.dj, d.modules]),
        builder: (context, _) {
          // DJ mixes need a source module with related tracks and analysable streams.
          if (!d.modules.sources.any((m) => m.supportsDj)) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: StudioHeader(title: l.djHeadline)),
                SliverToBoxAdapter(child: MessageView(icon: Icons.extension_rounded, text: l.djNoSources)),
              ],
            );
          }
          final mix = d.mix;
          final selected = mix.selected;
          final wide = MediaQuery.sizeOf(context).width > 700;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: StudioHeader(title: l.djHeadline)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, Studio.s3),
                  child: Text(
                    l.djIntro,
                    style: const TextStyle(fontFamily: Studio.sans, fontSize: 13.5, color: Studio.text2, height: 1.4),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SectionHeader(l.djCategories)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: wide ? 5 : 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 64,
                  ),
                  delegate: SliverChildListDelegate([
                    for (final (i, c) in DjCategory.all.indexed)
                      StaggeredIn(
                        index: i,
                        child: CategoryTile(
                          label: c.label,
                          icon: icons[c.id] ?? Icons.album_rounded,
                          selected: selected.contains(c.id),
                          accent: accent,
                          onTap: () => mix.toggle(c.id),
                        ),
                      ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(child: SectionHeader(l.djBlend)),
              SliverToBoxAdapter(
                child: _Panel(
                  child: Column(
                    children: [
                      Slider(value: mix.discovery, divisions: 10, onChanged: (v) => mix.discovery = v),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Mono('${l.djFavorites} ${((1 - mix.discovery) * 100).round()} %', size: 11),
                            const Spacer(),
                            Mono('${l.djDiscover} ${(mix.discovery * 100).round()} %', size: 11),
                          ],
                        ),
                      ),
                      const SizedBox(height: Studio.s3),
                      SegmentedButton<EnergyMode>(
                        showSelectedIcon: false,
                        segments: [
                          for (final m in EnergyMode.values)
                            ButtonSegment(value: m, label: Text(energyModeLabel(l, m))),
                        ],
                        selected: {d.dj.state.energyMode},
                        onSelectionChanged: (s) => d.dj.setEnergyMode(s.first),
                      ),
                      const SizedBox(height: Studio.s3),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.djLookahead,
                                  style: const TextStyle(fontFamily: Studio.sans, fontSize: 14, color: Studio.text),
                                ),
                                Mono(l.djLookaheadDesc(d.dj.lookahead, d.dj.lookahead ~/ 2), size: 11),
                              ],
                            ),
                          ),
                          SegmentedButton<int>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: 20, label: Text('20')),
                              ButtonSegment(value: 50, label: Text('50')),
                            ],
                            selected: {d.dj.lookahead},
                            onSelectionChanged: (s) => d.dj.lookahead = s.first,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, Studio.s4, 16, Studio.s2),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: Studio.br16),
                    ),
                    onPressed: selected.isEmpty || mix.building ? null : () => _start(context),
                    icon: mix.building
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.play_arrow_rounded),
                    label: Text(mix.building ? l.djBuilding : (selected.isEmpty ? l.djPickCategory : l.djStart)),
                  ),
                ),
              ),
              // Progress of the look-ahead analysis while DJ Flow is running.
              SliverToBoxAdapter(
                child: ValueListenableBuilder<(int, int)>(
                  valueListenable: d.dj.ahead,
                  builder: (context, a, _) => AnimatedSize(
                    duration: Motion.medium,
                    child: a.$2 == 0 || !d.dj.state.isActive
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(20, Studio.s2, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(value: a.$1 / a.$2, minHeight: 3, borderRadius: Studio.br4),
                                const SizedBox(height: 6),
                                Mono(l.djAnalyzed(a.$1, a.$2), size: 11),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _start(BuildContext context) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final n = await context.deps.mix.start();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(n == 0 ? l.djNothing : l.djMixStarted(n))));
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PressableCard(
    onTap: onTap,
    child: AnimatedContainer(
      duration: Motion.short,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? accent.withValues(alpha: .14) : Studio.surface,
        borderRadius: Studio.br14,
        border: Border.all(color: selected ? accent.withValues(alpha: .55) : Studio.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: selected ? accent : Studio.text2),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: Studio.sans,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Studio.text : Studio.text2,
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: selected ? 1 : 0,
            duration: Motion.short,
            child: Icon(Icons.check_circle_rounded, size: 18, color: accent),
          ),
        ],
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.all(Studio.s3),
      decoration: Studio.panel(radius: Studio.br16),
      child: child,
    ),
  );
}

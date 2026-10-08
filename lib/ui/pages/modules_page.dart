import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/deps.dart';
import '../../modules/registry.dart';
import '../../modules/updater/updater.dart' show githubRepo;
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/studio.dart';

/// Module manager: the source modules of this build (on/off), installed designs and the catalog.
class ModulesPage extends StatefulWidget {
  const ModulesPage({super.key});

  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  /// null = catalog not opened yet (no request before the user asks for it).
  Future<List<CatalogEntry>>? _catalog;

  void _openCatalog() => setState(() => _catalog = context.deps.modules.catalog.load());

  static final _docs = Uri.parse('https://github.com/$githubRepo/blob/main/docs/MODULES.md');

  @override
  Widget build(BuildContext context) {
    final modules = context.deps.modules;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.modules)),
      body: ListenableBuilder(
        listenable: modules,
        builder: (context, _) {
          final active = modules.activeTheme;
          return ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              _Panel(
                title: l.modulesSources,
                children: [
                  if (modules.bundled.isEmpty) ListTile(title: Text(l.modulesNoSources, style: Studio.bodyDim)),
                  for (final m in modules.bundled)
                    SwitchListTile(
                      secondary: const Icon(Icons.cloud_rounded),
                      title: Text(m.manifest.name),
                      subtitle: Text('${m.manifest.description}\n${_byline(context, m.manifest)}'),
                      isThreeLine: true,
                      value: modules.isEnabled(m.id),
                      onChanged: (v) => modules.setEnabled(m.id, v),
                    ),
                ],
              ),
              _Panel(
                title: l.modulesThemes,
                children: [
                  _ThemeTile(
                    color: null,
                    title: l.themeDefault,
                    subtitle: l.themeDefaultDesc,
                    selected: active == null,
                    onTap: () => modules.useTheme(null),
                  ),
                  for (final t in modules.themes)
                    _ThemeTile(
                      color: t.accent,
                      title: t.manifest.name,
                      subtitle: _byline(context, t.manifest),
                      selected: active?.id == t.id,
                      onTap: () => modules.useTheme(t.id),
                      onRemove: () => modules.uninstallTheme(t.id),
                    ),
                ],
              ),
              _Panel(
                title: l.modulesCatalog,
                children: [
                  if (_catalog == null)
                    ListTile(
                      leading: const Icon(Icons.storefront_rounded),
                      title: Text(l.modulesBrowse),
                      subtitle: Text(l.modulesBrowseDesc),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _openCatalog,
                    )
                  else
                    FutureBuilder<List<CatalogEntry>>(
                      future: _catalog,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return ListTile(
                            leading: const Icon(Icons.cloud_off_rounded),
                            title: Text(l.errorLoading),
                            trailing: TextButton(onPressed: _openCatalog, child: Text(l.retry)),
                          );
                        }
                        final entries = snap.data;
                        if (entries == null) {
                          return const Padding(
                            padding: EdgeInsets.all(Studio.s5),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (entries.isEmpty) return ListTile(title: Text(l.noResults));
                        return Column(children: [for (final e in entries) _CatalogTile(e)]);
                      },
                    ),
                ],
              ),
              _Panel(
                title: l.modulesDevelop,
                children: [
                  ListTile(
                    leading: const Icon(Icons.code_rounded),
                    title: Text(l.modulesDevelopTitle),
                    subtitle: Text(l.modulesDevelopDesc),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () => launchUrl(_docs, mode: LaunchMode.externalApplication),
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

String _byline(BuildContext context, ModuleManifest m) => context.l10n.moduleByline(m.version, m.author);

class _CatalogTile extends StatelessWidget {
  const _CatalogTile(this.entry);
  final CatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final modules = context.deps.modules;
    final l = context.l10n;
    final m = entry.manifest;
    final theme = entry.theme;
    final Widget trailing;
    if (theme != null) {
      final installed = modules.themes.any((t) => t.id == m.id && t.manifest.version == m.version);
      trailing = installed
          ? const Icon(Icons.check_circle_rounded, color: Studio.signal)
          : FilledButton.tonal(
              onPressed: () {
                modules.installTheme(theme);
                modules.useTheme(theme.id);
              },
              child: Text(l.moduleInstall),
            );
    } else {
      // Source modules are code: they come with an app build, not from the catalog.
      final bundled = modules.bundled.any((b) => b.id == m.id);
      trailing = Mono(bundled ? l.moduleIncluded : l.moduleNotInBuild, size: 10, color: Studio.text3);
    }
    return ListTile(
      leading: theme != null
          ? _Swatch(theme.accent)
          : const Icon(Icons.cloud_outlined),
      title: Text(m.name),
      subtitle: Text([if (m.description.isNotEmpty) m.description, _byline(context, m)].join('\n')),
      isThreeLine: m.description.isNotEmpty,
      trailing: trailing,
      onTap: m.homepage == null
          ? null
          : () => launchUrl(Uri.parse(m.homepage!), mode: LaunchMode.externalApplication),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.onRemove,
  });

  /// null = the accent from the settings.
  final Color? color;
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: color == null ? const Icon(Icons.palette_outlined) : _Swatch(color!),
    title: Text(title),
    subtitle: Text(subtitle),
    selected: selected,
    onTap: onTap,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selected) const Icon(Icons.check_rounded),
        if (onRemove != null)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: context.l10n.moduleRemove,
            onPressed: onRemove,
          ),
      ],
    ),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color.withValues(alpha: .5), blurRadius: 10)],
    ),
  );
}

/// Titled panel, like the groups on the settings page.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Studio.s4, Studio.s3, Studio.s4, Studio.s2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, Studio.s3, 0, Studio.s2),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: Studio.sans,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Studio.text2,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: Studio.br16,
          child: DecoratedBox(
            decoration: Studio.panel(radius: Studio.br16),
            child: Material(
              type: MaterialType.transparency,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ),
        ),
      ],
    ),
  );
}

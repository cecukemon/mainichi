/// The Bunko browser (features/bunko-browser.md): a read-only, tabbed view
/// of every word, sentence structure, and grammar-glue entry the capture
/// flow has added — the first way to see the Bunko's contents at all.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bunko_store.dart';
import '../../data/enums.dart';
import '../bunko_providers.dart';
import '../role_label.dart';
import '../widgets/structure_detail_sheet.dart';
import '../widgets/word_detail_sheet.dart';

class BunkoScreen extends ConsumerWidget {
  const BunkoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bunkoProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bunko'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Words'),
            Tab(text: 'Structures'),
            Tab(text: 'Glue'),
          ]),
        ),
        body: Builder(
          builder: (context) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error) {
              return _ErrorView(
                  onRetry: () => ref.read(bunkoProvider.notifier).load());
            }
            return TabBarView(
              children: [
                _WordsTab(state: state, ref: ref),
                _StructuresTab(structures: state.structures),
                _GlueTab(glue: state.glue),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WordsTab extends StatelessWidget {
  const _WordsTab({required this.state, required this.ref});
  final BunkoState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (state.words.isEmpty) {
      return const _EmptyTab(
        icon: Icons.translate,
        message: 'Words you import from worksheets appear here.',
      );
    }
    final counts = state.roleCounts;
    final presentRoles = [
      for (final role in WordRole.values) if (counts.containsKey(role)) role,
    ];

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('All (${state.words.length})'),
                  selected: state.roleFilter == null,
                  onSelected: (_) =>
                      ref.read(bunkoProvider.notifier).setRoleFilter(null),
                ),
              ),
              for (final role in presentRoles)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${roleLabel(role)} (${counts[role]})'),
                    selected: state.roleFilter == role,
                    onSelected: (_) =>
                        ref.read(bunkoProvider.notifier).setRoleFilter(role),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 0.5),
        Expanded(
          child: Builder(builder: (context) {
            final words = state.filteredWords;
            if (words.isEmpty) {
              return const _EmptyTab(
                icon: Icons.translate,
                message: 'No words of this type yet.',
              );
            }
            return ListView.separated(
              itemCount: words.length,
              separatorBuilder: (_, _) => const Divider(height: 0.5),
              itemBuilder: (context, i) => _WordRow(word: words[i]),
            );
          }),
        ),
      ],
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({required this.word});
  final BunkoWordRow word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleParts = [
      if (word.kanji.isNotEmpty) word.kana,
      if (word.meaning?.isNotEmpty == true) word.meaning!,
    ];
    return ListTile(
      onTap: () => showWordDetailSheet(context, word.id),
      title: Text(word.kanji.isNotEmpty ? word.kanji : word.kana,
          style: theme.textTheme.titleMedium),
      subtitle: subtitleParts.isEmpty
          ? null
          : Text(subtitleParts.join(' · '),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: Text(roleLabel(word.role),
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

class _StructuresTab extends StatelessWidget {
  const _StructuresTab({required this.structures});
  final List<BunkoStructureRow> structures;

  @override
  Widget build(BuildContext context) {
    if (structures.isEmpty) {
      return const _EmptyTab(
        icon: Icons.view_list_outlined,
        message: 'Sentence structures you import appear here.',
      );
    }
    return ListView.separated(
      itemCount: structures.length,
      separatorBuilder: (_, _) => const Divider(height: 0.5),
      itemBuilder: (context, i) {
        final structure = structures[i];
        final theme = Theme.of(context);
        return ListTile(
          onTap: () => showStructureDetailSheet(context, structure.id),
          title: Text(structure.template, style: theme.textTheme.titleMedium),
          subtitle: Text('${structure.slots.length} slots',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        );
      },
    );
  }
}

class _GlueTab extends StatelessWidget {
  const _GlueTab({required this.glue});
  final List<BunkoGlueRow> glue;

  @override
  Widget build(BuildContext context) {
    if (glue.isEmpty) {
      return const _EmptyTab(
        icon: Icons.link,
        message: 'Grammar glue (particles, copula) appears here.',
      );
    }
    return ListView.separated(
      itemCount: glue.length,
      separatorBuilder: (_, _) => const Divider(height: 0.5),
      itemBuilder: (context, i) {
        final row = glue[i];
        final theme = Theme.of(context);
        return ListTile(
          title: Text(row.surface, style: theme.textTheme.titleMedium),
          subtitle: Text(glueKindLabel(row.kind),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        );
      },
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text('Nothing here yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load your Bunko", style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

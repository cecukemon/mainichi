/// Read-only detail sheet for a single Bunko word (features/bunko-browser.md).
/// Everything shown comes straight from the store, including fields the
/// browse list doesn't render (notes, meaning source, status, examples) —
/// the natural home for an "Edit" action later.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bunko_store.dart';
import '../../data/enums.dart';
import '../bunko_providers.dart';
import '../role_label.dart';

Future<void> showWordDetailSheet(BuildContext context, int id) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => WordDetailSheet(id: id),
  );
}

class WordDetailSheet extends ConsumerStatefulWidget {
  const WordDetailSheet({super.key, required this.id});
  final int id;

  @override
  ConsumerState<WordDetailSheet> createState() => _WordDetailSheetState();
}

class _WordDetailSheetState extends ConsumerState<WordDetailSheet> {
  late final Future<BunkoWordDetail?> _future =
      ref.read(bunkoStoreProvider).wordById(widget.id);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
        child: FutureBuilder<BunkoWordDetail?>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final detail = snapshot.data;
            if (detail == null) {
              return const SizedBox(
                height: 80,
                child: Center(child: Text('This entry was removed.')),
              );
            }
            return _WordDetailBody(detail: detail);
          },
        ),
      ),
    );
  }
}

class _WordDetailBody extends StatelessWidget {
  const _WordDetailBody({required this.detail});
  final BunkoWordDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = detail.word;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                word.kanji.isNotEmpty ? word.kanji : word.kana,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            _RoleChip(label: roleLabel(word.role)),
          ],
        ),
        if (word.kanji.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(word.kana,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
        const Divider(height: 32),
        _Label('MEANING'),
        const SizedBox(height: 3),
        Text(word.meaning?.isNotEmpty == true ? word.meaning! : '—',
            style: theme.textTheme.bodyLarge),
        const SizedBox(height: 14),
        _MetaRow(
          status: word.status,
          meaningSource: word.meaningSource,
          createdAt: word.createdAt,
        ),
        if (word.notes?.isNotEmpty == true) ...[
          const SizedBox(height: 14),
          _Label('NOTES'),
          const SizedBox(height: 3),
          Text(word.notes!, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 14),
        _Label('EXAMPLES'),
        const SizedBox(height: 6),
        if (detail.examples.isEmpty)
          Text('No example sentences.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
        else
          for (final example in detail.examples)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(example, style: theme.textTheme.bodyMedium),
            ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.status,
    required this.meaningSource,
    required this.createdAt,
  });
  final ItemStatus status;
  final MeaningSource meaningSource;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = [
      status == ItemStatus.approved ? 'Approved' : 'Draft',
      _meaningSourceLabel(meaningSource),
      formatBunkoDate(createdAt),
    ];
    return Text(parts.join(' · '),
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
  }
}

String _meaningSourceLabel(MeaningSource source) => switch (source) {
      MeaningSource.printedGloss => 'printed gloss',
      MeaningSource.picture => 'from picture',
      MeaningSource.inferred => 'inferred',
      MeaningSource.manual => 'manual',
      MeaningSource.none => 'no source',
    };

const List<String> _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Jul 18, 2026" — shared with [structure_detail_sheet.dart].
String formatBunkoDate(DateTime date) =>
    '${_monthAbbr[date.month - 1]} ${date.day}, ${date.year}';

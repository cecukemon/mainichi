/// Assisted fix-up for verbs captured in polite form instead of dictionary
/// (base) form — e.g. もらいます stored where もらう should be
/// (features/bunko-browser.md). Deconjugation is ambiguous (きます could be
/// くる or きる), so this always asks a human to pick, via
/// `baseFormCandidates` (lib/japanese/polite_form.dart); it never rewrites
/// silently.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bunko_store.dart';
import '../../japanese/polite_form.dart';
import '../bunko_providers.dart';

Future<void> showVerbFixupSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const VerbFixupSheet(),
  );
}

class VerbFixupSheet extends ConsumerWidget {
  const VerbFixupSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suspects = ref.watch(bunkoProvider.select((s) => s.suspectBaseForms));
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text('Fix verb base forms', style: theme.textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'These verbs look like they were captured in polite form rather '
              'than dictionary (base) form — pick the correct base, or confirm '
              'the entry was already right.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 0.5),
          Expanded(
            child: suspects.isEmpty
                ? Center(
                    child: Text('All clear — no suspect verbs.',
                        style: theme.textTheme.bodyMedium),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    itemCount: suspects.length,
                    separatorBuilder: (_, _) => const Divider(height: 28),
                    itemBuilder: (context, i) => _SuspectCard(word: suspects[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SuspectCard extends ConsumerStatefulWidget {
  const _SuspectCard({required this.word});
  final BunkoWordRow word;

  @override
  ConsumerState<_SuspectCard> createState() => _SuspectCardState();
}

class _SuspectCardState extends ConsumerState<_SuspectCard> {
  bool _editing = false;
  bool _busy = false;
  late final TextEditingController _kanaFreeText =
      TextEditingController(text: widget.word.kana);
  late final TextEditingController _kanjiFreeText =
      TextEditingController(text: widget.word.kanji);

  @override
  void dispose() {
    _kanaFreeText.dispose();
    _kanjiFreeText.dispose();
    super.dispose();
  }

  /// Chip tap: kanji is auto-transformed when possible; when the kanji field
  /// is non-empty but not suffix-strippable (irregular okurigana, kana/kanji
  /// mismatch), drop into edit mode instead of writing a guess.
  Future<void> _confirmCandidate(String kana) async {
    final word = widget.word;
    if (word.kanji.isEmpty) {
      await _confirm(kana, '');
      return;
    }
    final transformed = transformKanjiBaseForm(word.kanji, kana);
    if (transformed == null) {
      setState(() {
        _editing = true;
        _kanaFreeText.text = kana;
      });
      return;
    }
    await _confirm(kana, transformed);
  }

  Future<void> _confirm(String kana, String kanji) async {
    if (kana.isEmpty) return;
    setState(() => _busy = true);
    final result = await ref
        .read(bunkoStoreProvider)
        .fixWordBaseForm(widget.word.id, kana: kana, kanji: kanji);
    if (!mounted) return;
    await ref.read(bunkoProvider.notifier).load();
    if (!mounted) return;
    final surface = kanji.isNotEmpty ? '$kanji ($kana)' : kana;
    final message = switch (result.outcome) {
      FixWordOutcome.updated => 'Updated to $surface.',
      FixWordOutcome.merged => 'Merged into the existing $surface entry.',
      FixWordOutcome.notFound => 'This entry no longer exists.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _dismiss() async {
    setState(() => _busy = true);
    await ref.read(bunkoStoreProvider).dismissBaseFormSuspicion(widget.word.id);
    if (!mounted) return;
    await ref.read(bunkoProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = widget.word;
    final suspicion = politeFormSuspicion(word.kana);
    final candidates = baseFormCandidates(word.kana);

    return Opacity(
      opacity: _busy ? 0.5 : 1,
      child: IgnorePointer(
        ignoring: _busy,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    word.kanji.isNotEmpty
                        ? '${word.kanji} (${word.kana})'
                        : word.kana,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                _SuspicionChip(suspicion: suspicion),
              ],
            ),
            if (word.meaning?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(word.meaning!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 10),
            if (_editing) ...[
              TextField(
                controller: _kanaFreeText,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    labelText: 'Base form (kana)'),
              ),
              if (word.kanji.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _kanjiFreeText,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      labelText: 'Base form (kanji)'),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => _confirm(
                    _kanaFreeText.text.trim(),
                    _kanjiFreeText.text.trim(),
                  ),
                  child: const Text('Confirm'),
                ),
              ),
            ] else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final candidate in candidates)
                    ActionChip(
                      label: Text(candidate),
                      onPressed: () => _confirmCandidate(candidate),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.edit, size: 14),
                    label: const Text('Type it'),
                    onPressed: () => setState(() => _editing = true),
                  ),
                  if (suspicion == PoliteFormSuspicion.ambiguousMasu)
                    ActionChip(
                      avatar: const Icon(Icons.check_circle_outline, size: 14),
                      label: const Text('Keep as-is'),
                      onPressed: _dismiss,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SuspicionChip extends StatelessWidget {
  const _SuspicionChip({required this.suspicion});
  final PoliteFormSuspicion suspicion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unambiguous = suspicion == PoliteFormSuspicion.unambiguous;
    final color = unambiguous
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.tertiaryContainer;
    final onColor = unambiguous
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onTertiaryContainer;
    final label = unambiguous ? 'polite form' : 'ends in ます';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: onColor)),
    );
  }
}

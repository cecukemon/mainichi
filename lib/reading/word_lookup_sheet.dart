/// Word-tap lookup: a bottom sheet (not an inline popover, D43) with the
/// tapped word's reading, role, meaning — annotated with its grammatical form
/// when conjugated (D44) — and the dictionary form it conjugates from.
/// Everything shown comes from the vocab store, never the model (spec §10.3).
library;

import 'package:flutter/material.dart';

import '../generation/conversation_generator.dart';
import '../japanese/okurigana.dart';
import '../japanese/segmenter.dart';
import 'form_label.dart';
import 'furigana_text.dart';
import 'line_display.dart';

Future<void> showWordLookupSheet(
  BuildContext context, {
  required String surface,
  required List<FuriganaSegment> segments,
  required SeedWord entry,
  required Set<String> taughtForms,
}) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => WordLookupSheet(
      surface: surface,
      segments: segments,
      entry: entry,
      taughtForms: taughtForms,
    ),
  );
}

class WordLookupSheet extends StatelessWidget {
  const WordLookupSheet({
    super.key,
    required this.surface,
    required this.segments,
    required this.entry,
    required this.taughtForms,
  });

  final String surface;
  final List<FuriganaSegment> segments;
  final SeedWord entry;
  final Set<String> taughtForms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final form = detectTaughtForm(
      surface,
      entry: LexiconEntry(
        id: entry.id,
        kana: entry.kana,
        kanji: entry.kanji,
        role: entry.role,
      ),
      taughtForms: taughtForms,
    );
    final annotation = formAnnotation(form);
    final isConjugated = form != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FuriganaText(
                    tokens: [segments],
                    baseStyle: theme.textTheme.headlineMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entry.role.replaceAll('_', ' '),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(readingOf(segments),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const Divider(height: 32),
            Text('MEANING',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 3),
            Text.rich(
              TextSpan(
                text: entry.meaning.isEmpty ? '—' : entry.meaning,
                style: theme.textTheme.bodyLarge,
                children: [
                  if (annotation != null)
                    TextSpan(
                      text: ' · $annotation',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            if (isConjugated) ...[
              const SizedBox(height: 14),
              _DictionaryFormCard(entry: entry),
            ],
          ],
        ),
      ),
    );
  }
}

class _DictionaryFormCard extends StatelessWidget {
  const _DictionaryFormCard({required this.entry});

  final SeedWord entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = entry.kanji.isNotEmpty ? entry.kanji : entry.kana;
    final segments = furiganaSegments(
          surface: base,
          kana: entry.kana,
          kanji: entry.kanji,
          conjugates: conjugatingRoles.contains(entry.role),
        ) ??
        [FuriganaSegment(base)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(Icons.reply,
              size: 19, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DICTIONARY FORM',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FuriganaText(
                      tokens: [segments],
                      baseStyle: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(entry.kana,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

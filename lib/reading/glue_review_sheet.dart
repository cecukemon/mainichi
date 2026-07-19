/// Review sheet for a single-character backfill candidate (D56).
///
/// A single kana character behind a scope failure is almost certainly an
/// untaught particle — grammar glue, not vocabulary — so the sheet defaults
/// to a lightweight glue review: pick a kind, no meaning required, approve
/// commits a GrammarGlue row. The rare genuine single-char word is one toggle
/// away: word mode swaps in the capture flow's [VocabReviewCard] with the
/// same requirements as the multi-char backfill sheet (meaning required,
/// commits a Words row). The caller decides which commit path runs via the
/// two approve callbacks.
library;

import 'package:flutter/material.dart';

import '../capture/models.dart';
import '../capture/widgets/vocab_review_card.dart';
import '../data/enums.dart';

class GlueReviewSheet extends StatefulWidget {
  const GlueReviewSheet({
    super.key,
    required this.surface,
    required this.wordDraft,
    required this.onApproveGlue,
    required this.onApproveWord,
    required this.onSkip,
    required this.onDiscard,
  });

  final String surface;

  /// The word-mode draft (from `ScopeBackfillService.draftForSurface`), so
  /// the embedded card is identical to the multi-char backfill sheet's.
  final VocabDraftItem wordDraft;

  final void Function(GlueKind kind) onApproveGlue;
  final void Function(VocabDraftItem edited) onApproveWord;
  final VoidCallback onSkip;
  final VoidCallback onDiscard;

  @override
  State<GlueReviewSheet> createState() => _GlueReviewSheetState();
}

class _GlueReviewSheetState extends State<GlueReviewSheet> {
  GlueKind _kind = GlueKind.particle;
  bool _asWord = false;

  static const _kindLabels = {
    GlueKind.particle: 'Particle',
    GlueKind.copula: 'Copula',
    GlueKind.interjection: 'Interjection',
    GlueKind.adnominal: 'Adnominal',
    GlueKind.other: 'Other',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Did your class teach this?',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Only add it if it appeared in class — otherwise discard.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        SwitchListTile(
          value: _asWord,
          onChanged: (v) => setState(() => _asWord = v),
          title: const Text('This is a real word, not grammar'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        if (_asWord)
          Expanded(
            child: VocabReviewCard(
              item: widget.wordDraft,
              showWorksheetComparison: false,
              requireMeaning: true,
              onApprove: widget.onApproveWord,
              onSkip: widget.onSkip,
              onDiscard: widget.onDiscard,
            ),
          )
        else
          Expanded(child: _glueBody(theme)),
      ],
    );
  }

  Widget _glueBody(ThemeData theme) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(widget.surface,
                  style: theme.textTheme.displaySmall),
            ),
            const SizedBox(height: 16),
            Text('What kind of grammar?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in GlueKind.values)
                  ChoiceChip(
                    label: Text(_kindLabels[kind]!),
                    selected: _kind == kind,
                    onSelected: (_) => setState(() => _kind = kind),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => widget.onApproveGlue(_kind),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onSkip,
                    child: const Text('Skip'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: widget.onDiscard,
                child: const Text('Discard extraction'),
              ),
            ),
          ],
        ),
      );
}

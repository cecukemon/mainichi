/// Picture-derived word review card: the drawing leads, meaning is chip-
/// picked (not free text — it's a guess from a drawing, not a printed
/// gloss), and kanji defaults to "No kanji" since none was printed alongside
/// a drawing (capture-loop.md §3). Distinct from [VocabReviewCard] — see
/// the "Capture Loop - Revised Cards" design handoff, card E.
library;

import 'package:flutter/material.dart';

import '../../data/enums.dart';
import '../models.dart';
import 'worksheet_photo_box.dart';

const _noKanji = '';

class PictureWordReviewCard extends StatefulWidget {
  const PictureWordReviewCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onSkip,
    required this.onDiscard,
  });

  final VocabDraftItem item;
  final void Function(VocabDraftItem edited) onApprove;
  final VoidCallback onSkip;
  final VoidCallback onDiscard;

  @override
  State<PictureWordReviewCard> createState() => _PictureWordReviewCardState();
}

class _PictureWordReviewCardState extends State<PictureWordReviewCard> {
  late String _kanji;
  late String _kana;
  bool _typingKana = false;
  late final TextEditingController _kanaFreeText;
  late String _meaning;
  late WordRole _role;
  bool _showKanjiCandidates = false;

  @override
  void initState() {
    super.initState();
    _kanji = widget.item.kanji;
    _kana = widget.item.kana;
    _kanaFreeText = TextEditingController(text: widget.item.kana);
    _meaning = widget.item.meaning;
    _role = widget.item.role;
  }

  @override
  void dispose() {
    _kanaFreeText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final meaningOptions = {
      if (item.meaning.isNotEmpty) item.meaning,
      ...item.meaningCandidates,
    }.toList();
    final kanaOptions = item.kanaCandidates.isEmpty ? [item.kana] : item.kanaCandidates;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Chip(
            label: Text('Picture-derived · meaning inferred'),
            backgroundColor: Color(0x26FF9800),
          ),
          const SizedBox(height: 14),
          const WorksheetPhotoBox(label: 'drawing crop', height: 150),
          const SizedBox(height: 6),
          Text(
            'Drawing from the worksheet — no text gloss',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Meaning', style: Theme.of(context).textTheme.labelMedium),
              Text('pick the best fit', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in meaningOptions)
                ChoiceChip(
                  label: Text(option),
                  selected: _meaning == option,
                  onSelected: (_) => setState(() => _meaning = option),
                ),
              if (item.handwrittenGloss != null)
                ChoiceChip(
                  avatar: const Icon(Icons.sticky_note_2_outlined, size: 14),
                  label: Text('${item.handwrittenGloss} · your note'),
                  selected: _meaning == item.handwrittenGloss,
                  onSelected: (_) => setState(() => _meaning = item.handwrittenGloss!),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kana reading', style: Theme.of(context).textTheme.labelMedium),
              Text('tap to pick — no typing', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          if (_typingKana)
            TextField(
              controller: _kanaFreeText,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              onChanged: (v) => _kana = v,
            )
          else
            Wrap(
              spacing: 6,
              children: [
                for (final candidate in kanaOptions)
                  ChoiceChip(
                    label: Text(candidate),
                    selected: _kana == candidate,
                    onSelected: (_) => setState(() => _kana = candidate),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.keyboard, size: 14),
                  label: const Text('Type (rōmaji)'),
                  onPressed: () => setState(() => _typingKana = true),
                ),
              ],
            ),
          const SizedBox(height: 18),
          Text('Kanji', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              ChoiceChip(
                avatar: const Icon(Icons.block, size: 14),
                label: const Text('No kanji'),
                selected: _kanji == _noKanji,
                onSelected: (_) => setState(() => _kanji = _noKanji),
              ),
              if (_showKanjiCandidates)
                for (final candidate in item.kanjiCandidates)
                  ChoiceChip(
                    label: Text(candidate),
                    selected: _kanji == candidate,
                    onSelected: (_) => setState(() => _kanji = candidate),
                  )
              else
                ActionChip(
                  avatar: const Icon(Icons.add, size: 14),
                  label: const Text('Add from sheet'),
                  onPressed: item.kanjiCandidates.isEmpty
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No kanji was recorded for this drawing.')),
                          )
                      : () => setState(() => _showKanjiCandidates = true),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'No kanji was printed with this drawing.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Text('Role', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          DropdownButtonFormField<WordRole>(
            initialValue: _role,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            items: [
              for (final role in WordRole.values) DropdownMenuItem(value: role, child: Text(role.name)),
            ],
            onChanged: (v) => setState(() => _role = v ?? _role),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: widget.onSkip, child: const Text('Skip'))),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => widget.onApprove(
                    item.copyWith(
                      kanji: _kanji,
                      kana: _kana,
                      meaning: _meaning,
                      role: _role,
                      kanaOnly: _kanji.isEmpty,
                    ),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: widget.onDiscard,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Discard extraction'),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

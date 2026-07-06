/// Vocab (and picture-derived word) review card. Field order is fixed —
/// kanji, kana, meaning, role — kanji and meaning-for-picture-words are
/// candidate chips rather than free text (no Japanese IME assumed; see
/// capture-loop.md §3). features/review-queue-vocab-item-kanji-candidates.html,
/// features/review-queue-picture-word.html.
library;

import 'package:flutter/material.dart';

import '../../data/enums.dart';
import '../models.dart';

class VocabReviewCard extends StatefulWidget {
  const VocabReviewCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onSkip,
  });

  final VocabDraftItem item;
  final void Function(VocabDraftItem edited) onApprove;
  final VoidCallback onSkip;

  @override
  State<VocabReviewCard> createState() => _VocabReviewCardState();
}

const _noKanji = '';

class _VocabReviewCardState extends State<VocabReviewCard> {
  late String _kanji;
  late final TextEditingController _kanjiFreeText;
  late final TextEditingController _kana;
  late final TextEditingController _meaning;
  late WordRole _role;

  @override
  void initState() {
    super.initState();
    _kanji = widget.item.kanji;
    _kanjiFreeText = TextEditingController(text: widget.item.kanji);
    _kana = TextEditingController(text: widget.item.kana);
    _meaning = TextEditingController(text: widget.item.meaning);
    _role = widget.item.role;
  }

  @override
  void dispose() {
    _kanjiFreeText.dispose();
    _kana.dispose();
    _meaning.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final meaningOptions = {
      if (item.meaning.isNotEmpty) item.meaning,
      ...item.meaningCandidates,
      if (item.handwrittenGloss != null) item.handwrittenGloss!,
    }.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            label: Text(item.isPictureDerived
                ? 'Picture-derived — meaning inferred'
                : 'Vocabulary — low confidence'),
            backgroundColor: Colors.orange.withValues(alpha: 0.15),
          ),
          if (item.isPictureDerived) ...[
            const SizedBox(height: 12),
            Container(
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_outlined, size: 30, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Drawing from the worksheet — no text gloss',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Text('Kanji', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          if (item.kanjiCandidates.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Read from worksheet', style: Theme.of(context).textTheme.bodySmall),
                      Text(item.kanjiCandidates.first, style: const TextStyle(fontSize: 20)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final candidate in item.kanjiCandidates)
                  ChoiceChip(
                    label: Text(candidate),
                    selected: _kanji == candidate,
                    onSelected: (_) => setState(() => _kanji = candidate),
                  ),
                ChoiceChip(
                  avatar: const Icon(Icons.block, size: 14),
                  label: const Text('No kanji'),
                  selected: _kanji == _noKanji,
                  onSelected: (_) => setState(() => _kanji = _noKanji),
                ),
              ],
            ),
          ] else
            TextField(
              controller: _kanjiFreeText,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              onChanged: (v) => _kanji = v,
            ),
          const SizedBox(height: 16),
          Text('Kana reading', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          TextField(controller: _kana, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 16),
          Text('Meaning', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          TextField(controller: _meaning, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
          if (meaningOptions.length > 1) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final option in meaningOptions)
                  ChoiceChip(
                    avatar: (item.handwrittenGloss == option) ? const Icon(Icons.sticky_note_2_outlined, size: 14) : null,
                    label: Text(option),
                    selected: _meaning.text == option,
                    onSelected: (_) => setState(() => _meaning.text = option),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
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
                    item.copyWith(kanji: _kanji, kana: _kana.text, meaning: _meaning.text, role: _role),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

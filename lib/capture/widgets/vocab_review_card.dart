/// Vocab (and picture-derived word) review card. Field order is fixed —
/// kanji, kana, meaning, role — kanji and meaning-for-picture-words are
/// candidate chips rather than free text (no Japanese IME assumed; see
/// capture-loop.md §3). features/review-queue-vocab-item-kanji-candidates.html,
/// features/review-queue-picture-word.html.
library;

import 'package:flutter/material.dart';

import '../../data/enums.dart';
import '../models.dart';
import 'worksheet_photo_box.dart';

class VocabReviewCard extends StatefulWidget {
  const VocabReviewCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onSkip,
    required this.onDiscard,
    this.showWorksheetComparison = true,
    this.requireMeaning = false,
  });

  final VocabDraftItem item;
  final void Function(VocabDraftItem edited) onApprove;
  final VoidCallback onSkip;
  final VoidCallback onDiscard;

  /// Whether to show the source-crop comparison box. True in the capture
  /// queue; false when the card reviews a word with no worksheet behind it
  /// (the reading screen's Bunko backfill, D52).
  final bool showWorksheetComparison;

  /// When true, Approve is disabled until the meaning field is non-empty —
  /// used by the backfill flow, where nothing pre-fills the meaning and a
  /// blank one would degrade the lookup sheet.
  final bool requireMeaning;

  @override
  State<VocabReviewCard> createState() => _VocabReviewCardState();
}

const _noKanji = '';

class _VocabReviewCardState extends State<VocabReviewCard> {
  late String _kanji;
  late final TextEditingController _kanjiFreeText;
  late String _kana;
  bool _typingKana = false;
  late final TextEditingController _kanaFreeText;
  late final TextEditingController _meaning;
  late WordRole _role;

  @override
  void initState() {
    super.initState();
    _kanji = widget.item.kanji;
    _kanjiFreeText = TextEditingController(text: widget.item.kanji);
    _kana = widget.item.kana;
    _kanaFreeText = TextEditingController(text: widget.item.kana);
    _meaning = TextEditingController(text: widget.item.meaning);
    if (widget.requireMeaning) {
      // Approve's enabled state tracks the field; rebuild on every edit.
      _meaning.addListener(() => setState(() {}));
    }
    _role = widget.item.role;
  }

  @override
  void dispose() {
    _kanjiFreeText.dispose();
    _kanaFreeText.dispose();
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
    final kanaOptions = item.kanaCandidates.isEmpty ? [item.kana] : item.kanaCandidates;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Chip(
            label: Text('Vocabulary — low confidence'),
            backgroundColor: Color(0x26FF9800),
          ),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(item.notes, style: Theme.of(context).textTheme.bodySmall)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (widget.showWorksheetComparison) ...[
            Text('Compare with the worksheet', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            WorksheetPhotoBox(
              label: '${item.kanji.isNotEmpty ? item.kanji : item.kana} · source crop',
            ),
            const SizedBox(height: 16),
          ],
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
                  onPressed: widget.requireMeaning && _meaning.text.trim().isEmpty
                      ? null
                      : () => widget.onApprove(
                            item.copyWith(kanji: _kanji, kana: _kana, meaning: _meaning.text, role: _role),
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

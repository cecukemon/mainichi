/// Template review card: sentence with colored inline slot tokens, one
/// role/form dropdown pair per slot (features/review-queue-template-item.html).
library;

import 'package:flutter/material.dart';

import '../../data/enums.dart';
import '../models.dart';

const _slotColors = [Colors.blue, Colors.purple, Colors.teal, Colors.brown];

class TemplateReviewCard extends StatefulWidget {
  const TemplateReviewCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onSkip,
  });

  final TemplateDraftItem item;
  final void Function(TemplateDraftItem edited) onApprove;
  final VoidCallback onSkip;

  @override
  State<TemplateReviewCard> createState() => _TemplateReviewCardState();
}

class _TemplateReviewCardState extends State<TemplateReviewCard> {
  late List<SlotDraft> _slots;

  @override
  void initState() {
    super.initState();
    _slots = List.of(widget.item.slots);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            label: const Text('Template — slot guess'),
            backgroundColor: Colors.orange.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text('Sentence', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _renderSentence(context),
          ),
          const SizedBox(height: 16),
          Text('Slots', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < _slots.length; i++) _SlotEditor(
            slot: _slots[i],
            color: _slotColors[i % _slotColors.length],
            onChanged: (updated) => setState(() => _slots[i] = updated),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: widget.onSkip, child: const Text('Skip'))),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => widget.onApprove(widget.item.copyWith(slots: _slots)),
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

  /// Splits the template on `{slot_name}` placeholders and renders each as a
  /// colored token matching its slot editor below.
  Widget _renderSentence(BuildContext context) {
    final spans = <InlineSpan>[];
    var slotIndex = 0;
    final pattern = RegExp(r'\{[^}]+\}');
    var cursor = 0;
    for (final match in pattern.allMatches(widget.item.template)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: widget.item.template.substring(cursor, match.start)));
      }
      final color = _slotColors[slotIndex % _slotColors.length];
      spans.add(
        WidgetSpan(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(4)),
            child: Text(
              _slots.length > slotIndex ? '{${_slots[slotIndex].name}}' : match.group(0)!,
              style: TextStyle(color: color, fontSize: 18),
            ),
          ),
        ),
      );
      slotIndex++;
      cursor = match.end;
    }
    if (cursor < widget.item.template.length) {
      spans.add(TextSpan(text: widget.item.template.substring(cursor)));
    }
    return RichText(text: TextSpan(style: const TextStyle(fontSize: 18, color: Colors.black87), children: spans));
  }
}

class _SlotEditor extends StatelessWidget {
  const _SlotEditor({required this.slot, required this.color, required this.onChanged});

  final SlotDraft slot;
  final Color color;
  final void Function(SlotDraft updated) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(4)),
            child: Text('{${slot.name}}', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<WordRole>(
                  initialValue: slot.role,
                  decoration: const InputDecoration(labelText: 'Role', isDense: true, border: OutlineInputBorder()),
                  items: [for (final r in WordRole.values) DropdownMenuItem(value: r, child: Text(r.name))],
                  onChanged: (v) => onChanged(slot.copyWith(role: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<SlotForm>(
                  initialValue: slot.form,
                  decoration: const InputDecoration(labelText: 'Form', isDense: true, border: OutlineInputBorder()),
                  items: [for (final f in SlotForm.values) DropdownMenuItem(value: f, child: Text(f.name))],
                  onChanged: (v) => onChanged(slot.copyWith(form: v)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

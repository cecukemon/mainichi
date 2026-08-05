/// Read-only detail sheet for a single Bunko sentence structure
/// (features/bunko-browser.md): template, its typed slots, notes, status,
/// and example sentences.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bunko_store.dart';
import '../../data/enums.dart';
import '../bunko_providers.dart';
import '../role_label.dart';
import 'word_detail_sheet.dart' show formatBunkoDate;

Future<void> showStructureDetailSheet(BuildContext context, int id) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => StructureDetailSheet(id: id),
  );
}

class StructureDetailSheet extends ConsumerStatefulWidget {
  const StructureDetailSheet({super.key, required this.id});
  final int id;

  @override
  ConsumerState<StructureDetailSheet> createState() =>
      _StructureDetailSheetState();
}

class _StructureDetailSheetState extends ConsumerState<StructureDetailSheet> {
  late final Future<BunkoStructureDetail?> _future =
      ref.read(bunkoStoreProvider).structureById(widget.id);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
        child: FutureBuilder<BunkoStructureDetail?>(
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
            return _StructureDetailBody(detail: detail);
          },
        ),
      ),
    );
  }
}

class _StructureDetailBody extends StatelessWidget {
  const _StructureDetailBody({required this.detail});
  final BunkoStructureDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final structure = detail.structure;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(structure.template, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          [
            structure.status == ItemStatus.approved ? 'Approved' : 'Draft',
            formatBunkoDate(structure.createdAt),
          ].join(' · '),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const Divider(height: 32),
        _Label('SLOTS'),
        const SizedBox(height: 6),
        if (structure.slots.isEmpty)
          Text('No slots.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
        else
          for (final slot in structure.slots)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '{${slot.name}} — ${roleLabel(slot.role)}, ${_slotFormLabel(slot.form)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
        if (structure.notes?.isNotEmpty == true) ...[
          const SizedBox(height: 14),
          _Label('NOTES'),
          const SizedBox(height: 3),
          Text(structure.notes!, style: theme.textTheme.bodyMedium),
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

String _slotFormLabel(SlotForm form) => switch (form) {
      SlotForm.dictionary => 'dictionary form',
      SlotForm.negative => 'negative',
      SlotForm.polite => 'polite',
      SlotForm.politeNegative => 'polite negative',
      SlotForm.past => 'past',
      SlotForm.te => 'te-form',
    };

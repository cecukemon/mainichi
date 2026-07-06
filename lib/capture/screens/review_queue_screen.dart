/// The focused review queue: one flagged item at a time (capture-loop.md §2
/// step 3). Dispatches to the vocab/template/dedup card per [QueueRef.type].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capture_providers.dart';
import '../models.dart';
import '../widgets/dedup_review_card.dart';
import '../widgets/template_review_card.dart';
import '../widgets/vocab_review_card.dart';
import 'commit_screen.dart';

class ReviewQueueScreen extends ConsumerWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(captureQueueProvider);
    final notifier = ref.read(captureQueueProvider.notifier);
    final draft = state.draft!;
    final currentRef = state.currentRef;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => Navigator.of(context).pop()),
        title: Text(currentRef == null ? 'Queue complete' : 'Item ${state.resolvedRefs.length + state.skippedRefs.length + 1} of ${state.order.length}'),
        actions: [
          if (state.skippedCount > 0)
            TextButton(
              onPressed: () => _showSkipped(context, notifier, state),
              child: Text('Skipped (${state.skippedCount})'),
            ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: state.order.isEmpty
                ? 1
                : (state.resolvedRefs.length + state.skippedRefs.length) / state.order.length,
          ),
          Expanded(
            child: currentRef == null
                ? Center(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const CommitScreen()),
                      ),
                      child: const Text('Continue to commit'),
                    ),
                  )
                : KeyedSubtree(
                    key: ValueKey(currentRef),
                    child: _buildCard(currentRef, draft, notifier),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(QueueRef ref, CaptureDraft draft, CaptureQueueNotifier notifier) {
    switch (ref.type) {
      case QueueItemType.dedup:
        return DedupReviewCard(
          item: draft.vocabulary[ref.index],
          onMerge: notifier.mergeCurrentDedup,
          onNotAMatch: notifier.notAMatchCurrentDedup,
          onSkip: notifier.skipCurrent,
        );
      case QueueItemType.vocab:
        return VocabReviewCard(
          item: draft.vocabulary[ref.index],
          onApprove: notifier.approveCurrentVocab,
          onSkip: notifier.skipCurrent,
        );
      case QueueItemType.template:
        return TemplateReviewCard(
          item: draft.templates[ref.index],
          onApprove: notifier.approveCurrentTemplate,
          onSkip: notifier.skipCurrent,
        );
    }
  }

  void _showSkipped(BuildContext context, CaptureQueueNotifier notifier, CaptureQueueState state) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: [
          for (final skippedRef in state.skippedRefs)
            ListTile(
              title: Text(_labelFor(skippedRef, state)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                notifier.reopen(skippedRef);
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    );
  }

  String _labelFor(QueueRef ref, CaptureQueueState state) {
    switch (ref.type) {
      case QueueItemType.dedup:
      case QueueItemType.vocab:
        final item = state.draft!.vocabulary[ref.index];
        return item.kanji.isNotEmpty ? '${item.kanji} (${item.kana})' : item.kana;
      case QueueItemType.template:
        return state.draft!.templates[ref.index].template;
    }
  }
}

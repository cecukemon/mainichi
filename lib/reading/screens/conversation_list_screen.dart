/// The conversation-list screen (features/conversation-list.md): a browsable,
/// newest-first list of cached conversations. Tapping a row opens it in the
/// reading exercise; swiping a row away deletes it (with snackbar-undo).
/// Replaces the home screen's blind LRU "Re-read a previous one" jump.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/conversation_cache.dart';
import '../conversation_list.dart';
import '../reading_providers.dart' show ReadingStart;
import 'reading_exercise_screen.dart';

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  void _open(BuildContext context, WidgetRef ref, ConversationSummary row) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => ReadingExerciseScreen(
            start: ReadingStart.conversation,
            conversationId: row.id,
          ),
        ))
        // Reading it stamps lastPracticedAt — reload on return so the row's
        // "practiced" line reflects the visit.
        .then((_) {
      if (context.mounted) ref.read(conversationListProvider.notifier).load();
    });
  }

  void _startReading(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ReadingExerciseScreen(start: ReadingStart.generate),
    ));
  }

  /// Optimistic delete + snackbar undo. The row is already out of the list
  /// (the notifier dropped it); the real DB/disk removal fires only when the
  /// undo window closes without an undo.
  void _delete(BuildContext context, WidgetRef ref, ConversationSummary row) {
    final notifier = ref.read(conversationListProvider.notifier);
    final removed = notifier.takeOut(row.id);
    if (removed == null) return;

    final messenger = ScaffoldMessenger.of(context);
    var undone = false;
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${_titleOf(row)}"',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            undone = true;
            notifier.putBack(removed.row, removed.index);
          },
        ),
      ),
    );
    controller.closed.then((_) {
      if (!undone) notifier.commitDelete(row.id);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Past conversations')),
      body: Builder(
        builder: (context) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error) {
            return _ErrorView(
                onRetry: () =>
                    ref.read(conversationListProvider.notifier).load());
          }
          if (state.isEmpty) {
            return _EmptyView(onStart: () => _startReading(context));
          }
          return ListView.separated(
            itemCount: state.rows.length,
            separatorBuilder: (_, _) => const Divider(height: 0.5),
            itemBuilder: (context, i) {
              final row = state.rows[i];
              return Dismissible(
                key: ValueKey(row.id),
                direction: DismissDirection.endToStart,
                background: const _DeleteBackground(),
                onDismissed: (_) => _delete(context, ref, row),
                child: _ConversationRow(
                  row: row,
                  onTap: () => _open(context, ref, row),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _titleOf(ConversationSummary row) =>
    row.title.isEmpty ? 'Untitled conversation' : row.title;

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.row, required this.onTap});

  final ConversationSummary row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      title: Text(
        _titleOf(row),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          conversationMetaLine(row),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
      trailing: Icon(Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.error,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: theme.colorScheme.onError),
          const SizedBox(height: 2),
          Text('Delete',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onError)),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.menu_book_outlined,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text('Nothing here yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Conversations you read are saved automatically.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Start reading practice'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load your conversations",
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

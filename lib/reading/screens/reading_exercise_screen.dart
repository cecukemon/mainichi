/// The reading exercise (spec §5, features/reading-exercise.md): a continuous
/// feed of generated conversations rendered script-style — speaker name in a
/// fixed left margin column, furigana over vocab tokens, tap a word for the
/// lookup sheet. Replaces the furigana-preview spike screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generation/conversation_generator.dart';
import '../furigana_text.dart';
import '../line_display.dart';
import '../reading_providers.dart';
import '../word_lookup_sheet.dart';

class ReadingExerciseScreen extends ConsumerStatefulWidget {
  const ReadingExerciseScreen({super.key});

  @override
  ConsumerState<ReadingExerciseScreen> createState() =>
      _ReadingExerciseScreenState();
}

class _ReadingExerciseScreenState extends ConsumerState<ReadingExerciseScreen> {
  bool _showFurigana = true; // default on (spec §4)

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(readingSessionProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Exit',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Reading'),
        actions: [
          const Text('ふりがな'),
          Switch(
            value: _showFurigana,
            onChanged: (v) => setState(() => _showFurigana = v),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: switch (session.phase) {
        ReadingPhase.loading => const _LoadingView(),
        ReadingPhase.error => _ErrorView(
            message: session.errorMessage,
            hasCachedFallback: session.hasCachedFallback,
          ),
        ReadingPhase.ready => _ConversationView(
            conversation: session.conversation!,
            seed: session.seed!,
            taughtForms: session.taughtForms,
            showFurigana: _showFurigana,
          ),
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Generating a conversation…',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            "Composing from the words you've learned",
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.message, required this.hasCachedFallback});

  final String message;
  final bool hasCachedFallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't generate that one",
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  ref.read(readingSessionProvider.notifier).loadNext(),
              child: const Text('Try again'),
            ),
            if (hasCachedFallback) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () =>
                    ref.read(readingSessionProvider.notifier).readCached(),
                child: const Text('Reread an earlier one'),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Exit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationView extends ConsumerWidget {
  const _ConversationView({
    required this.conversation,
    required this.seed,
    required this.taughtForms,
    required this.showFurigana,
  });

  final GeneratedConversation conversation;
  final GenerationSeed seed;
  final Set<String> taughtForms;
  final bool showFurigana;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            children: [
              for (final line in conversation.lines)
                _LineRow(
                  line: line,
                  seed: seed,
                  taughtForms: taughtForms,
                  showFurigana: showFurigana,
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  showFurigana
                      ? 'Tap any word to look it up'
                      : "Furigana hidden — tap a word if it hasn't stuck",
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        ref.read(readingSessionProvider.notifier).loadNext(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Next'),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.seed,
    required this.taughtForms,
    required this.showFurigana,
  });

  final GenLine line;
  final GenerationSeed seed;
  final Set<String> taughtForms;
  final bool showFurigana;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = displayTokens(line, seed);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speaker margin column (D43: book-marginalia, not "Name: line").
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 22, right: 4),
              child: Text(
                line.speakerSurface,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                for (final token in tokens)
                  _TokenView(
                    token: token,
                    taughtForms: taughtForms,
                    showFurigana: showFurigana,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenView extends StatelessWidget {
  const _TokenView({
    required this.token,
    required this.taughtForms,
    required this.showFurigana,
  });

  final DisplayToken token;
  final Set<String> taughtForms;
  final bool showFurigana;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = FuriganaText(
      tokens: [token.segments],
      showFurigana: showFurigana,
      baseStyle: theme.textTheme.titleLarge?.copyWith(height: 1.5),
    );
    if (!token.isTappable) return text;

    return GestureDetector(
      onTap: () => showWordLookupSheet(
        context,
        surface: token.surface,
        segments: token.segments,
        entry: token.entry!,
        taughtForms: taughtForms,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
        ),
        child: text,
      ),
    );
  }
}

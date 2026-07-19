/// The reading exercise (spec §5, features/reading-exercise.md): a continuous
/// feed of generated conversations rendered script-style — speaker name in a
/// fixed left margin column, furigana over vocab tokens, tap a word for the
/// lookup sheet. Replaces the furigana-preview spike screen.
///
/// Also carries the listening layer (features/listening-exercise.md): a
/// player row (play/stop, speed), per-line replay in the speaker margin, and
/// a blur-the-text listening mode. Audio never autoplays.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capture/widgets/vocab_review_card.dart';
import '../../generation/conversation_generator.dart';
import '../../listening/line_audio.dart';
import '../../listening/listening_providers.dart';
import '../../listening/playback_controller.dart';
import '../furigana_text.dart';
import '../glue_review_sheet.dart';
import '../line_display.dart';
import '../reading_providers.dart';
import '../word_lookup_sheet.dart';

class ReadingExerciseScreen extends ConsumerStatefulWidget {
  const ReadingExerciseScreen({super.key, this.start = ReadingStart.generate});

  /// Whether the session opens by generating a fresh conversation or by
  /// rereading a cached one — chosen at the home screen's two entrypoints.
  final ReadingStart start;

  @override
  ConsumerState<ReadingExerciseScreen> createState() =>
      _ReadingExerciseScreenState();
}

class _ReadingExerciseScreenState extends ConsumerState<ReadingExerciseScreen> {
  bool _showFurigana = true; // default on (spec §4)

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(readingSessionProvider(widget.start));

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
            start: widget.start,
            message: session.errorMessage,
            hasCachedFallback: session.hasCachedFallback,
            candidates: session.candidates,
          ),
        // Keyed per conversation so the audio controller and blur state
        // reset with each new one (identity fallback: id is null when the
        // cache write failed).
        ReadingPhase.ready => _ConversationView(
            key: ValueKey(session.conversationId ??
                identityHashCode(session.conversation)),
            start: widget.start,
            conversation: session.conversation!,
            seed: session.seed!,
            conversationId: session.conversationId,
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
  const _ErrorView({
    required this.start,
    required this.message,
    required this.hasCachedFallback,
    this.candidates = const [],
  });

  final ReadingStart start;
  final String message;
  final bool hasCachedFallback;

  /// Word-shaped unmatched surfaces from the scope failure — the Bunko
  /// backfill affordance (D52). Empty on non-scope errors.
  final List<String> candidates;

  /// The backfill review sheet: the capture flow's card, reframed for a word
  /// with no worksheet behind it. Approve requires a meaning; discard is the
  /// answer when the class never taught the word. A single-character surface
  /// is almost certainly a particle, so it gets the glue-flavored sheet
  /// instead (D56) — same framing, defaulting to a GrammarGlue commit, with
  /// the word card one toggle away.
  void _openBackfillSheet(BuildContext context, WidgetRef ref, String surface) {
    final notifier = ref.read(readingSessionProvider(start).notifier);
    final draft =
        ref.read(scopeBackfillProvider).draftForSurface(surface);
    final isSingleChar = surface.runes.length == 1;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        // Keep the card's fields above the keyboard.
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.75,
          child: isSingleChar
              ? GlueReviewSheet(
                  surface: surface,
                  wordDraft: draft,
                  onApproveGlue: (kind) {
                    Navigator.of(sheetContext).pop();
                    notifier.addGlueToBunko(surface, kind);
                  },
                  onApproveWord: (edited) {
                    Navigator.of(sheetContext).pop();
                    notifier.addCandidateToBunko(edited, surface);
                  },
                  onSkip: () => Navigator.of(sheetContext).pop(),
                  onDiscard: () {
                    Navigator.of(sheetContext).pop();
                    notifier.dismissCandidate(surface);
                  },
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Did your class teach this?',
                              style:
                                  Theme.of(sheetContext).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Only add it if it appeared in class — otherwise discard.',
                            style: Theme.of(sheetContext)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(sheetContext)
                                        .colorScheme
                                        .onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: VocabReviewCard(
                        item: draft,
                        showWorksheetComparison: false,
                        requireMeaning: true,
                        onApprove: (edited) {
                          Navigator.of(sheetContext).pop();
                          notifier.addCandidateToBunko(edited, surface);
                        },
                        onSkip: () => Navigator.of(sheetContext).pop(),
                        onDiscard: () {
                          Navigator.of(sheetContext).pop();
                          notifier.dismissCandidate(surface);
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

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
            if (candidates.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Missing from your Bunko?',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                'Add a word only if your class taught it.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final surface in candidates)
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: Text(surface),
                      onPressed: () =>
                          _openBackfillSheet(context, ref, surface),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  ref.read(readingSessionProvider(start).notifier).loadNext(),
              child: const Text('Try again'),
            ),
            if (hasCachedFallback) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref
                    .read(readingSessionProvider(start).notifier)
                    .readCached(),
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

class _ConversationView extends ConsumerStatefulWidget {
  const _ConversationView({
    super.key,
    required this.start,
    required this.conversation,
    required this.seed,
    required this.conversationId,
    required this.taughtForms,
    required this.showFurigana,
  });

  final ReadingStart start;
  final GeneratedConversation conversation;
  final GenerationSeed seed;

  /// Null when the cache write failed — reading works, audio is unavailable.
  final int? conversationId;

  final Set<String> taughtForms;
  final bool showFurigana;

  @override
  ConsumerState<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends ConsumerState<_ConversationView> {
  ListeningController? _audio;
  bool _blurred = false;

  @override
  void initState() {
    super.initState();
    final id = widget.conversationId;
    if (id != null) {
      _audio = ListeningController(
        audioStore: ref.read(conversationAudioStoreProvider),
        player: ref.read(lineAudioPlayerFactoryProvider)(),
        conversationId: id,
        lines: lineAudioSpecs(widget.conversation, widget.seed),
      );
    }
  }

  @override
  void dispose() {
    _audio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = _audio;
    if (audio == null) return _buildBody(context, null);
    // The body must be constructed inside the builder — a prebuilt widget
    // instance would be seen as unchanged and never repainted on notify.
    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) => _buildBody(context, audio),
    );
  }

  Widget _buildBody(BuildContext context, ListeningController? audio) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (audio != null)
          _AudioBar(
            controller: audio,
            blurred: _blurred,
            onToggleBlur: () => setState(() => _blurred = !_blurred),
          ),
        Expanded(child: _buildLines(audio)),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _blurred
                      ? 'Listening mode — tap the text to reveal it'
                      : widget.showFurigana
                          ? 'Tap any word to look it up'
                          : "Furigana hidden — tap a word if it hasn't stuck",
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    // In reread mode, Next stays in the cache (rotating to the
                    // next least-recently-practiced one) rather than generating
                    // — the whole point of that entrypoint.
                    onPressed: () {
                      final notifier =
                          ref.read(readingSessionProvider(widget.start).notifier);
                      switch (widget.start) {
                        case ReadingStart.generate:
                          notifier.loadNext();
                        case ReadingStart.reread:
                          notifier.readCached();
                      }
                    },
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

  Widget _buildLines(ListeningController? audio) {
    final listView = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: [
        for (final (index, line) in widget.conversation.lines.indexed)
          _LineRow(
            line: line,
            seed: widget.seed,
            taughtForms: widget.taughtForms,
            showFurigana: widget.showFurigana,
            isCurrent: audio?.currentLine == index &&
                audio?.status == AudioStatus.playing,
            onReplay: audio == null ? null : () => audio.playLine(index),
          ),
      ],
    );
    if (!_blurred) return listView;

    // Listening mode: the whole list is blurred and inert (word taps and
    // line replays included) — playback runs from the audio bar. Tap
    // anywhere on the text to reveal it.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _blurred = false),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: IgnorePointer(child: listView),
      ),
    );
  }
}

/// The player row: play/stop, speed (client-side rate, D50), listening-mode
/// toggle. Inline error text on synthesis failure — reading is unaffected.
class _AudioBar extends StatelessWidget {
  const _AudioBar({
    required this.controller,
    required this.blurred,
    required this.onToggleBlur,
  });

  final ListeningController controller;
  final bool blurred;
  final VoidCallback onToggleBlur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (controller.status == AudioStatus.preparing)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (controller.status == AudioStatus.playing)
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined, size: 30),
                  tooltip: 'Stop',
                  onPressed: controller.stop,
                )
              else
                IconButton(
                  icon: const Icon(Icons.play_circle_outlined, size: 30),
                  tooltip: 'Play',
                  onPressed: controller.playAll,
                ),
              const SizedBox(width: 4),
              SegmentedButton<double>(
                segments: [
                  for (final s in listeningSpeeds)
                    ButtonSegment(
                      value: s,
                      label: Text(s == 1.0 ? '1×' : '$s×'),
                    ),
                ],
                selected: {controller.speed},
                onSelectionChanged: (v) => controller.setSpeed(v.single),
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                    blurred ? Icons.visibility_outlined : Icons.hearing_outlined),
                tooltip: blurred ? 'Show text' : 'Listening mode (hide text)',
                isSelected: blurred,
                onPressed: onToggleBlur,
              ),
            ],
          ),
          if (controller.status == AudioStatus.error)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                '${controller.errorMessage} Tap play to retry.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          const Divider(height: 8),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.seed,
    required this.taughtForms,
    required this.showFurigana,
    this.isCurrent = false,
    this.onReplay,
  });

  final GenLine line;
  final GenerationSeed seed;
  final Set<String> taughtForms;
  final bool showFurigana;

  /// Whether this line is the one currently sounding — highlights the row.
  final bool isCurrent;

  /// Replays this line's audio (the rewind control, D50). Null when the
  /// conversation has no audio layer.
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = displayTokens(line, seed);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speaker margin column (D43: book-marginalia, not "Name: line"),
          // with the per-line replay affordance beneath the name.
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 22, right: 4),
                  child: Text(
                    line.speakerSurface,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                if (onReplay != null)
                  IconButton(
                    icon: const Icon(Icons.replay, size: 16),
                    tooltip: 'Play this line',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    color: theme.colorScheme.onSurfaceVariant,
                    onPressed: onReplay,
                  ),
              ],
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

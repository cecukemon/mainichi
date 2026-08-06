/// The reading exercise (spec §5, features/reading-exercise.md): a continuous
/// feed of generated conversations rendered script-style — speaker name in a
/// fixed left margin column, furigana over vocab tokens, tap a word for the
/// lookup sheet. Replaces the furigana-preview spike screen.
///
/// Also carries the listening layer (features/listening-exercise.md): a
/// player row (play/stop, speed), per-line replay in the speaker margin, and
/// a blur-the-text listening mode. Audio never autoplays. Shadowing mode
/// (D63, features/speaking-exercise.md §2) rides on the same player row:
/// playback holds after each line — "Your turn" — until the learner taps on.
/// The hold also carries an optional "Check me" grading step (D73): record
/// the held line, check it against Google STT, see the verdict — folded in
/// from what used to be a standalone read-aloud mode.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capture/widgets/vocab_review_card.dart';
import '../../generation/conversation_generator.dart';
import '../../listening/line_audio.dart';
import '../../listening/listening_providers.dart';
import '../../listening/playback_controller.dart';
import '../../speaking/read_aloud_controller.dart';
import '../../speaking/read_aloud_grader.dart';
import '../../speaking/speaking_providers.dart';
import '../furigana_text.dart';
import '../glue_review_sheet.dart';
import '../line_display.dart';
import '../reading_providers.dart';
import '../word_lookup_sheet.dart';

class ReadingExerciseScreen extends ConsumerStatefulWidget {
  const ReadingExerciseScreen({
    super.key,
    this.start = ReadingStart.generate,
    this.conversationId,
  }) : assert(start != ReadingStart.conversation || conversationId != null,
            'ReadingStart.conversation needs a conversationId');

  /// How the session opens: generate a fresh conversation, reread the
  /// least-recently-practiced cached one, or open the specific cached
  /// [conversationId] picked from the conversation list.
  final ReadingStart start;

  /// The cached row to open, when [start] is [ReadingStart.conversation].
  final int? conversationId;

  @override
  ConsumerState<ReadingExerciseScreen> createState() =>
      _ReadingExerciseScreenState();
}

class _ReadingExerciseScreenState extends ConsumerState<ReadingExerciseScreen> {
  bool _showFurigana = true; // default on (spec §4)

  ReadingRequest get _request =>
      (start: widget.start, conversationId: widget.conversationId);

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(readingSessionProvider(_request));

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
            request: _request,
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
            request: _request,
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
    required this.request,
    required this.message,
    required this.hasCachedFallback,
    this.candidates = const [],
  });

  final ReadingRequest request;
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
    final notifier = ref.read(readingSessionProvider(request).notifier);
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
                  ref.read(readingSessionProvider(request).notifier).loadNext(),
              child: const Text('Try again'),
            ),
            if (hasCachedFallback) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref
                    .read(readingSessionProvider(request).notifier)
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
    required this.request,
    required this.conversation,
    required this.seed,
    required this.conversationId,
    required this.taughtForms,
    required this.showFurigana,
  });

  final ReadingRequest request;
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
  ReadAloudController? _readAloud;
  bool _blurred = false;

  /// One key per line so the active line can be scrolled into view.
  late final List<GlobalKey> _lineKeys;

  /// Drives the conversation list, so a far jump (e.g. back to the top for a
  /// new pass) can land near the target even when its render object has been
  /// recycled and [Scrollable.ensureVisible] alone can't reach it.
  final ScrollController _scrollController = ScrollController();

  /// The line last scrolled to, so a rebuild doesn't re-scroll the same line
  /// mid-recording; reset to null when nothing is active so re-selecting the
  /// same line scrolls again.
  int? _scrolledForLine;

  @override
  void initState() {
    super.initState();
    _lineKeys =
        [for (final _ in widget.conversation.lines) GlobalKey()];
    final id = widget.conversationId;
    if (id != null) {
      _audio = ListeningController(
        audioStore: ref.read(conversationAudioStoreProvider),
        player: ref.read(lineAudioPlayerFactoryProvider)(),
        conversationId: id,
        lines: lineAudioSpecs(widget.conversation, widget.seed),
      );
      // Grades against each line's written text (orthography, not kana — see
      // read_aloud_grader.dart). Gated on the same conversationId as audio:
      // "Check me" only exists inside the shadowing hold on the player row.
      _readAloud = ReadAloudController(
        recorder: ref.read(speechRecorderFactoryProvider)(),
        stt: ref.read(sttServiceProvider),
        expectedLines: [for (final l in widget.conversation.lines) l.text],
      );
    }
  }

  /// The line currently highlighted: the line sounding during playback or
  /// held for shadowing (also highlighted, if blurred, in listening mode).
  /// Null when nothing is highlighted.
  int? _activeLine(ListeningController? audio) {
    if (audio != null &&
        (audio.status == AudioStatus.playing ||
            audio.status == AudioStatus.awaitingRepeat)) {
      return audio.currentLine;
    }
    return null;
  }

  /// Scrolls the highlighted line into view when it changes, so the line
  /// being read or heard (and, during a "Check me" grade, its verdict just
  /// below) stays visible even when it started below the fold. A post-frame
  /// callback because the scroll must run after the line has laid out.
  void _maybeScrollToActiveLine(int? activeLine) {
    if (activeLine == null) {
      _scrolledForLine = null;
      return;
    }
    if (activeLine == _scrolledForLine) return;
    _scrolledForLine = activeLine;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollLineIntoView(activeLine, allowJump: true);
    });
  }

  /// Brings [line] into view. Prefers [Scrollable.ensureVisible] for a precise
  /// animated scroll, which only works while the line's render object is live.
  /// When it isn't — the line sits far outside the list's cache extent, e.g.
  /// jumping from the last line back to the first for a new pass — [allowJump]
  /// lets us estimate its offset, jump close so it builds, then refine on the
  /// next frame.
  void _scrollLineIntoView(int line, {required bool allowJump}) {
    final ctx = _lineKeys[line].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        // Upper third, leaving room below for the verdict/transcript block.
        alignment: 0.3,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    if (!allowJump || !_scrollController.hasClients || _lineKeys.isEmpty) return;
    final position = _scrollController.position;
    final estimate =
        (line / _lineKeys.length) * position.maxScrollExtent;
    _scrollController.jumpTo(estimate.clamp(0.0, position.maxScrollExtent));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollLineIntoView(line, allowJump: false);
    });
  }

  @override
  void dispose() {
    _audio?.dispose();
    _readAloud?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleBlur() {
    setState(() => _blurred = !_blurred);
  }

  // Turning shadowing off drops the hold row that "Check me" lives on —
  // cancel any recording/transcription in flight rather than leaving it
  // orphaned.
  void _toggleShadowing() {
    final audio = _audio;
    if (audio == null) return;
    final turningOn = !audio.shadowing;
    if (!turningOn) _readAloud?.cancel();
    audio.setShadowing(turningOn);
  }

  /// Stops playback and cancels any in-flight "Check me" recording — the
  /// hold row (and the mic button on it) disappears the moment audio stops,
  /// so a recording left running would be orphaned.
  void _stopAudio() {
    _readAloud?.cancel();
    _audio?.stop();
  }

  @override
  Widget build(BuildContext context) {
    final audio = _audio;
    final readAloud = _readAloud;
    final listenables = <Listenable>[?audio, ?readAloud];
    if (listenables.isEmpty) return _buildBody(context, null, null);
    // The body must be constructed inside the builder — a prebuilt widget
    // instance would be seen as unchanged and never repainted on notify.
    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) => _buildBody(context, audio, readAloud),
    );
  }

  Widget _buildBody(BuildContext context, ListeningController? audio,
      ReadAloudController? readAloud) {
    final theme = Theme.of(context);
    _maybeScrollToActiveLine(_activeLine(audio));

    return Column(
      children: [
        if (audio != null)
          _AudioBar(
            controller: audio,
            readAloud: readAloud,
            blurred: _blurred,
            onToggleBlur: _toggleBlur,
            onToggleShadowing: _toggleShadowing,
            onStop: _stopAudio,
          ),
        Expanded(child: _buildLines(audio, readAloud)),
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
                    // next least-recently-practiced one) rather than
                    // generating — the whole point of that entrypoint. Opening
                    // one conversation from the list is not a playlist: its
                    // Next generates fresh, exactly like the generate entry
                    // (features/conversation-list.md §2).
                    onPressed: () {
                      final notifier = ref
                          .read(readingSessionProvider(widget.request).notifier);
                      switch (widget.request.start) {
                        case ReadingStart.generate:
                        case ReadingStart.conversation:
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

  Widget _buildLines(ListeningController? audio, ReadAloudController? readAloud) {
    final listView = ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: [
        for (final (index, line) in widget.conversation.lines.indexed)
          _LineRow(
            key: _lineKeys[index],
            line: line,
            seed: widget.seed,
            taughtForms: widget.taughtForms,
            showFurigana: widget.showFurigana,
            // Highlighted while sounding and through the shadowing hold —
            // the learner repeats the line they can see marked.
            isCurrent: audio?.currentLine == index &&
                (audio?.status == AudioStatus.playing ||
                    audio?.status == AudioStatus.awaitingRepeat),
            // A margin replay re-entering the chain mid-check would orphan
            // the recording — cancel it first (mirrors `_stopAudio`).
            onReplay: audio == null
                ? null
                : () {
                    readAloud?.cancel();
                    audio.playLine(index);
                  },
            // "Check me" (D73) only ever targets the currently held line, so
            // this is non-null exactly when that line has something to show:
            // an in-flight recording/transcription or a past verdict.
            readAloud: readAloud == null
                ? null
                : _LineReadAloudState(
                    recording: readAloud.activeLine == index &&
                        readAloud.status == ReadAloudStatus.recording,
                    transcribing: readAloud.activeLine == index &&
                        readAloud.status == ReadAloudStatus.transcribing,
                    result: readAloud.resultFor(index),
                    error: readAloud.activeLine == index &&
                            readAloud.status == ReadAloudStatus.error
                        ? readAloud.errorMessage
                        : null,
                  ),
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

/// The player row: play/stop, speed (client-side rate, D50), shadowing
/// toggle (D63) with its "Your turn" hold row, and listening-mode toggle.
/// The hold row carries an optional "Check me" grading step (D73, folded in
/// from the read-aloud mode D67 shipped): record the held line, get a
/// verdict. Inline error text on synthesis failure — reading is unaffected.
class _AudioBar extends StatelessWidget {
  const _AudioBar({
    required this.controller,
    required this.readAloud,
    required this.blurred,
    required this.onToggleBlur,
    required this.onToggleShadowing,
    required this.onStop,
  });

  final ListeningController controller;

  /// Null when grading is unavailable (no conversationId) — "Check me" is
  /// simply omitted from the hold row.
  final ReadAloudController? readAloud;

  final bool blurred;
  final VoidCallback onToggleBlur;
  final VoidCallback onToggleShadowing;

  /// Stops playback — routed through the parent so an in-flight "Check me"
  /// recording is cancelled first, not orphaned (see `_stopAudio`).
  final VoidCallback onStop;

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
              else if (controller.status == AudioStatus.playing ||
                  controller.status == AudioStatus.awaitingRepeat)
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined, size: 30),
                  tooltip: 'Stop',
                  onPressed: onStop,
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
              // The mode toggles sit in an Expanded Wrap so they stay right-
              // aligned and on one line on real phones, but reflow to a
              // second run instead of overflowing on a narrow width or large
              // text scale (a third toggle, D67, once overran a fixed Row —
              // dropped back to two at D73, but the Wrap stays: it's the
              // robust-by-construction fix, not a fit for a fixed count).
              // Compact density keeps them on one line in the common case.
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.record_voice_over_outlined),
                      tooltip: controller.shadowing
                          ? 'Turn off shadowing'
                          : 'Shadowing (repeat after each line)',
                      isSelected: controller.shadowing,
                      visualDensity: VisualDensity.compact,
                      onPressed: onToggleShadowing,
                    ),
                    IconButton(
                      icon: Icon(blurred
                          ? Icons.visibility_outlined
                          : Icons.hearing_outlined),
                      tooltip:
                          blurred ? 'Show text' : 'Listening mode (hide text)',
                      isSelected: blurred,
                      visualDensity: VisualDensity.compact,
                      onPressed: onToggleBlur,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Shadowing hold (D63): the learner repeats the line aloud, then
          // taps on. Advance is a tap, never a timer. The row stays mounted
          // for the whole pass — the same-height row shows through both the
          // sounding line and the hold, just with different text and the
          // buttons disabled while a line plays — so the conversation beneath
          // it doesn't jump up and down as each line is read. "Check me"
          // (D73) is optional and never gates advancing — only its own
          // recording/transcribing disables Hear-it-again/Next, so grading
          // is opt-in every line, not a requirement to move on.
          if (controller.shadowing &&
              (controller.status == AudioStatus.playing ||
                  controller.status == AudioStatus.awaitingRepeat))
            Builder(builder: (context) {
              final awaiting =
                  controller.status == AudioStatus.awaitingRepeat;
              final checkingThisLine = readAloud != null &&
                  readAloud!.activeLine == controller.currentLine;
              final checkStatus =
                  checkingThisLine ? readAloud!.status : ReadAloudStatus.idle;
              final checking = checkStatus == ReadAloudStatus.recording ||
                  checkStatus == ReadAloudStatus.transcribing;
              return Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      awaiting ? 'Your turn — say it aloud' : 'Listen…',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (readAloud != null)
                          _CheckMeButton(
                            status: checkStatus,
                            enabled: awaiting,
                            onTap: () =>
                                readAloud!.toggleLine(controller.currentLine!),
                          ),
                        TextButton(
                          onPressed: awaiting && !checking
                              ? controller.repeatShadowLine
                              : null,
                          child: const Text('Hear it again'),
                        ),
                        FilledButton(
                          onPressed: awaiting && !checking
                              ? controller.advanceShadow
                              : null,
                          child:
                              Text(controller.onLastLine ? 'Done' : 'Next line'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
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

/// The mic control on the shadowing hold row (D73): idle → "Check me", tap
/// records; recording → "Stop & check", tap stops and grades; transcribing →
/// a spinner, no tap target. [enabled] gates the idle/recording states —
/// checking only ever runs during the hold ("Your turn"), never while a line
/// is sounding.
class _CheckMeButton extends StatelessWidget {
  const _CheckMeButton({
    required this.status,
    required this.enabled,
    required this.onTap,
  });

  final ReadAloudStatus status;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (status == ReadAloudStatus.transcribing) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final recording = status == ReadAloudStatus.recording;
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(recording ? Icons.stop_circle_outlined : Icons.mic_outlined,
          size: 18),
      label: Text(recording ? 'Stop & check' : 'Check me'),
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
    );
  }
}

/// Per-line "Check me" state handed to a [_LineRow]: an in-flight
/// recording/transcription or a past verdict for that specific line. Null
/// when the conversation has no audio layer (mirrors [_LineRow.onReplay]).
@immutable
class _LineReadAloudState {
  const _LineReadAloudState({
    required this.recording,
    required this.transcribing,
    required this.result,
    required this.error,
  });

  final bool recording;
  final bool transcribing;

  final ReadAloudResult? result;

  /// Error text for this line, or null.
  final String? error;
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    super.key,
    required this.line,
    required this.seed,
    required this.taughtForms,
    required this.showFurigana,
    this.isCurrent = false,
    this.onReplay,
    this.readAloud,
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

  /// "Check me" state for this line, or null when the conversation has no
  /// audio layer (D73).
  final _LineReadAloudState? readAloud;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = displayTokens(line, seed);
    final ra = readAloud;

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
          // with the replay control beneath the name — the "Check me" mic
          // lives on the shadowing hold row instead (D73).
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
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
                if (ra != null) _ReadAloudFeedback(state: ra),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The verdict-and-transcript block under a line after a "Check me" grade.
/// The raw transcript is always shown (spec §5): it's the truth the verdict
/// only hints at.
class _ReadAloudFeedback extends StatelessWidget {
  const _ReadAloudFeedback({required this.state});

  final _LineReadAloudState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          state.error!,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.error),
        ),
      );
    }
    if (state.recording) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Recording… tap "Stop & check" when you’re done',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.primary),
        ),
      );
    }
    final result = state.result;
    if (result == null) return const SizedBox.shrink();

    final (IconData icon, Color color, String label) = switch (result.verdict) {
      ReadAloudVerdict.match => (
          Icons.check_circle,
          theme.colorScheme.primary,
          'Sounds right'
        ),
      ReadAloudVerdict.close => (
          Icons.info_outline,
          theme.colorScheme.tertiary,
          'Close — check what it heard'
        ),
      ReadAloudVerdict.mismatch => (
          Icons.cancel_outlined,
          theme.colorScheme.error,
          "Didn't match"
        ),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            result.transcript.isEmpty
                ? 'Heard: (nothing)'
                : 'Heard: ${result.transcript}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

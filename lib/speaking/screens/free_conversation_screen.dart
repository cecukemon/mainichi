/// Free conversation screen (speaking rung 3, D69). A separate screen, not a
/// mode on the reading screen: the data is a growing list of turns, not a fixed
/// conversation, and there's one bottom mic rather than per-line mics.
///
/// The app's lines render with furigana and word-tap lookup (reusing the
/// reading stack); the learner's replies show as plain transcript text with a
/// verdict, note, and a suggested rewrite beneath (spec §5: the transcript is
/// always the truth the verdict only hints at).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generation/conversation_generator.dart';
import '../../reading/line_display.dart';
import '../../reading/furigana_text.dart';
import '../../reading/reading_providers.dart' show seedSourceProvider;
import '../../reading/word_lookup_sheet.dart';
import '../conversation_turn.dart';
import '../free_conversation_controller.dart';
import '../speaking_providers.dart';

class FreeConversationScreen extends ConsumerStatefulWidget {
  const FreeConversationScreen({super.key});

  @override
  ConsumerState<FreeConversationScreen> createState() =>
      _FreeConversationScreenState();
}

class _FreeConversationScreenState
    extends ConsumerState<FreeConversationScreen> {
  FreeConversationController? _controller;
  GenerationSeed? _seed;
  Object? _bootstrapError;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Loads the seed, builds the controller, and starts the opening turn. The
  /// seed load is async (drift), so the controller can't be a plain provider.
  Future<void> _bootstrap() async {
    try {
      final seed = await ref.read(seedSourceProvider).loadGenerationSeed();
      if (!mounted) return;
      final controller = FreeConversationController(
        recorder: ref.read(speechRecorderFactoryProvider)(),
        stt: ref.read(sttServiceProvider),
        service: ref.read(conversationServiceProvider),
        seed: seed,
      );
      controller.addListener(_scrollToBottomSoon);
      setState(() {
        _seed = seed;
        _controller = controller;
      });
      controller.start();
    } catch (error) {
      if (!mounted) return;
      setState(() => _bootstrapError = error);
    }
  }

  /// The taught conjugation forms for the lookup sheet's form annotation.
  Set<String> get _taughtForms => {
        'dictionary',
        for (final s in _seed!.structures)
          for (final sl in s.slots) sl.form,
      };

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_scrollToBottomSoon);
    _controller?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'End conversation',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Conversation'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_bootstrapError != null) {
      return _CenteredMessage(
        icon: Icons.error_outline,
        text: "Couldn't load your Bunko. Try again.",
      );
    }
    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.status == FreeConvStatus.loadingOpening) {
          return const _CenteredMessage(
            spinner: true,
            text: 'Starting a conversation…',
          );
        }
        return Column(
          children: [
            Expanded(child: _buildTurns(controller)),
            const Divider(height: 1),
            _BottomBar(
              controller: controller,
              onMic: controller.toggleMic,
              onRetry: controller.retry,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTurns(FreeConversationController controller) {
    // A leading spinner state with no turns yet (opening error already handled)
    // is only the empty guard's error, shown in the bottom bar; keep the list.
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: controller.turns.length,
      itemBuilder: (context, i) {
        final turn = controller.turns[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AppLineView(
              line: turn.appLine,
              seed: _seed!,
              taughtForms: _taughtForms,
            ),
            if (turn.answered)
              _LearnerReplyView(
                transcript: turn.learnerTranscript!,
                grade: turn.grade,
              ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

/// One persona line: the name, then the tokens with furigana + tap lookup.
class _AppLineView extends StatelessWidget {
  const _AppLineView({
    required this.line,
    required this.seed,
    required this.taughtForms,
  });

  final GenLine line;
  final GenerationSeed seed;
  final Set<String> taughtForms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = displayTokens(line, seed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          line.speakerSurface,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 2),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            for (final token in tokens)
              _AppToken(token: token, taughtForms: taughtForms),
          ],
        ),
      ],
    );
  }
}

/// A single app-line token — tappable (opening the lookup sheet) when it maps
/// to a vocab entry. Mirrors the reading screen's `_TokenView` (furigana always
/// on here — the v1 free-conversation screen has no toggle).
class _AppToken extends StatelessWidget {
  const _AppToken({required this.token, required this.taughtForms});

  final DisplayToken token;
  final Set<String> taughtForms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = FuriganaText(
      tokens: [token.segments],
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

/// The learner's reply: their transcript (always shown), a verdict chip, the
/// one-line note, and — when offered — a natural rewrite to try.
class _LearnerReplyView extends StatelessWidget {
  const _LearnerReplyView({required this.transcript, required this.grade});

  final String transcript;
  final TurnGrade? grade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = grade;
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You: $transcript',
            style: theme.textTheme.titleMedium,
          ),
          if (g != null) ...[
            const SizedBox(height: 6),
            _VerdictChip(verdict: g.verdict),
            if (g.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(g.note,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (g.rewrite.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Try saying: ${g.rewrite}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic)),
            ],
          ],
        ],
      ),
    );
  }
}

class _VerdictChip extends StatelessWidget {
  const _VerdictChip({required this.verdict});

  final TurnVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (IconData icon, Color color, String label) = switch (verdict) {
      TurnVerdict.good => (Icons.check_circle, theme.colorScheme.primary, 'Good'),
      TurnVerdict.awkward => (
          Icons.info_outline,
          theme.colorScheme.tertiary,
          'A bit off'
        ),
      TurnVerdict.off => (
          Icons.cancel_outlined,
          theme.colorScheme.error,
          "Didn't quite work"
        ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// The status line + mic (or, in an error state, a retry). One mic toggles
/// record/stop; it spins while transcribing or thinking.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.controller,
    required this.onMic,
    required this.onRetry,
  });

  final FreeConversationController controller;
  final VoidCallback onMic;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = controller.status;

    if (status == FreeConvStatus.error) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(controller.errorMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final busy = status == FreeConvStatus.transcribing ||
        status == FreeConvStatus.thinking;
    final (String hint, Widget control) = switch (status) {
      FreeConvStatus.recording => (
          'Listening… tap to finish',
          _MicFab(icon: Icons.stop, color: theme.colorScheme.error, onTap: onMic),
        ),
      FreeConvStatus.transcribing => ('Hearing you…', const _Spinner()),
      FreeConvStatus.thinking => ('Thinking…', const _Spinner()),
      _ => (
          'Tap the mic and reply out loud',
          _MicFab(
              icon: Icons.mic, color: theme.colorScheme.primary, onTap: onMic),
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(hint,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          IgnorePointer(ignoring: busy, child: control),
        ],
      ),
    );
  }
}

class _MicFab extends StatelessWidget {
  const _MicFab({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: null,
      backgroundColor: color,
      onPressed: onTap,
      child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 56,
        height: 56,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.text,
    this.icon,
    this.spinner = false,
  });

  final String text;
  final IconData? icon;
  final bool spinner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spinner) const CircularProgressIndicator(),
          if (icon != null) Icon(icon, size: 40, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

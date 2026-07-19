/// Riverpod wiring for the reading exercise (features/reading-exercise.md).
///
/// One conversation at a time, continuous feed (D39): the notifier loads a
/// fresh generation on creation and on every `loadNext`. Failures become an
/// explicit error state with retry — never a silent retry loop (D42).
library;

import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../data/conversation_cache.dart';
import '../data/enums.dart' show GlueKind;
import '../data/seed_repository.dart';
import '../generation/conversation_generator.dart';
import '../generation/generation_client.dart';
import '../settings/api_key_store.dart';
import '../settings/settings_providers.dart';
import '../capture/capture_providers.dart' show databaseProvider;
import '../capture/models.dart' show VocabDraftItem;
import 'scope_backfill.dart';

/// Derives from [databaseProvider]; tests override with a fixture source.
final seedSourceProvider = Provider<SeedSource>(
  (ref) => DriftSeedSource(ref.watch(databaseProvider)),
);

/// The generated-content cache (features/generated-cache.md): written through
/// on every valid generation, read by the error state's reread fallback.
final conversationStoreProvider = Provider<ConversationStore>(
  (ref) => DriftConversationStore(ref.watch(databaseProvider)),
);

/// Derives from [apiKeyStoreProvider], same pattern as
/// `extractionServiceProvider` — tests override with a fake service.
final generationServiceProvider = Provider<GenerationService>((ref) {
  final store = ref.watch(apiKeyStoreProvider);
  return LiveGenerationService(apiKeyProvider: store.read);
});

/// The error state's Bunko-backfill path (D52) — injected as a service (not
/// the raw db) so widget tests override it with a fake, same pattern as
/// [generationServiceProvider].
final scopeBackfillProvider = Provider<ScopeBackfillService>(
  (ref) => ScopeBackfillService(ref.watch(databaseProvider)),
);

/// Which action the session runs on entry: generate a fresh conversation
/// (D39, the default), or reread the least-recently-practiced cached one
/// (features/generated-cache.md). The home screen offers both directly, so
/// reread is no longer only reachable from the generation-failure fallback.
enum ReadingStart { generate, reread }

/// autoDispose: leaving the screen ends the session; re-entering starts a
/// fresh one (no stale conversation flashing before the new load). Keyed on
/// [ReadingStart] so the two home entrypoints get independent sessions.
final readingSessionProvider = StateNotifierProvider.autoDispose.family<
    ReadingSessionNotifier, ReadingSessionState, ReadingStart>(
  (ref, start) => ReadingSessionNotifier(
    ref.watch(seedSourceProvider),
    ref.watch(generationServiceProvider),
    ref.watch(conversationStoreProvider),
    ref.watch(scopeBackfillProvider),
    start: start,
  ),
);

enum ReadingPhase { loading, error, ready }

@immutable
class ReadingSessionState {
  const ReadingSessionState.loading()
      : phase = ReadingPhase.loading,
        conversation = null,
        seed = null,
        conversationId = null,
        errorMessage = '',
        hasCachedFallback = false,
        rejectedConversation = null,
        candidates = const [];
  const ReadingSessionState.error(this.errorMessage,
      {this.hasCachedFallback = false,
      this.rejectedConversation,
      this.candidates = const []})
      : phase = ReadingPhase.error,
        conversation = null,
        seed = null,
        conversationId = null;
  const ReadingSessionState.ready(
      GeneratedConversation this.conversation, GenerationSeed this.seed,
      {this.conversationId})
      : phase = ReadingPhase.ready,
        errorMessage = '',
        hasCachedFallback = false,
        rejectedConversation = null,
        candidates = const [];

  final ReadingPhase phase;
  final GeneratedConversation? conversation;
  final GenerationSeed? seed;

  /// The conversation's row id in the generated-content cache — what the
  /// audio layer keys its files on. Null only when the cache write failed
  /// (the rare case: reading works, audio is unavailable).
  final int? conversationId;

  final String errorMessage;

  /// On error: whether the generated-content cache can serve a reread
  /// instead (features/generated-cache.md) — drives the fallback action.
  final bool hasCachedFallback;

  /// On a scope-failure error: the rejected conversation, held (never shown)
  /// so a Bunko backfill can re-validate it in place — the self-healing loop
  /// (D52). Null on non-scope errors.
  final GeneratedConversation? rejectedConversation;

  /// On a scope-failure error: word-shaped unmatched surfaces the backfill
  /// affordance offers for review ([ScopeReport.candidates]). Empty on
  /// non-scope errors, so chips render only when there's something to add.
  final List<String> candidates;

  /// Slot forms the structure library actually teaches — what
  /// `detectTaughtForm` is allowed to recognize on a tapped word.
  Set<String> get taughtForms => {
        'dictionary',
        if (seed != null)
          for (final s in seed!.structures)
            for (final slot in s.slots) slot.form,
      };
}

class ReadingSessionNotifier extends StateNotifier<ReadingSessionState> {
  ReadingSessionNotifier(this._seeds, this._service, this._cache, this._backfill,
      {ReadingStart start = ReadingStart.generate})
      : super(const ReadingSessionState.loading()) {
    switch (start) {
      case ReadingStart.generate:
        loadNext();
      case ReadingStart.reread:
        readCached();
    }
  }

  final SeedSource _seeds;
  final GenerationService _service;
  final ConversationStore _cache;
  final ScopeBackfillService _backfill;

  Future<void> loadNext() async {
    state = const ReadingSessionState.loading();
    try {
      final seed = await _seeds.loadGenerationSeed();
      if (seed.vocab.isEmpty || seed.structures.isEmpty) {
        await _fail('Nothing to read from yet — import a worksheet first.');
        return;
      }
      final convo = await _service.generate(seed: seed);
      final report = validateScope(convo, seed);
      if (!report.ok) {
        // Out-of-scope output is discarded, not shown (D20/D42) — the learner
        // must never see untaught material presented as practice. The learner
        // gets a generic message, but the specific violations go to the dev
        // log so the small-Bunko failure rate can be diagnosed (which check
        // rejected, and on what token) rather than guessed at.
        developer.log(
          'generation rejected, ${report.violations.length} violation(s):\n'
          '${report.violations.join('\n')}',
          name: 'reading.scope',
        );
        await _fail(
          "The generator didn't return a conversation in scope. "
          'You can try again, or head back.',
          rejectedConversation: convo,
          candidates: report.candidates,
        );
        return;
      }
      // Persist before showing so the ready state can carry the cache row id
      // the audio layer needs; a persistence failure still shows the
      // conversation, just without audio (id stays null).
      final id = await _persist(convo);
      if (!mounted) return;
      state = ReadingSessionState.ready(convo, seed, conversationId: id);
    } on ApiKeyMissing {
      await _fail('No API key configured — add one in Settings.');
    } on GenerationRefused {
      await _fail(
          'The generator declined that one. You can try again, or head back.');
    } on GenerationTruncated {
      // Distinct from the generic parse bucket: the model reached the output
      // cap before finishing (the raised limit should make this rare). Log it
      // so a recurring case is visible against the new ceiling.
      developer.log('generation truncated (hit max_tokens)',
          name: 'reading.generate');
      await _fail('That conversation ran long and got cut off. '
          'Try again, or head back.');
    } catch (error, stack) {
      // Everything that isn't a missing key, a refusal, or an out-of-scope
      // result lands here: connectivity, server-side HTTP status, a timeout,
      // or an unparseable reply. The old catch-all blamed the connection for
      // all of them and dropped the exception. Log the real error under
      // `reading.generate` and give the case-appropriate message so the
      // intermittent-failure question can be diagnosed, not guessed.
      developer.log(
        'generation failed: $error',
        name: 'reading.generate',
        error: error,
        stackTrace: stack,
      );
      await _fail(_generationFailureMessage(error));
    }
  }

  /// The error state's fallback action: serve the least-recently-practiced
  /// cached conversation instead of generating (features/generated-cache.md).
  Future<void> readCached() async {
    state = const ReadingSessionState.loading();
    try {
      final seed = await _seeds.loadGenerationSeed();
      final cached = await _cache.leastRecentlyPracticed();
      if (cached == null) {
        await _fail('Nothing cached yet — generate a conversation first.');
        return;
      }
      await _cache.markPracticed(cached.id);
      if (!mounted) return;
      state = ReadingSessionState.ready(cached.conversation, seed,
          conversationId: cached.id);
    } catch (_) {
      await _fail("Couldn't load a cached conversation.");
    }
  }

  /// Write-through into the generated-content cache. Link rows derive from
  /// the validated conversation, not the model's used_* self-report. The
  /// conversation is already validated — a persistence failure is the cheaper
  /// loss, so it never blocks reading (null: no cache row, no audio).
  Future<int?> _persist(GeneratedConversation convo) async {
    try {
      return await _cache.save(
        convo,
        wordIds: convo.tokenVocabIds,
        structureIds: convo.lineStructureIds,
      );
    } catch (_) {
      return null;
    }
  }

  /// The backfill affordance's commit path (D52): write the approved word
  /// through the capture commit, then re-validate the rejected conversation
  /// ([_revalidateAfterBackfill]).
  Future<void> addCandidateToBunko(
      VocabDraftItem approved, String surface) async {
    final rejected = state.rejectedConversation;
    if (rejected == null) return; // phase changed under the sheet — no-op
    state = const ReadingSessionState.loading();
    try {
      await _backfill.commit(approved, surface: surface);
    } catch (_) {
      await _fail("Couldn't save the word. You can try again, or head back.");
      return;
    }
    await _revalidateAfterBackfill(rejected);
  }

  /// The glue analogue of [addCandidateToBunko] (D56): commit an approved
  /// particle/glue surface into the GrammarGlue table, then re-validate — the
  /// freshly loaded seed carries the new glue row, so the self-heal closes
  /// for particles exactly as it does for words.
  Future<void> addGlueToBunko(String surface, GlueKind kind) async {
    final rejected = state.rejectedConversation;
    if (rejected == null) return; // phase changed under the sheet — no-op
    state = const ReadingSessionState.loading();
    try {
      await _backfill.commitGlue(surface: surface, kind: kind);
    } catch (_) {
      await _fail("Couldn't save it. You can try again, or head back.");
      return;
    }
    await _revalidateAfterBackfill(rejected);
  }

  /// After any backfill commit: re-validate the rejected conversation against
  /// a freshly loaded seed — if the added item was the only problem, it now
  /// passes and is shown (the self-healing loop). Otherwise the error state
  /// returns with recomputed candidates (the just-added item drops out; any
  /// remaining ones show).
  Future<void> _revalidateAfterBackfill(GeneratedConversation rejected) async {
    try {
      final seed = await _seeds.loadGenerationSeed();
      final report = validateScope(rejected, seed);
      if (report.ok) {
        final id = await _persist(rejected);
        if (!mounted) return;
        state = ReadingSessionState.ready(rejected, seed, conversationId: id);
      } else {
        await _fail(
          'Added — but this conversation still uses other untaught material. '
          'You can add another word, try a fresh one, or head back.',
          rejectedConversation: rejected,
          candidates: report.candidates,
        );
      }
    } catch (_) {
      // The item is committed and stands (it's legitimately taught material
      // regardless); only the re-validation failed.
      await _fail(
          'It was added, but the conversation could not be re-checked. '
          'You can try a fresh one, or head back.');
    }
  }

  /// Discard from the backfill sheet: the chip disappears for this error
  /// state, nothing is persisted (the user judged the word untaught).
  void dismissCandidate(String surface) {
    if (state.phase != ReadingPhase.error) return;
    state = ReadingSessionState.error(
      state.errorMessage,
      hasCachedFallback: state.hasCachedFallback,
      rejectedConversation: state.rejectedConversation,
      candidates: [
        for (final c in state.candidates)
          if (c != surface) c,
      ],
    );
  }

  Future<void> _fail(
    String message, {
    GeneratedConversation? rejectedConversation,
    List<String> candidates = const [],
  }) async {
    var canReread = false;
    try {
      canReread = await _cache.leastRecentlyPracticed() != null;
    } catch (_) {/* no fallback offered if even the cache read fails */}
    if (!mounted) return;
    state = ReadingSessionState.error(
      message,
      hasCachedFallback: canReread,
      rejectedConversation: rejectedConversation,
      candidates: candidates,
    );
  }
}

/// Maps a generation transport/parse failure to a learner-facing message.
/// Only a genuine connectivity failure warrants "check your connection"; a
/// server-side status (rejected key, rate limit, overload) and a reply that
/// couldn't be parsed each get their own honest message. The raw error is
/// logged separately (under `reading.generate`) for diagnosis; this only
/// picks the wording.
String _generationFailureMessage(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status != null) {
      // Reached the generator; it answered with an error status.
      if (status == 401 || status == 403) {
        return 'The generator rejected the API key. Check it in Settings.';
      }
      if (status == 429) {
        return 'The generator is busy right now (rate limit). '
            'Wait a moment and try again.';
      }
      if (status >= 500) {
        return 'The generator is temporarily overloaded. '
            'Try again in a moment.';
      }
      return 'The generator returned an error ($status). '
          'You can try again, or head back.';
    }
    // No response = the request never completed: offline, DNS, or timeout.
    return "Couldn't reach the generator. "
        'Check your connection and try again.';
  }
  // Reached and answered, but the reply couldn't be read — truncated or
  // malformed JSON, a missing text block, or an unexpected shape.
  return 'The generator replied, but the response could not be read. '
      'You can try again, or head back.';
}

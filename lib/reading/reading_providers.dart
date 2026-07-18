/// Riverpod wiring for the reading exercise (features/reading-exercise.md).
///
/// One conversation at a time, continuous feed (D39): the notifier loads a
/// fresh generation on creation and on every `loadNext`. Failures become an
/// explicit error state with retry — never a silent retry loop (D42).
library;

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../data/conversation_cache.dart';
import '../data/seed_repository.dart';
import '../generation/conversation_generator.dart';
import '../generation/generation_client.dart';
import '../settings/api_key_store.dart';
import '../settings/settings_providers.dart';
import '../capture/capture_providers.dart' show databaseProvider;

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

/// autoDispose: leaving the screen ends the session; re-entering starts a
/// fresh one (no stale conversation flashing before the new load).
final readingSessionProvider = StateNotifierProvider.autoDispose<
    ReadingSessionNotifier, ReadingSessionState>(
  (ref) => ReadingSessionNotifier(
    ref.watch(seedSourceProvider),
    ref.watch(generationServiceProvider),
    ref.watch(conversationStoreProvider),
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
        hasCachedFallback = false;
  const ReadingSessionState.error(this.errorMessage,
      {this.hasCachedFallback = false})
      : phase = ReadingPhase.error,
        conversation = null,
        seed = null,
        conversationId = null;
  const ReadingSessionState.ready(
      GeneratedConversation this.conversation, GenerationSeed this.seed,
      {this.conversationId})
      : phase = ReadingPhase.ready,
        errorMessage = '',
        hasCachedFallback = false;

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
  ReadingSessionNotifier(this._seeds, this._service, this._cache)
      : super(const ReadingSessionState.loading()) {
    loadNext();
  }

  final SeedSource _seeds;
  final GenerationService _service;
  final ConversationStore _cache;

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
        await _fail("The generator didn't return a conversation in scope. "
            'You can try again, or head back.');
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
    } catch (_) {
      await _fail(
          "Couldn't reach the generator. Check your connection and try again.");
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

  Future<void> _fail(String message) async {
    var canReread = false;
    try {
      canReread = await _cache.leastRecentlyPracticed() != null;
    } catch (_) {/* no fallback offered if even the cache read fails */}
    if (!mounted) return;
    state =
        ReadingSessionState.error(message, hasCachedFallback: canReread);
  }
}

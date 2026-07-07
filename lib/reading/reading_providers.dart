/// Riverpod wiring for the reading exercise (features/reading-exercise.md).
///
/// One conversation at a time, continuous feed (D39): the notifier loads a
/// fresh generation on creation and on every `loadNext`. Failures become an
/// explicit error state with retry — never a silent retry loop (D42).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

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
  ),
);

enum ReadingPhase { loading, error, ready }

@immutable
class ReadingSessionState {
  const ReadingSessionState.loading()
      : phase = ReadingPhase.loading,
        conversation = null,
        seed = null,
        errorMessage = '';
  const ReadingSessionState.error(this.errorMessage)
      : phase = ReadingPhase.error,
        conversation = null,
        seed = null;
  const ReadingSessionState.ready(
      GeneratedConversation this.conversation, GenerationSeed this.seed)
      : phase = ReadingPhase.ready,
        errorMessage = '';

  final ReadingPhase phase;
  final GeneratedConversation? conversation;
  final GenerationSeed? seed;
  final String errorMessage;

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
  ReadingSessionNotifier(this._seeds, this._service)
      : super(const ReadingSessionState.loading()) {
    loadNext();
  }

  final SeedSource _seeds;
  final GenerationService _service;

  Future<void> loadNext() async {
    state = const ReadingSessionState.loading();
    try {
      final seed = await _seeds.loadGenerationSeed();
      if (seed.vocab.isEmpty || seed.structures.isEmpty) {
        state = const ReadingSessionState.error(
            'Nothing to read from yet — import a worksheet first.');
        return;
      }
      final convo = await _service.generate(seed: seed);
      final report = validateScope(convo, seed);
      if (!report.ok) {
        // Out-of-scope output is discarded, not shown (D20/D42) — the learner
        // must never see untaught material presented as practice.
        state = const ReadingSessionState.error(
            "The generator didn't return a conversation in scope. "
            'You can try again, or head back.');
        return;
      }
      if (!mounted) return;
      state = ReadingSessionState.ready(convo, seed);
    } on ApiKeyMissing {
      if (!mounted) return;
      state = const ReadingSessionState.error(
          'No API key configured — add one in Settings.');
    } on GenerationRefused {
      if (!mounted) return;
      state = const ReadingSessionState.error(
          'The generator declined that one. You can try again, or head back.');
    } catch (_) {
      if (!mounted) return;
      state = const ReadingSessionState.error(
          "Couldn't reach the generator. Check your connection and try again.");
    }
  }
}

/// Riverpod wiring for the speaking layer (features/speaking-exercise.md).
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../generation/conversation_generator.dart' show GenerationSeed;
import '../listening/listening_providers.dart'
    show ttsServiceProvider, lineAudioPlayerFactoryProvider;
import '../settings/settings_providers.dart';
import 'conversation_client.dart';
import 'free_conv_audio.dart';
import 'free_conv_audio_store.dart';
import 'speech_recorder.dart';
import 'stt_service.dart';

/// Reuses the Google key slot — Cloud STT and TTS take the same key (§3).
final sttServiceProvider = Provider<SttService>((ref) {
  final store = ref.watch(googleApiKeyStoreProvider);
  return LiveSttService(apiKeyProvider: store.read);
});

/// The combined grade+generate transport for free conversation (rung 3). Takes
/// the Anthropic key, same slot as generation (mirrors [generationServiceProvider]).
final conversationServiceProvider = Provider<ConversationService>((ref) {
  final store = ref.watch(apiKeyStoreProvider);
  return LiveConversationService(apiKeyProvider: store.read);
});

/// A factory, not an instance: the screen makes one recorder per displayed
/// conversation and owns its lifecycle (mirrors [lineAudioPlayerFactoryProvider]).
/// Tests override with a fake — the real one talks to platform channels.
final speechRecorderFactoryProvider = Provider<SpeechRecorder Function()>(
  (ref) => () =>
      RecordSpeechRecorder(tempDirectory: () async => Directory.systemTemp),
);

/// The ephemeral scratch store behind free conversation's per-line "hear it"
/// button (D72). Reuses the listening layer's TTS service — same Google key
/// slot. Tests override with a fake to stay off the real filesystem.
final freeConvAudioStoreProvider = Provider<FreeConvAudioStore>((ref) {
  final tts = ref.watch(ttsServiceProvider);
  return DiskFreeConvAudioStore(
      rootDir: getApplicationDocumentsDirectory, tts: tts);
});

/// A factory, not an instance: the free-conversation screen makes one
/// controller per session, seeded once the Bunko has loaded (mirrors
/// [speechRecorderFactoryProvider]). Reuses the listening layer's platform
/// player factory.
final freeConvAudioControllerFactoryProvider =
    Provider<FreeConvAudioController Function(GenerationSeed)>((ref) {
  final store = ref.watch(freeConvAudioStoreProvider);
  final playerFactory = ref.watch(lineAudioPlayerFactoryProvider);
  return (seed) => FreeConvAudioController(
        store: store,
        player: playerFactory(),
        seed: seed,
      );
});

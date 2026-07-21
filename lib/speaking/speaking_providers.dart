/// Riverpod wiring for the speaking layer (features/speaking-exercise.md).
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_providers.dart';
import 'conversation_client.dart';
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

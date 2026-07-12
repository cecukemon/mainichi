/// Riverpod wiring for the listening layer (features/listening-exercise.md).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../reading/reading_providers.dart' show conversationStoreProvider;
import '../settings/settings_providers.dart';
import 'audio_store.dart';
import 'just_audio_player.dart';
import 'playback_controller.dart';
import 'tts_service.dart';

/// Derives from [googleApiKeyStoreProvider], same pattern as the generation
/// service — tests override with a fake.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final store = ref.watch(googleApiKeyStoreProvider);
  return LiveTtsService(apiKeyProvider: store.read);
});

final conversationAudioStoreProvider = Provider<AudioStore>(
  (ref) => ConversationAudioStore(
    rootDir: getApplicationDocumentsDirectory,
    tts: ref.watch(ttsServiceProvider),
    conversations: ref.watch(conversationStoreProvider),
  ),
);

/// A factory rather than a player instance: the screen creates one player per
/// displayed conversation and owns its lifecycle. Tests override with a fake
/// (the real one talks to platform channels).
final lineAudioPlayerFactoryProvider = Provider<LineAudioPlayer Function()>(
  (ref) => JustAudioLinePlayer.new,
);

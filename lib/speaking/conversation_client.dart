/// Live transport for the free-conversation combined call (speaking rung 3,
/// D69). Sends the constraint set + conversation history to the Anthropic
/// Messages API and returns the parsed grade + next line.
///
/// Mirrors `LiveGenerationService` exactly — `dio`, key read fresh from the
/// `ApiKeyStore` at call time (D9). Transport only: scope validation of the
/// next line stays with the caller (the controller), which owns how a
/// violation surfaces.
library;

import 'package:dio/dio.dart';

import '../settings/api_key_store.dart' show ApiKeyMissing;
import 'conversation_turn.dart';
import '../generation/conversation_generator.dart' show GenerationSeed;

const String _endpoint = 'https://api.anthropic.com/v1/messages';

abstract class ConversationService {
  /// Runs one combined grade+generate turn against [seed]. With [history]
  /// empty and [latestReply] null it returns only the opening line (no grade);
  /// otherwise it grades [latestReply] and returns the persona's next line.
  ///
  /// Throws [ApiKeyMissing] when no key is configured and [GenerationRefused]
  /// when the model declines; transport errors surface as `DioException`.
  Future<ConversationTurn> turn({
    required GenerationSeed seed,
    List<TurnHistory> history,
    String? latestReply,
    String? personaSurface,
  });
}

class LiveConversationService implements ConversationService {
  LiveConversationService({required this.apiKeyProvider, Dio? dio})
      : _dio = dio ?? Dio();

  /// Reads the current key fresh on every call (rather than once at
  /// construction) so a key added mid-session doesn't need an app restart.
  final Future<String?> Function() apiKeyProvider;
  final Dio _dio;

  @override
  Future<ConversationTurn> turn({
    required GenerationSeed seed,
    List<TurnHistory> history = const [],
    String? latestReply,
    String? personaSurface,
  }) async {
    final apiKey = await apiKeyProvider();
    if (apiKey == null || apiKey.isEmpty) throw ApiKeyMissing();

    final response = await _dio.post<Map<String, dynamic>>(
      _endpoint,
      data: buildConversationTurnRequest(
        seed: seed,
        history: history,
        latestReply: latestReply,
        personaSurface: personaSurface,
      ),
      options: Options(
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
      ),
    );

    return parseConversationTurn(response.data!);
  }
}

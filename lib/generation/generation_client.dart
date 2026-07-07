/// Live transport for conversation generation (spec §2/§10.3): sends the
/// constraint set to the Anthropic Messages API and returns the parsed
/// conversation.
///
/// Mirrors `LiveExtractionService` — `dio` instead of the CLI's `HttpClient`,
/// key read fresh from the `ApiKeyStore` at call time (D9: every online call
/// sits behind an interface). Transport only: scope validation stays with the
/// caller, which decides how a violation surfaces (the reading screen shows an
/// explicit error state with retry, D42).
library;

import 'package:dio/dio.dart';

import '../settings/api_key_store.dart' show ApiKeyMissing;
import 'conversation_generator.dart';

const String _endpoint = 'https://api.anthropic.com/v1/messages';

abstract class GenerationService {
  /// Generates a conversation constrained to [seed]. Throws [ApiKeyMissing]
  /// when no key is configured and [GenerationRefused] when the model
  /// declines; transport errors surface as `DioException`.
  Future<GeneratedConversation> generate({
    required GenerationSeed seed,
    int lineCount = 6,
    String? focus,
  });
}

class LiveGenerationService implements GenerationService {
  LiveGenerationService({required this.apiKeyProvider, Dio? dio})
      : _dio = dio ?? Dio();

  /// Reads the current key fresh on every call (rather than once at
  /// construction) so a key added mid-session doesn't need an app restart.
  final Future<String?> Function() apiKeyProvider;
  final Dio _dio;

  @override
  Future<GeneratedConversation> generate({
    required GenerationSeed seed,
    int lineCount = 6,
    String? focus,
  }) async {
    final apiKey = await apiKeyProvider();
    if (apiKey == null || apiKey.isEmpty) throw ApiKeyMissing();

    final response = await _dio.post<Map<String, dynamic>>(
      _endpoint,
      data: buildGenerationRequest(
        seed: seed,
        lineCount: lineCount,
        focus: focus,
      ),
      options: Options(
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
      ),
    );

    return parseGenerationResponse(response.data!);
  }
}

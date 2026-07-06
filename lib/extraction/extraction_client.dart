/// Live transport for worksheet extraction (spec §3/§10.2): sends a photo to
/// the Anthropic Messages API and returns the raw structured-output JSON.
///
/// Mirrors `tool/extract_worksheet.dart`'s CLI transport but as an
/// app-embeddable client — `dio` instead of `dart:io`'s `HttpClient`, and the
/// key read fresh from the `ApiKeyStore` at call time rather than an env var
/// (D9: every online call sits behind an interface).
library;

import 'dart:convert';

import 'package:dio/dio.dart';

import 'worksheet_extractor.dart';

const String _endpoint = 'https://api.anthropic.com/v1/messages';

/// Thrown when no API key is configured — distinct from [ExtractionRefused]
/// (the model declined) and transport errors, so the UI can point the user at
/// Settings specifically rather than showing a generic failure.
class ApiKeyMissing implements Exception {
  @override
  String toString() => 'ApiKeyMissing: no Anthropic API key configured';
}

abstract class ExtractionService {
  /// Sends [imageBytes] for extraction and returns the raw structured-output
  /// JSON (`worksheet_extractor.dart`'s `extractionSchema` shape). The caller
  /// owns any resizing/orientation correction before calling this.
  Future<Map<String, dynamic>> extract({
    required List<int> imageBytes,
    required String mediaType,
  });
}

/// Calls the Messages API over HTTPS via `dio`.
class LiveExtractionService implements ExtractionService {
  LiveExtractionService({required this.apiKeyProvider, Dio? dio}) : _dio = dio ?? Dio();

  /// Reads the current key fresh on every call (rather than once at
  /// construction) so a key added mid-session doesn't need an app restart.
  final Future<String?> Function() apiKeyProvider;
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> extract({
    required List<int> imageBytes,
    required String mediaType,
  }) async {
    final apiKey = await apiKeyProvider();
    if (apiKey == null || apiKey.isEmpty) throw ApiKeyMissing();

    final body = buildExtractionRequest(
      base64Image: base64Encode(imageBytes),
      mediaType: mediaType,
    );

    final response = await _dio.post<Map<String, dynamic>>(
      _endpoint,
      data: body,
      options: Options(
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
      ),
    );

    return parseExtractionResponse(response.data!);
  }
}

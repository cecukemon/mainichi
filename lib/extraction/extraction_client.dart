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

import '../settings/api_key_store.dart' show ApiKeyMissing;
import 'worksheet_extractor.dart';

export '../settings/api_key_store.dart' show ApiKeyMissing;

const String _endpoint = 'https://api.anthropic.com/v1/messages';

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

    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
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
    } on DioException catch (e) {
      // Surface the API's own error text (e.g. a 400 "invalid schema" naming
      // the offending field) instead of dio's generic status-code blurb.
      final detail = _apiErrorMessage(e.response?.data);
      if (detail != null) throw ExtractionApiError(e.response?.statusCode, detail);
      rethrow;
    }

    return parseExtractionResponse(response.data!);
  }

  /// Pulls `error.message` out of an Anthropic error body, if present.
  static String? _apiErrorMessage(Object? data) {
    if (data is Map && data['error'] is Map) {
      final message = (data['error'] as Map)['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return null;
  }
}

/// An error the extraction API returned in its response body (e.g. an invalid
/// request), carrying the API's own message rather than dio's generic one.
class ExtractionApiError implements Exception {
  ExtractionApiError(this.statusCode, this.message);
  final int? statusCode;
  final String message;
  @override
  String toString() =>
      'ExtractionApiError(${statusCode ?? '?'}): $message';
}

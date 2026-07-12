/// Live transport for Google Cloud Text-to-Speech (spec §10.2, D50): one call
/// per conversation line, returning MP3 bytes for the audio file store.
///
/// Same shape as the other live services (D9): `dio` behind an interface, key
/// read fresh per call, transport only — what to synthesize (the
/// store-assembled kana line, never the kanji) and where to put the bytes are
/// the callers' concerns.
library;

import 'dart:convert';

import 'package:dio/dio.dart';

import '../settings/api_key_store.dart' show ApiKeyMissing;

const String _endpoint =
    'https://texttospeech.googleapis.com/v1/text:synthesize';

/// The two conversation voices (features/listening-exercise.md §4: which
/// concrete voices sound best is a calibrate-live item). Constants in one
/// place because the voice id participates in the audio cache key.
const String speakerVoiceA = 'ja-JP-Neural2-B';
const String speakerVoiceB = 'ja-JP-Neural2-C';

abstract class TtsService {
  /// Synthesizes [text] (kana) with [voice] at 1.0× and returns MP3 bytes.
  /// Throws [ApiKeyMissing] when no Google key is configured; transport
  /// errors surface as `DioException`.
  Future<List<int>> synthesize({required String text, required String voice});
}

class LiveTtsService implements TtsService {
  LiveTtsService({required this.apiKeyProvider, Dio? dio}) : _dio = dio ?? Dio();

  /// Reads the current key fresh on every call (rather than once at
  /// construction) so a key added mid-session doesn't need an app restart.
  final Future<String?> Function() apiKeyProvider;
  final Dio _dio;

  @override
  Future<List<int>> synthesize(
      {required String text, required String voice}) async {
    final apiKey = await apiKeyProvider();
    if (apiKey == null || apiKey.isEmpty) throw ApiKeyMissing('Google');

    final response = await _dio.post<Map<String, dynamic>>(
      _endpoint,
      queryParameters: {'key': apiKey},
      data: {
        'input': {'text': text},
        'voice': {'languageCode': 'ja-JP', 'name': voice},
        'audioConfig': {'audioEncoding': 'MP3'},
      },
      options: Options(headers: {'content-type': 'application/json'}),
    );

    return base64Decode(response.data!['audioContent'] as String);
  }
}

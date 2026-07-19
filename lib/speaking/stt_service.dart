/// Live transport for Google Cloud Speech-to-Text (speaking rung 2, D67):
/// one synchronous `recognize` call per recorded line, returning the best
/// transcript the recognizer heard.
///
/// Same shape as [TtsService] (D9/D50): `dio` behind an interface, key read
/// fresh per call, transport only. What was recorded and how the transcript
/// is graded are the callers' concerns. Google Cloud TTS and STT accept the
/// same API key, so this reuses the existing Google key slot — no third
/// settings entry (features/speaking-exercise.md §3).
library;

import 'dart:convert';

import 'package:dio/dio.dart';

import '../settings/api_key_store.dart' show ApiKeyMissing;

const String _endpoint = 'https://speech.googleapis.com/v1/speech:recognize';

/// The recording format the recorder must produce and the recognizer is told
/// to expect. LINEAR16 (PCM in a WAV container) at 16 kHz mono is Google's
/// recommended lossless input for synchronous recognition and needs no
/// transcoding. Kept here beside the service because the two must agree.
const int sttSampleRateHertz = 16000;
const String _sttEncoding = 'LINEAR16';
const String _sttLanguageCode = 'ja-JP';

abstract class SttService {
  /// Recognizes Japanese speech in [audioContent] (LINEAR16 WAV bytes at
  /// [sttSampleRateHertz]) and returns the best transcript, or the empty
  /// string when the recognizer heard nothing intelligible (an empty
  /// `results` array — a normal outcome, not an error). Throws
  /// [ApiKeyMissing] when no Google key is configured; transport errors
  /// surface as `DioException`.
  Future<String> transcribe(List<int> audioContent);
}

class LiveSttService implements SttService {
  LiveSttService({required this.apiKeyProvider, Dio? dio}) : _dio = dio ?? Dio();

  /// Reads the current key fresh on every call (rather than once at
  /// construction) so a key added mid-session doesn't need an app restart.
  final Future<String?> Function() apiKeyProvider;
  final Dio _dio;

  @override
  Future<String> transcribe(List<int> audioContent) async {
    final apiKey = await apiKeyProvider();
    if (apiKey == null || apiKey.isEmpty) throw ApiKeyMissing('Google');

    final response = await _dio.post<Map<String, dynamic>>(
      _endpoint,
      queryParameters: {'key': apiKey},
      data: {
        'config': {
          'encoding': _sttEncoding,
          'sampleRateHertz': sttSampleRateHertz,
          'languageCode': _sttLanguageCode,
        },
        'audio': {'content': base64Encode(audioContent)},
      },
      options: Options(headers: {'content-type': 'application/json'}),
    );

    // Empty/absent `results` means nothing was recognized — a real, common
    // outcome for a quiet or unclear recording. Surface it as "" so the
    // grader treats it as a mismatch and the UI shows an empty transcript,
    // rather than throwing.
    final results = response.data?['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return '';
    final alternatives =
        (results.first as Map<String, dynamic>)['alternatives'] as List<dynamic>?;
    if (alternatives == null || alternatives.isEmpty) return '';
    return (alternatives.first as Map<String, dynamic>)['transcript']
            as String? ??
        '';
  }
}

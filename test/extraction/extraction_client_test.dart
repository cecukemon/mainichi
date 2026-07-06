import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/extraction/extraction_client.dart';

import 'fake_dio_adapter.dart';

Map<String, dynamic> _messagesApiResponse(Map<String, dynamic> extraction) {
  return {
    'stop_reason': 'end_turn',
    'content': [
      {'type': 'text', 'text': jsonEncode(extraction)},
    ],
  };
}

void main() {
  test('throws ApiKeyMissing without calling the network when no key is set', () async {
    final adapter = FakeDioAdapter(statusCode: 200, body: {});
    final dio = Dio()..httpClientAdapter = adapter;
    final service = LiveExtractionService(apiKeyProvider: () async => null, dio: dio);

    await expectLater(
      () => service.extract(imageBytes: const [1, 2, 3], mediaType: 'image/jpeg'),
      throwsA(isA<ApiKeyMissing>()),
    );
    expect(adapter.lastRequest, isNull);
  });

  test('sends the api key header and parses the structured-output response', () async {
    final extraction = {
      'worksheet': {'title': 't', 'topic': 'topic', 'orientation_note': 'upright'},
      'vocabulary': <Object>[],
      'structures': <Object>[],
      'handwriting': {'detected': false, 'ignored_notes': <String>[]},
    };
    final adapter = FakeDioAdapter(statusCode: 200, body: _messagesApiResponse(extraction));
    final dio = Dio()..httpClientAdapter = adapter;
    final service = LiveExtractionService(apiKeyProvider: () async => 'sk-ant-test', dio: dio);

    final result = await service.extract(imageBytes: const [1, 2, 3], mediaType: 'image/png');

    expect(result, extraction);
    final sentHeaders = adapter.lastRequest!.headers;
    expect(sentHeaders['x-api-key'], 'sk-ant-test');
    expect(sentHeaders['anthropic-version'], '2023-06-01');
    final sentBody = adapter.lastRequest!.data as Map<String, dynamic>;
    final image = ((sentBody['messages'] as List).first['content'] as List).first as Map;
    expect(image['source']['media_type'], 'image/png');
  });
}

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/settings/api_key_store.dart';
import 'package:mainichi/speaking/stt_service.dart';

import '../extraction/fake_dio_adapter.dart';

void main() {
  test('throws ApiKeyMissing without calling the network when no key is set',
      () async {
    final adapter = FakeDioAdapter(statusCode: 200, body: {});
    final dio = Dio()..httpClientAdapter = adapter;
    final service = LiveSttService(apiKeyProvider: () async => null, dio: dio);

    await expectLater(
      () => service.transcribe([1, 2, 3]),
      throwsA(isA<ApiKeyMissing>()),
    );
    expect(adapter.lastRequest, isNull);
  });

  test('sends base64 LINEAR16 config + audio, returns the top transcript',
      () async {
    final audio = [1, 2, 3, 4];
    final adapter = FakeDioAdapter(
      statusCode: 200,
      body: {
        'results': [
          {
            'alternatives': [
              {'transcript': '田中はすしを食べますか', 'confidence': 0.94},
            ],
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final service =
        LiveSttService(apiKeyProvider: () async => 'AIza-test', dio: dio);

    final transcript = await service.transcribe(audio);

    expect(transcript, '田中はすしを食べますか');
    final request = adapter.lastRequest!;
    expect(request.queryParameters['key'], 'AIza-test');
    final sent = request.data as Map<String, dynamic>;
    expect(sent['config'], {
      'encoding': 'LINEAR16',
      'sampleRateHertz': sttSampleRateHertz,
      'languageCode': 'ja-JP',
    });
    expect(sent['audio'], {'content': base64Encode(audio)});
  });

  test('empty results (nothing recognized) returns the empty string, no throw',
      () async {
    final adapter = FakeDioAdapter(statusCode: 200, body: {'results': []});
    final dio = Dio()..httpClientAdapter = adapter;
    final service =
        LiveSttService(apiKeyProvider: () async => 'AIza-test', dio: dio);

    expect(await service.transcribe([1]), '');
  });

  test('absent results field also returns the empty string', () async {
    final adapter = FakeDioAdapter(statusCode: 200, body: {});
    final dio = Dio()..httpClientAdapter = adapter;
    final service =
        LiveSttService(apiKeyProvider: () async => 'AIza-test', dio: dio);

    expect(await service.transcribe([1]), '');
  });
}

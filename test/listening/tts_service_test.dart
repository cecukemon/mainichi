import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/listening/tts_service.dart';
import 'package:mainichi/settings/api_key_store.dart';

import '../extraction/fake_dio_adapter.dart';

void main() {
  test('throws ApiKeyMissing without calling the network when no key is set',
      () async {
    final adapter = FakeDioAdapter(statusCode: 200, body: {});
    final dio = Dio()..httpClientAdapter = adapter;
    final service = LiveTtsService(apiKeyProvider: () async => null, dio: dio);

    await expectLater(
      () => service.synthesize(text: 'すし。', voice: speakerVoiceA),
      throwsA(isA<ApiKeyMissing>()),
    );
    expect(adapter.lastRequest, isNull);
  });

  test('sends kana + voice, decodes the base64 MP3 payload', () async {
    final mp3 = [7, 8, 9];
    final adapter = FakeDioAdapter(
      statusCode: 200,
      body: {'audioContent': base64Encode(mp3)},
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final service =
        LiveTtsService(apiKeyProvider: () async => 'AIza-test', dio: dio);

    final bytes =
        await service.synthesize(text: 'たなかは たべます。', voice: speakerVoiceB);

    expect(bytes, mp3);
    final request = adapter.lastRequest!;
    expect(request.queryParameters['key'], 'AIza-test');
    final sent = request.data as Map<String, dynamic>;
    expect(sent['input'], {'text': 'たなかは たべます。'});
    expect(sent['voice'],
        {'languageCode': 'ja-JP', 'name': speakerVoiceB});
    expect(sent['audioConfig'], {'audioEncoding': 'MP3'});
  });
}

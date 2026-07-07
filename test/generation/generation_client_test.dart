import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/generation/conversation_generator.dart';
import 'package:mainichi/generation/generation_client.dart';
import 'package:mainichi/settings/api_key_store.dart';

import '../extraction/fake_dio_adapter.dart';

const _seed = GenerationSeed(
  vocab: [
    SeedWord(id: 20, kana: 'すずき', kanji: '鈴木', role: 'name'),
    SeedWord(id: 4, kana: 'ほん', role: 'noun', meaning: 'book'),
  ],
  structures: [
    SeedStructure(id: 1, template: 'これは {noun_1} です', slots: [
      SeedSlot(name: 'noun_1', role: 'noun'),
    ]),
  ],
);

Map<String, dynamic> _messagesApiResponse(Map<String, dynamic> generation) => {
      'stop_reason': 'end_turn',
      'content': [
        {'type': 'text', 'text': jsonEncode(generation)},
      ],
    };

void main() {
  test('throws ApiKeyMissing without calling the network when no key is set',
      () async {
    final adapter = FakeDioAdapter(statusCode: 200, body: {});
    final dio = Dio()..httpClientAdapter = adapter;
    final service =
        LiveGenerationService(apiKeyProvider: () async => null, dio: dio);

    await expectLater(
      () => service.generate(seed: _seed),
      throwsA(isA<ApiKeyMissing>()),
    );
    expect(adapter.lastRequest, isNull);
  });

  test('sends key header, seed context, and focus; parses the conversation',
      () async {
    final generation = {
      'lines': [
        {
          'speaker_name_id': 20,
          'speaker_surface': '鈴木',
          'text': 'これは ほん です。',
          'structure_id': 1,
          'tokens': [
            {'surface': 'これ', 'vocab_id': 0},
            {'surface': 'ほん', 'vocab_id': 4},
          ],
        },
      ],
      'used_vocab_ids': [4, 20],
      'used_structure_ids': [1],
    };
    final adapter =
        FakeDioAdapter(statusCode: 200, body: _messagesApiResponse(generation));
    final dio = Dio()..httpClientAdapter = adapter;
    final service = LiveGenerationService(
        apiKeyProvider: () async => 'sk-ant-test', dio: dio);

    final convo =
        await service.generate(seed: _seed, lineCount: 4, focus: 'books');

    expect(convo.lines.single.text, 'これは ほん です。');
    expect(convo.lines.single.tokens[1].vocabId, 4);
    expect(convo.usedStructureIds, [1]);

    final sentHeaders = adapter.lastRequest!.headers;
    expect(sentHeaders['x-api-key'], 'sk-ant-test');
    expect(sentHeaders['anthropic-version'], '2023-06-01');

    final sentBody = adapter.lastRequest!.data as Map<String, dynamic>;
    final system = (sentBody['system'] as List).cast<Map<String, dynamic>>();
    expect(system.last['text'], contains('ほん')); // seed reached the context
    expect(system.last['cache_control'], {'type': 'ephemeral'});
    final userMessage =
        (sentBody['messages'] as List).first['content'] as String;
    expect(userMessage, contains('4-line'));
    expect(userMessage, contains('books'));
  });

  test('surfaces a model refusal as GenerationRefused', () async {
    final adapter = FakeDioAdapter(statusCode: 200, body: {
      'stop_reason': 'refusal',
      'stop_details': 'declined',
      'content': <Object>[],
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final service = LiveGenerationService(
        apiKeyProvider: () async => 'sk-ant-test', dio: dio);

    await expectLater(
      () => service.generate(seed: _seed),
      throwsA(isA<GenerationRefused>()),
    );
  });
}

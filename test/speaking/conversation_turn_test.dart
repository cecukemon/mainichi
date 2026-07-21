import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/generation/conversation_generator.dart';
import 'package:mainichi/speaking/conversation_turn.dart';

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

// An in-scope persona line: ほん + です + か.
final Map<String, dynamic> _replyJson = {
  'speaker_name_id': 20,
  'speaker_surface': 'すずき',
  'text': 'ほんですか',
  'structure_id': 0,
  'tokens': [
    {'surface': 'ほん', 'vocab_id': 4},
    {'surface': 'です', 'vocab_id': 0},
    {'surface': 'か', 'vocab_id': 0},
  ],
};

Map<String, dynamic> _apiResponse(Map<String, dynamic> turn) => {
      'stop_reason': 'end_turn',
      'content': [
        {'type': 'text', 'text': jsonEncode(turn)},
      ],
    };

void main() {
  group('buildConversationTurnRequest', () {
    test('opening: cached constraint prefix, no-grade ask, no history', () {
      final req = buildConversationTurnRequest(seed: _seed);

      final system = req['system'] as List;
      expect(system, hasLength(2));
      final ctx = system[1] as Map;
      // The load-bearing detail: byte-identical to the generation prefix so
      // the prompt cache breakpoint is shared (D7).
      expect(ctx['text'], constraintContext(_seed));
      expect(ctx['cache_control'], {'type': 'ephemeral'});

      final content = ((req['messages'] as List).first as Map)['content']
          as String;
      expect(content, contains('opening line'));
      expect(content, isNot(contains('Conversation so far')));

      final schema = ((req['output_config'] as Map)['format']
          as Map)['schema'];
      expect(schema, same(conversationTurnSchema));
    });

    test('turn: history and the latest reply appear in the user message', () {
      final req = buildConversationTurnRequest(
        seed: _seed,
        personaSurface: 'すずき',
        history: const [
          TurnHistory(personaLine: 'ほんですか', learnerReply: 'はい'),
          TurnHistory(personaLine: 'ほんはおもしろいですか', learnerReply: null),
        ],
        latestReply: 'はい、おもしろいです',
      );

      final content = ((req['messages'] as List).first as Map)['content']
          as String;
      expect(content, contains('Conversation so far'));
      expect(content, contains('すずき: ほんですか'));
      expect(content, contains('はい')); // the earlier reply
      expect(content, contains('すずき: ほんはおもしろいですか'));
      expect(content, contains('はい、おもしろいです')); // the latest reply
      // The cache prefix is unchanged across turns.
      expect(((req['system'] as List)[1] as Map)['text'],
          constraintContext(_seed));
    });
  });

  test('conversationTurnSchema: reply required, grade optional', () {
    expect(conversationTurnSchema['required'], ['reply']);
    final props = conversationTurnSchema['properties'] as Map;
    expect(props.containsKey('grade'), isTrue);
    final reply = props['reply'] as Map;
    expect(
      reply['required'] as List,
      containsAll(<String>[
        'speaker_name_id',
        'speaker_surface',
        'text',
        'structure_id',
        'tokens',
      ]),
    );
  });

  group('parseConversationTurn', () {
    test('opening response: reply parsed, grade null', () {
      final turn = parseConversationTurn(_apiResponse({'reply': _replyJson}));
      expect(turn.grade, isNull);
      expect(turn.reply.text, 'ほんですか');
      expect(turn.reply.speakerNameId, 20);
      expect(turn.reply.tokens, hasLength(3));
    });

    test('graded turn: verdict, note, and rewrite parsed', () {
      final turn = parseConversationTurn(_apiResponse({
        'grade': {
          'verdict': 'awkward',
          'note': 'Word order is off.',
          'rewrite': 'はい、すきです',
        },
        'reply': _replyJson,
      }));
      expect(turn.grade!.verdict, TurnVerdict.awkward);
      expect(turn.grade!.note, 'Word order is off.');
      expect(turn.grade!.rewrite, 'はい、すきです');
    });

    test('an unknown verdict degrades to off, not a throw', () {
      final turn = parseConversationTurn(_apiResponse({
        'grade': {'verdict': 'splendid', 'note': '', 'rewrite': ''},
        'reply': _replyJson,
      }));
      expect(turn.grade!.verdict, TurnVerdict.off);
    });

    test('refusal and truncation throw the generator exceptions', () {
      expect(
        () => parseConversationTurn(
            {'stop_reason': 'refusal', 'stop_details': {}}),
        throwsA(isA<GenerationRefused>()),
      );
      expect(
        () => parseConversationTurn({'stop_reason': 'max_tokens', 'content': []}),
        throwsA(isA<GenerationTruncated>()),
      );
    });
  });

  group('validateNextLine', () {
    test('accepts an in-scope line', () {
      const line = GenLine(
        speakerNameId: 20,
        speakerSurface: 'すずき',
        text: 'ほんですか',
        structureId: 0,
        tokens: [
          GenToken(surface: 'ほん', vocabId: 4),
          GenToken(surface: 'です', vocabId: 0),
          GenToken(surface: 'か', vocabId: 0),
        ],
      );
      expect(validateNextLine(line, _seed).ok, isTrue);
    });

    test('rejects an out-of-scope line (unknown vocab id)', () {
      const line = GenLine(
        speakerNameId: 20,
        speakerSurface: 'すずき',
        text: 'ねこです',
        structureId: 0,
        tokens: [
          GenToken(surface: 'ねこ', vocabId: 999),
          GenToken(surface: 'です', vocabId: 0),
        ],
      );
      expect(validateNextLine(line, _seed).ok, isFalse);
    });
  });
}

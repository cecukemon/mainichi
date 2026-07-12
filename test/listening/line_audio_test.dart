import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/generation/conversation_generator.dart';
import 'package:mainichi/listening/line_audio.dart';
import 'package:mainichi/listening/tts_service.dart';

const _seed = GenerationSeed(
  vocab: [
    SeedWord(id: 20, kana: 'すずき', kanji: '鈴木', role: 'name'),
    SeedWord(id: 21, kana: 'たなか', kanji: '田中', role: 'name'),
    SeedWord(id: 5, kana: 'すし', role: 'noun', meaning: 'sushi'),
    SeedWord(id: 31, kana: 'たべる', kanji: '食べる', role: 'verb', meaning: 'to eat'),
  ],
  structures: [
    SeedStructure(id: 1, template: '{noun_1} を {verb_1}', slots: [
      SeedSlot(name: 'noun_1', role: 'noun'),
      SeedSlot(name: 'verb_1', role: 'verb', form: 'polite'),
    ]),
  ],
);

GenLine _line({
  int speaker = 20,
  required String text,
  required List<GenToken> tokens,
}) =>
    GenLine(
      speakerNameId: speaker,
      speakerSurface: '鈴木',
      text: text,
      structureId: 0,
      tokens: tokens,
    );

void main() {
  test('kanaLine speaks store readings for kanji surfaces, glue as-is', () {
    final line = _line(
      text: '田中は 食べます。',
      tokens: const [
        GenToken(surface: '田中', vocabId: 21),
        GenToken(surface: 'は', vocabId: 0),
        GenToken(surface: '食べます', vocabId: 31),
      ],
    );
    expect(kanaLine(line, _seed), 'たなかは たべます。');
  });

  test('kanaLine keeps punctuation from text even when tokens omit it (D42)',
      () {
    final line = _line(
      text: 'いいえ、すしを 食べません。',
      tokens: const [
        GenToken(surface: 'いいえ', vocabId: 0),
        GenToken(surface: 'すし', vocabId: 5),
        GenToken(surface: 'を', vocabId: 0),
        GenToken(surface: '食べません', vocabId: 31),
      ],
    );
    expect(kanaLine(line, _seed), 'いいえ、すしを たべません。');
  });

  test('voices map per speaker: first → A, second → B, third wraps', () {
    final convo = GeneratedConversation(
      lines: [
        _line(speaker: 20, text: 'すし。', tokens: const [
          GenToken(surface: 'すし', vocabId: 5),
        ]),
        _line(speaker: 21, text: 'すし。', tokens: const [
          GenToken(surface: 'すし', vocabId: 5),
        ]),
        _line(speaker: 20, text: 'すし。', tokens: const [
          GenToken(surface: 'すし', vocabId: 5),
        ]),
        _line(speaker: 99, text: 'すし。', tokens: const [
          GenToken(surface: 'すし', vocabId: 5),
        ]),
      ],
      usedVocabIds: const [5],
      usedStructureIds: const [],
    );
    final specs = lineAudioSpecs(convo, _seed);
    expect(specs.map((s) => s.voice).toList(), [
      speakerVoiceA,
      speakerVoiceB,
      speakerVoiceA,
      speakerVoiceA, // third distinct speaker wraps rather than failing
    ]);
    expect(specs.first.kana, 'すし。');
  });
}

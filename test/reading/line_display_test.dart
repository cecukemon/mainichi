import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/generation/conversation_generator.dart';
import 'package:mainichi/reading/line_display.dart';

const _seed = GenerationSeed(
  vocab: [
    SeedWord(id: 20, kana: 'すずき', kanji: '鈴木', role: 'name'),
    SeedWord(id: 31, kana: 'たべる', kanji: '食べる', role: 'verb', meaning: 'to eat'),
    SeedWord(id: 5, kana: 'すし', role: 'noun', meaning: 'sushi'),
  ],
  structures: [],
);

GenLine _line(String text, List<GenToken> tokens) => GenLine(
      speakerNameId: 20,
      speakerSurface: '鈴木',
      text: text,
      structureId: 0,
      tokens: tokens,
    );

void main() {
  test('vocab tokens carry their entry and furigana; glue is plain', () {
    final tokens = displayTokens(
      _line('鈴木は すしを 食べません。', const [
        GenToken(surface: '鈴木', vocabId: 20),
        GenToken(surface: 'は', vocabId: 0),
        GenToken(surface: 'すし', vocabId: 5),
        GenToken(surface: 'を', vocabId: 0),
        GenToken(surface: '食べません', vocabId: 31),
      ]),
      _seed,
    );

    final suzuki = tokens.firstWhere((t) => t.surface == '鈴木');
    expect(suzuki.isTappable, isTrue);
    expect(suzuki.segments.single.ruby, 'すずき');

    final taberu = tokens.firstWhere((t) => t.surface == '食べません');
    expect(taberu.entry!.meaning, 'to eat');
    expect(readingOf(taberu.segments), 'たべません');

    final wa = tokens.firstWhere((t) => t.surface == 'は');
    expect(wa.isTappable, isFalse);
  });

  test('punctuation comes from text even when tokens omit it (D42)', () {
    // The model's known variance: 、 present in text, missing from tokens.
    final tokens = displayTokens(
      _line('はい、すしです。', const [
        GenToken(surface: 'はい', vocabId: 0),
        GenToken(surface: 'すし', vocabId: 5),
        GenToken(surface: 'です', vocabId: 0),
      ]),
      _seed,
    );

    expect(tokens.map((t) => t.surface).join(), 'はい、すしです。');
    expect(tokens.firstWhere((t) => t.surface == '、').isTappable, isFalse);
  });

  test('an unreconcilable surface renders plain instead of wrong furigana',
      () {
    // Wrong vocab id for the surface: okurigana matching fails → not tappable.
    final tokens = displayTokens(
      _line('すし', const [GenToken(surface: 'すし', vocabId: 31)]),
      _seed,
    );
    expect(tokens.single.isTappable, isFalse);
    expect(tokens.single.segments.single.ruby, isNull);
  });

  test('a token missing from text still renders rather than disappearing', () {
    final tokens = displayTokens(
      _line('すしです。', const [
        GenToken(surface: 'すし', vocabId: 5),
        GenToken(surface: 'ですか', vocabId: 0), // not in text
      ]),
      _seed,
    );
    expect(tokens.map((t) => t.surface),
        containsAll(['すし', 'ですか', 'です。']));
  });
}

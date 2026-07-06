import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/japanese/segmenter.dart';

const _glue = {
  'は', 'を', 'に', 'か',
  'です', 'では', 'ありません',
  'はい', 'いいえ', 'この',
};

const _lexicon = [
  LexiconEntry(id: 1, kana: 'これ', role: 'demonstrative'),
  LexiconEntry(id: 4, kana: 'ほん', role: 'noun'),
  LexiconEntry(id: 20, kana: 'すずき', kanji: '鈴木', role: 'name'),
  LexiconEntry(id: 30, kana: 'いく', kanji: '行く', role: 'verb'),
  LexiconEntry(id: 31, kana: 'たべる', kanji: '食べる', role: 'verb'),
  LexiconEntry(id: 32, kana: 'のむ', role: 'verb'), // kana-only godan
  LexiconEntry(id: 40, kana: 'おもしろい', kanji: '面白い', role: 'i_adjective'),
];

const _forms = {'dictionary', 'polite', 'polite_negative', 'negative'};

SegmentationResult _factor(String text, {Set<String> forms = _forms}) =>
    factorLine(text, lexicon: _lexicon, taughtForms: forms, glue: _glue);

void main() {
  test('factors a copula line into words, glue, and punctuation', () {
    final r = _factor('これは ほん です。');
    expect(r.ok, isTrue);
    expect(
      r.segments!.map((s) => s.toString()).toList(),
      ['これ(word#1)', 'は(glue)', ' (punctuation)', 'ほん(word#4)', ' (punctuation)', 'です(glue)', '。(punctuation)'],
    );
  });

  test('factors taught conjugations: ichidan, godan, and kanji forms', () {
    expect(_factor('鈴木は 食べます。').ok, isTrue); // ichidan, kanji stem
    expect(_factor('たべません').ok, isTrue); // ichidan kana, polite negative
    expect(_factor('のみます').ok, isTrue); // godan i-row connector (む→み)
    expect(_factor('行きます').ok, isTrue); // godan, kanji stem (く→き)
  });

  test('factors the i-adjective negative with ありません as glue', () {
    expect(_factor('この ほんは 面白く ありません。').ok, isTrue);
    expect(_factor('おもしろくありません').ok, isTrue); // fused, no spaces
  });

  test('tolerates fused glue (ではありません) without token boundaries', () {
    expect(_factor('これは ほん ではありません。').ok, isTrue);
  });

  test('rejects an untaught word, reporting where it got stuck', () {
    final r = _factor('これは ねこ です');
    expect(r.ok, isFalse);
    expect(r.unmatchedFrom, startsWith('ねこ'));
  });

  test('rejects an untaught honorific even beside taught material (さん)', () {
    final r = _factor('鈴木さんは');
    expect(r.ok, isFalse);
    expect(r.unmatchedFrom, startsWith('さん'));
  });

  test('rejects an untaught conjugation of a taught verb (volitional)', () {
    // 行きましょう: taught stem 行 + き, but ましょう is not a taught ending.
    // This is exactly what the per-token check cannot catch — its
    // pure-kana-tail rule accepts any kana after the stem.
    final r = _factor('行きましょう');
    expect(r.ok, isFalse);
  });

  test('conjugations are gated on the taught forms, not assumed', () {
    // Same line, but no structure has taught the polite form yet.
    final r = _factor('行きます', forms: {'dictionary'});
    expect(r.ok, isFalse);
    // The dictionary form itself is always available.
    expect(_factor('行く', forms: {'dictionary'}).ok, isTrue);
  });

  test('unmapped taught forms (te) flag rather than pass silently', () {
    // If a worksheet someday teaches the te-form, its lines fail factoring
    // until _verbSuffixes learns the (irregular-prone) mapping — the same
    // extend-on-first-contact discipline as knownGrammarGlue.
    final r = _factor('食べて', forms: {..._forms, 'te'});
    expect(r.ok, isFalse);
  });

  test('handles ideographic spaces and empty lines', () {
    expect(_factor('これは　ほん　です').ok, isTrue); // U+3000 separators
    expect(_factor('').ok, isTrue);
  });

  test('backtracks out of a wrong greedy pick', () {
    // Longest-first would try これ before this hypothetical longer word if
    // one existed; the classic trap needs a piece that is a prefix of
    // another. ここ (id 50) vs こ...: build a lexicon where greedy must
    // retreat: ここは = ここ+は, but with ここのほん taught as one word,
    // longest-first tries it and must backtrack when the rest fails.
    const lexicon = [
      LexiconEntry(id: 50, kana: 'ここ', role: 'noun'),
      LexiconEntry(id: 51, kana: 'ここのほんだ', role: 'noun'),
      LexiconEntry(id: 4, kana: 'ほん', role: 'noun'),
      LexiconEntry(id: 52, kana: 'の', role: 'particle'),
    ];
    final r = factorLine('ここのほんです',
        lexicon: lexicon, taughtForms: const {'dictionary'}, glue: _glue);
    expect(r.ok, isTrue);
    expect(r.segments!.first.wordId, 50); // ここ, not the greedy ここのほんだ
  });
}

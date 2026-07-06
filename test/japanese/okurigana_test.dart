import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/japanese/okurigana.dart';

void main() {
  group('splitOkurigana', () {
    test('verb: 行く/いく → stem 行/い, okurigana く', () {
      final s = splitOkurigana(kana: 'いく', kanji: '行く');
      expect(s.kanjiStem, '行');
      expect(s.stemReading, 'い');
      expect(s.okurigana, 'く');
    });

    test('ichidan verb: 食べる/たべる → stem 食/た, okurigana べる', () {
      final s = splitOkurigana(kana: 'たべる', kanji: '食べる');
      expect(s.kanjiStem, '食');
      expect(s.stemReading, 'た');
      expect(s.okurigana, 'べる');
    });

    test('i-adjective: 面白い/おもしろい → stem 面白/おもしろ, okurigana い', () {
      final s = splitOkurigana(kana: 'おもしろい', kanji: '面白い');
      expect(s.kanjiStem, '面白');
      expect(s.stemReading, 'おもしろ');
      expect(s.okurigana, 'い');
    });

    test('mixed-script name: 田なか/たなか → stem 田/た, okurigana なか', () {
      final s = splitOkurigana(kana: 'たなか', kanji: '田なか');
      expect(s.kanjiStem, '田');
      expect(s.stemReading, 'た');
      expect(s.okurigana, 'なか');
    });

    test('all-kanji word: 鈴木/すずき → whole-word stem, no okurigana', () {
      final s = splitOkurigana(kana: 'すずき', kanji: '鈴木');
      expect(s.kanjiStem, '鈴木');
      expect(s.stemReading, 'すずき');
      expect(s.okurigana, '');
    });
  });

  group('furiganaSegments', () {
    List<FuriganaSegment>? verb(String surface) => furiganaSegments(
        surface: surface, kana: 'いく', kanji: '行く', conjugates: true);

    test('base form: ruby over the stem only, okurigana plain', () {
      expect(verb('行く'),
          [const FuriganaSegment('行', 'い'), const FuriganaSegment('く')]);
    });

    test('conjugated form: same stem ruby, conjugated tail plain — the D5 okurigana fix', () {
      expect(verb('行きます'),
          [const FuriganaSegment('行', 'い'), const FuriganaSegment('きます')]);
      expect(verb('行きません'),
          [const FuriganaSegment('行', 'い'), const FuriganaSegment('きません')]);
    });

    test('kana-written form of a kanji-taught word is plain, not an error', () {
      expect(verb('いく'), [const FuriganaSegment('いく')]);
      expect(verb('いきます'), [const FuriganaSegment('いきます')]);
    });

    test('godan stem-kana change (のむ→のみます) is accepted as pure-kana conjugation', () {
      final segs = furiganaSegments(
          surface: '飲みます', kana: 'のむ', kanji: '飲む', conjugates: true);
      expect(segs,
          [const FuriganaSegment('飲', 'の'), const FuriganaSegment('みます')]);
      final kanaSegs = furiganaSegments(
          surface: 'のみます', kana: 'のむ', kanji: '飲む', conjugates: true);
      expect(kanaSegs, [const FuriganaSegment('のみます')]);
    });

    test('non-conjugating word must match exactly — conjugated tail rejected', () {
      expect(
        furiganaSegments(
            surface: '鈴木', kana: 'すずき', kanji: '鈴木', conjugates: false),
        [const FuriganaSegment('鈴木', 'すずき')],
      );
      expect(
        furiganaSegments(
            surface: '鈴木です', kana: 'すずき', kanji: '鈴木', conjugates: false),
        isNull,
      );
    });

    test('kana-only entry: surface must be the kana or a kana conjugation of it', () {
      expect(
        furiganaSegments(surface: 'たべる', kana: 'たべる', kanji: '', conjugates: true),
        [const FuriganaSegment('たべる')],
      );
      expect(
        furiganaSegments(surface: 'たべます', kana: 'たべる', kanji: '', conjugates: true),
        [const FuriganaSegment('たべます')],
      );
      // Kanji surface for a kanji-less entry is never reconcilable here
      // (validateScope also flags it separately as untaught kanji).
      expect(
        furiganaSegments(surface: '食べます', kana: 'たべる', kanji: '', conjugates: true),
        isNull,
      );
    });

    test('hallucinated kana surface with a valid id is rejected — the laundering gap', () {
      // ねこ tagged with the entry for ほん: nothing connects the surface to
      // the entry, so it must not silently render (with wrong furigana) or
      // pass validation.
      expect(
        furiganaSegments(surface: 'ねこ', kana: 'ほん', kanji: '', conjugates: false),
        isNull,
      );
      expect(
        furiganaSegments(surface: 'いきます', kana: 'のむ', kanji: '飲む', conjugates: true),
        isNull,
      );
    });

    test('surrounding punctuation splits into plain segments', () {
      expect(verb('行きます。'), [
        const FuriganaSegment('行', 'い'),
        const FuriganaSegment('きます'),
        const FuriganaSegment('。'),
      ]);
      expect(
        furiganaSegments(surface: 'ほん、', kana: 'ほん', kanji: '', conjugates: false),
        [const FuriganaSegment('ほん'), const FuriganaSegment('、')],
      );
    });

    test('a mid-word reading break is not silently accepted (wrong-tail garbage)', () {
      expect(verb('行漢字'), isNull); // stem + non-kana tail
    });

    test('katakana word round-trips (long vowel mark is kana)', () {
      expect(
        furiganaSegments(surface: 'スミス', kana: 'スミス', kanji: '', conjugates: false),
        [const FuriganaSegment('スミス')],
      );
    });
  });
}

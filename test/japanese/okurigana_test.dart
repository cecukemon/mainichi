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

    test('no glue set supplied: a fused particle is still rejected', () {
      // furiganaSegments keeps its pre-D74 contract — the peel is opt-in via
      // matchSurface's trailingGlue.
      expect(
        furiganaSegments(
            surface: 'あなたは', kana: 'あなた', kanji: '', conjugates: false),
        isNull,
      );
    });
  });

  group('matchSurface trailing-glue peel (D74)', () {
    const glue = {'は', 'を', 'に', 'か', 'の', 'です'};

    SurfaceMatch? match(String surface,
            {String kana = 'あなた',
            String kanji = '',
            bool conjugates = false}) =>
        matchSurface(
          surface: surface,
          kana: kana,
          kanji: kanji,
          conjugates: conjugates,
          trailingGlue: glue,
        );

    test('the live failure: あなたは tagged as あなた is accepted and split', () {
      // Observed live — the model fused the topic particle into the content
      // token instead of emitting it as separate glue.
      final m = match('あなたは')!;
      expect(m.base, 'あなた');
      expect(m.trailing, 'は');
      expect(m.hadFusedGlue, isTrue);
      expect(m.segments, [const FuriganaSegment('あなた')]);
    });

    test('a clean surface reports no fused glue and keeps the whole surface',
        () {
      final m = match('あなた')!;
      expect(m.base, 'あなた');
      expect(m.trailing, '');
      expect(m.hadFusedGlue, isFalse);
    });

    test('furigana still covers the word alone when kanji is fused with glue',
        () {
      // The real payoff: 先生は would otherwise render plain, losing furigana.
      final m = match('先生は', kana: 'せんせい', kanji: '先生')!;
      expect(m.base, '先生');
      expect(m.trailing, 'は');
      expect(m.segments, [const FuriganaSegment('先生', 'せんせい')]);
    });

    test('multiple fused particles peel together', () {
      final m = match('あなたには')!;
      expect(m.base, 'あなた');
      expect(m.trailing, 'には');
    });

    test('a direct match wins over any peel — a real conjugation is not split',
        () {
      // ます-style endings can appear in a table-backed glue set; a legitimately
      // tokenized 飲みます must stay whole so the lookup sheet can still
      // recognize its polite form.
      final m = matchSurface(
        surface: '飲みます',
        kana: 'のむ',
        kanji: '飲む',
        conjugates: true,
        trailingGlue: {...glue, 'ます'},
      );
      expect(m!.base, '飲みます');
      expect(m.trailing, '');
      expect(m.segments,
          [const FuriganaSegment('飲', 'の'), const FuriganaSegment('みます')]);
    });

    test('a multi-piece tail peels as a unit (先生ですか → 先生 + ですか)', () {
      // Walks split points down from the longest head: 先生です is not a form
      // of the entry, so it keeps going until the whole ですか factors off.
      final m = match('先生ですか', kana: 'せんせい', kanji: '先生')!;
      expect(m.base, '先生');
      expect(m.trailing, 'ですか');
      expect(m.segments, [const FuriganaSegment('先生', 'せんせい')]);
    });

    test('a conjugating entry keeps its whole tail rather than peeling it', () {
      // The kana-conjugation rule already accepts any pure-kana tail sharing
      // the stem, so のみますか matches directly and never reaches the peel —
      // which is what preserves the polite-form annotation in the lookup sheet.
      final m = matchSurface(
        surface: 'のみますか',
        kana: 'のむ',
        kanji: '飲む',
        conjugates: true,
        trailingGlue: {...glue, 'ます'},
      );
      expect(m!.base, 'のみますか');
      expect(m.hadFusedGlue, isFalse);
    });

    test('the peel does not launder a hallucinated surface', () {
      // ねこ tagged with the entry for あなた: no split leaves a head that
      // reconciles, so this stays a violation (the D24/laundering guarantee).
      expect(match('ねこは'), isNull);
      expect(match('ねこ'), isNull);
    });

    test('the peel cannot consume the entire surface', () {
      // は alone tagged as a content word must not "match" by peeling itself.
      expect(match('は'), isNull);
      expect(match('はは', kana: 'はは'), isNotNull); // real word, direct match
    });

    test('trailing punctuation rides along behind the peeled glue', () {
      final m = match('あなたは、')!;
      expect(m.base, 'あなた');
      expect(m.trailing, 'は、');
    });

    test('an untaught tail is not peelable', () {
      // さん is not in the glue set — fusing it must still fail (the D20 bug
      // must not come back through this door).
      expect(match('あなたさん'), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/speaking/read_aloud_grader.dart';

void main() {
  ReadAloudVerdict grade(String expected, String transcript) =>
      gradeReadAloud(expected: expected, transcript: transcript);

  group('normalizeForGrading', () {
    test('drops whitespace and Japanese/ASCII punctuation', () {
      expect(normalizeForGrading('田中は、すしを 食べますか。'), '田中はすしを食べますか');
      expect(normalizeForGrading('いいえ、 食べません！'), 'いいえ食べません');
    });

    test('keeps the kana length mark ー (it is pronunciation)', () {
      expect(normalizeForGrading('コーヒー'), 'コーヒー');
    });

    test('folds full-width ASCII to half-width', () {
      expect(normalizeForGrading('ＡＢＣ'), 'ABC');
    });
  });

  group('gradeReadAloud', () {
    test('identical text is a match', () {
      expect(grade('すしを食べます', 'すしを食べます'), ReadAloudVerdict.match);
    });

    test('punctuation-only differences still match (STT omits punctuation)',
        () {
      expect(grade('田中は、すしを食べますか。', '田中はすしを食べますか'),
          ReadAloudVerdict.match);
    });

    test('a single dropped particle is close, not a match or a miss', () {
      // Learner/STT dropped を out of a 7-char line.
      expect(grade('すしを食べます', 'すし食べます'), ReadAloudVerdict.close);
    });

    test('completely different speech is a mismatch', () {
      expect(grade('すしを食べます', 'こんにちは'), ReadAloudVerdict.mismatch);
    });

    group('kanji tolerance (D68)', () {
      test('a kana-only line read perfectly matches even when STT writes kanji',
          () {
        // The two live cases: すき → 好き, わたし → 私 (1 kanji for 3 kana).
        expect(grade('あなたはコーヒーがすきですか?', 'あなたはコーヒーが好きですか'),
            ReadAloudVerdict.match);
        expect(grade('はい、わたしはコーヒーがすきです。', 'はい、私はコーヒーが好きです'),
            ReadAloudVerdict.match);
      });

      test('a single kanji standing in for one kana still matches', () {
        expect(grade('すきです', '好きです'), ReadAloudVerdict.match);
      });

      test('a wrong reading of a kana word still fails on the kana skeleton',
          () {
        // すき misread as きらい, heard in kanji: the surrounding kana match but
        // き≠ら / い trips it — kanji tolerance must not launder this into a pass.
        final verdict = grade('わたしはすきです', 'わたしは嫌いです');
        expect(verdict, isNot(ReadAloudVerdict.match));
      });

      test('a lone kanji cannot absorb a whole line for free', () {
        // The absorb cap: one kanji can't stand in for an entire sentence.
        expect(grade('あなたはコーヒーがすきですか', '好'), ReadAloudVerdict.mismatch);
      });
    });

    test('empty transcript (recognizer heard nothing) is a mismatch', () {
      expect(grade('すしを食べます', ''), ReadAloudVerdict.mismatch);
    });

    test('empty expected is a mismatch (nothing to grade against)', () {
      expect(grade('', 'すし'), ReadAloudVerdict.mismatch);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/japanese/polite_form.dart';

void main() {
  group('politeFormSuspicion', () {
    test('unambiguous endings: ませんでした, ました, ません', () {
      expect(politeFormSuspicion('もらいませんでした'), PoliteFormSuspicion.unambiguous);
      expect(politeFormSuspicion('もらいました'), PoliteFormSuspicion.unambiguous);
      expect(politeFormSuspicion('のみません'), PoliteFormSuspicion.unambiguous);
      expect(politeFormSuspicion('たべませんでした'), PoliteFormSuspicion.unambiguous);
    });

    test('ambiguous ます ending', () {
      expect(politeFormSuspicion('もらいます'), PoliteFormSuspicion.ambiguousMasu);
      // 励ます — a legitimate dictionary-form verb, still flagged for a human
      // to confirm (suspicion tier, not a verdict).
      expect(politeFormSuspicion('はげます'), PoliteFormSuspicion.ambiguousMasu);
    });

    test('no polite suffix at all', () {
      expect(politeFormSuspicion('たべる'), PoliteFormSuspicion.none);
      expect(politeFormSuspicion('ほん'), PoliteFormSuspicion.none);
    });

    test('a bare suffix with no stem is not a verb, not a suspicion', () {
      expect(politeFormSuspicion('ます'), PoliteFormSuspicion.none);
      expect(politeFormSuspicion('ました'), PoliteFormSuspicion.none);
      expect(politeFormSuspicion('ませんでした'), PoliteFormSuspicion.none);
    });
  });

  group('baseFormCandidates', () {
    test('godan i-row stem: godan candidate first, then ichidan', () {
      expect(baseFormCandidates('もらいます'), ['もらう', 'もらいる']);
    });

    test('e-row stem: ichidan only', () {
      expect(baseFormCandidates('たべます'), ['たべる']);
    });

    test('irregular する', () {
      expect(baseFormCandidates('します'), ['する']);
    });

    test('irregular くる — both irregular and legitimate ichidan 着る offered', () {
      expect(baseFormCandidates('きます'), ['くる', 'きる']);
    });

    test('works across the unambiguous suffixes too', () {
      expect(baseFormCandidates('もらいました'), ['もらう', 'もらいる']);
      expect(baseFormCandidates('もらいませんでした'), ['もらう', 'もらいる']);
    });

    test('no polite suffix or empty stem yields no candidates', () {
      expect(baseFormCandidates('たべる'), isEmpty);
      expect(baseFormCandidates('ます'), isEmpty);
    });
  });

  group('transformKanjiBaseForm', () {
    test('strips the polite suffix and matches the chosen kana ending', () {
      expect(transformKanjiBaseForm('飲みます', 'のむ'), '飲む');
    });

    test('kanji not ending in the polite suffix returns null', () {
      // Already dictionary form — nothing to strip.
      expect(transformKanjiBaseForm('食べる', 'たべる'), isNull);
    });

    test('empty kanji or chosen base returns null', () {
      expect(transformKanjiBaseForm('', 'たべる'), isNull);
      expect(transformKanjiBaseForm('食べます', ''), isNull);
    });
  });
}

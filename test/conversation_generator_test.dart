import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/glue_seed.dart';
import 'package:mainichi/generation/conversation_generator.dart';

const _seed = GenerationSeed(
  vocab: [
    SeedWord(id: 1, kana: 'これ', role: 'demonstrative', kanaOnly: true),
    SeedWord(id: 4, kana: 'ほん', role: 'noun', meaning: 'book', kanaOnly: true),
    SeedWord(id: 20, kana: 'すずき', kanji: '鈴木', role: 'name', meaning: 'Suzuki'),
  ],
  structures: [
    SeedStructure(
      id: 1,
      template: 'これは {noun_1} です',
      slots: [SeedSlot(name: 'noun_1', role: 'noun')],
    ),
  ],
);

GeneratedConversation _convo(List<GenToken> tokens,
        {int speaker = 20,
        int structureId = 1,
        String text = 'これは ほん です'}) =>
    GeneratedConversation(
      lines: [
        GenLine(
          speakerNameId: speaker,
          speakerSurface: 'すずき',
          text: text,
          structureId: structureId,
          tokens: tokens,
        ),
      ],
      usedVocabIds: const [4],
      usedStructureIds: const [1],
    );

void main() {
  test('the table seed rows pin against the glue constant (D56)', () {
    // glue_seed.dart (data layer) and seedGrammarGlue (generation layer)
    // deliberately don't import each other; this test is what keeps them in
    // sync.
    expect(
      grammarGlueSeedRows.map((r) => r.$1).toSet(),
      seedGrammarGlue,
    );
  });

  group('buildGenerationRequest', () {
    final req = buildGenerationRequest(seed: _seed, lineCount: 5);

    test('uses structured output and the requested line count', () {
      expect((req['output_config']['format'] as Map)['type'], 'json_schema');
      expect(((req['messages'] as List).first as Map)['content'],
          contains('5-line'));
    });

    test('constraint context is a cacheable system block', () {
      final system = req['system'] as List;
      expect(system, hasLength(2));
      final ctx = system[1] as Map;
      expect(ctx['cache_control'], {'type': 'ephemeral'});
      expect(
          ctx['text'],
          allOf(contains('VOCABULARY'), contains('STRUCTURES'),
              contains('GRAMMAR GLUE')));
    });

    test('grammar glue is listed sorted, byte-stable across insertion orders '
        '(the cache breakpoint sits on this text, D56)', () {
      GenerationSeed withGlue(Set<String> glue) =>
          GenerationSeed(vocab: _seed.vocab, structures: _seed.structures, glue: glue);
      final a = constraintContext(withGlue({'は', 'が', 'です'}));
      final b = constraintContext(withGlue({'です', 'は', 'が'}));
      expect(a, b);
      expect(a.indexOf('"が"'), lessThan(a.indexOf('"です"')));
    });

    test('marks kana-only vocab explicitly in the context', () {
      final ctx = ((req['system'] as List)[1] as Map)['text'] as String;
      // これ (id 1 in _seed below) is kana-only; ほん is not tested here since
      // this seed only has kanaOnly words — see the dedicated seed above.
      expect(ctx, contains('"kana_only": true'));
    });

    test('omits the focus steer by default', () {
      final content =
          ((req['messages'] as List).first as Map)['content'] as String;
      expect(content, isNot(contains('Favor')));
    });

    test('adds an optional focus steer without touching scope rules', () {
      final focused = buildGenerationRequest(
        seed: _seed,
        focus: 'eating and drinking',
      );
      final content =
          ((focused['messages'] as List).first as Map)['content'] as String;
      expect(content, contains('Favor vocabulary and patterns about: eating and drinking.'));
    });
  });

  group('parseGenerationResponse', () {
    Map<String, dynamic> wrap(Map<String, dynamic> convo) => {
          'stop_reason': 'end_turn',
          'content': [
            {'type': 'text', 'text': jsonEncode(convo)},
          ],
        };

    test('parses lines, tokens, and used ids', () {
      final convo = parseGenerationResponse(wrap({
        'lines': [
          {
            'speaker_name_id': 20,
            'speaker_surface': 'すずき',
            'text': 'これは ほん です',
            'structure_id': 1,
            'tokens': [
              {'surface': 'ほん', 'vocab_id': 4},
              {'surface': 'です', 'vocab_id': 0},
            ],
          },
        ],
        'used_vocab_ids': [4],
        'used_structure_ids': [1],
      }));
      expect(convo.lines.single.speakerNameId, 20);
      expect(convo.lines.single.tokens.last.isGlue, isTrue);
      expect(convo.usedVocabIds, [4]);
    });

    test('throws on refusal', () {
      expect(
        () => parseGenerationResponse(
            {'stop_reason': 'refusal', 'stop_details': {}, 'content': []}),
        throwsA(isA<GenerationRefused>()),
      );
    });
  });

  group('validateScope', () {
    test('clean conversation passes', () {
      // Token split matches observed live tokenization: これ and は are
      // separate tokens, not one combined "これは".
      final report = validateScope(
        _convo(const [
          GenToken(surface: 'これ', vocabId: 1),
          GenToken(surface: 'は', vocabId: 0),
          GenToken(surface: 'ほん', vocabId: 4),
          GenToken(surface: 'です', vocabId: 0),
        ]),
        _seed,
      );
      expect(report.ok, isTrue);
    });

    test('an ASCII ? is treated as punctuation, not untaught material '
        '(regression, 2026-07-19)', () {
      // Live failure: the model ended a question with an ASCII "?" (U+003F)
      // instead of the full-width "？", and both the reconstruction and
      // factoring checks flagged it because their punctuation classes only
      // listed the full-width marks.
      final report = validateScope(
        _convo(
          const [
            GenToken(surface: 'これ', vocabId: 1),
            GenToken(surface: 'は', vocabId: 0),
            GenToken(surface: 'ほん', vocabId: 4),
            GenToken(surface: 'です', vocabId: 0),
            GenToken(surface: 'か', vocabId: 0),
          ],
          text: 'これは ほん ですか?',
        ),
        _seed,
      );
      expect(report.violations, isEmpty);
    });

    test('every glue token grounded in live generation runs passes', () {
      // Union observed across the copula/adjective/demonstrative/verb
      // validation runs (decision D20/D21) — a regression guard against
      // re-tightening the allowlist and breaking real output.
      const grounded = [
        'は', 'を', 'に', 'か',
        'です', 'では', 'ありません',
        'はい', 'いいえ', 'この',
        '、', '。',
      ];
      final matcher = GlueMatcher(seedGrammarGlue);
      for (final surface in grounded) {
        expect(matcher.isKnown(surface), isTrue,
            reason: '"$surface" should be known glue');
      }
    });

    test(
        'tolerates the model fusing known pieces into one token '
        '(ではありません seen live as both 2 tokens and 1, decision D21)', () {
      final matcher = GlueMatcher(seedGrammarGlue);
      expect(matcher.isKnown('ではありません'), isTrue);
      // です + か, also plausible to fuse
      expect(matcher.isKnown('ですか'), isTrue);
    });

    test('still rejects an untaught word even when adjacent to known glue', () {
      // Guards against the factoring regex being so loose that appending a
      // known particle to an unknown word sneaks it through.
      expect(GlueMatcher(seedGrammarGlue).isKnown('さんは'), isFalse);
    });

    test('rejects an untaught honorific tagged as glue (the さん bug, D20)', () {
      // Exact reproduction: 田中さん — さん slipped through as vocab_id 0
      // because it carries no kanji, so the old kanji-only check missed it.
      final report = validateScope(
        _convo(const [
          GenToken(surface: '田中', vocabId: 21),
          GenToken(surface: 'さん', vocabId: 0),
        ], text: '田中さん'),
        GenerationSeed(vocab: [
          ..._seed.vocab,
          const SeedWord(
              id: 21, kana: 'たなか', kanji: '田中', role: 'name', meaning: 'Tanaka'),
        ], structures: _seed.structures),
      );
      expect(report.violations, contains(contains('untaught word')));
    });

    test('flags an out-of-vocabulary token', () {
      final report = validateScope(
        _convo(const [
          GenToken(surface: 'これ', vocabId: 1),
          GenToken(surface: 'は', vocabId: 0),
          GenToken(surface: 'ねこ', vocabId: 99),
          GenToken(surface: 'です', vocabId: 0),
        ], text: 'これは ねこ です'),
        _seed,
      );
      expect(report.ok, isFalse);
      // The factoring check independently flags ねこ too, so two violations.
      expect(report.violations, contains(contains('unknown vocab id 99')));
      expect(report.violations, contains(contains('unmatched from "ねこ')));
    });

    test('flags tokens that do not reconstruct the line text', () {
      // The out-of-scope word sits only in `text`; the token list omits it,
      // so every per-token check is blind to it. The reconstruction check
      // catches the discrepancy (and factoring independently flags ねこ).
      final report = validateScope(
        _convo(const [
          GenToken(surface: 'これ', vocabId: 1),
          GenToken(surface: 'は', vocabId: 0),
          GenToken(surface: 'です', vocabId: 0),
        ], text: 'これは ねこ です'),
        _seed,
      );
      expect(report.violations, contains(contains('do not reconstruct')));
    });

    test('reconstruction ignores spacing differences between text and tokens', () {
      // `text` separates words with spaces (ASCII or ideographic); tokens
      // carry the bare surfaces. That must not count as a mismatch.
      final report = validateScope(
        _convo(const [
          GenToken(surface: 'これ', vocabId: 1),
          GenToken(surface: 'は', vocabId: 0),
          GenToken(surface: 'ほん', vocabId: 4),
          GenToken(surface: 'です', vocabId: 0),
        ], text: 'これは　ほん です'),
        _seed,
      );
      expect(report.ok, isTrue);
    });

    test('reconstruction tolerates punctuation the tokens omit', () {
      // Observed live (session 9): 、 in `text` but not in `tokens`. Safe to
      // ignore since factoring covers all of `text` and the reading screen
      // renders punctuation from `text` (D42) — a missing word still flags
      // (previous test), a missing comma no longer does.
      final report = validateScope(
        _convo(const [
          GenToken(surface: 'これ', vocabId: 1),
          GenToken(surface: 'は', vocabId: 0),
          GenToken(surface: 'ほん', vocabId: 4),
          GenToken(surface: 'です', vocabId: 0),
        ], text: 'これは、ほん です。'),
        _seed,
      );
      expect(report.ok, isTrue);
    });

    test('flags an unknown speaker name', () {
      final report = validateScope(
        _convo(const [
          GenToken(surface: 'これ', vocabId: 1),
          GenToken(surface: 'は', vocabId: 0),
          GenToken(surface: 'ほん', vocabId: 4),
          GenToken(surface: 'です', vocabId: 0),
        ], speaker: 77),
        _seed,
      );
      expect(report.violations.single, contains('is not a known name'));
    });

    test('flags kanji hiding in a glue token', () {
      final report = validateScope(
        _convo(const [GenToken(surface: '猫', vocabId: 0)], text: '猫'),
        _seed,
      );
      expect(report.violations, contains(contains('tagged as glue')));
    });

    test(
        'flags invented kanji for a content word with empty kanji field '
        'even when kanaOnly is false (not just intrinsically kana-only words)',
        () {
      // たべる has real-world kanji (食べる) but the worksheet never showed
      // it — kanji is "", kanaOnly is false. Generation must still be
      // barred from writing 食べます.
      const seedWithVerb = GenerationSeed(
        vocab: [
          SeedWord(id: 25, kana: 'たべる', role: 'verb', kanaOnly: false),
        ],
        structures: [],
      );
      final report = validateScope(
        GeneratedConversation(
          lines: [
            GenLine(
              speakerNameId: 0,
              speakerSurface: 'x',
              text: '食べます',
              structureId: 0,
              tokens: const [GenToken(surface: '食べます', vocabId: 25)],
            ),
          ],
          usedVocabIds: const [],
          usedStructureIds: const [],
        ),
        seedWithVerb,
      );
      expect(report.violations, contains(contains('no kanji taught yet')));
    });

    test('flags a hallucinated surface tagged with a valid vocab id (laundering gap)', () {
      // ねこ carries ほん's perfectly valid id — every id-based check passes,
      // and before the surface↔entry check this rendered ねこ with ほん's
      // furigana. The sibling hole of the D24 reconstruction check.
      final report = validateScope(
        _convo(const [
          GenToken(surface: 'これ', vocabId: 1),
          GenToken(surface: 'は', vocabId: 0),
          GenToken(surface: 'ねこ', vocabId: 4),
          GenToken(surface: 'です', vocabId: 0),
        ], text: 'これは ねこ です'),
        _seed,
      );
      expect(report.violations, contains(contains('not a recognizable form')));
    });

    test('accepts a conjugated surface of a conjugating entry', () {
      // The polite form must be taught by a structure for 行きます to be in
      // scope — the factoring check derives its ending set from slot forms.
      const seedWithVerb = GenerationSeed(
        vocab: [
          SeedWord(id: 20, kana: 'すずき', kanji: '鈴木', role: 'name'),
          SeedWord(id: 30, kana: 'いく', kanji: '行く', role: 'verb'),
        ],
        structures: [
          SeedStructure(
            id: 5,
            template: '{verb_1}',
            slots: [SeedSlot(name: 'verb_1', role: 'verb', form: 'polite')],
          ),
        ],
      );
      final report = validateScope(
        GeneratedConversation(
          lines: [
            GenLine(
              speakerNameId: 20,
              speakerSurface: 'すずき',
              text: '行きます',
              structureId: 0,
              tokens: const [GenToken(surface: '行きます', vocabId: 30)],
            ),
          ],
          usedVocabIds: const [30],
          usedStructureIds: const [],
        ),
        seedWithVerb,
      );
      expect(report.ok, isTrue);
    });

    test('factoring catches an untaught conjugation even when every token-level check passes', () {
      // 行きましょう (volitional): tokens reconstruct the text, the vocab id
      // is valid, and the surface passes the per-token stem check (any
      // pure-kana tail on a taught stem). Only the independent factoring
      // check — endings gated on taught slot forms — catches that ましょう
      // was never taught. This is the check's whole reason to exist.
      const seed = GenerationSeed(
        vocab: [
          SeedWord(id: 20, kana: 'すずき', kanji: '鈴木', role: 'name'),
          SeedWord(id: 30, kana: 'いく', kanji: '行く', role: 'verb'),
        ],
        structures: [
          SeedStructure(
            id: 5,
            template: '{verb_1}',
            slots: [SeedSlot(name: 'verb_1', role: 'verb', form: 'polite')],
          ),
        ],
      );
      final report = validateScope(
        GeneratedConversation(
          lines: [
            GenLine(
              speakerNameId: 20,
              speakerSurface: 'すずき',
              text: '行きましょう',
              structureId: 0,
              tokens: const [GenToken(surface: '行きましょう', vocabId: 30)],
            ),
          ],
          usedVocabIds: const [30],
          usedStructureIds: const [],
        ),
        seed,
      );
      expect(report.violations.single, contains('does not factor'));
    });
  });

  group('backfill candidates + glue relaxation (D52/D53)', () {
    test('an untaught glue-tagged word becomes a candidate, deduped across '
        'the glue and factoring checks', () {
      final report = validateScope(
        _convo(const [
          GenToken(surface: 'ねこ', vocabId: 0),
          GenToken(surface: 'は', vocabId: 0),
          GenToken(surface: 'ほん', vocabId: 4),
          GenToken(surface: 'です', vocabId: 0),
        ], text: 'ねこは ほん です'),
        _seed,
      );
      expect(report.ok, isFalse);
      expect(report.candidates, ['ねこ']);
    });

    test('a single-character glue violation becomes a candidate (an untaught '
        'particle, backfillable through the glue sheet since D56)', () {
      final report = validateScope(
        _convo(const [
          GenToken(surface: 'これ', vocabId: 1),
          GenToken(surface: 'が', vocabId: 0),
          GenToken(surface: 'ほん', vocabId: 4),
          GenToken(surface: 'です', vocabId: 0),
        ], text: 'これが ほん です'),
        _seed,
      );
      expect(report.ok, isFalse);
      expect(report.candidates, ['が']);
    });

    test('punctuation never becomes a candidate, even with single characters '
        'now eligible', () {
      // A glue-tagged 。 passes the matcher's punctuation branch — no
      // violation, no chip — while the untaught single-char が on the same
      // line still surfaces as one. Pins that dropping the length gate
      // (D56) didn't open the door to punctuation chips.
      final report = validateScope(
        _convo(const [
          GenToken(surface: 'これ', vocabId: 1),
          GenToken(surface: 'が', vocabId: 0),
          GenToken(surface: 'ほん', vocabId: 4),
          GenToken(surface: 'です', vocabId: 0),
          GenToken(surface: '。', vocabId: 0),
        ], text: 'これが ほん です。'),
        _seed,
      );
      expect(report.ok, isFalse);
      expect(report.candidates, ['が']);
    });

    test('a seed with widened glue accepts what the default seed rejects '
        '(the table-backed allowlist, D56)', () {
      final convo = _convo(const [
        GenToken(surface: 'これ', vocabId: 1),
        GenToken(surface: 'が', vocabId: 0),
        GenToken(surface: 'ほん', vocabId: 4),
        GenToken(surface: 'です', vocabId: 0),
      ], text: 'これが ほん です');
      expect(validateScope(convo, _seed).ok, isFalse);

      final widened = GenerationSeed(
        vocab: _seed.vocab,
        structures: _seed.structures,
        glue: {...seedGrammarGlue, 'が'},
      );
      expect(validateScope(convo, widened).ok, isTrue);
    });

    test('a kanji-bearing surface yields no candidate (reading unknown)', () {
      final report = validateScope(
        _convo(const [
          GenToken(surface: '勉強', vocabId: 0),
          GenToken(surface: 'です', vocabId: 0),
        ], text: '勉強 です'),
        _seed,
      );
      expect(report.ok, isFalse);
      expect(report.candidates, isEmpty);
    });

    test('relaxation: a glue-tagged token matching taught kana passes (a '
        'mislabeled word, not a scope leak)', () {
      // これ is taught vocab (id 1) but the model tags it vocab_id 0. Every
      // character is still covered by factoring; the label error alone must
      // not reject the conversation (D53) — this is what lets a backfilled
      // word rescue the conversation that flagged it.
      final report = validateScope(
        _convo(const [
          GenToken(surface: 'これ', vocabId: 0),
          GenToken(surface: 'は', vocabId: 0),
          GenToken(surface: 'ほん', vocabId: 4),
          GenToken(surface: 'です', vocabId: 0),
        ]),
        _seed,
      );
      expect(report.violations, isEmpty);
    });

    test('relaxation is kana-only: a kanji surface stays rejected even when '
        'it matches a taught word', () {
      // 鈴木 is taught (すずき/鈴木), but the glue escape matches kana
      // surfaces only — a kanji-surfaced glue token would render without
      // furigana, so it stays a violation (D53).
      final report = validateScope(
        _convo(const [
          GenToken(surface: '鈴木', vocabId: 0),
          GenToken(surface: 'は', vocabId: 0),
          GenToken(surface: 'ほん', vocabId: 4),
          GenToken(surface: 'です', vocabId: 0),
        ], text: '鈴木は ほん です'),
        _seed,
      );
      expect(report.ok, isFalse);
      expect(report.violations, anyElement(contains('鈴木')));
    });

    test('factoring failure cross-references the token list for a clean '
        'candidate even when the glue check never fires', () {
      // ねこ claims a *valid* vocab id (4, ほん) — the surface check flags it
      // and factoring fails, but no glue violation exists. The candidate
      // comes from matching the unmatched remainder against token surfaces.
      final report = validateScope(
        _convo(const [
          GenToken(surface: 'ねこ', vocabId: 4),
          GenToken(surface: 'です', vocabId: 0),
        ], text: 'ねこ です'),
        _seed,
      );
      expect(report.ok, isFalse);
      expect(report.candidates, ['ねこ']);
    });

    test('factoring fallback trims the remainder at a glue boundary when '
        'tokens and text disagree', () {
      // ねこ sits in the text but not in the token list (the D24 hole), so
      // no token surface matches the remainder — the fallback cuts 'ねこは'
      // at the known-glue は.
      final report = validateScope(
        _convo(const [
          GenToken(surface: 'は', vocabId: 0),
          GenToken(surface: 'ほん', vocabId: 4),
          GenToken(surface: 'です', vocabId: 0),
        ], text: 'ねこは ほん です'),
        _seed,
      );
      expect(report.ok, isFalse);
      expect(report.candidates, ['ねこ']);
    });
  });

  test('renderConversation pulls furigana from the store, not the model', () {
    final out = renderConversation(
      _convo(const [
        GenToken(surface: 'これは', vocabId: 0),
        GenToken(surface: 'ほん', vocabId: 4),
        GenToken(surface: 'です', vocabId: 0),
      ]),
      _seed,
    );
    expect(out, startsWith('鈴木[すずき]:')); // speaker name furigana
    expect(out, contains('これはほんです')); // kana tokens, no furigana
  });

  test('renderConversation keeps a conjugated surface, ruby on the stem only', () {
    // The pre-spike renderer substituted the base form (行く[いく]) into a
    // line that said 行きます whenever the entry had kanji — masked until now
    // because the demo verbs were kana-only.
    const seed = GenerationSeed(
      vocab: [
        SeedWord(id: 20, kana: 'すずき', kanji: '鈴木', role: 'name'),
        SeedWord(id: 30, kana: 'いく', kanji: '行く', role: 'verb'),
      ],
      structures: [],
    );
    final out = renderConversation(
      GeneratedConversation(
        lines: [
          GenLine(
            speakerNameId: 20,
            speakerSurface: 'すずき',
            text: '行きます。',
            structureId: 0,
            tokens: const [GenToken(surface: '行きます。', vocabId: 30)],
          ),
        ],
        usedVocabIds: const [30],
        usedStructureIds: const [],
      ),
      seed,
    );
    expect(out, contains('行[い]きます。'));
    expect(out, isNot(contains('行く')));
  });
}

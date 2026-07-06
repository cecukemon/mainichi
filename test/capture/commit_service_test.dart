import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/capture/commit_service.dart';
import 'package:mainichi/capture/models.dart';
import 'package:mainichi/data/database.dart';
import 'package:mainichi/data/enums.dart';

VocabDraftItem _vocab({
  required String kana,
  String kanji = '',
  String meaning = 'to eat',
  ExistingWordMatch? existingMatch,
  MergeDecision mergeDecision = MergeDecision.undecided,
  String? newExampleSentence,
}) =>
    VocabDraftItem(
      kana: kana,
      kanji: kanji,
      romaji: '',
      meaning: meaning,
      role: WordRole.verb,
      kanaOnly: false,
      meaningSource: MeaningSource.printedGloss,
      confidence: ConfidenceTier.high,
      existingMatch: existingMatch,
      mergeDecision: mergeDecision,
      newExampleSentence: newExampleSentence,
    );

ExistingWordMatch _match(int wordId, {String kana = 'たべる', String kanji = ''}) =>
    ExistingWordMatch(
      wordId: wordId,
      kana: kana,
      kanji: kanji,
      meaning: null,
      role: WordRole.verb,
      exampleSentences: const [],
    );

const _template = TemplateDraftItem(
  template: 'これは {noun} です',
  slots: [SlotDraft(name: 'noun', role: WordRole.noun)],
  example: 'これは ほん です。',
  confidence: ConfidenceTier.low,
);

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('writes a new word and a new template', () async {
    final draft = CaptureDraft(
      worksheetTitle: '',
      worksheetTopic: '',
      vocabulary: [_vocab(kana: 'たべる', kanji: '食べる')],
      templates: const [_template],
    );

    final result = await runCommit(db, draft);

    expect(result.newWordCount, 1);
    expect(result.mergedCount, 0);
    expect(result.newTemplateCount, 1);
    expect(await db.select(db.words).get(), hasLength(1));
    final structures = await db.select(db.structures).get();
    expect(structures, hasLength(1));
    expect(await db.select(db.slots).get(), hasLength(1));
  });

  test('a confirmed merge attaches an example instead of inserting a new word', () async {
    final existingId = await db.into(db.words).insert(
          WordsCompanion.insert(kana: 'たべる', kanji: const Value('食べる'), role: WordRole.verb),
        );
    final draft = CaptureDraft(
      worksheetTitle: '',
      worksheetTopic: '',
      vocabulary: [
        _vocab(
          kana: 'たべる',
          kanji: '食べる',
          existingMatch: ExistingWordMatch(
            wordId: existingId,
            kana: 'たべる',
            kanji: '食べる',
            meaning: 'to eat',
            role: WordRole.verb,
            exampleSentences: const [],
          ),
          mergeDecision: MergeDecision.merge,
          newExampleSentence: 'わたしは すしを たべます。',
        ),
      ],
      templates: const [],
    );

    final result = await runCommit(db, draft);

    expect(result.newWordCount, 0);
    expect(result.mergedCount, 1);
    expect(await db.select(db.words).get(), hasLength(1)); // still just the one row
    final examples = await db.select(db.exampleSentences).get();
    expect(examples, hasLength(1));
    expect(examples.single.wordId, existingId);
  });

  test('skipped items are neither written nor counted, and are reported back', () async {
    final draft = CaptureDraft(
      worksheetTitle: '',
      worksheetTopic: '',
      vocabulary: [_vocab(kana: 'たべる', kanji: '食べる'), _vocab(kana: 'のむ', kanji: '飲む')],
      templates: const [_template],
    );

    final result = await runCommit(
      db,
      draft,
      skippedRefs: {QueueRef(QueueItemType.vocab, 1), QueueRef(QueueItemType.template, 0)},
    );

    expect(result.newWordCount, 1);
    expect(result.newTemplateCount, 0);
    expect(result.skipped, hasLength(2));
    expect(await db.select(db.words).get(), hasLength(1));
    expect(await db.select(db.structures).get(), isEmpty);
  });

  test('a skipped dedup check withholds the whole word, not just the merge', () async {
    await db.into(db.words).insert(
          WordsCompanion.insert(kana: 'たべる', kanji: const Value('食べる'), role: WordRole.verb),
        );
    final draft = CaptureDraft(
      worksheetTitle: '',
      worksheetTopic: '',
      vocabulary: [_vocab(kana: 'たべる', kanji: '食べる')],
      templates: const [],
    );

    final result = await runCommit(
      db,
      draft,
      skippedRefs: {QueueRef(QueueItemType.dedup, 0)},
    );

    expect(result.newWordCount, 0);
    expect(result.mergedCount, 0);
    expect(result.skipped, hasLength(1));
  });

  test('a merge fills in newly-taught kanji on a kanji-less existing entry', () async {
    // The kana-first-kanji-later sequence: たべる was imported weeks ago
    // without kanji (and mis-flagged kanaOnly); today's worksheet prints 食べる.
    final existingId = await db.into(db.words).insert(
          WordsCompanion.insert(
              kana: 'たべる', role: WordRole.verb, kanaOnly: const Value(true)),
        );
    final draft = CaptureDraft(
      worksheetTitle: '',
      worksheetTopic: '',
      vocabulary: [
        _vocab(
          kana: 'たべる',
          kanji: '食べる',
          existingMatch: _match(existingId),
          mergeDecision: MergeDecision.merge,
        ),
      ],
      templates: const [],
    );

    final result = await runCommit(db, draft);

    expect(result.mergedCount, 1);
    expect(result.kanjiUpgradedCount, 1);
    final word = await db.select(db.words).getSingle();
    expect(word.kanji, '食べる');
    expect(word.kanaOnly, isFalse);
    expect(previewCommit(draft, const {}).kanjiUpgradedCount, 1);
  });

  test('a merge never overwrites kanji the existing entry already has', () async {
    final existingId = await db.into(db.words).insert(
          WordsCompanion.insert(
              kana: 'たべる', kanji: const Value('食べる'), role: WordRole.verb),
        );
    final draft = CaptureDraft(
      worksheetTitle: '',
      worksheetTopic: '',
      vocabulary: [
        _vocab(
          kana: 'たべる',
          kanji: '喰べる', // extractor misread — must not clobber the store
          existingMatch: _match(existingId, kanji: '食べる'),
          mergeDecision: MergeDecision.merge,
        ),
      ],
      templates: const [],
    );

    final result = await runCommit(db, draft);

    expect(result.kanjiUpgradedCount, 0);
    expect((await db.select(db.words).getSingle()).kanji, '食べる');
  });

  test('a merge fills a missing meaning but never replaces an existing one', () async {
    final withoutMeaning = await db.into(db.words).insert(
          WordsCompanion.insert(kana: 'たべる', role: WordRole.verb),
        );
    final withMeaning = await db.into(db.words).insert(
          WordsCompanion.insert(
              kana: 'のむ', role: WordRole.verb, meaning: const Value('to drink')),
        );
    final draft = CaptureDraft(
      worksheetTitle: '',
      worksheetTopic: '',
      vocabulary: [
        _vocab(
          kana: 'たべる',
          meaning: 'to eat',
          existingMatch: _match(withoutMeaning),
          mergeDecision: MergeDecision.merge,
        ),
        _vocab(
          kana: 'のむ',
          meaning: 'to gulp',
          existingMatch: _match(withMeaning, kana: 'のむ'),
          mergeDecision: MergeDecision.merge,
        ),
      ],
      templates: const [],
    );

    await runCommit(db, draft);

    final words = await db.select(db.words).get();
    expect(words.firstWhere((w) => w.kana == 'たべる').meaning, 'to eat');
    expect(words.firstWhere((w) => w.kana == 'のむ').meaning, 'to drink');
  });

  test('same (kana, kanji, role) twice in one batch merges instead of violating the unique key', () async {
    final draft = CaptureDraft(
      worksheetTitle: '',
      worksheetTopic: '',
      vocabulary: [_vocab(kana: 'たべる', kanji: '食べる'), _vocab(kana: 'たべる', kanji: '食べる')],
      templates: const [],
    );

    final result = await runCommit(db, draft);

    expect(result.newWordCount, 1);
    expect(result.mergedCount, 1);
    expect(await db.select(db.words).get(), hasLength(1));
  });

  test('writes import provenance (source image, model, raw draft) to the Imports row', () async {
    final draft = CaptureDraft(
      worksheetTitle: '',
      worksheetTopic: '',
      vocabulary: [_vocab(kana: 'たべる', kanji: '食べる')],
      templates: const [],
      sourceImage: '/tmp/worksheet.jpg',
      model: 'claude-opus-4-8',
      rawDraftJson: '{"worksheet":{"title":""}}',
    );

    await runCommit(db, draft);

    final import = await db.select(db.imports).getSingle();
    expect(import.sourceImage, '/tmp/worksheet.jpg');
    expect(import.model, 'claude-opus-4-8');
    expect(import.rawDraftJson, '{"worksheet":{"title":""}}');
  });

  test('a mid-commit failure rolls back the whole import, leaving no partial rows', () async {
    // Two existing rows differing only by kanji: upgrading the kana-only one
    // to 飲む on merge would collide with the other on (kana, kanji, role) —
    // the unguarded collision noted in decision log D26. Used here purely to
    // force a throw partway through a commit.
    final target = await db.into(db.words).insert(
          WordsCompanion.insert(kana: 'のむ', role: WordRole.verb, kanaOnly: const Value(true)),
        );
    await db.into(db.words).insert(
          WordsCompanion.insert(kana: 'のむ', kanji: const Value('飲む'), role: WordRole.verb),
        );

    final draft = CaptureDraft(
      worksheetTitle: '',
      worksheetTopic: '',
      vocabulary: [
        _vocab(kana: 'たべる', kanji: '食べる'), // inserts cleanly first
        _vocab(
          kana: 'のむ',
          kanji: '飲む',
          existingMatch: _match(target, kana: 'のむ'),
          mergeDecision: MergeDecision.merge,
        ), // kanji-upgrade UPDATE collides -> throws mid-commit
      ],
      templates: const [],
    );

    await expectLater(runCommit(db, draft), throwsA(anything));

    // The first word insert AND the Imports row are both rolled back: only the
    // two pre-seeded words remain, and no import provenance was persisted.
    expect(await db.select(db.words).get(), hasLength(2));
    expect(await db.select(db.imports).get(), isEmpty);
  });
}

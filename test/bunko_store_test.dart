import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/bunko_store.dart';
import 'package:mainichi/data/database.dart';
import 'package:mainichi/data/enums.dart';

void main() {
  late AppDatabase db;
  late DriftBunkoStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = DriftBunkoStore(db);
  });
  tearDown(() => db.close());

  group('listWords', () {
    test('returns every field, newest first, kanji "" round-trips', () async {
      await db.into(db.words).insert(WordsCompanion.insert(
            kana: 'すし',
            role: WordRole.noun,
            meaning: const Value('sushi'),
            notes: const Value('printed gloss'),
          ));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final secondId = await db.into(db.words).insert(WordsCompanion.insert(
            kana: 'たべる',
            role: WordRole.verb,
          ));

      final rows = await store.listWords();

      expect(rows, hasLength(2));
      expect(rows.first.id, secondId);
      expect(rows.first.kanji, '');
      expect(rows.first.meaning, isNull);
      expect(rows.first.status, ItemStatus.draft);

      final sushi = rows.last;
      expect(sushi.kana, 'すし');
      expect(sushi.meaning, 'sushi');
      expect(sushi.notes, 'printed gloss');
      expect(sushi.role, WordRole.noun);
    });

    test('draft-status rows are returned, not filtered', () async {
      await db.into(db.words).insert(WordsCompanion.insert(
            kana: 'いぬ',
            role: WordRole.noun,
            status: const Value(ItemStatus.draft),
          ));

      final rows = await store.listWords();

      expect(rows.single.status, ItemStatus.draft);
    });
  });

  group('listStructures', () {
    test('attaches slots ordered by ordinal', () async {
      final structureId = await db.into(db.structures).insert(
          StructuresCompanion.insert(template: 'これは {noun_1} です'));
      await db.into(db.slots).insert(SlotsCompanion.insert(
            structureId: structureId,
            name: 'noun_2',
            role: WordRole.noun,
            ordinal: const Value(1),
          ));
      await db.into(db.slots).insert(SlotsCompanion.insert(
            structureId: structureId,
            name: 'noun_1',
            role: WordRole.noun,
            ordinal: const Value(0),
          ));

      final rows = await store.listStructures();

      expect(rows.single.slots.map((s) => s.name), ['noun_1', 'noun_2']);
    });

    test('a structure with no slots returns an empty list', () async {
      await db
          .into(db.structures)
          .insert(StructuresCompanion.insert(template: '{noun_1} だ'));

      final rows = await store.listStructures();

      expect(rows.single.slots, isEmpty);
    });
  });

  test('listGlue returns rows newest first', () async {
    // Surfaces distinct from the seeded allowlist (D56) so this doesn't
    // collide with the on-create seed.
    await db.into(db.grammarGlue).insert(GrammarGlueCompanion.insert(
        surface: 'てすとglue1', kind: GlueKind.particle));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final secondId = await db.into(db.grammarGlue).insert(
        GrammarGlueCompanion.insert(
            surface: 'てすとglue2', kind: GlueKind.copula));

    final rows = await store.listGlue();

    expect(rows.first.id, secondId);
    expect(rows.first.surface, 'てすとglue2');
  });

  group('wordById', () {
    test('includes only that word\'s examples', () async {
      final wordId = await db
          .into(db.words)
          .insert(WordsCompanion.insert(kana: 'すし', role: WordRole.noun));
      final otherId = await db
          .into(db.words)
          .insert(WordsCompanion.insert(kana: 'たべる', role: WordRole.verb));
      await db.into(db.exampleSentences).insert(ExampleSentencesCompanion.insert(
            sentence: 'すしを食べる。',
            wordId: Value(wordId),
          ));
      await db.into(db.exampleSentences).insert(ExampleSentencesCompanion.insert(
            sentence: 'たべものです。',
            wordId: Value(otherId),
          ));

      final detail = await store.wordById(wordId);

      expect(detail, isNotNull);
      expect(detail!.examples, ['すしを食べる。']);
    });

    test('returns null for a missing id', () async {
      expect(await store.wordById(999), isNull);
    });
  });

  group('structureById', () {
    test('includes only that structure\'s examples', () async {
      final structureId = await db.into(db.structures).insert(
          StructuresCompanion.insert(template: 'これは {noun_1} です'));
      final otherId = await db
          .into(db.structures)
          .insert(StructuresCompanion.insert(template: '{noun_1} だ'));
      await db.into(db.exampleSentences).insert(
          ExampleSentencesCompanion.insert(
              sentence: 'これはすしです。',
              structureId: Value(structureId)));
      await db.into(db.exampleSentences).insert(
          ExampleSentencesCompanion.insert(
              sentence: 'たべものだ。',
              structureId: Value(otherId)));

      final detail = await store.structureById(structureId);

      expect(detail, isNotNull);
      expect(detail!.examples, ['これはすしです。']);
    });

    test('returns null for a missing id', () async {
      expect(await store.structureById(999), isNull);
    });
  });

  group('fixWordBaseForm', () {
    test('rewrites kana/kanji in place when no existing entry collides',
        () async {
      final id = await db.into(db.words).insert(WordsCompanion.insert(
            kana: 'もらいます',
            role: WordRole.verb,
            status: const Value(ItemStatus.approved),
          ));

      final result =
          await store.fixWordBaseForm(id, kana: 'もらう', kanji: '');

      expect(result.outcome, FixWordOutcome.updated);
      final row = await (db.select(db.words)..where((w) => w.id.equals(id)))
          .getSingle();
      expect(row.kana, 'もらう');
    });

    test('returns notFound for a missing id', () async {
      final result =
          await store.fixWordBaseForm(999, kana: 'もらう', kanji: '');
      expect(result.outcome, FixWordOutcome.notFound);
    });

    test(
        'merges into an existing dictionary-form entry on a unique-key '
        'collision, filling gaps and repointing dependents', () async {
      final targetId = await db.into(db.words).insert(WordsCompanion.insert(
            kana: 'もらう',
            role: WordRole.verb,
            status: const Value(ItemStatus.approved),
          ));
      final sourceId = await db.into(db.words).insert(WordsCompanion.insert(
            kana: 'もらいます',
            role: WordRole.verb,
            status: const Value(ItemStatus.approved),
            meaning: const Value('to receive'),
            notes: const Value('polite form printed'),
          ));
      await db.into(db.exampleSentences).insert(
          ExampleSentencesCompanion.insert(
              sentence: 'プレゼントをもらいます。', wordId: Value(sourceId)));

      final conversationId = await db.into(db.generatedConversations).insert(
          GeneratedConversationsCompanion.insert(
              payloadJson: '{}', lineCount: 1));
      await db.into(db.conversationWords).insert(ConversationWordsCompanion(
          conversationId: Value(conversationId), wordId: Value(sourceId)));

      await db.into(db.srsCards).insert(SrsCardsCompanion.insert(
          itemType: SrsItemType.word, itemId: sourceId));

      final result =
          await store.fixWordBaseForm(sourceId, kana: 'もらう', kanji: '');

      expect(result.outcome, FixWordOutcome.merged);
      expect(result.mergedIntoId, targetId);

      // Source row is gone.
      expect(
          await (db.select(db.words)..where((w) => w.id.equals(sourceId)))
              .getSingleOrNull(),
          isNull);

      // Fill-the-gap: target had no meaning/notes, so the source's are kept.
      final target = await (db.select(db.words)
            ..where((w) => w.id.equals(targetId)))
          .getSingle();
      expect(target.meaning, 'to receive');
      expect(target.notes, 'polite form printed');

      // Example sentence repointed onto the target, not lost to cascade.
      final examples = await (db.select(db.exampleSentences)
            ..where((e) => e.wordId.equals(targetId)))
          .get();
      expect(examples.map((e) => e.sentence), ['プレゼントをもらいます。']);

      // ConversationWords repointed onto the target.
      final convWords = await (db.select(db.conversationWords)
            ..where((r) => r.conversationId.equals(conversationId)))
          .get();
      expect(convWords.map((r) => r.wordId), [targetId]);

      // SrsCards repointed onto the target (no card existed there yet).
      final srsCards = await (db.select(db.srsCards)
            ..where((c) =>
                c.itemType.equalsValue(SrsItemType.word) &
                c.itemId.equals(targetId)))
          .get();
      expect(srsCards, hasLength(1));
    });

    test('never overwrites an existing meaning/notes/kanji on merge',
        () async {
      final targetId = await db.into(db.words).insert(WordsCompanion.insert(
            kana: 'もらう',
            kanji: const Value('貰う'),
            role: WordRole.verb,
            meaning: const Value('to get (already known)'),
          ));
      final sourceId = await db.into(db.words).insert(WordsCompanion.insert(
            kana: 'もらいます',
            role: WordRole.verb,
            meaning: const Value('to receive (different gloss)'),
          ));

      await store.fixWordBaseForm(sourceId, kana: 'もらう', kanji: '貰う');

      final target = await (db.select(db.words)
            ..where((w) => w.id.equals(targetId)))
          .getSingle();
      expect(target.meaning, 'to get (already known)');
      expect(target.kanji, '貰う');
    });

    test(
        'a conversation referencing both source and target does not throw '
        'on the composite-key collision', () async {
      final targetId = await db.into(db.words).insert(
          WordsCompanion.insert(kana: 'もらう', role: WordRole.verb));
      final sourceId = await db.into(db.words).insert(
          WordsCompanion.insert(kana: 'もらいます', role: WordRole.verb));
      final conversationId = await db.into(db.generatedConversations).insert(
          GeneratedConversationsCompanion.insert(
              payloadJson: '{}', lineCount: 1));
      await db.into(db.conversationWords).insert(ConversationWordsCompanion(
          conversationId: Value(conversationId), wordId: Value(targetId)));
      await db.into(db.conversationWords).insert(ConversationWordsCompanion(
          conversationId: Value(conversationId), wordId: Value(sourceId)));

      final result =
          await store.fixWordBaseForm(sourceId, kana: 'もらう', kanji: '');

      expect(result.outcome, FixWordOutcome.merged);
      final convWords = await (db.select(db.conversationWords)
            ..where((r) => r.conversationId.equals(conversationId)))
          .get();
      expect(convWords.map((r) => r.wordId), [targetId]); // deduped, not doubled
    });

    test('an existing SrsCard on the target wins; the source card is dropped',
        () async {
      final targetId = await db.into(db.words).insert(
          WordsCompanion.insert(kana: 'もらう', role: WordRole.verb));
      final sourceId = await db.into(db.words).insert(
          WordsCompanion.insert(kana: 'もらいます', role: WordRole.verb));
      await db.into(db.srsCards).insert(SrsCardsCompanion.insert(
          itemType: SrsItemType.word, itemId: targetId));
      await db.into(db.srsCards).insert(SrsCardsCompanion.insert(
          itemType: SrsItemType.word, itemId: sourceId));

      await store.fixWordBaseForm(sourceId, kana: 'もらう', kanji: '');

      final cards = await (db.select(db.srsCards)
            ..where((c) => c.itemType.equalsValue(SrsItemType.word)))
          .get();
      expect(cards.map((c) => c.itemId), [targetId]);
    });
  });

  group('dismissBaseFormSuspicion', () {
    test('appends the checked marker to notes', () async {
      final id = await db.into(db.words).insert(
          WordsCompanion.insert(kana: 'はげます', role: WordRole.verb));

      await store.dismissBaseFormSuspicion(id);

      final row = await (db.select(db.words)..where((w) => w.id.equals(id)))
          .getSingle();
      expect(row.notes, contains(baseFormCheckedMarker));
    });

    test('is idempotent — does not duplicate the marker', () async {
      final id = await db.into(db.words).insert(WordsCompanion.insert(
            kana: 'はげます',
            role: WordRole.verb,
            notes: const Value('励ます — encourage'),
          ));

      await store.dismissBaseFormSuspicion(id);
      await store.dismissBaseFormSuspicion(id);

      final row = await (db.select(db.words)..where((w) => w.id.equals(id)))
          .getSingle();
      expect(baseFormCheckedMarker.allMatches(row.notes!).length, 1);
      expect(row.notes, contains('励ます — encourage'));
    });
  });
}

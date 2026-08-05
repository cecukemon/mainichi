import 'package:drift/drift.dart' show Value;
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
}

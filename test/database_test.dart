import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/database.dart';
import 'package:mainichi/data/enums.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('word roundtrips with enum columns and kanji default', () async {
    final id = await db
        .into(db.words)
        .insert(WordsCompanion.insert(kana: 'ほん', role: WordRole.noun));

    final w =
        await (db.select(db.words)..where((t) => t.id.equals(id))).getSingle();
    expect(w.kana, 'ほん');
    expect(w.kanji, ''); // default — "no kanji shown"
    expect(w.role, WordRole.noun);
    expect(w.meaningSource, MeaningSource.inferred); // clientDefault
    expect(w.status, ItemStatus.draft); // clientDefault
    expect(w.kanaOnly, isFalse);
  });

  test('dedup: same (kana, kanji, role) is rejected', () async {
    Future<int> insert() => db
        .into(db.words)
        .insert(WordsCompanion.insert(kana: 'ほん', role: WordRole.noun));
    await insert();
    await expectLater(insert(), throwsA(isA<Exception>()));
  });

  test('same kana with a different role is allowed', () async {
    await db
        .into(db.words)
        .insert(WordsCompanion.insert(kana: 'じん', role: WordRole.suffix));
    await db
        .into(db.words)
        .insert(WordsCompanion.insert(kana: 'じん', role: WordRole.noun));
    expect(await db.select(db.words).get(), hasLength(2));
  });

  test('slot carries a conjugation form and cascades on structure delete',
      () async {
    final sid = await db.into(db.structures).insert(
        StructuresCompanion.insert(template: 'この {noun_1} は {iadj} です'));
    await db.into(db.slots).insert(SlotsCompanion.insert(
          structureId: sid,
          name: 'iadj',
          role: WordRole.iAdjective,
          form: Value(SlotForm.negative),
        ));

    final slots = await db.select(db.slots).get();
    expect(slots, hasLength(1));
    expect(slots.single.form, SlotForm.negative);

    await (db.delete(db.structures)..where((t) => t.id.equals(sid))).go();
    expect(await db.select(db.slots).get(), isEmpty); // FK cascade
  });

  test('one SRS card per item', () async {
    Future<int> card() => db.into(db.srsCards).insert(
        SrsCardsCompanion.insert(itemType: SrsItemType.word, itemId: 1));
    await card();
    await expectLater(card(), throwsA(isA<Exception>()));
  });

  test('conversation links cascade but the linked word survives', () async {
    final wid = await db
        .into(db.words)
        .insert(WordsCompanion.insert(kana: 'ほん', role: WordRole.noun));
    final cid = await db.into(db.generatedConversations).insert(
        GeneratedConversationsCompanion.insert(payloadJson: '{}', lineCount: 4));
    await db.into(db.conversationWords).insert(
        ConversationWordsCompanion.insert(conversationId: cid, wordId: wid));

    expect(await db.select(db.conversationWords).get(), hasLength(1));

    await (db.delete(db.generatedConversations)..where((t) => t.id.equals(cid)))
        .go();
    expect(await db.select(db.conversationWords).get(), isEmpty); // link gone
    expect(await db.select(db.words).get(), hasLength(1)); // word survives
  });
}

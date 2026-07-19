import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/database.dart';
import 'package:mainichi/data/enums.dart';
import 'package:mainichi/data/glue_seed.dart';

/// An [AppDatabase] whose schema is pinned at v1 — everything except the
/// grammar_glue table — for exercising the real v1→v2 `onUpgrade` path.
class _V1Database extends AppDatabase {
  _V1Database(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          for (final table in allTables) {
            if (table.actualTableName == grammarGlue.actualTableName) continue;
            await m.createTable(table);
          }
        },
      );
}

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

  test('fresh database is seeded with the glue constant, all seed-origin',
      () async {
    final rows = await db.select(db.grammarGlue).get();
    expect(
      {for (final r in rows) r.surface: r.kind},
      {for (final (surface, kind) in grammarGlueSeedRows) surface: kind},
    );
    expect(rows.where((r) => r.importId != null), isEmpty);
  });

  test('glue seeding is idempotent and preserves backfilled provenance',
      () async {
    final importId = await db.into(db.imports).insert(const ImportsCompanion());
    await db.into(db.grammarGlue).insert(GrammarGlueCompanion.insert(
          surface: 'ね',
          kind: GlueKind.particle,
          importId: Value(importId),
        ));

    await db.seedGrammarGlue(); // re-run: no duplicates, nothing clobbered
    final rows = await db.select(db.grammarGlue).get();
    expect(rows, hasLength(grammarGlueSeedRows.length + 1));
    expect(rows.singleWhere((r) => r.surface == 'ね').importId, importId);
  });

  test('glue surface is unique', () async {
    Future<int> insert() => db.into(db.grammarGlue).insert(
        GrammarGlueCompanion.insert(surface: 'ね', kind: GlueKind.particle));
    await insert();
    await expectLater(insert(), throwsA(isA<Exception>()));
  });

  test('v1→v2 upgrade creates and seeds grammar_glue on an existing install',
      () async {
    // Memory databases can't be reopened, so run the upgrade against a file.
    final dir = await Directory.systemTemp.createTemp('mainichi_migration');
    final file = File('${dir.path}/v1.db');
    addTearDown(() => dir.delete(recursive: true));

    final v1 = _V1Database(NativeDatabase(file));
    final wordId = await v1
        .into(v1.words)
        .insert(WordsCompanion.insert(kana: 'ほん', role: WordRole.noun));
    await v1.close();

    final v2 = AppDatabase(NativeDatabase(file));
    addTearDown(v2.close);
    final glue = await v2.select(v2.grammarGlue).get();
    expect(glue, hasLength(grammarGlueSeedRows.length));
    // Pre-existing data survives the upgrade untouched.
    final word = await (v2.select(v2.words)
          ..where((t) => t.id.equals(wordId)))
        .getSingle();
    expect(word.kana, 'ほん');
  });
}

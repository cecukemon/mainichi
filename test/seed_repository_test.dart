import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/database.dart';
import 'package:mainichi/data/enums.dart';
import 'package:mainichi/data/glue_seed.dart';
import 'package:mainichi/data/seed_repository.dart';

void main() {
  late AppDatabase db;
  late DriftSeedSource source;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    source = DriftSeedSource(db);
  });
  tearDown(() => db.close());

  Future<int> insertWord(String kana,
          {String kanji = '',
          String? meaning,
          WordRole role = WordRole.noun,
          bool kanaOnly = false,
          ItemStatus status = ItemStatus.approved}) =>
      db.into(db.words).insert(WordsCompanion.insert(
            kana: kana,
            kanji: Value(kanji),
            meaning: Value(meaning),
            role: role,
            kanaOnly: Value(kanaOnly),
            status: Value(status),
          ));

  test('maps approved words to SeedWord with wire-format roles', () async {
    await insertWord('たべる', kanji: '食べる', meaning: 'to eat', role: WordRole.verb);
    await insertWord('おもしろい', role: WordRole.iAdjective, kanaOnly: true);

    final seed = await source.loadGenerationSeed();
    expect(seed.vocab, hasLength(2));

    final taberu = seed.vocab.first;
    expect(taberu.kana, 'たべる');
    expect(taberu.kanji, '食べる');
    expect(taberu.meaning, 'to eat');
    expect(taberu.role, 'verb');

    final omoshiroi = seed.vocab.last;
    expect(omoshiroi.role, 'i_adjective'); // wire format, not the enum name
    expect(omoshiroi.kanaOnly, isTrue);
    expect(omoshiroi.meaning, ''); // null meaning normalized to ''
  });

  test('excludes drafts — an un-reviewed item never reaches generation',
      () async {
    await insertWord('ほん');
    await insertWord('ねこ', status: ItemStatus.draft);
    await db.into(db.structures).insert(StructuresCompanion.insert(
        template: '{noun_1} draft', status: const Value(ItemStatus.draft)));

    final seed = await source.loadGenerationSeed();
    expect(seed.vocab.map((w) => w.kana), ['ほん']);
    expect(seed.structures, isEmpty);
  });

  test('maps structures with slots in ordinal order and wire-format forms',
      () async {
    final sid = await db.into(db.structures).insert(StructuresCompanion.insert(
        template: '{name_1} は {verb_1}',
        status: const Value(ItemStatus.approved)));
    // Inserted out of order; ordinal must win.
    await db.into(db.slots).insert(SlotsCompanion.insert(
        structureId: sid,
        name: 'verb_1',
        role: WordRole.verb,
        form: const Value(SlotForm.politeNegative),
        ordinal: const Value(1)));
    await db.into(db.slots).insert(SlotsCompanion.insert(
        structureId: sid,
        name: 'name_1',
        role: WordRole.name,
        ordinal: const Value(0)));

    final seed = await source.loadGenerationSeed();
    final s = seed.structures.single;
    expect(s.template, '{name_1} は {verb_1}');
    expect(s.slots.map((x) => x.name), ['name_1', 'verb_1']);
    expect(s.slots[0].form, 'dictionary');
    expect(s.slots[1].form, 'polite_negative'); // wire format
    expect(s.slots[1].role, 'verb');
  });

  test('empty store yields an empty seed, and slotless structures survive',
      () async {
    expect((await source.loadGenerationSeed()).vocab, isEmpty);

    await db.into(db.structures).insert(StructuresCompanion.insert(
        template: 'はい', status: const Value(ItemStatus.approved)));
    final seed = await source.loadGenerationSeed();
    expect(seed.structures.single.slots, isEmpty);
  });

  test('seed glue comes from the GrammarGlue table, growing with it (D56)',
      () async {
    final seed = await source.loadGenerationSeed();
    expect(seed.glue, {for (final (surface, _) in grammarGlueSeedRows) surface});

    await db.into(db.grammarGlue).insert(
        GrammarGlueCompanion.insert(surface: 'ね', kind: GlueKind.particle));
    expect((await source.loadGenerationSeed()).glue, contains('ね'));
  });

  test('wire strings round-trip through the extraction mappers', () {
    for (final r in WordRole.values) {
      expect(WordRole.fromExtraction(r.wire), r);
    }
    for (final f in SlotForm.values) {
      expect(SlotForm.fromExtraction(f.wire), f);
    }
  });
}

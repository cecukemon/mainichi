import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/conversation_cache.dart';
import 'package:mainichi/data/database.dart' hide GeneratedConversation;
import 'package:mainichi/data/enums.dart';
import 'package:mainichi/generation/conversation_generator.dart';

GeneratedConversation _convo(String text, {int structureId = 0}) =>
    GeneratedConversation(
      lines: [
        GenLine(
          speakerNameId: 20,
          speakerSurface: '鈴木',
          text: text,
          structureId: structureId,
          tokens: const [
            GenToken(surface: 'すし', vocabId: 5),
            GenToken(surface: 'です', vocabId: 0),
          ],
        ),
      ],
      usedVocabIds: const [5],
      usedStructureIds: const [],
    );

void main() {
  late AppDatabase db;
  late DriftConversationStore store;
  late int wordId;
  late int structureId;
  // Drift stores DateTime at second resolution; a ticking fake clock keeps
  // every stamp distinct without sleeping through real seconds.
  var clock = DateTime(2026, 7, 7);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    store = DriftConversationStore(db,
        now: () => clock = clock.add(const Duration(seconds: 1)));
    wordId = await db
        .into(db.words)
        .insert(WordsCompanion.insert(kana: 'すし', role: WordRole.noun));
    structureId = await db.into(db.structures).insert(
        StructuresCompanion.insert(template: 'これは {noun_1} です'));
  });
  tearDown(() => db.close());

  test('save persists the payload, link rows, and a practice stamp', () async {
    final id = await store.save(
      _convo('すしです。', structureId: 1),
      wordIds: {wordId},
      structureIds: {structureId},
    );

    final row = await (db.select(db.generatedConversations)
          ..where((c) => c.id.equals(id)))
        .getSingle();
    expect(row.lineCount, 1);
    expect(row.lastPracticedAt, isNotNull);
    expect(await db.select(db.conversationWords).get(),
        [predicate((r) => (r as ConversationWord).wordId == wordId)]);
    expect(await db.select(db.conversationStructures).get(), hasLength(1));
  });

  test('payload round-trips through the cache intact', () async {
    final original = _convo('すしです。');
    await store.save(original, wordIds: {wordId}, structureIds: {});

    final cached = await store.leastRecentlyPracticed();
    final line = cached!.conversation.lines.single;
    expect(line.text, 'すしです。');
    expect(line.speakerSurface, '鈴木');
    expect(line.tokens.first.vocabId, 5);
    expect(line.tokens.last.isGlue, isTrue);
  });

  test('leastRecentlyPracticed serves the oldest stamp; markPracticed rotates',
      () async {
    final first =
        await store.save(_convo('a'), wordIds: {wordId}, structureIds: {});
    await store.save(_convo('b'), wordIds: {wordId}, structureIds: {});

    expect((await store.leastRecentlyPracticed())!.id, first);

    await store.markPracticed(first);
    expect((await store.leastRecentlyPracticed())!.id, isNot(first));
  });

  test('empty cache yields null', () async {
    expect(await store.leastRecentlyPracticed(), isNull);
  });

  test('deleting a linked word cascades the link row, not the conversation',
      () async {
    final id =
        await store.save(_convo('すしです。'), wordIds: {wordId}, structureIds: {});
    await (db.delete(db.words)..where((w) => w.id.equals(wordId))).go();

    expect(await db.select(db.conversationWords).get(), isEmpty);
    expect((await store.leastRecentlyPracticed())!.id, id);
  });
}

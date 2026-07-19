import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/conversation_cache.dart';
import 'package:mainichi/data/database.dart' hide GeneratedConversation;
import 'package:mainichi/data/enums.dart';
import 'package:mainichi/generation/conversation_generator.dart';

GeneratedConversation _convo(String text,
        {int structureId = 0, String topic = ''}) =>
    GeneratedConversation(
      topic: topic,
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

  test('setAudioPath records the audio directory on the row', () async {
    final id =
        await store.save(_convo('すしです。'), wordIds: {wordId}, structureIds: {});

    await store.setAudioPath(id, '/docs/audio/conv_$id');

    final row = await (db.select(db.generatedConversations)
          ..where((c) => c.id.equals(id)))
        .getSingle();
    expect(row.audioPath, '/docs/audio/conv_$id');
  });

  test('deleting a linked word cascades the link row, not the conversation',
      () async {
    final id =
        await store.save(_convo('すしです。'), wordIds: {wordId}, structureIds: {});
    await (db.delete(db.words)..where((w) => w.id.equals(wordId))).go();

    expect(await db.select(db.conversationWords).get(), isEmpty);
    expect((await store.leastRecentlyPracticed())!.id, id);
  });

  test('save stores the topic as the row title', () async {
    final id = await store.save(_convo('すしです。', topic: 'Ordering food'),
        wordIds: {wordId}, structureIds: {});

    final row = await (db.select(db.generatedConversations)
          ..where((c) => c.id.equals(id)))
        .getSingle();
    expect(row.title, 'Ordering food');
  });

  test('list returns summaries newest-first with title and stamps', () async {
    final first = await store.save(_convo('a', topic: 'First'),
        wordIds: {wordId}, structureIds: {});
    final second = await store.save(_convo('b', topic: 'Second'),
        wordIds: {wordId}, structureIds: {});

    final rows = await store.list();
    // Both were saved "now" (ticking clock); newest createdAt first, and the
    // id tiebreak keeps the later insert ahead.
    expect(rows.map((r) => r.id).toList(), [second, first]);
    expect(rows.first.title, 'Second');
    expect(rows.first.lineCount, 1);
    expect(rows.first.lastPracticedAt, isNotNull);
  });

  test('byId round-trips the full payload; unknown id is null', () async {
    final id = await store.save(_convo('すしです。', topic: 'Lunch'),
        wordIds: {wordId}, structureIds: {});

    final cached = await store.byId(id);
    expect(cached!.conversation.topic, 'Lunch');
    expect(cached.conversation.lines.single.text, 'すしです。');
    expect(await store.byId(9999), isNull);
  });

  test('delete removes the conversation and cascades its link rows', () async {
    final id = await store.save(_convo('すしです。', structureId: 1, topic: 'X'),
        wordIds: {wordId}, structureIds: {structureId});
    expect(await db.select(db.conversationWords).get(), hasLength(1));
    expect(await db.select(db.conversationStructures).get(), hasLength(1));

    await store.delete(id);

    expect(await store.byId(id), isNull);
    expect(await db.select(db.conversationWords).get(), isEmpty);
    expect(await db.select(db.conversationStructures).get(), isEmpty);
    // The linked word/structure themselves survive.
    expect(await db.select(db.words).get(), hasLength(1));
    expect(await db.select(db.structures).get(), hasLength(1));
  });

  test('delete of an unknown id is a no-op', () async {
    await store.save(_convo('a', topic: 'X'), wordIds: {wordId}, structureIds: {});
    await store.delete(9999);
    expect(await store.list(), hasLength(1));
  });
}

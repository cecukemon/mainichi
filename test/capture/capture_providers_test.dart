import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/capture/capture_providers.dart';
import 'package:mainichi/capture/models.dart';
import 'package:mainichi/data/database.dart';
import 'package:mainichi/data/enums.dart';

CaptureDraft _liveDraft() {
  return const CaptureDraft(
    worksheetTitle: 'live worksheet',
    worksheetTopic: 'topic',
    vocabulary: [
      VocabDraftItem(
        kana: 'ねこ',
        kanji: '猫',
        romaji: 'neko',
        meaning: 'cat',
        role: WordRole.noun,
        kanaOnly: false,
        meaningSource: MeaningSource.printedGloss,
        confidence: ConfidenceTier.high,
      ),
    ],
    templates: [],
  );
}

void main() {
  test('loadFromExtraction loads the given draft without seeding demo data', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final notifier = CaptureQueueNotifier(db);

    await notifier.loadFromExtraction(_liveDraft());

    expect(notifier.state.draft?.worksheetTitle, 'live worksheet');
    expect(notifier.state.draft?.vocabulary.single.kana, 'ねこ');
    // A live import must never write demo Bunko data (unlike loadDemoFixture).
    expect(await db.select(db.words).get(), isEmpty);
  });

  test('loadDemoFixture seeds a demo Bunko entry and loads the fixture draft', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final notifier = CaptureQueueNotifier(db);

    await notifier.loadDemoFixture();

    expect(notifier.state.draft, isNotNull);
    expect(await db.select(db.words).get(), hasLength(1));
  });
}

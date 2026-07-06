/// Seeds a demo Bunko entry so the dedup-merge card in the capture loop has a
/// real existing row to match against (features/review-queue-dedup-merge.html).
/// Only used by the fixture-driven demo flow — see capture-loop.md §4.
library;

import 'package:drift/drift.dart';

import '../../data/database.dart';
import '../../data/enums.dart';

Future<void> seedDemoBunko(AppDatabase db) async {
  final wordId = await db.into(db.words).insert(
        WordsCompanion.insert(
          kana: 'たべる',
          kanji: const Value('食べる'),
          meaning: const Value('to eat'),
          role: WordRole.verb,
          status: const Value(ItemStatus.approved),
        ),
      );
  await db.into(db.exampleSentences).insert(
        ExampleSentencesCompanion.insert(
          sentence: 'わたしは パンを たべます。',
          wordId: Value(wordId),
        ),
      );
}

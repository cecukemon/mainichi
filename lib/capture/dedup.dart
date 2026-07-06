/// Dedup candidate lookup against the existing Bunko (spec §3, capture-loop.md §3).
///
/// Same kana is not proof of the same word (a same-kana false match is a real
/// risk), so this only ever proposes a candidate for the review queue to
/// confirm or reject — it never merges on its own.
library;

import '../data/database.dart';
import 'models.dart';

/// Finds an existing Bunko entry with the same [kana]. Matching on kana alone
/// is deliberately proposed rather than auto-merged — capture-loop.md §3
/// decided every merge gets confirmed, exact (kana, kanji, role) matches
/// included, since that's the simplest rule and the false-match risk that
/// motivated confirmation applies whenever a person is skimming quickly.
Future<ExistingWordMatch?> findDedupCandidate(
  AppDatabase db,
  VocabDraftItem item,
) async {
  final rows = await (db.select(db.words)..where((w) => w.kana.equals(item.kana))).get();
  if (rows.isEmpty) return null;
  final match = rows.first;

  final examples = await (db.select(db.exampleSentences)
        ..where((e) => e.wordId.equals(match.id))
        ..limit(2))
      .get();

  return ExistingWordMatch(
    wordId: match.id,
    kana: match.kana,
    kanji: match.kanji,
    meaning: match.meaning,
    exampleSentences: examples.map((e) => e.sentence).toList(),
  );
}

/// Attaches dedup candidates (§ above) to every vocab item in [draft] by
/// querying [db]. Returns a new draft; does not mutate the input.
Future<CaptureDraft> attachDedupCandidates(AppDatabase db, CaptureDraft draft) async {
  final updated = <VocabDraftItem>[];
  for (final item in draft.vocabulary) {
    final match = await findDedupCandidate(db, item);
    updated.add(
      match == null
          ? item
          : VocabDraftItem(
              kana: item.kana,
              kanji: item.kanji,
              romaji: item.romaji,
              meaning: item.meaning,
              role: item.role,
              kanaOnly: item.kanaOnly,
              meaningSource: item.meaningSource,
              confidence: item.confidence,
              notes: item.notes,
              kanjiCandidates: item.kanjiCandidates,
              meaningCandidates: item.meaningCandidates,
              handwrittenGloss: item.handwrittenGloss,
              existingMatch: match,
              reviewStatus: item.reviewStatus,
              mergeDecision: item.mergeDecision,
              newExampleSentence: item.newExampleSentence,
            ),
    );
  }
  return draft.copyWith(vocabulary: updated);
}

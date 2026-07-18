/// Bunko backfill from a rejected generation (features/reading-exercise.md).
///
/// When scope validation rejects a conversation over a word the class *did*
/// teach but was never captured (その — see the grammar-glue open question in
/// project-status.md), the reading screen's error state offers the unmatched
/// surface for review. This service turns that surface into a review draft
/// for the capture flow's `VocabReviewCard`, and commits an approved draft
/// through the normal `runCommit` path as a one-item import with honest
/// reading-backfill provenance — no fake worksheet lineage (D52).
library;

import 'dart:convert';

import '../capture/commit_service.dart';
import '../capture/models.dart';
import '../config/model_config.dart';
import '../data/database.dart';
import '../data/enums.dart';

/// Marker written into the Imports row's `rawDraftJson` (the table has no
/// source-type column; the raw-material slot is the honest place — the
/// generation model did propose the surface, D52).
const String backfillSource = 'reading-backfill';

class ScopeBackfillService {
  ScopeBackfillService(this._db);

  final AppDatabase _db;

  /// A review draft for an unmatched surface. v1 candidates are kana-only by
  /// construction (`ScopeReport.candidates`), so the surface is the kana and
  /// kanji is empty — the same "kanji not taught yet" shape the validator
  /// already respects. Nothing extracted a meaning or role: the card starts
  /// blank/`other` and the user supplies both (approve requires a meaning).
  VocabDraftItem draftForSurface(String surface) => VocabDraftItem(
        kana: surface,
        kanji: '',
        romaji: '',
        meaning: '',
        role: WordRole.other,
        kanaOnly: false,
        meaningSource: MeaningSource.none,
        confidence: ConfidenceTier.low,
      );

  /// Commits an approved backfill word as a one-item [CaptureDraft] through
  /// [runCommit] — same transaction, exact `(kana, kanji, role)` merge (so
  /// re-adding an identical word merges instead of duplicating), and approved
  /// status as any capture commit. Known v1 limitation: a kana match with a
  /// *different* role inserts a near-duplicate — the card has no merge UI
  /// (features/reading-exercise.md).
  Future<CommitResult> commit(VocabDraftItem approved,
      {required String surface}) {
    final draft = CaptureDraft(
      worksheetTitle: 'Reading backfill',
      worksheetTopic: '',
      vocabulary: [approved],
      templates: const [],
      model: ModelConfig.generation,
      rawDraftJson: jsonEncode({
        'source': backfillSource,
        'surface': surface,
        'added': {
          'kana': approved.kana,
          'kanji': approved.kanji,
          'role': approved.role.name,
        },
      }),
    );
    return runCommit(_db, draft);
  }
}

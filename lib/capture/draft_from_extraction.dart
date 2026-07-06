/// Converts the extractor's raw structured-output JSON
/// (`worksheet_extractor.dart`'s `extractionSchema`) into an in-progress
/// [CaptureDraft] — the shape the review-queue screens consume.
///
/// The extractor emits one guess per field (kanji, kana, meaning); it doesn't
/// yet rank alternates (capture-loop.md §4 known gap), so candidate lists here
/// are singletons. It also doesn't attribute a handwritten gloss or a printed
/// example sentence to a specific vocab item (word-boundary matching, deferred
/// per spec §9) — those fields stay unset for a live draft, unlike the
/// hand-built fixture in `fixtures/sample_draft.dart`, which sets them
/// directly to give the review UI something concrete to show.
library;

import 'dart:convert';

import '../data/enums.dart';
import 'models.dart';

/// [sourceImage] and [model] are import provenance the extraction JSON itself
/// doesn't carry (the photo path is known at the call site; the model id is
/// the one the request was sent with) — passed through to the `Imports` row on
/// commit. The raw draft is captured verbatim by re-encoding [extraction].
CaptureDraft draftFromExtraction(
  Map<String, dynamic> extraction, {
  String? sourceImage,
  String? model,
}) {
  final worksheet = extraction['worksheet'] as Map<String, dynamic>;
  final vocabulary = (extraction['vocabulary'] as List).cast<Map<String, dynamic>>();
  final structures = (extraction['structures'] as List).cast<Map<String, dynamic>>();
  final handwriting = extraction['handwriting'] as Map<String, dynamic>;

  return CaptureDraft(
    worksheetTitle: worksheet['title'] as String,
    worksheetTopic: worksheet['topic'] as String,
    vocabulary: [for (final v in vocabulary) _vocabFromExtraction(v)],
    templates: [for (final s in structures) _templateFromExtraction(s)],
    ignoredHandwrittenNotes: (handwriting['ignored_notes'] as List).cast<String>(),
    sourceImage: sourceImage,
    model: model,
    rawDraftJson: jsonEncode(extraction),
  );
}

ConfidenceTier _confidenceFromExtraction(String s) =>
    s == 'high' ? ConfidenceTier.high : ConfidenceTier.low;

VocabDraftItem _vocabFromExtraction(Map<String, dynamic> v) {
  final kana = v['kana'] as String;
  final kanji = v['kanji'] as String;
  final meaning = v['meaning'] as String;
  return VocabDraftItem(
    kana: kana,
    kanji: kanji,
    romaji: v['romaji'] as String,
    meaning: meaning,
    role: WordRole.fromExtraction(v['role'] as String),
    kanaOnly: v['kana_only'] as bool,
    meaningSource: MeaningSource.fromExtraction(v['meaning_source'] as String),
    confidence: _confidenceFromExtraction(v['confidence'] as String),
    notes: v['notes'] as String,
    kanjiCandidates: kanji.isEmpty ? const [] : [kanji],
    kanaCandidates: [kana],
    meaningCandidates: meaning.isEmpty ? const [] : [meaning],
  );
}

TemplateDraftItem _templateFromExtraction(Map<String, dynamic> s) {
  final slots = (s['slots'] as List).cast<Map<String, dynamic>>();
  return TemplateDraftItem(
    template: s['template'] as String,
    slots: [
      for (final slot in slots)
        SlotDraft(
          name: slot['name'] as String,
          role: WordRole.fromExtraction(slot['role'] as String),
          form: SlotForm.fromExtraction(slot['form'] as String?),
        ),
    ],
    example: s['example'] as String,
    confidence: _confidenceFromExtraction(s['confidence'] as String),
    notes: s['notes'] as String,
  );
}

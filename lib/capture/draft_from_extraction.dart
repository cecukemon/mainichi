/// Converts the extractor's raw structured-output JSON
/// (`worksheet_extractor.dart`'s `extractionSchema`) into an in-progress
/// [CaptureDraft] — the shape the review-queue screens consume.
///
/// The extractor now ranks kanji alternates (`kanji_candidates`) and reports a
/// best-effort crop `region` per vocab item (D58); the kana/meaning candidate
/// lists stay singletons (one guess each). Legacy payloads (and the hand-built
/// fixture) that predate those fields fall back to a `[kanji]` singleton and a
/// null region. It still doesn't attribute a handwritten gloss or a printed
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
    kanjiCandidates: _kanjiCandidates(v['kanji_candidates'], kanji),
    kanaCandidates: [kana],
    meaningCandidates: meaning.isEmpty ? const [] : [meaning],
    region: CropRegion.tryParse(v['region']),
  );
}

/// The extractor's ranked kanji list, made robust: de-duplicated in order,
/// with the confirmed `kanji` field forced to the front. Falls back to a
/// `[kanji]` singleton (or `[]`) when the field is absent (legacy payloads,
/// the fixture) — preserving the pre-D58 behavior.
List<String> _kanjiCandidates(Object? raw, String kanji) {
  final fromModel = raw is List ? raw.whereType<String>().where((s) => s.isNotEmpty) : const <String>[];
  final ordered = <String>[
    if (kanji.isNotEmpty) kanji,
    ...fromModel,
  ];
  final seen = <String>{};
  return [
    for (final k in ordered)
      if (seen.add(k)) k,
  ];
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

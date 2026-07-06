/// In-progress import draft models for the capture loop (features/capture-loop.md).
///
/// These sit between the extractor's raw JSON (spec §3) and the drift rows
/// written on commit: they add per-item review state (approved/skipped),
/// user corrections, and dedup-candidate matches against the existing Bunko.
library;

import 'package:meta/meta.dart';

import '../data/enums.dart';

enum ConfidenceTier { high, low }

enum ReviewStatus { pending, approved, skipped }

/// Whether a possible dedup match has been confirmed, rejected, or is still
/// awaiting a decision. Independent of [ReviewStatus] — a vocab item can be
/// approved while its dedup match is still undecided, and vice versa.
enum MergeDecision { undecided, merge, notAMatch }

/// An existing Bunko (vocabulary store) entry that a draft vocab item might be
/// the same word as. Same-kana is not proof by itself (spec: "a same-kana
/// false match is a real risk"), so this is always a proposal to confirm, not
/// an automatic merge.
@immutable
class ExistingWordMatch {
  const ExistingWordMatch({
    required this.wordId,
    required this.kana,
    required this.kanji,
    required this.meaning,
    required this.role,
    required this.exampleSentences,
  });

  final int wordId;
  final String kana;
  final String kanji;
  final String? meaning;
  final WordRole role;
  final List<String> exampleSentences;
}

@immutable
class VocabDraftItem {
  const VocabDraftItem({
    required this.kana,
    required this.kanji,
    required this.romaji,
    required this.meaning,
    required this.role,
    required this.kanaOnly,
    required this.meaningSource,
    required this.confidence,
    this.notes = '',
    this.kanjiCandidates = const [],
    this.kanaCandidates = const [],
    this.meaningCandidates = const [],
    this.handwrittenGloss,
    this.existingMatch,
    this.reviewStatus = ReviewStatus.pending,
    this.mergeDecision = MergeDecision.undecided,
    this.newExampleSentence,
  });

  final String kana;
  final String kanji;
  final String romaji;
  final String meaning;
  final WordRole role;
  final bool kanaOnly;
  final MeaningSource meaningSource;
  final ConfidenceTier confidence;
  final String notes;

  /// Ranked kanji alternates offered as chips instead of free-text entry (no
  /// Japanese IME assumed — see capture-loop.md §3). The extractor today only
  /// ever emits one kanji guess, so this is usually just `[kanji]`; ranked
  /// alternates are a known extractor gap (capture-loop.md §4).
  final List<String> kanjiCandidates;

  /// Same idea as [kanjiCandidates] but for the kana reading: tap to pick
  /// rather than type, with a "Type (rōmaji)" fallback in the UI for the rare
  /// case none of the candidates are right. Usually just `[kana]` today.
  final List<String> kanaCandidates;

  /// Meaning alternates offered as chips (used for picture-derived words,
  /// where the meaning is a guess from a drawing). A handwritten margin gloss,
  /// if present, is folded in here rather than shown as its own affordance.
  final List<String> meaningCandidates;

  /// A handwritten margin note the extractor recorded but didn't use as
  /// content, if one seems to belong to this item.
  final String? handwrittenGloss;

  final ExistingWordMatch? existingMatch;
  final ReviewStatus reviewStatus;
  final MergeDecision mergeDecision;

  /// Example sentence to attach on merge. Real extraction files examples under
  /// the template that printed them (spec §3); attributing one to a specific
  /// word needs word-boundary matching, deferred per spec §9. This fixture
  /// sets it directly so the merge card/commit path has something concrete to
  /// show and write.
  final String? newExampleSentence;

  bool get isPictureDerived => meaningSource == MeaningSource.picture;
  bool get needsReview => confidence == ConfidenceTier.low;
  bool get hasDedupCandidate =>
      existingMatch != null && mergeDecision == MergeDecision.undecided;

  VocabDraftItem copyWith({
    String? kana,
    String? kanji,
    String? romaji,
    String? meaning,
    WordRole? role,
    bool? kanaOnly,
    ReviewStatus? reviewStatus,
    MergeDecision? mergeDecision,
  }) {
    return VocabDraftItem(
      kana: kana ?? this.kana,
      kanji: kanji ?? this.kanji,
      romaji: romaji ?? this.romaji,
      meaning: meaning ?? this.meaning,
      role: role ?? this.role,
      kanaOnly: kanaOnly ?? this.kanaOnly,
      meaningSource: meaningSource,
      confidence: confidence,
      notes: notes,
      kanjiCandidates: kanjiCandidates,
      kanaCandidates: kanaCandidates,
      meaningCandidates: meaningCandidates,
      handwrittenGloss: handwrittenGloss,
      existingMatch: existingMatch,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      mergeDecision: mergeDecision ?? this.mergeDecision,
      newExampleSentence: newExampleSentence,
    );
  }
}

@immutable
class SlotDraft {
  const SlotDraft({required this.name, required this.role, this.form = SlotForm.dictionary});

  final String name;
  final WordRole role;
  final SlotForm form;

  SlotDraft copyWith({WordRole? role, SlotForm? form}) =>
      SlotDraft(name: name, role: role ?? this.role, form: form ?? this.form);
}

@immutable
class TemplateDraftItem {
  const TemplateDraftItem({
    required this.template,
    required this.slots,
    required this.example,
    required this.confidence,
    this.notes = '',
    this.reviewStatus = ReviewStatus.pending,
  });

  final String template;
  final List<SlotDraft> slots;
  final String example;
  final ConfidenceTier confidence;
  final String notes;
  final ReviewStatus reviewStatus;

  bool get needsReview => confidence == ConfidenceTier.low;

  TemplateDraftItem copyWith({List<SlotDraft>? slots, ReviewStatus? reviewStatus}) =>
      TemplateDraftItem(
        template: template,
        slots: slots ?? this.slots,
        example: example,
        confidence: confidence,
        notes: notes,
        reviewStatus: reviewStatus ?? this.reviewStatus,
      );
}

@immutable
class CaptureDraft {
  const CaptureDraft({
    required this.worksheetTitle,
    required this.worksheetTopic,
    required this.vocabulary,
    required this.templates,
    this.ignoredHandwrittenNotes = const [],
  });

  final String worksheetTitle;
  final String worksheetTopic;
  final List<VocabDraftItem> vocabulary;
  final List<TemplateDraftItem> templates;
  final List<String> ignoredHandwrittenNotes;

  int get highConfidenceCount =>
      vocabulary.where((v) => !v.needsReview).length +
      templates.where((t) => !t.needsReview).length;

  int get needsReviewCount => vocabulary.where((v) => v.needsReview).length +
      templates.where((t) => t.needsReview).length;

  int get dedupCandidateCount =>
      vocabulary.where((v) => v.hasDedupCandidate).length;

  int get vocabReviewCount =>
      vocabulary.where((v) => v.needsReview && !v.isPictureDerived).length;
  int get pictureWordReviewCount =>
      vocabulary.where((v) => v.needsReview && v.isPictureDerived).length;
  int get templateReviewCount => templates.where((t) => t.needsReview).length;

  CaptureDraft copyWith({
    List<VocabDraftItem>? vocabulary,
    List<TemplateDraftItem>? templates,
  }) =>
      CaptureDraft(
        worksheetTitle: worksheetTitle,
        worksheetTopic: worksheetTopic,
        vocabulary: vocabulary ?? this.vocabulary,
        templates: templates ?? this.templates,
        ignoredHandwrittenNotes: ignoredHandwrittenNotes,
      );
}

enum QueueItemType { vocab, pictureWord, template, dedup }

/// A stable pointer into a [CaptureDraft]'s vocabulary/templates list, used as
/// the queue's unit of navigation. A vocab item can appear as both a
/// [QueueItemType.dedup] entry and a [QueueItemType.vocab] entry — dedup
/// confirmation and vocab-field review are independent decisions (capture-loop.md §2).
@immutable
class QueueRef {
  const QueueRef(this.type, this.index);

  final QueueItemType type;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is QueueRef && other.type == type && other.index == index;

  @override
  int get hashCode => Object.hash(type, index);
}

/// Builds the review queue in a fixed order: for each vocab item, its dedup
/// check (if any) comes before its field review (if any); then templates.
List<QueueRef> buildQueue(CaptureDraft draft) {
  final refs = <QueueRef>[];
  for (var i = 0; i < draft.vocabulary.length; i++) {
    final item = draft.vocabulary[i];
    if (item.hasDedupCandidate) refs.add(QueueRef(QueueItemType.dedup, i));
    if (item.needsReview) {
      refs.add(QueueRef(item.isPictureDerived ? QueueItemType.pictureWord : QueueItemType.vocab, i));
    }
  }
  for (var i = 0; i < draft.templates.length; i++) {
    if (draft.templates[i].needsReview) {
      refs.add(QueueRef(QueueItemType.template, i));
    }
  }
  return refs;
}

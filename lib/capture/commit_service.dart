/// Writes an approved [CaptureDraft] into the Bunko (spec §3, capture-loop.md §2
/// step 4). One photo, one commit: called once, after the review queue has no
/// unresolved items.
library;

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../data/database.dart';
import '../data/enums.dart';
import 'models.dart';

@immutable
class SkippedItemSummary {
  const SkippedItemSummary({required this.label, required this.reason});
  final String label;
  final String reason;
}

@immutable
class CommitResult {
  const CommitResult({
    required this.newWordCount,
    required this.mergedCount,
    required this.newTemplateCount,
    required this.skipped,
    this.kanjiUpgradedCount = 0,
  });

  final int newWordCount;
  final int mergedCount;
  final int newTemplateCount;
  final List<SkippedItemSummary> skipped;

  /// How many merges also filled in kanji the existing entry didn't have yet
  /// (the class teaches a word's kanji weeks after its kana — see [runCommit]).
  final int kanjiUpgradedCount;
}

String _vocabLabel(VocabDraftItem item) =>
    item.kanji.isNotEmpty ? '${item.kanji} (${item.kana})' : item.kana;

String _vocabSkipReason(VocabDraftItem item) {
  if (item.hasDedupCandidate) return 'possible Bunko match left unconfirmed';
  if (item.isPictureDerived) return 'picture-derived, low confidence';
  if (item.needsReview) return 'low confidence';
  return 'left skipped';
}

/// A vocab item's applicable queue refs are skipped if either its dedup check
/// or its field review was explicitly left skipped (capture-loop.md §3: a
/// skip means the whole item isn't written, not just the sub-decision).
/// Field review may be a [QueueItemType.vocab] or [QueueItemType.pictureWord]
/// ref depending on [VocabDraftItem.isPictureDerived].
bool _vocabIsSkipped(int index, Set<QueueRef> skippedRefs) =>
    skippedRefs.contains(QueueRef(QueueItemType.dedup, index)) ||
    skippedRefs.contains(QueueRef(QueueItemType.vocab, index)) ||
    skippedRefs.contains(QueueRef(QueueItemType.pictureWord, index));

/// A vocab item explicitly discarded as junk — excluded entirely (no write,
/// no skipped summary entry), unlike a real skip.
bool _vocabIsDiscarded(int index, Set<QueueRef> discardedRefs) =>
    discardedRefs.contains(QueueRef(QueueItemType.vocab, index)) ||
    discardedRefs.contains(QueueRef(QueueItemType.pictureWord, index));

/// A commit-screen preview computed without touching the DB — same shape as
/// [CommitResult], but "merged" only reflects confirmed dedup matches, not
/// same-batch duplicates (those are only caught during the actual commit).
CommitResult previewCommit(
  CaptureDraft draft,
  Set<QueueRef> skippedRefs, {
  Set<QueueRef> discardedRefs = const {},
}) {
  var newWordCount = 0;
  var mergedCount = 0;
  var kanjiUpgradedCount = 0;
  final skipped = <SkippedItemSummary>[];

  for (var i = 0; i < draft.vocabulary.length; i++) {
    final item = draft.vocabulary[i];
    if (_vocabIsDiscarded(i, discardedRefs)) {
      // Excluded entirely — not written, not counted as skipped.
    } else if (_vocabIsSkipped(i, skippedRefs)) {
      skipped.add(SkippedItemSummary(label: _vocabLabel(item), reason: _vocabSkipReason(item)));
    } else if (item.existingMatch != null && item.mergeDecision == MergeDecision.merge) {
      mergedCount++;
      if (item.kanji.isNotEmpty && item.existingMatch!.kanji.isEmpty) {
        kanjiUpgradedCount++;
      }
    } else {
      newWordCount++;
    }
  }

  var newTemplateCount = 0;
  for (var i = 0; i < draft.templates.length; i++) {
    if (skippedRefs.contains(QueueRef(QueueItemType.template, i))) {
      skipped.add(SkippedItemSummary(label: draft.templates[i].template, reason: 'low confidence'));
    } else {
      newTemplateCount++;
    }
  }

  return CommitResult(
    newWordCount: newWordCount,
    mergedCount: mergedCount,
    newTemplateCount: newTemplateCount,
    skipped: skipped,
    kanjiUpgradedCount: kanjiUpgradedCount,
  );
}

Future<CommitResult> runCommit(
  AppDatabase db,
  CaptureDraft draft, {
  Set<QueueRef> skippedRefs = const {},
  Set<QueueRef> discardedRefs = const {},
}) async {
  final importId = await db.into(db.imports).insert(
        ImportsCompanion.insert(rawDraftJson: const Value(null)),
      );

  var newWordCount = 0;
  var mergedCount = 0;
  var newTemplateCount = 0;
  var kanjiUpgradedCount = 0;
  final skipped = <SkippedItemSummary>[];

  for (var i = 0; i < draft.vocabulary.length; i++) {
    final item = draft.vocabulary[i];
    if (_vocabIsDiscarded(i, discardedRefs)) continue;
    if (_vocabIsSkipped(i, skippedRefs)) {
      skipped.add(SkippedItemSummary(label: _vocabLabel(item), reason: _vocabSkipReason(item)));
      continue;
    }

    int? existingWordId;
    if (item.existingMatch != null && item.mergeDecision == MergeDecision.merge) {
      existingWordId = item.existingMatch!.wordId;
    } else {
      // Also covers an exact (kana, kanji, role) match inserted earlier in
      // this same commit batch — the drift unique key would otherwise throw.
      final exact = await (db.select(db.words)
            ..where((w) =>
                w.kana.equals(item.kana) &
                w.kanji.equals(item.kanji) &
                w.role.equals(item.role.name)))
          .getSingleOrNull();
      existingWordId = exact?.id;
    }

    if (existingWordId != null) {
      // The class routinely teaches a word's kanji weeks after its kana, so a
      // merge is how newly-printed kanji reaches the existing entry. Only an
      // empty kanji field is filled — a *different* already-taught kanji is a
      // genuine conflict for review, never something to overwrite silently.
      // Gaining kanji also clears kanaOnly: the word evidently has a kanji
      // form the class now teaches.
      if (item.kanji.isNotEmpty) {
        final upgraded = await (db.update(db.words)
              ..where((w) => w.id.equals(existingWordId!) & w.kanji.equals('')))
            .write(WordsCompanion(
          kanji: Value(item.kanji),
          kanaOnly: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));
        kanjiUpgradedCount += upgraded;
      }
      // Same fill-the-gap rule for the meaning: a worksheet gloss lands on an
      // entry that never got one (e.g. imported picture-only), but an existing
      // meaning is not second-guessed.
      if (item.meaning.isNotEmpty) {
        await (db.update(db.words)
              ..where((w) => w.id.equals(existingWordId!) & w.meaning.isNull()))
            .write(WordsCompanion(
          meaning: Value(item.meaning),
          meaningSource: Value(item.meaningSource),
          updatedAt: Value(DateTime.now()),
        ));
      }
      if (item.newExampleSentence != null) {
        await db.into(db.exampleSentences).insert(
              ExampleSentencesCompanion.insert(
                sentence: item.newExampleSentence!,
                wordId: Value(existingWordId),
                importId: Value(importId),
              ),
            );
      }
      mergedCount++;
      continue;
    }

    final wordId = await db.into(db.words).insert(
          WordsCompanion.insert(
            kana: item.kana,
            kanji: Value(item.kanji),
            meaning: Value(item.meaning.isEmpty ? null : item.meaning),
            role: item.role,
            kanaOnly: Value(item.kanaOnly),
            meaningSource: Value(item.meaningSource),
            status: const Value(ItemStatus.approved),
            notes: Value(item.notes.isEmpty ? null : item.notes),
            importId: Value(importId),
          ),
        );
    if (item.newExampleSentence != null) {
      await db.into(db.exampleSentences).insert(
            ExampleSentencesCompanion.insert(
              sentence: item.newExampleSentence!,
              wordId: Value(wordId),
              importId: Value(importId),
            ),
          );
    }
    newWordCount++;
  }

  for (var i = 0; i < draft.templates.length; i++) {
    final template = draft.templates[i];
    if (skippedRefs.contains(QueueRef(QueueItemType.template, i))) {
      skipped.add(SkippedItemSummary(label: template.template, reason: 'low confidence'));
      continue;
    }

    // Structures.template is unique — a repeat of the same pattern (a
    // re-import, or two templates in this batch) attaches to the existing row
    // rather than duplicating it.
    final existingStructure = await (db.select(db.structures)
          ..where((s) => s.template.equals(template.template)))
        .getSingleOrNull();
    final structureId = existingStructure?.id ??
        await db.into(db.structures).insert(
              StructuresCompanion.insert(
                template: template.template,
                notes: Value(template.notes.isEmpty ? null : template.notes),
                status: const Value(ItemStatus.approved),
                importId: Value(importId),
              ),
            );
    if (existingStructure == null) {
      for (var ordinal = 0; ordinal < template.slots.length; ordinal++) {
        final slot = template.slots[ordinal];
        await db.into(db.slots).insert(
              SlotsCompanion.insert(
                structureId: structureId,
                name: slot.name,
                role: slot.role,
                form: Value(slot.form),
                ordinal: Value(ordinal),
              ),
            );
      }
    }
    if (template.example.isNotEmpty) {
      await db.into(db.exampleSentences).insert(
            ExampleSentencesCompanion.insert(
              sentence: template.example,
              structureId: Value(structureId),
              importId: Value(importId),
            ),
          );
    }
    newTemplateCount++;
  }

  return CommitResult(
    newWordCount: newWordCount,
    mergedCount: mergedCount,
    newTemplateCount: newTemplateCount,
    skipped: skipped,
    kanjiUpgradedCount: kanjiUpgradedCount,
  );
}

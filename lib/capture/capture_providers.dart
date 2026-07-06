/// Riverpod wiring for the capture loop (features/capture-loop.md).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../data/database.dart';
import 'commit_service.dart';
import 'dedup.dart';
import 'fixtures/sample_draft.dart';
import 'fixtures/seed_demo_bunko.dart';
import 'models.dart';

/// Overridden at the app root with a real on-device connection, and in tests
/// with an in-memory one.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final captureQueueProvider =
    StateNotifierProvider<CaptureQueueNotifier, CaptureQueueState>(
  (ref) => CaptureQueueNotifier(ref.watch(databaseProvider)),
);

@immutable
class CaptureQueueState {
  const CaptureQueueState({
    this.draft,
    this.order = const [],
    this.resolvedRefs = const {},
    this.skippedRefs = const {},
    this.pointer = 0,
    this.commitResult,
  });

  final CaptureDraft? draft;
  final List<QueueRef> order;
  final Set<QueueRef> resolvedRefs;
  final Set<QueueRef> skippedRefs;
  final int pointer;
  final CommitResult? commitResult;

  bool get isLoading => draft == null;
  QueueRef? get currentRef => pointer < order.length ? order[pointer] : null;
  int get skippedCount => skippedRefs.length;
  bool get queueComplete =>
      order.every((r) => resolvedRefs.contains(r) || skippedRefs.contains(r));

  CaptureQueueState copyWith({
    CaptureDraft? draft,
    List<QueueRef>? order,
    Set<QueueRef>? resolvedRefs,
    Set<QueueRef>? skippedRefs,
    int? pointer,
    CommitResult? commitResult,
  }) {
    return CaptureQueueState(
      draft: draft ?? this.draft,
      order: order ?? this.order,
      resolvedRefs: resolvedRefs ?? this.resolvedRefs,
      skippedRefs: skippedRefs ?? this.skippedRefs,
      pointer: pointer ?? this.pointer,
      commitResult: commitResult ?? this.commitResult,
    );
  }
}

class CaptureQueueNotifier extends StateNotifier<CaptureQueueState> {
  CaptureQueueNotifier(this._db) : super(const CaptureQueueState()) {
    _init();
  }

  final AppDatabase _db;

  Future<void> _init() async {
    await seedDemoBunko(_db);
    final draft = await attachDedupCandidates(_db, buildSampleDraft());
    state = CaptureQueueState(draft: draft, order: buildQueue(draft));
  }

  /// Bulk-marks every high-confidence vocab/template as approved. Cosmetic —
  /// high-confidence items are always commit-eligible regardless (spec:
  /// "pre-approved by default") — but reflects the tap in the UI state.
  void approveAllHighConfidence() {
    final draft = state.draft;
    if (draft == null) return;
    state = state.copyWith(
      draft: draft.copyWith(
        vocabulary: [
          for (final v in draft.vocabulary)
            if (!v.needsReview) v.copyWith(reviewStatus: ReviewStatus.approved) else v,
        ],
        templates: [
          for (final t in draft.templates)
            if (!t.needsReview) t.copyWith(reviewStatus: ReviewStatus.approved) else t,
        ],
      ),
    );
  }

  void approveCurrentVocab(VocabDraftItem edited) {
    final ref = state.currentRef;
    if (ref == null || ref.type != QueueItemType.vocab) return;
    _replaceVocab(ref.index, edited.copyWith(reviewStatus: ReviewStatus.approved));
    _resolve(ref);
  }

  void approveCurrentTemplate(TemplateDraftItem edited) {
    final ref = state.currentRef;
    if (ref == null || ref.type != QueueItemType.template) return;
    _replaceTemplate(ref.index, edited.copyWith(reviewStatus: ReviewStatus.approved));
    _resolve(ref);
  }

  void mergeCurrentDedup() {
    final ref = state.currentRef;
    if (ref == null || ref.type != QueueItemType.dedup) return;
    final item = state.draft!.vocabulary[ref.index];
    _replaceVocab(ref.index, item.copyWith(mergeDecision: MergeDecision.merge));
    _resolve(ref);
  }

  void notAMatchCurrentDedup() {
    final ref = state.currentRef;
    if (ref == null || ref.type != QueueItemType.dedup) return;
    final item = state.draft!.vocabulary[ref.index];
    _replaceVocab(ref.index, item.copyWith(mergeDecision: MergeDecision.notAMatch));
    _resolve(ref);
  }

  void skipCurrent() {
    final ref = state.currentRef;
    if (ref == null) return;
    state = state.copyWith(skippedRefs: {...state.skippedRefs, ref});
    _advance();
  }

  /// Reopens a previously-skipped item — skips are deferrals, not rejections
  /// (capture-loop.md §3).
  void reopen(QueueRef ref) {
    final skipped = {...state.skippedRefs}..remove(ref);
    state = state.copyWith(skippedRefs: skipped, pointer: state.order.indexOf(ref));
  }

  Future<void> commit() async {
    final draft = state.draft;
    if (draft == null) return;
    final result = await runCommit(_db, draft, skippedRefs: state.skippedRefs);
    state = state.copyWith(commitResult: result);
  }

  void _replaceVocab(int index, VocabDraftItem item) {
    final vocab = [...state.draft!.vocabulary];
    vocab[index] = item;
    state = state.copyWith(draft: state.draft!.copyWith(vocabulary: vocab));
  }

  void _replaceTemplate(int index, TemplateDraftItem item) {
    final templates = [...state.draft!.templates];
    templates[index] = item;
    state = state.copyWith(draft: state.draft!.copyWith(templates: templates));
  }

  void _resolve(QueueRef ref) {
    state = state.copyWith(resolvedRefs: {...state.resolvedRefs, ref});
    _advance();
  }

  void _advance() {
    var next = state.pointer + 1;
    while (next < state.order.length &&
        (state.resolvedRefs.contains(state.order[next]) ||
            state.skippedRefs.contains(state.order[next]))) {
      next++;
    }
    state = state.copyWith(pointer: next);
  }
}

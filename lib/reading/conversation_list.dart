/// Riverpod wiring and formatting for the conversation-list screen
/// (features/conversation-list.md): a browsable, newest-first list of cached
/// conversations with per-row delete (snackbar-undo).
///
/// Delete is optimistic — [ConversationListNotifier.takeOut] drops the row
/// from the visible list and the real DB/disk removal ([commitDelete]) only
/// runs once the undo window lapses. So an undo never has to resurrect a DB
/// row or re-synthesise audio; it just puts the summary back.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../data/conversation_cache.dart';
import '../listening/audio_store.dart';
import '../listening/listening_providers.dart' show conversationAudioStoreProvider;
import 'reading_providers.dart' show conversationStoreProvider;

@immutable
class ConversationListState {
  const ConversationListState({
    required this.rows,
    this.loading = false,
    this.error = false,
  });
  const ConversationListState.loading()
      : rows = const [],
        loading = true,
        error = false;

  final List<ConversationSummary> rows;
  final bool loading;
  final bool error;

  /// True only once a successful load returned nothing — drives the empty
  /// state (distinct from "still loading" and "load failed").
  bool get isEmpty => !loading && !error && rows.isEmpty;
}

class ConversationListNotifier extends StateNotifier<ConversationListState> {
  ConversationListNotifier(this._store, this._audio)
      : super(const ConversationListState.loading());

  final ConversationStore _store;
  final AudioStore _audio;

  Future<void> load() async {
    state = const ConversationListState.loading();
    try {
      final rows = await _store.list();
      state = ConversationListState(rows: rows);
    } catch (_) {
      state = const ConversationListState(rows: [], error: true);
    }
  }

  /// Optimistically drops the row from the visible list and returns it with
  /// its position for a potential [putBack]. Nothing is persisted yet.
  /// Returns null if the id is already gone.
  ({ConversationSummary row, int index})? takeOut(int id) {
    final index = state.rows.indexWhere((r) => r.id == id);
    if (index < 0) return null;
    final row = state.rows[index];
    state = ConversationListState(
      rows: [for (final r in state.rows) if (r.id != id) r],
    );
    return (row: row, index: index);
  }

  /// Re-inserts an undone row at its original position.
  void putBack(ConversationSummary row, int index) {
    final rows = [...state.rows];
    rows.insert(index.clamp(0, rows.length), row);
    state = ConversationListState(rows: rows);
  }

  /// Persists a deletion: the DB row (link rows cascade) then the on-disk
  /// audio directory. Runs when the undo window closes. Best-effort — the row
  /// is already gone from the list, and a failed disk cleanup only leaves an
  /// orphaned audio dir (storage is trivial).
  Future<void> commitDelete(int id) async {
    try {
      await _store.delete(id);
      await _audio.deleteAudio(conversationId: id);
    } catch (_) {
      // Swallowed: see the method doc.
    }
  }
}

/// autoDispose: the list reloads fresh each time the screen is entered, so it
/// reflects conversations added since (write-through happens on the reading
/// screen). Loads on creation.
final conversationListProvider = StateNotifierProvider.autoDispose<
    ConversationListNotifier, ConversationListState>(
  (ref) => ConversationListNotifier(
    ref.watch(conversationStoreProvider),
    ref.watch(conversationAudioStoreProvider),
  )..load(),
);

// ---------------------------------------------------------------------------
// Row metadata formatting (features/conversation-list.md §2), e.g.
// "Jul 18 · practiced yesterday". Pure, so it's unit-tested directly.
// ---------------------------------------------------------------------------

const List<String> _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// The row's metadata line: creation date · practiced-relative phrase.
String conversationMetaLine(ConversationSummary c, {DateTime? now}) {
  final created = '${_monthAbbr[c.createdAt.month - 1]} ${c.createdAt.day}';
  return '$created · ${practicedPhrase(c.lastPracticedAt, now ?? DateTime.now())}';
}

/// "not yet practiced" / "practiced today" / "practiced 3 days ago" / weeks /
/// months, thresholded on the calendar-day gap so "yesterday" reads right
/// regardless of the time of day.
String practicedPhrase(DateTime? lastPracticedAt, DateTime now) {
  if (lastPracticedAt == null) return 'not yet practiced';
  final days = _calendarDaysBetween(lastPracticedAt, now);
  if (days <= 0) return 'practiced today';
  if (days == 1) return 'practiced yesterday';
  if (days < 7) return 'practiced $days days ago';
  if (days < 14) return 'practiced 1 week ago';
  if (days < 35) return 'practiced ${days ~/ 7} weeks ago';
  final months = days ~/ 30;
  return months <= 1
      ? 'practiced 1 month ago'
      : 'practiced $months months ago';
}

int _calendarDaysBetween(DateTime a, DateTime b) {
  final da = DateTime(a.year, a.month, a.day);
  final db = DateTime(b.year, b.month, b.day);
  return db.difference(da).inDays;
}

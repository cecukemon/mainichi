import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/conversation_cache.dart';
import 'package:mainichi/generation/conversation_generator.dart';
import 'package:mainichi/listening/audio_store.dart';
import 'package:mainichi/listening/line_audio.dart';
import 'package:mainichi/listening/listening_providers.dart';
import 'package:mainichi/reading/conversation_list.dart';
import 'package:mainichi/reading/reading_providers.dart';
import 'package:mainichi/reading/screens/conversation_list_screen.dart';

/// In-memory store backing the list screen. Only the list/byId/delete surface
/// the screen exercises is implemented meaningfully.
class FakeConversationStore implements ConversationStore {
  FakeConversationStore(this._rows);
  final List<ConversationSummary> _rows;
  final List<int> deleted = [];

  @override
  Future<List<ConversationSummary>> list() async => List.of(_rows);

  @override
  Future<void> delete(int id) async {
    deleted.add(id);
    _rows.removeWhere((r) => r.id == id);
  }

  @override
  Future<CachedConversation?> byId(int id) async => null;

  @override
  Future<int> save(GeneratedConversation conversation,
          {required Set<int> wordIds, required Set<int> structureIds}) =>
      throw UnimplementedError();
  @override
  Future<CachedConversation?> leastRecentlyPracticed() =>
      throw UnimplementedError();
  @override
  Future<void> markPracticed(int id) async {}
  @override
  Future<void> setAudioPath(int id, String path) async {}
}

class FakeAudioStore implements AudioStore {
  final List<int> deletedAudio = [];

  @override
  Future<void> deleteAudio({required int conversationId}) async =>
      deletedAudio.add(conversationId);

  @override
  Future<List<String>> ensureAudio(
          {required int conversationId, required List<LineAudioSpec> lines}) =>
      throw UnimplementedError();
}

ConversationSummary _row(int id, String title) => ConversationSummary(
      id: id,
      title: title,
      createdAt: DateTime(2026, 7, 18),
      lastPracticedAt: DateTime(2026, 7, 17),
      lineCount: 6,
    );

Future<(FakeConversationStore, FakeAudioStore)> _pump(
  WidgetTester tester, {
  List<ConversationSummary>? rows,
}) async {
  final store = FakeConversationStore(rows ?? []);
  final audio = FakeAudioStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        conversationStoreProvider.overrideWithValue(store),
        conversationAudioStoreProvider.overrideWithValue(audio),
      ],
      child: const MaterialApp(home: ConversationListScreen()),
    ),
  );
  await tester.pump(); // resolve the async load
  return (store, audio);
}

void main() {
  testWidgets('renders each conversation with its title and metadata',
      (tester) async {
    await _pump(tester, rows: [
      _row(1, 'Ordering at a restaurant'),
      _row(2, 'Asking for directions'),
    ]);

    expect(find.text('Ordering at a restaurant'), findsOneWidget);
    expect(find.text('Asking for directions'), findsOneWidget);
    expect(find.textContaining('Jul 18 ·'), findsNWidgets(2));
  });

  testWidgets('empty cache shows the friendly empty state', (tester) async {
    await _pump(tester, rows: []);

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.textContaining('saved automatically'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Start reading practice'),
        findsOneWidget);
  });

  testWidgets('swipe removes the row and shows an undo snackbar',
      (tester) async {
    final (store, _) = await _pump(tester, rows: [
      _row(1, 'Ordering at a restaurant'),
      _row(2, 'Asking for directions'),
    ]);

    await tester.drag(find.text('Ordering at a restaurant'),
        const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Ordering at a restaurant'), findsNothing);
    expect(find.text('Deleted "Ordering at a restaurant"'), findsOneWidget);
    // Not yet persisted — the commit waits for the undo window to close.
    expect(store.deleted, isEmpty);
  });

  testWidgets('undo restores the row and never persists the delete',
      (tester) async {
    final (store, audio) = await _pump(tester, rows: [
      _row(1, 'Ordering at a restaurant'),
    ]);

    await tester.drag(find.text('Ordering at a restaurant'),
        const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Ordering at a restaurant'), findsOneWidget);
    expect(store.deleted, isEmpty);
    expect(audio.deletedAudio, isEmpty);
  });

  // The commit-on-lapse path (DB + audio) is exercised directly on the
  // notifier — driving a SnackBar's auto-dismiss timer through the widget
  // tester is timing-fragile, and the optimistic-delete logic lives here.
  group('ConversationListNotifier', () {
    test('load surfaces the store rows', () async {
      final store = FakeConversationStore([_row(1, 'A'), _row(2, 'B')]);
      final notifier = ConversationListNotifier(store, FakeAudioStore());
      await notifier.load();
      expect(notifier.state.rows.map((r) => r.id), [1, 2]);
      expect(notifier.state.isEmpty, isFalse);
    });

    test('takeOut drops the row optimistically without persisting', () async {
      final store = FakeConversationStore([_row(1, 'A'), _row(2, 'B')]);
      final notifier = ConversationListNotifier(store, FakeAudioStore());
      await notifier.load();

      final removed = notifier.takeOut(1);
      expect(removed!.index, 0);
      expect(notifier.state.rows.map((r) => r.id), [2]);
      expect(store.deleted, isEmpty); // nothing committed yet
    });

    test('putBack restores the row at its original position', () async {
      final store = FakeConversationStore([_row(1, 'A'), _row(2, 'B')]);
      final notifier = ConversationListNotifier(store, FakeAudioStore());
      await notifier.load();

      final removed = notifier.takeOut(1)!;
      notifier.putBack(removed.row, removed.index);
      expect(notifier.state.rows.map((r) => r.id), [1, 2]);
    });

    test('commitDelete removes the DB row and its audio directory', () async {
      final store = FakeConversationStore([_row(1, 'A')]);
      final audio = FakeAudioStore();
      final notifier = ConversationListNotifier(store, audio);
      await notifier.load();

      notifier.takeOut(1);
      await notifier.commitDelete(1);
      expect(store.deleted, [1]);
      expect(audio.deletedAudio, [1]);
    });
  });
}

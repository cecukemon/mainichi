/// The generated-content cache's write path and minimal read path
/// (spec §10.3, features/generated-cache.md): every valid conversation is
/// persisted with links to the vocab/structures it exercises; the only
/// reader today is the reading screen's error-state fallback.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../generation/conversation_generator.dart';
// The drift row class for the table is also named `GeneratedConversation`;
// this module means the engine's type, and only touches rows via the db API.
import 'database.dart' hide GeneratedConversation;

@immutable
class CachedConversation {
  const CachedConversation({required this.id, required this.conversation});
  final int id;
  final GeneratedConversation conversation;
}

abstract class ConversationStore {
  /// Persists a validated conversation with its link rows, stamped as
  /// practiced now (it is on screen when this is called). Word/structure ids
  /// are the caller's (derived from the validated conversation, not the
  /// model's self-report).
  Future<int> save(
    GeneratedConversation conversation, {
    required Set<int> wordIds,
    required Set<int> structureIds,
  });

  /// The cached conversation least recently practiced, or null when empty.
  Future<CachedConversation?> leastRecentlyPracticed();

  Future<void> markPracticed(int id);

  /// Records where this conversation's synthesized audio lives (the per-
  /// conversation directory, features/listening-exercise.md). Set on first
  /// successful synthesis.
  Future<void> setAudioPath(int id, String path);
}

class DriftConversationStore implements ConversationStore {
  /// [now] is injectable because drift stores DateTime at second resolution —
  /// tests need controllable stamps to exercise the LRU ordering.
  DriftConversationStore(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  @override
  Future<int> save(
    GeneratedConversation conversation, {
    required Set<int> wordIds,
    required Set<int> structureIds,
  }) {
    return _db.transaction(() async {
      final id = await _db.into(_db.generatedConversations).insert(
            GeneratedConversationsCompanion.insert(
              payloadJson: jsonEncode(conversation.toJson()),
              lineCount: conversation.lines.length,
            ),
          );
      for (final wordId in wordIds) {
        await _db.into(_db.conversationWords).insert(
              ConversationWordsCompanion.insert(
                conversationId: id,
                wordId: wordId,
              ),
            );
      }
      for (final structureId in structureIds) {
        await _db.into(_db.conversationStructures).insert(
              ConversationStructuresCompanion.insert(
                conversationId: id,
                structureId: structureId,
              ),
            );
      }
      await markPracticed(id);
      return id;
    });
  }

  @override
  Future<CachedConversation?> leastRecentlyPracticed() async {
    final row = await (_db.select(_db.generatedConversations)
          ..orderBy([
            (c) => OrderingTerm.asc(c.lastPracticedAt),
            (c) => OrderingTerm.asc(c.id),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return CachedConversation(
      id: row.id,
      conversation: GeneratedConversation.fromJson(
        jsonDecode(row.payloadJson) as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<void> setAudioPath(int id, String path) =>
      (_db.update(_db.generatedConversations)..where((c) => c.id.equals(id)))
          .write(GeneratedConversationsCompanion(audioPath: Value(path)));

  @override
  Future<void> markPracticed(int id) =>
      (_db.update(_db.generatedConversations)..where((c) => c.id.equals(id)))
          .write(GeneratedConversationsCompanion(
        lastPracticedAt: Value(_now()),
      ));
}

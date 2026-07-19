/// The mainichi local database (spec §10.1: all data stored locally, no backend).
///
/// Construct with an executor so the app and tests can supply different ones:
/// the app opens an on-device file (see `connection.dart`, added later); tests
/// use `NativeDatabase.memory()`.
library;

import 'package:drift/drift.dart';

import 'enums.dart';
import 'glue_seed.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Words,
    Structures,
    Slots,
    ExampleSentences,
    Imports,
    GeneratedConversations,
    ConversationWords,
    ConversationStructures,
    SrsCards,
    GrammarGlue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedGrammarGlue();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2 (D56): glue allowlist promoted from a code constant to a
            // reviewable table; existing installs get the constant's rows.
            await m.createTable(grammarGlue);
            await seedGrammarGlue();
          }
          if (from < 3) {
            // v3 (conversation list): GeneratedConversations gains a `title`.
            // No backfill — pre-title cached rows are regenerable content, so
            // drop the cache (conversations + their link rows) and recreate it
            // fresh with the new column, rather than surface blank titles; new
            // generations arrive titled. Drop children first (FK order),
            // recreate parent first. Orphaned audio dirs are left to the
            // delete path (storage is trivial, features/conversation-list.md §3).
            await customStatement('DROP TABLE IF EXISTS conversation_words');
            await customStatement('DROP TABLE IF EXISTS conversation_structures');
            await customStatement('DROP TABLE IF EXISTS generated_conversations');
            await m.createTable(generatedConversations);
            await m.createTable(conversationWords);
            await m.createTable(conversationStructures);
          }
        },
        beforeOpen: (details) async {
          // Cascade deletes (Slots, link tables, examples) rely on this.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Inserts [grammarGlueSeedRows], skipping surfaces already present, so
  /// seeding is idempotent and never clobbers a backfilled row's provenance.
  Future<void> seedGrammarGlue() => batch((b) {
        b.insertAll(
          grammarGlue,
          [
            for (final (surface, kind) in grammarGlueSeedRows)
              GrammarGlueCompanion.insert(surface: surface, kind: kind),
          ],
          mode: InsertMode.insertOrIgnore,
        );
      });
}

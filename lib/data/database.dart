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
  int get schemaVersion => 2;

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

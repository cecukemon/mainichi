/// The mainichi local database (spec §10.1: all data stored locally, no backend).
///
/// Construct with an executor so the app and tests can supply different ones:
/// the app opens an on-device file (see `connection.dart`, added later); tests
/// use `NativeDatabase.memory()`.
library;

import 'package:drift/drift.dart';

import 'enums.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          // Cascade deletes (Slots, link tables, examples) rely on this.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

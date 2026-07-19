/// Read-side query mapping the real store to a [GenerationSeed] — the reading
/// screen's live constraint set (spec §2 / §10.1 interfaces).
///
/// Deliberately the first and only slice of the repository/query layer (D22:
/// build it against real calls, not speculatively). Only `approved` items are
/// included, upholding the enums.dart invariant that an un-reviewed draft can
/// never leak into practice.
library;

import 'package:drift/drift.dart';

import '../generation/conversation_generator.dart';
import 'database.dart';
import 'enums.dart';

/// Where a generation run's constraint set comes from. The screen depends on
/// this, not on drift, so tests and previews can supply a fixture seed.
abstract class SeedSource {
  Future<GenerationSeed> loadGenerationSeed();
}

class DriftSeedSource implements SeedSource {
  DriftSeedSource(this._db);

  final AppDatabase _db;

  @override
  Future<GenerationSeed> loadGenerationSeed() async {
    final words = await (_db.select(_db.words)
          ..where((w) => w.status.equalsValue(ItemStatus.approved))
          ..orderBy([(w) => OrderingTerm.asc(w.id)]))
        .get();

    final structures = await (_db.select(_db.structures)
          ..where((s) => s.status.equalsValue(ItemStatus.approved))
          ..orderBy([(s) => OrderingTerm.asc(s.id)]))
        .get();

    // The whole table — presence means approved (a row only gets here via
    // the initial seed or the backfill review sheet, D56).
    final glue = await (_db.select(_db.grammarGlue)
          ..orderBy([(g) => OrderingTerm.asc(g.surface)]))
        .get();

    final slots = await (_db.select(_db.slots)
          ..orderBy([
            (s) => OrderingTerm.asc(s.structureId),
            (s) => OrderingTerm.asc(s.ordinal),
          ]))
        .get();
    final slotsByStructure = <int, List<SeedSlot>>{};
    for (final s in slots) {
      slotsByStructure.putIfAbsent(s.structureId, () => []).add(
            SeedSlot(name: s.name, role: s.role.wire, form: s.form.wire),
          );
    }

    return GenerationSeed(
      vocab: [
        for (final w in words)
          SeedWord(
            id: w.id,
            kana: w.kana,
            kanji: w.kanji,
            role: w.role.wire,
            meaning: w.meaning ?? '',
            kanaOnly: w.kanaOnly,
          ),
      ],
      structures: [
        for (final s in structures)
          SeedStructure(
            id: s.id,
            template: s.template,
            slots: slotsByStructure[s.id] ?? const [],
          ),
      ],
      glue: {for (final g in glue) g.surface},
    );
  }
}

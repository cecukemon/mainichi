import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/capture/models.dart' show ConfidenceTier;
import 'package:mainichi/config/model_config.dart';
import 'package:mainichi/data/database.dart';
import 'package:mainichi/data/enums.dart';
import 'package:mainichi/reading/scope_backfill.dart';

void main() {
  late AppDatabase db;
  late ScopeBackfillService service;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = ScopeBackfillService(db);
  });
  tearDown(() => db.close());

  group('draftForSurface', () {
    test('a kana surface becomes a kana-filled, review-shaped draft', () {
      final draft = service.draftForSurface('その');
      expect(draft.kana, 'その');
      expect(draft.kanji, '');
      expect(draft.kanaOnly, isFalse); // "kanji not taught yet", not "never"
      expect(draft.meaning, ''); // user supplies; approve requires it
      expect(draft.role, WordRole.other);
      expect(draft.meaningSource, MeaningSource.none);
      expect(draft.confidence, ConfidenceTier.low);
    });
  });

  group('commit', () {
    test('writes an approved word with reading-backfill provenance', () async {
      final edited = service
          .draftForSurface('その')
          .copyWith(meaning: 'that (near you)', role: WordRole.demonstrative);
      final result = await service.commit(edited, surface: 'その');

      expect(result.newWordCount, 1);
      final word = await db.select(db.words).getSingle();
      expect(word.kana, 'その');
      expect(word.status, ItemStatus.approved);
      expect(word.meaning, 'that (near you)');
      expect(word.role, WordRole.demonstrative);

      // Provenance: no worksheet lineage — a null photo, the generation
      // model, and the backfill marker in the raw-draft slot (D52).
      final import = await db.select(db.imports).getSingle();
      expect(word.importId, import.id);
      expect(import.sourceImage, isNull);
      expect(import.model, ModelConfig.generation);
      final raw = jsonDecode(import.rawDraftJson!) as Map<String, dynamic>;
      expect(raw['source'], backfillSource);
      expect(raw['surface'], 'その');
    });

    test('re-adding the identical word merges instead of duplicating',
        () async {
      final edited = service
          .draftForSurface('その')
          .copyWith(meaning: 'that', role: WordRole.demonstrative);
      await service.commit(edited, surface: 'その');
      final second = await service.commit(edited, surface: 'その');

      expect(second.newWordCount, 0);
      expect(second.mergedCount, 1);
      expect(await db.select(db.words).get(), hasLength(1));
    });
  });

  group('commitGlue (D56)', () {
    test('writes a glue row with glue-backfill provenance', () async {
      await service.commitGlue(surface: 'が', kind: GlueKind.particle);

      final row = await (db.select(db.grammarGlue)
            ..where((g) => g.surface.equals('が')))
          .getSingle();
      expect(row.kind, GlueKind.particle);

      final import = await db.select(db.imports).getSingle();
      expect(row.importId, import.id);
      expect(import.sourceImage, isNull);
      expect(import.model, ModelConfig.generation);
      final raw = jsonDecode(import.rawDraftJson!) as Map<String, dynamic>;
      expect(raw['source'], glueBackfillSource);
      expect(raw['surface'], 'が');
      expect(raw['kind'], 'particle');
    });

    test('an already-known surface is a no-op — no duplicate row, no orphan '
        'Imports provenance', () async {
      await service.commitGlue(surface: 'が', kind: GlueKind.particle);
      await service.commitGlue(surface: 'が', kind: GlueKind.other);

      final rows = await (db.select(db.grammarGlue)
            ..where((g) => g.surface.equals('が')))
          .get();
      expect(rows, hasLength(1));
      expect(rows.single.kind, GlueKind.particle); // first commit stands
      expect(await db.select(db.imports).get(), hasLength(1));
    });

    test('a seeded surface is a no-op too (presence is what matters)',
        () async {
      await service.commitGlue(surface: 'は', kind: GlueKind.particle);
      final rows = await (db.select(db.grammarGlue)
            ..where((g) => g.surface.equals('は')))
          .get();
      expect(rows, hasLength(1));
      expect(rows.single.importId, isNull); // still the seed row
      expect(await db.select(db.imports).get(), isEmpty);
    });
  });
}

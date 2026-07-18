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
}

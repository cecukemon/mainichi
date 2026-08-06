/// Read-only query layer over the Bunko (words, sentence structures, grammar
/// glue) for the browse screen (features/bunko-browser.md). Purely a second
/// read path onto the same tables the capture flow writes — no new storage,
/// no duplication. Unlike [DriftSeedSource] (which feeds the generation
/// engine and only returns `approved` items in a stripped-down shape), this
/// store shows every row as-is, including fields the generator never needs
/// (notes, status, timestamps, example sentences), so future edit methods
/// have a natural home on the same interface.
library;

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import 'database.dart';
import 'enums.dart';

@immutable
class BunkoWordRow {
  const BunkoWordRow({
    required this.id,
    required this.kana,
    required this.kanji,
    required this.meaning,
    required this.role,
    required this.kanaOnly,
    required this.meaningSource,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  final int id;
  final String kana;

  /// '' when the worksheet printed no kanji form (tables.dart convention).
  final String kanji;
  final String? meaning;
  final WordRole role;
  final bool kanaOnly;
  final MeaningSource meaningSource;
  final ItemStatus status;
  final String? notes;
  final DateTime createdAt;
}

@immutable
class BunkoSlot {
  const BunkoSlot({required this.name, required this.role, required this.form});
  final String name;
  final WordRole role;
  final SlotForm form;
}

@immutable
class BunkoStructureRow {
  const BunkoStructureRow({
    required this.id,
    required this.template,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.slots,
  });

  final int id;
  final String template;
  final String? notes;
  final ItemStatus status;
  final DateTime createdAt;

  /// Ordered by ordinal.
  final List<BunkoSlot> slots;
}

@immutable
class BunkoGlueRow {
  const BunkoGlueRow({
    required this.id,
    required this.surface,
    required this.kind,
    required this.addedAt,
  });

  final int id;
  final String surface;
  final GlueKind kind;
  final DateTime addedAt;
}

@immutable
class BunkoWordDetail {
  const BunkoWordDetail({required this.word, required this.examples});
  final BunkoWordRow word;
  final List<String> examples;
}

/// Appended to [Words.notes] when a suspected polite-form verb (see
/// `politeFormSuspicion`) is confirmed as a legitimate dictionary form (e.g.
/// 励ます, 済ます) so the fix-up sheet stops flagging it.
const String baseFormCheckedMarker = '[base-form-checked]';

enum FixWordOutcome { updated, merged, notFound }

/// Result of [BunkoStore.fixWordBaseForm].
@immutable
class FixWordResult {
  const FixWordResult._(this.outcome, this.mergedIntoId);
  const FixWordResult.updated() : this._(FixWordOutcome.updated, null);

  /// The rewrite collided with the `(kana, kanji, role)` unique key of an
  /// existing entry ([mergedIntoId]) — the source word's meaning/notes/kanji
  /// gaps, example sentences, and conversation/SRS references were carried
  /// over onto it, and the source row was deleted.
  const FixWordResult.merged(int intoId) : this._(FixWordOutcome.merged, intoId);
  const FixWordResult.notFound() : this._(FixWordOutcome.notFound, null);

  final FixWordOutcome outcome;
  final int? mergedIntoId;
}

@immutable
class BunkoStructureDetail {
  const BunkoStructureDetail({required this.structure, required this.examples});
  final BunkoStructureRow structure;
  final List<String> examples;
}

abstract class BunkoStore {
  /// Every word, newest first. Status is not filtered — the browser mirrors
  /// the store as-is (features/bunko-browser.md).
  Future<List<BunkoWordRow>> listWords();

  /// Every structure with its slots, newest first.
  Future<List<BunkoStructureRow>> listStructures();

  /// Every grammar-glue row, newest first.
  Future<List<BunkoGlueRow>> listGlue();

  /// A word plus its example sentences, or null if it's been deleted since
  /// the list was loaded.
  Future<BunkoWordDetail?> wordById(int id);

  /// A structure plus its example sentences, or null if it's been deleted
  /// since the list was loaded.
  Future<BunkoStructureDetail?> structureById(int id);

  /// Rewrites word [id]'s kana/kanji to the dictionary-form base the caller
  /// picked (verb base-form fix-up, features/bunko-browser.md). See
  /// [FixWordResult] for the merge behavior when the rewrite collides with
  /// an existing entry.
  Future<FixWordResult> fixWordBaseForm(int id,
      {required String kana, required String kanji});

  /// Marks word [id] as a manually-confirmed dictionary form despite ending
  /// in ます (e.g. 励ます) — appends [baseFormCheckedMarker] to its notes so
  /// the fix-up sheet stops flagging it. No-op if already marked.
  Future<void> dismissBaseFormSuspicion(int id);
}

class DriftBunkoStore implements BunkoStore {
  DriftBunkoStore(this._db);

  final AppDatabase _db;

  BunkoWordRow _wordRow(Word w) => BunkoWordRow(
        id: w.id,
        kana: w.kana,
        kanji: w.kanji,
        meaning: w.meaning,
        role: w.role,
        kanaOnly: w.kanaOnly,
        meaningSource: w.meaningSource,
        status: w.status,
        notes: w.notes,
        createdAt: w.createdAt,
      );

  Future<Map<int, List<BunkoSlot>>> _slotsByStructure(
      Iterable<int> structureIds) async {
    if (structureIds.isEmpty) return {};
    final rows = await (_db.select(_db.slots)
          ..where((s) => s.structureId.isIn(structureIds))
          ..orderBy([(s) => OrderingTerm.asc(s.ordinal)]))
        .get();
    final byStructure = <int, List<BunkoSlot>>{};
    for (final s in rows) {
      byStructure
          .putIfAbsent(s.structureId, () => [])
          .add(BunkoSlot(name: s.name, role: s.role, form: s.form));
    }
    return byStructure;
  }

  @override
  Future<List<BunkoWordRow>> listWords() async {
    final rows = await (_db.select(_db.words)
          ..orderBy([
            (w) => OrderingTerm.desc(w.createdAt),
            (w) => OrderingTerm.desc(w.id),
          ]))
        .get();
    return [for (final w in rows) _wordRow(w)];
  }

  @override
  Future<List<BunkoStructureRow>> listStructures() async {
    final rows = await (_db.select(_db.structures)
          ..orderBy([
            (s) => OrderingTerm.desc(s.createdAt),
            (s) => OrderingTerm.desc(s.id),
          ]))
        .get();
    final slotsByStructure = await _slotsByStructure(rows.map((s) => s.id));
    return [
      for (final s in rows)
        BunkoStructureRow(
          id: s.id,
          template: s.template,
          notes: s.notes,
          status: s.status,
          createdAt: s.createdAt,
          slots: slotsByStructure[s.id] ?? const [],
        ),
    ];
  }

  @override
  Future<List<BunkoGlueRow>> listGlue() async {
    final rows = await (_db.select(_db.grammarGlue)
          ..orderBy([
            (g) => OrderingTerm.desc(g.addedAt),
            (g) => OrderingTerm.desc(g.id),
          ]))
        .get();
    return [
      for (final g in rows)
        BunkoGlueRow(
            id: g.id, surface: g.surface, kind: g.kind, addedAt: g.addedAt),
    ];
  }

  @override
  Future<BunkoWordDetail?> wordById(int id) async {
    final w = await (_db.select(_db.words)..where((w) => w.id.equals(id)))
        .getSingleOrNull();
    if (w == null) return null;
    final examples = await (_db.select(_db.exampleSentences)
          ..where((e) => e.wordId.equals(id))
          ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
        .get();
    return BunkoWordDetail(
      word: _wordRow(w),
      examples: [for (final e in examples) e.sentence],
    );
  }

  @override
  Future<BunkoStructureDetail?> structureById(int id) async {
    final s =
        await (_db.select(_db.structures)..where((s) => s.id.equals(id)))
            .getSingleOrNull();
    if (s == null) return null;
    final slotsByStructure = await _slotsByStructure([id]);
    final examples = await (_db.select(_db.exampleSentences)
          ..where((e) => e.structureId.equals(id))
          ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
        .get();
    return BunkoStructureDetail(
      structure: BunkoStructureRow(
        id: s.id,
        template: s.template,
        notes: s.notes,
        status: s.status,
        createdAt: s.createdAt,
        slots: slotsByStructure[id] ?? const [],
      ),
      examples: [for (final e in examples) e.sentence],
    );
  }

  @override
  Future<FixWordResult> fixWordBaseForm(int id,
      {required String kana, required String kanji}) {
    return _db.transaction(() async {
      final source =
          await (_db.select(_db.words)..where((w) => w.id.equals(id)))
              .getSingleOrNull();
      if (source == null) return const FixWordResult.notFound();

      final collision = await (_db.select(_db.words)
            ..where((w) =>
                w.kana.equals(kana) &
                w.kanji.equals(kanji) &
                w.role.equalsValue(source.role) &
                w.id.equals(id).not()))
          .getSingleOrNull();

      if (collision == null) {
        await (_db.update(_db.words)..where((w) => w.id.equals(id))).write(
              WordsCompanion(
                kana: Value(kana),
                kanji: Value(kanji),
                updatedAt: Value(DateTime.now()),
              ),
            );
        return const FixWordResult.updated();
      }

      final targetId = collision.id;
      // Fill-the-gap merge, mirroring commit_service.dart's dedup merge: an
      // existing meaning/notes/kanji is never second-guessed, only filled
      // when genuinely empty.
      if (source.meaning?.isNotEmpty == true) {
        await (_db.update(_db.words)
              ..where((w) => w.id.equals(targetId) & w.meaning.isNull()))
            .write(WordsCompanion(
          meaning: Value(source.meaning),
          meaningSource: Value(source.meaningSource),
          updatedAt: Value(DateTime.now()),
        ));
      }
      if (source.notes?.isNotEmpty == true) {
        await (_db.update(_db.words)
              ..where((w) => w.id.equals(targetId) & w.notes.isNull()))
            .write(WordsCompanion(
          notes: Value(source.notes),
          updatedAt: Value(DateTime.now()),
        ));
      }
      if (kanji.isNotEmpty && collision.kanji.isEmpty) {
        await (_db.update(_db.words)
              ..where((w) => w.id.equals(targetId) & w.kanji.equals('')))
            .write(WordsCompanion(
          kanji: Value(kanji),
          kanaOnly: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));
      }

      // Repoint dependents onto the target before deleting the source row —
      // ExampleSentences/ConversationWords/SrsCards all cascade-delete on
      // wordId, which would silently destroy this data if deleted first.
      await (_db.update(_db.exampleSentences)
            ..where((e) => e.wordId.equals(id)))
          .write(ExampleSentencesCompanion(wordId: Value(targetId)));
      await _repointConversationWords(fromWordId: id, toWordId: targetId);
      await _repointSrsCard(fromWordId: id, toWordId: targetId);

      await (_db.delete(_db.words)..where((w) => w.id.equals(id))).go();
      return FixWordResult.merged(targetId);
    });
  }

  /// A conversation may already reference both the source and target word
  /// (the composite primary key would collide on a plain rewrite), so this
  /// inserts the target reference first (ignoring an existing one) and only
  /// then deletes the source's rows.
  Future<void> _repointConversationWords(
      {required int fromWordId, required int toWordId}) async {
    final rows = await (_db.select(_db.conversationWords)
          ..where((r) => r.wordId.equals(fromWordId)))
        .get();
    for (final row in rows) {
      await _db.into(_db.conversationWords).insert(
            ConversationWordsCompanion.insert(
              conversationId: row.conversationId,
              wordId: toWordId,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    await (_db.delete(_db.conversationWords)
          ..where((r) => r.wordId.equals(fromWordId)))
        .go();
  }

  /// itemType/itemId is a polymorphic reference (not a DB foreign key,
  /// tables.dart), unique per (itemType, itemId) — if the target already has
  /// a card, the source's card is simply dropped rather than merging SRS
  /// stats (out of scope for a base-form typo fix).
  Future<void> _repointSrsCard(
      {required int fromWordId, required int toWordId}) async {
    final targetHasCard = await (_db.select(_db.srsCards)
          ..where((c) =>
              c.itemType.equalsValue(SrsItemType.word) &
              c.itemId.equals(toWordId)))
        .getSingleOrNull();
    if (targetHasCard != null) {
      await (_db.delete(_db.srsCards)
            ..where((c) =>
                c.itemType.equalsValue(SrsItemType.word) &
                c.itemId.equals(fromWordId)))
          .go();
    } else {
      await (_db.update(_db.srsCards)
            ..where((c) =>
                c.itemType.equalsValue(SrsItemType.word) &
                c.itemId.equals(fromWordId)))
          .write(SrsCardsCompanion(itemId: Value(toWordId)));
    }
  }

  @override
  Future<void> dismissBaseFormSuspicion(int id) async {
    final word = await (_db.select(_db.words)..where((w) => w.id.equals(id)))
        .getSingleOrNull();
    if (word == null) return;
    if (word.notes?.contains(baseFormCheckedMarker) == true) return;
    final notes = word.notes?.isNotEmpty == true
        ? '${word.notes} $baseFormCheckedMarker'
        : baseFormCheckedMarker;
    await (_db.update(_db.words)..where((w) => w.id.equals(id))).write(
          WordsCompanion(notes: Value(notes), updatedAt: Value(DateTime.now())),
        );
  }
}

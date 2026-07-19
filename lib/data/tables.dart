/// Relational schema for mainichi (spec §0). drift / SQLite.
///
/// Shape mirrors the engine in §2: a [Words] store + a [Structures] library of
/// templates with typed [Slots], composed by the generator into cached
/// [GeneratedConversations]. [Imports] records provenance from the capture step
/// (§3); [SrsCards] holds spaced-repetition state (§6).
///
/// Conventions:
/// - `kanji` is non-null and defaults to '' (empty = "no kanji shown / not yet
///   taught"), so the `(kana, kanji, role)` dedup index works — SQLite treats
///   NULLs as distinct, which would defeat dedup of kana-only words.
/// - Enum columns are stored as `.name` (textEnum) for stability across reorder.
library;

import 'package:drift/drift.dart';

import 'enums.dart';

/// One vocabulary item, stored in dictionary (base) form. The three content
/// layers from §2 are [kana] / [kanji] / [meaning]; [kanaOnly] is the flag.
class Words extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Reading in hiragana/katakana, base form. Always present; feeds furigana
  /// and TTS (§4).
  TextColumn get kana => text()();

  /// Kanji form, only if the worksheet printed it; '' otherwise (§3).
  TextColumn get kanji => text().withDefault(const Constant(''))();

  /// English meaning; null when genuinely undeterminable at import.
  TextColumn get meaning => text().nullable()();

  TextColumn get role => textEnum<WordRole>()();

  /// True for words with no kanji form (やる, ある, particles).
  BoolColumn get kanaOnly => boolean().withDefault(const Constant(false))();

  TextColumn get meaningSource =>
      textEnum<MeaningSource>().clientDefault(() => MeaningSource.inferred.name)();

  TextColumn get status =>
      textEnum<ItemStatus>().clientDefault(() => ItemStatus.draft.name)();

  /// Free-text extraction notes (e.g. "negative stem おもしろく also printed").
  TextColumn get notes => text().nullable()();

  IntColumn get importId =>
      integer().nullable().references(Imports, #id, onDelete: KeyAction.setNull)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Dedup key (§3): a re-import of the same word attaches a new example rather
  /// than duplicating the entry.
  @override
  List<Set<Column>> get uniqueKeys => [
        {kana, kanji, role},
      ];
}

/// A sentence template with typed slots, e.g. `これは {noun_1} です` (§2).
class Structures extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Template text with `{slot_name}` placeholders. Unique — a re-import of the
  /// same pattern is deduped.
  TextColumn get template => text().unique()();

  TextColumn get notes => text().nullable()();

  TextColumn get status =>
      textEnum<ItemStatus>().clientDefault(() => ItemStatus.draft.name)();

  IntColumn get importId =>
      integer().nullable().references(Imports, #id, onDelete: KeyAction.setNull)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// A typed slot inside a [Structures] template. Role constrains which words can
/// fill it; [form] is the conjugation the slot expects (§2). Slot names are
/// unique within a template.
class Slots extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get structureId =>
      integer().references(Structures, #id, onDelete: KeyAction.cascade)();

  /// Placeholder name without braces, e.g. `noun_1`. Matches the template text.
  TextColumn get name => text()();

  TextColumn get role => textEnum<WordRole>()();

  TextColumn get form =>
      textEnum<SlotForm>().clientDefault(() => SlotForm.dictionary.name)();

  /// Left-to-right order of the slot in the template.
  IntColumn get ordinal => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {structureId, name},
      ];
}

/// A concrete example sentence as seen on a worksheet, filed under the headword
/// it illustrates (§3 dedup: examples per word grow over time). Optionally
/// linked to the structure it instantiates.
class ExampleSentences extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The sentence as printed. (Named `sentence`, not `text`, because `text` is
  /// drift's column-builder method on [Table].)
  TextColumn get sentence => text()();

  IntColumn get wordId =>
      integer().nullable().references(Words, #id, onDelete: KeyAction.cascade)();

  IntColumn get structureId => integer()
      .nullable()
      .references(Structures, #id, onDelete: KeyAction.setNull)();

  IntColumn get importId =>
      integer().nullable().references(Imports, #id, onDelete: KeyAction.setNull)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Grammatical "glue" the learner is assumed to know — the allowlist scope
/// validation trusts for vocab-id-0 tokens (see `validateScope`). Promoted
/// from the hardcoded `seedGrammarGlue` constant (decision D56) so new
/// particles can be added through review instead of a code edit.
///
/// Presence in the table means approved — a row only gets here via the
/// initial seed or the reading screen's backfill review sheet, so there is no
/// separate status column. `importId == null` marks a seed-origin row;
/// backfilled rows link to the Imports row that recorded their provenance.
class GrammarGlue extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The glue text exactly as it appears in generated lines (は, です, ...).
  TextColumn get surface => text().unique()();

  TextColumn get kind => textEnum<GlueKind>()();

  IntColumn get importId =>
      integer().nullable().references(Imports, #id, onDelete: KeyAction.setNull)();

  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

/// One worksheet-photo extraction run (§3). Keeps provenance for the review
/// flow and stores the raw draft JSON so an import can be re-reviewed or
/// debugged without re-calling the API.
class Imports extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Path or content-hash of the source photo.
  TextColumn get sourceImage => text().nullable()();

  /// Model id that produced the draft (e.g. `claude-opus-4-8`).
  TextColumn get model => text().nullable()();

  /// The extractor's structured-output draft, verbatim.
  TextColumn get rawDraftJson => text().nullable()();

  DateTimeColumn get importedAt => dateTime().withDefault(currentDateAndTime)();
}

/// A generated practice conversation, persisted as a first-class cached object
/// so SRS has stable items and practice is instant/offline (§10.3).
///
/// [payloadJson] holds the full conversation: ordered lines, each with speaker,
/// kanji text, and the per-token vocab-entry mapping that drives furigana (§4).
/// Kept as JSON rather than normalised into rows — it's a render cache, read
/// whole and never queried by inner field.
class GeneratedConversations extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get payloadJson => text()();

  IntColumn get lineCount => integer()();

  /// Cached TTS audio for the listening exercise; null until synthesised.
  TextColumn get audioPath => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastPracticedAt => dateTime().nullable()();
}

/// Which vocabulary a cached conversation exercises — lets the scheduler pick a
/// conversation that covers due words, and find conversations by word (§10.3).
class ConversationWords extends Table {
  IntColumn get conversationId => integer()
      .references(GeneratedConversations, #id, onDelete: KeyAction.cascade)();
  IntColumn get wordId =>
      integer().references(Words, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {conversationId, wordId};
}

/// Which structures a cached conversation exercises (mirror of
/// [ConversationWords] for templates).
class ConversationStructures extends Table {
  IntColumn get conversationId => integer()
      .references(GeneratedConversations, #id, onDelete: KeyAction.cascade)();
  IntColumn get structureId =>
      integer().references(Structures, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {conversationId, structureId};
}

/// Spaced-repetition state, one row per reviewable item (§6).
///
/// Decision to confirm: §6 frames SRS as scheduling vocabulary and structures,
/// while §10.3 says SRS "schedules the cached objects". Reconciled here as —
/// **knowledge strength and due dates live per word/structure** (so growth and
/// solid-vs-shaky stats are per item), and cached conversations are the
/// delivery vehicle chosen to cover whichever items are due. ([itemType],
/// [itemId]) is a polymorphic reference, so it is not a DB-level foreign key;
/// integrity is enforced in app code.
class SrsCards extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get itemType => textEnum<SrsItemType>()();
  IntColumn get itemId => integer()();

  /// SM-2-style ease factor.
  RealColumn get ease => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();

  DateTimeColumn get dueAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {itemType, itemId},
      ];
}

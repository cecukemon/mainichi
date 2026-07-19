/// Closed value sets shared by the data model (spec §0 / §2).
///
/// These are stored in the DB by `.name` (drift `textEnum`), so the **names are
/// load-bearing** — rename a value only with a migration. The extractor emits
/// snake_case strings (`i_adjective`, `printed_gloss`); the import boundary maps
/// those to these enums via the `from*` helpers below, so the wire format and
/// the storage format can evolve independently.
library;

/// Grammatical role of a vocabulary item or template slot. The same set types
/// both, which is what lets a slot only accept matching vocabulary (spec §2).
enum WordRole {
  noun,
  verb,
  iAdjective,
  naAdjective,
  pronoun,
  demonstrative,
  particle,
  questionWord,
  suffix,
  number,
  name,
  other;

  /// Maps the extractor's snake_case role string to a [WordRole].
  static WordRole fromExtraction(String s) => switch (s) {
        'noun' => WordRole.noun,
        'verb' => WordRole.verb,
        'i_adjective' => WordRole.iAdjective,
        'na_adjective' => WordRole.naAdjective,
        'pronoun' => WordRole.pronoun,
        'demonstrative' => WordRole.demonstrative,
        'particle' => WordRole.particle,
        'question_word' => WordRole.questionWord,
        'suffix' => WordRole.suffix,
        'number' => WordRole.number,
        'name' => WordRole.name,
        _ => WordRole.other,
      };

  /// The snake_case wire string, inverse of [fromExtraction]. The generation
  /// engine (`SeedWord.role`) and the segmenter speak this format.
  String get wire => switch (this) {
        WordRole.iAdjective => 'i_adjective',
        WordRole.naAdjective => 'na_adjective',
        // `this.` because WordRole.name (the enum value) shadows Enum.name.
        WordRole.questionWord => 'question_word',
        _ => this.name,
      };
}

/// Conjugation a slot expects. The vocabulary entry is always stored in
/// dictionary form; the slot's form tells the renderer/generator how to inflect
/// it (e.g. the i-adjective negative `おもしろい → おもしろく`). Extend as the
/// course introduces more conjugations.
enum SlotForm {
  dictionary,
  negative,
  polite,
  politeNegative,
  past,
  te;

  static SlotForm fromExtraction(String? s) => switch (s) {
        'negative' => SlotForm.negative,
        'polite' => SlotForm.polite,
        'polite_negative' => SlotForm.politeNegative,
        'past' => SlotForm.past,
        'te' => SlotForm.te,
        _ => SlotForm.dictionary,
      };

  /// The snake_case wire string, inverse of [fromExtraction].
  String get wire => switch (this) {
        SlotForm.politeNegative => 'polite_negative',
        _ => name,
      };
}

/// Where a vocabulary item's meaning came from — drives confidence tiering in
/// review (spec §3). `printedGloss` is a translation printed on the sheet;
/// `picture` is inferred from a drawing (ambiguous, low confidence); `manual`
/// is something you typed/corrected yourself.
enum MeaningSource {
  printedGloss,
  picture,
  inferred,
  manual,
  none;

  static MeaningSource fromExtraction(String s) => switch (s) {
        'printed_gloss' => MeaningSource.printedGloss,
        'picture' => MeaningSource.picture,
        'inferred' => MeaningSource.inferred,
        'manual' => MeaningSource.manual,
        _ => MeaningSource.none,
      };
}

/// Category of a grammar-glue entry (particles, copula forms, ... — the
/// closed set scope validation trusts as taught grammar; see the GrammarGlue
/// table). Categorization only — it does not affect validation, which treats
/// all glue alike; it exists so the review sheet and future audits can tell a
/// particle from a copula form.
enum GlueKind { particle, copula, interjection, adnominal, other }

/// Lifecycle of an imported word or structure. Extraction writes `draft`;
/// passing review flips it to `approved`. Generation only ever draws from
/// `approved` items, so an un-reviewed draft can never leak into practice.
enum ItemStatus { draft, approved }

/// What an SRS card tracks knowledge strength for (spec §6). Scheduling and
/// "what to review" live at the item level; generated conversations (spec §10.3)
/// are the stable delivery vehicle chosen to exercise due items.
enum SrsItemType { word, structure }

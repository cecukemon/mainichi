# Feature: Grammar from the textbook

**Status: proposed design (2026-11-07), revised after review (PR #16) and again after the open questions were answered with sample photos, not started.** No D-numbers assigned yet. Each "Key decision" below becomes a decision-log entry (next free: D75) when the phase that contains it is implemented.

The class has moved from handouts to a textbook. It comes in two volumes:

- **The main textbook** (Japanese only): lesson texts and the 練習A / 練習B exercises.
- **The German companion** (Übersetzung & grammatikalische Erklärungen): per-lesson vocabulary lists (I. Vokabular), grammar explanations (IV. Grammatik), and an appendix verb table (V. Flexion der Verben).

Vocabulary capture keeps working as today (photograph the vocab lists), with two small changes for the new layout (see §5). Grammar capture changes source: the books offer three kinds of page, each a better input than a worksheet:

1. **The verb table**: every verb of the course, with its conjugated forms printed per column and the lesson that introduces it.
2. **Grammar exercises**: substitution tables (練習A) and cue → answer drills (練習B).
3. **Grammar explanations**: a boxed pattern per grammar point, German prose, and numbered example sentences with German translations.

The motivating problem is user-reported: **generated conversations feel repetitive, as if not all allowed forms are being used.** The code confirms the cause (see §1). This design fixes it in four steps (A1, A2, B, C), ordered by how directly each attacks that problem.

---

## 0. What the pages look like

Read from sample photos (verb table pp. 170–171, vocab list L2 p. 16, grammar L5 pp. 38–39, 練習A/B L5). These details drive the extraction designs below.

**Verb table** (companion appendix, sorted by kana within a group):

- Grouped under printed section headings: "Gruppe I" (godan), presumably II (ichidan) and III (irregular: する, 来る, noun + します).
- **One row spans a two-page spread.** Left page: the entry (ます form, with kanji where the book uses them, sometimes a context bracket like 会います[ともだちに～] or a reading in parentheses like 書きます(かきます)), the ます-Form (kana, `stem ¦ ます`), the て-Form, the Wörterbuchform. Right page: the ない-Form (kana, `stem ¦ ない`), the た-Form, Bedeutung (German), Lektion.
- **Only the entry column has kanji.** Every form column is kana.
- **The Lektion column is the lesson that introduces the verb.** The table covers the whole course, so most rows are ahead of the class.
- The same verb can appear several times with different meanings and lessons (あります: L9 haben, L10 da sein, L21 stattfinden). The forms are identical.
- Irregular cells: ある's ない-Form is printed `— ¦ ない`.
- There's no たい column. Not every printed column has been taught yet (confirmed).

**Vocab list** (companion, I. Vokabular): kana | kanji (only when the book teaches one) | German meaning. The lesson number is on the side tab. Verbs are listed in their ます form, as usual for this course.

**Grammar explanation** (companion, IV. Grammatik): numbered points, each headed by a boxed pattern in the book's notation (`N(Ort)へ 行きます／来ます／帰ります`, `N(Person/Tier)と V`, `～よ`, `そうですね`), then German prose, then numbered examples (①, ②, …) with German translations and cross-references like "(s. L. 6)". A lesson's grammar fits on one spread, photographed as one image. Early lessons mostly introduce particles and set phrases, not conjugations.

**Exercises** (main textbook, Japanese with furigana, no answer key (confirmed)):

- **練習A** is a substitution table: `わたしは [スーパー / かいしゃ / とうきょう] へ 行きます。` plus a question row `あなたは [どこ] ……か。`. Optional particles are bracketed (`にちようび[に]`).
- **練習B** is a list of exercises, each with a worked 例 and numbered items. Two item shapes appear on one page:
  - **Cue → answer**: `例1: 京都(3月3日) → いつ 京都へ 行きますか。……3月3日に 行きます。`, items `1) さくら大学 (9月14日) →`. The answer is a Q/A pair, and the examples show variants (来週 takes no に).
  - **Question → answer from a picture**: `1) だれと 日本へ 来ましたか。 →`, answered from an illustration (a travel map, a week calendar).

---

## 1. Diagnosis: why generation is repetitive

D71 already removed the byte-identical-request and "Q&A only" causes. What remains is structural:

- **The prompt forbids every other form.** `generationInstructions` says, word for word: "Do NOT use the te-form, plain (dictionary-form) negative, plain past, or any other conjugation not in this list" (`lib/generation/conversation_generator.dart:338`), and line 337 hardcodes `"negative"` as the only i-adjective rule. The model isn't trying 食べて and getting filtered out: it's told not to try. This is the most direct cause, and the cheapest lever.
- **Forms are hardcoded and narrow.** `factorLine` only accepts conjugations produced by `_conjugatedForms`, whose `_verbSuffixes` table knows the ます family only. `taughtForms` is `alwaysTaughtVerbForms` plus whatever slot forms extracted Structures declare. `SlotForm` already has `te` (`lib/data/enums.dart:64`) but no suffix mapping for it, because of irregulars (D38), and has no `tai` at all.
- **Filtering reinforces it.** A conversation that does use 食べて or 行きたい fails `validateScope`. It isn't silently dropped: the screen goes to an error state with backfill chips, and the violations are logged under `reading.scope` (`lib/reading/reading_providers.dart:197-219`, D47/D52). But only ます-only output is ever shown, so even a prompt fix alone would just trade repetition for rejections.
- **Verb class is guessed.** Without a stored godan/ichidan, `_conjugatedForms` tries both connectors. That's harmless for ます (over-permissive: たべります passes), but it's unworkable for て/た/ない, where the two classes diverge completely.

So the fix has to change the prompt and the validator together, from the same data. Step A1 does that with a rule-based conjugator. A2 makes the data book-sourced. B and C add the *encouragement* side: patterns and grammar points that actively steer generation toward the new forms.

**Measuring the fix.** The problem is subjective, so before A1 lands, add a cheap dev log: the form distribution over accepted conversations (`detectTaughtForm` per verb token) and the `reading.scope` rejection rate. Compare before and after each step.

---

## 2. Phase A: verb forms as data

### Idea

Conjugations become **data**: generated by a rule-based conjugator from a stored verb group (A1), then checked against and overridden by surfaces from the book's verb table (A2). The book is the authority on surfaces (closing the irregulars problem, 行く→行って, 来る→来て). A per-form switch decides which forms are taught, because the table prints columns the class hasn't reached.

Phase A is split so the high-value change ships first:

- **A1: forms switch, conjugator, data-driven prompt.** `verbGroup`, the rule-based conjugator (te/ta/nai/tai, with 行く/ある/する/来る special-cased), the i-adjective inflection table, the Bunko Forms tab, and the prompt's form rule generated from `taughtForms`. Groups are inferred where the dictionary form makes it certain (any ending other than る is godan; する/くる and noun + する are irregular) and set by hand for the ambiguous る-verbs (帰る vs 食べる) until A2 fills them. This gets most of the variety win.
- **A2: verb-table import.** A reference table of every verb in the course: fills in groups, supplies the ます → dictionary mapping for vocab capture, and stores the book's surfaces.

### One form vocabulary: extend `SlotForm`

No second enum. `SlotForm` gains `nai`, `ta` and `tai` (later: potential, volitional, … as the book reaches them). Its wire values stay stable (drift stores `.name`), so stored slots don't need migrating. `taughtForms`, `detectTaughtForm`, `form_label.dart` and the extraction schema's `slotForms` list (`lib/extraction/worksheet_extractor.dart:~42`) keep speaking one vocabulary.

- The existing `negative` stays the **i-adjective く stem** (おもしろく + ありません glue). The verb plain negative is the new `nai`. `form_label.dart` labels them distinctly.
- The book's column headers are fixed (ます-Form, て-Form, Wörterbuchform, ない-Form, た-Form), so the verb-table extractor has a constant header → `SlotForm` map. `dictionary` already exists and is already always taught.

### What is stored and what is derived

| Form | Source |
|---|---|
| `dictionary` | the word itself |
| `polite` (ます) | stored (table); derived ます family: ません/ました/ませんでした |
| `te` | stored (table) |
| `nai` | stored (table); derived なかった, なくて (i-adjective inflection) |
| `ta` | **derived from て**: final て→た, で→だ, with no exceptions. The printed た column is only a check. |
| `tai` | **derived from the ます stem** (食べ + たい), regular for every verb; derived たくない, たかった, たくなかった |

**The i-adjective inflection table is new work.** Today the only i-adjective handling is the single `negative` → く stem rule (`lib/japanese/segmenter.dart:130-136`). A1 adds a small table (くない, かった, くなかった, くて) used for real i-adjectives, ない and たい alike.

### Kanji of conjugated forms

Every form column in the table is kana, and the Bunko word's own kanji stays the only authority on whether a word is written in kanji (spec §3). A form's kanji surface is built from the word's kanji and the form's kana by okurigana prefix substitution, the same matching `okurigana.dart` already does: 会う/あう splits into 会↔あ, so あって → 会って. 思い出す/おもいだす gives 思い出↔おもいだ, so おもいだして → 思い出して. A form whose kana doesn't start with the word's kanji reading (来る: く vs きて) comes from the conjugator's special case, or else it stays kana-only and is flagged in the log.

So a kana-only word never gets kanji forms, and **the table's kanji are never written to `Words`**. That removes the need for a "kanji in this table are taught" toggle, which an earlier draft of this design had.

### Data model

Schema plan, one migration per step:

- **v4 (A1)**
  - **`Words.verbGroup`**: nullable textEnum `VerbGroup { godan, ichidan, irregular }`. Null for non-verbs and for verbs whose group isn't known.
  - **`FormSettings`**: one row per `SlotForm` with `enabled` (bool). Storage for the Forms-tab switch. A missing row means the default (see Scope rule).
  - **`GrammarGlue.after`**: nullable `SlotForm`. Bound glue, see below.
  - **`Imports.kind`** (`worksheet | vocabList | verbTable | exercise | explanation`, existing rows backfilled as `worksheet`) and **`Imports.lesson`** (nullable int), so `rawDraftJson` (`lib/data/tables.dart:166`) can be re-reviewed by the right drafter and later steps don't need these columns.
  - **`MeaningSource.translatedGloss`**: a new enum value (text enum, no migration), see §5.
- **v5 (A2)**
  - **`VerbTableEntries`**: reference data, one row per distinct ます form. `masuKana` (unique), `dictKana`, `teKana`, `naiKana` (`''` for ある's `— ¦ ない`, meaning the form is just ない), `group`, `entryKanji` (the printed entry, for display and matching only), `sensesJson` (list of `{meaningEn, meaningDe, lesson}`, one per printed row of that verb), `importId`. Rows of one verb collapse into one entry, since their forms are identical.
  - **`Words.verbEntryId`**: nullable FK → `VerbTableEntries` (set null on delete). The link that gives a word its group and book surfaces.
- **v6 (B)**: `Drills`, `DrillItems`.
- **v7 (C)**: `GrammarPoints` + link table to Structures. `ImportPages` for multi-photo imports, if it turns out to be needed (see §4).

A table entry on its own **never puts anything in scope**. Only Bunko words are in the lexicon. A linked word's group comes from its entry (overriding `Words.verbGroup`) and its `te`/`nai` surfaces from the entry, falling back to the conjugator.

### Scope rule

The Forms switch is the **final gate**:

`taughtForms` = (`alwaysTaughtVerbForms` ∪ slot forms of approved Structures ∪ forms of approved grammar points) ∩ forms enabled in `FormSettings`.

- **New forms default to off** until switched on in the Forms tab, or by approving a Phase C grammar point that introduces them. A scope leak is worse than a missing form, by the app's own priorities (D20/D42). It also covers an old worksheet structure with a `te` slot, which would otherwise enable the te-form for every verb with a known group. Approving a Structure whose slot needs a disabled form asks whether to switch it on.
- The ます family and `dictionary` (`alwaysTaughtVerbForms`) default to on.
- `_conjugatedForms` yields the entry's surfaces first, then derived ones, then group-based conjugator output, **all filtered by `taughtForms`**. `detectTaughtForm` applies the same filter.
- For a verb with **unknown group and no linked entry**, only the ます family is accepted, as today. New forms never leak through a guess.

### Bound glue for auxiliaries

Auxiliaries (ください, います/いません/いました for ～ています, もいいですか) are glue, not conjugation forms. But `factorLine` matches glue anywhere in a line (`segmenter.dart:191-193`), so plain `います` glue would let せんせいがいます pass with いる untaught, and free-standing ください would follow any noun.

So glue gains an optional `after: SlotForm`. Bound glue only matches **directly after a word segment in that form**: `ください (after: te)`, `います (after: te)`. Unbound glue behaves as today. The segmenter tracks the form of the previous word segment, which `_conjugatedForms` already yields.

### Segmenter and rendering

- `LexiconEntry` gains `group` and `forms: Map<SlotForm, ({String kana, String kanji})>`. `_conjugatedForms` yields `(form, surface, kana, kanji)` so every surface carries its reading pair.
- **The conjugator returns reading-aware pairs too.** 来る → 来て/きて, する → して. That fixes the `okurigana.dart:18-21` limitation for every verb with a known group, not only those the table covered.
- **Furigana and TTS**: `displayTokens` (`lib/reading/line_display.dart:55-61`) currently calls `matchSurface` with the base pair. It switches to the pair attached to the matched surface, which the segmenter already knows (no separate `detectTaughtForm` pass, no trying each stored pair).
- `detectTaughtForm` returns the new form keys, and the word lookup sheet labels them ("て-form of 食べる").

### Generation (A1)

- **The form rule becomes data.** Lines 337-338 of `generationInstructions` are generated from `taughtForms`: one line listing the allowed conjugations, plus "Do NOT use any conjugation not in this list." The output must be deterministic (fixed form order, not set iteration order) so the cached prefix stays stable (D7).
- A **`TAUGHT FORMS`** section lists each taught form with a one-line description and a usage hint (て-form: requests with ください, sequences; たい: wants).
- **Per-verb forms only where needed.** A `"forms"` entry is emitted only for verbs whose surfaces aren't predictable from TAUGHT FORMS plus the group rule: irregulars and verbs whose table surfaces differ from the conjugator. Rough estimate: emitting all forms for 100 verbs × 5 forms × ~12 tokens is ~6k tokens per request, and caching only helps within the TTL, which spread-out one-tap reading sessions often miss. Irregular-only emission keeps it to a few hundred.
- **Form focus is its own clause.** D71's `varietyFocus` is wrapped as "Favor vocabulary and patterns about: $focus." (`conversation_generator.dart:436`), which doesn't fit a directive. A separate clause in the user message (same D71 placement) picks one taught non-ます form at random: "Use at least one たい-form." The extra random pick changes RNG consumption order, so the seeded-determinism tests in `conversation_generator_test.dart` need updating.
- **Free conversation is affected too.** `conversation_turn.dart` sends `constraintContext(seed)` byte-for-byte (`:14`, `:254`) and validates with `validateScope`. Its `conversationInstructions` needs the same data-driven form rule, and its token cost changes with TAUGHT FORMS.

### Capture: the verb-table import (A2)

A new extraction mode on the photo import screen: **"Verb table"**. It gets its own schema and prompt, not an extension of `extractionSchema`. A dense table is a different task from a worksheet, and a separate schema keeps both prompts sharp.

- **One photo per spread.** A row's columns are split across the left and right pages, so both pages go in one image (as in the sample). Rows are joined by order, not by vertical position: the right page has multi-line meanings that shift its rows down relative to the left. The guide on the prep screen says so.
- **Schema**: `group_heading` (the "Gruppe …" heading if one is visible on the spread, else null) and `rows`: `entry` (verbatim, including any bracket), `masu`, `te`, `dict`, `nai`, `ta` (kana, without the `¦` separators; `nai` as printed with `—` kept), `meaning_de`, `meaning_en` (translated, see §5), `lesson`, and `confidence`. No regions and no notes, to keep output small; the same `max_tokens` discipline as D54 (a spread is ~30 rows × ~8 short fields).
- **The group comes from both the heading and the forms.** It's derived from the ます and dictionary forms: dictionary ending in する or being くる → irregular; ichidan if the ます stem equals the dictionary form minus る; otherwise godan (かえります vs かえる → godan; います vs いる → ichidan; いります vs いる → godan). The heading only shows on a group's first page, so it's a cross-check, not the source. On the review screen, a disagreement flags the row.
- **Consistency check as an OCR and alignment guard.** With the group known, the conjugator computes て, ない and た and compares them with the printed ones. The printed た must also equal た derived from the printed て, which is a cheap check that the left and right halves of the row were joined correctly. A match means high confidence. A mismatch flags the row, and the card shows printed vs. computed. That catches OCR misreads (small っ read as つ, missing dakuten) and off-by-one joins. The book still wins when the user confirms.
- **Review is per flagged row.** Clean rows commit as a batch, because committing a table row changes no word, it only adds reference data. (An earlier draft merged table rows into words and needed a bulk-confirm exception to capture-loop §3. Reference rows don't.)
- **Linking to words.** On commit, and whenever a verb is later committed through vocab capture:
  - A word links to the entry whose `dictKana` matches its kana. If several entries share a dictionary kana (いる: 居る ichidan vs 要る godan; きる: 着る vs 切る), the word's kanji decides (compared with the entry's kanji stem). A remaining tie is never resolved automatically: it shows up on the word's lookup sheet as "Which verb is this?" with the candidates' meanings.
  - **Polite-form captures resolve exactly.** The vocab lists print verbs in ます form, so captured verbs often arrive as たべます (the `politeFormSuspicion` / fix-up path, `lib/data/bunko_store.dart:97`). The fix-up sheet looks the ます kana up in `VerbTableEntries.masuKana` (unique, no ambiguity) and proposes the table's dictionary form instead of guessing. The user still confirms, as today.
- **Lessons gate new words.** Rows whose verb isn't in the Bunko are only offered as new words if a sense's lesson is at or below the current lesson (the highest `Imports.lesson` so far, editable on the prep screen). They go through the normal vocab review card, with the English meaning and the German one shown beside it. Later rows wait in the reference table and link automatically when that lesson's vocab list is captured. **So the whole appendix can be photographed once**, up front.
- **Context brackets** (`[ともだちに～]`, `[ビザが～]`) stay in `entry` for display. Turning them into valency hints for generation is out of scope.

### Tests

- Prompt: the form rule and TAUGHT FORMS are derived from `taughtForms`, and the text is identical under reordering of the input set (cache stability).
- Conjugator vs. a fixture of known verbs per group, including 行く/ある/する/来る with reading-aware pairs. た from て for the full fixture. Group derivation from (ます, dictionary) including いります/いる vs います/いる and べんきょうします.
- i-adjective table: おもしろくない, 食べたくない, 食べなかった.
- Kanji by prefix substitution: 会って, 思い出して; a kana-only word gets no kanji form.
- Segmenter: entry surfaces accepted (行って, 来て with き reading, して); a group-unknown verb's て-form rejected.
- Forms switch off ⇒ an entry surface is rejected by `factorLine` **and** by `detectTaughtForm`, even with a matching `te` slot on an approved Structure.
- Bound glue: 食べてください passes; せんせいください fails; `います (after: te)` doesn't admit a bare いる sentence when いる is untaught.
- `validateScope`: a 食べてください line passes once ください is bound glue; fails before. The same for free conversation.
- Verb-table extraction, using the pp. 170–171 photo as the fixture: rows joined across the spread, あります's three senses collapse into one entry, `— ¦ ない` parses, a deliberately shifted right-page row fails the た-from-て check, a corrupted っ is flagged.
- Linking: dictionary-kana match; いる tie resolved by kanji, or left unlinked; たべます resolved via `masuKana`; a row with a lesson above the current one isn't offered as a new word.
- Migration v3→v4 on a populated DB: existing words untouched, `verbGroup` null, `Imports.kind` backfilled to `worksheet`, `lesson` null, glue unbound. v4→v5 adds an empty `VerbTableEntries` and a null `verbEntryId`.
- Determinism tests in `conversation_generator_test.dart` updated for the form-focus pick.

---

## 3. Phase B: exercises → structures + a sentence-building drill

A third import mode, **"Exercises"**, for 練習A and 練習B pages from the main textbook. The text is Japanese with furigana, which the extractor already reads into kanji + kana pairs. The lesson comes from the side tab and pre-fills the prep screen.

### 練習A: substitution tables → Structures

A substitution table already is a Structure: the fixed text is the template, the shaded column is the slot, and its entries are the fillers. This is better grounded than on worksheets, where the slot generalization is always marked low confidence, because the book shows exactly what varies.

- Each table becomes one Structure, with its fillers kept as examples. The question row (`あなたは [どこ] ……か。`) becomes a second, question variant of the same Structure.
- Bracketed optional particles (`にちようび[に]`) are both accepted: the filler is stored without the bracket, and the bracketed glue is optional in the template.
- Fillers go through normal vocab dedup and review by their dictionary form.

### 練習B: drills

Each exercise becomes a **drill**: its 例 (one or two worked examples) plus items. An item is one of two kinds:

- **Cue item**: cue words in parentheses (`さくら大学 (9月14日)`). The model builds the answer from the 例 and the cues.
- **Picture item**: a question whose answer comes from an illustration. The extractor stores the illustration's region (the existing `region` crop) and proposes an answer from the picture, at low confidence.

There's **no answer key**, so every answer is model-generated and confirmed on the review card. To keep that review cheap:

- Each answer runs through `factorLine` at import. One that doesn't factor exposes a gap (a missing form or glue) at capture time instead of practice time, and is flagged.
- Picture items always show the crop next to the proposed answer.
- An answer can have several lines (the Q/A pair in 例1), and the 例's own variants (来週 without に) are kept as accepted alternatives where they apply.

### Data model

- **`Drills`** (`structureId`, `exampleJson` (the 例 lines as printed), `lesson`, `importId`) and **`DrillItems`** (`drillId`, `kind` = cue | picture, `cuesJson`, `question` (picture items), `region`, `answerLines`, `answerSource` = generated | picture | manual, `ordinal`).
- `cuesJson` stores each cue **as printed** (for display) **plus the resolved dictionary-form word id** (for dedup and SRS). A cue that doesn't resolve to a word keeps the item out of practice until it's reviewed. Dates and numbers (9月14日) resolve as glue/number tokens, not words.

### Practice

A new **"Build the sentence"** exercise on the home screen:

1. Show the 例 (furigana, tap-to-lookup as usual) and one item: its cues, or its question plus the picture crop.
2. The learner answers by typing (Japanese keyboard) or speaking (the existing STT path from "Check me", D73).
3. Grading, two paths:
   - **Spoken**: `read_aloud_grader.dart` as is. It treats any kanji as an opaque match for aligned kana (D68, `:9-26`), which is right for STT.
   - **Typed**: that leniency is wrong for IME input (a wrong kanji would pass). Typed answers are reduced to readings through `factorLine` against the lexicon, then compared as kana. A typed answer that doesn't factor is a mismatch.
   - Match / close / mismatch use the existing thresholds. "Close" and "mismatch" escalate to a single Claude check ("is this a correct alternative?"), because word order and particle choice allow legitimate variants, and because the stored answer is itself only model-generated. The check must require the cue words and the target structure, not just grammatical Japanese. An "I was right" override stays available, and using it on a confirmed answer offers to add the learner's version as an alternative.
   - **Escalation cost**: with the 0.95/0.7 thresholds, a single particle error in a short sentence lands in "close", so expect most wrong answers to escalate. Estimate the per-session cost before shipping, and consider a cheaper model for the check.

Each item is graded against one structure, which is also the clean **per-structure SRS signal** that the open phase-5 SRS grading question asks for (`project-status.md:17`, D40). `SrsItemType` is already `{word, structure}` (`enums.dart:119`), so no new type is needed.

---

## 4. Phase C: grammar explanations → grammar points

### Data model

**`GrammarPoints`**: `lesson`, `ordinal` (the printed point number), `pattern` (the boxed header, verbatim: `N(Ort)へ 行きます／来ます／帰ります`), `summary` (short, English, translated from the German prose), `forms` (list of `SlotForm` keys it introduces), `glue` (surfaces it introduces, with their `after` binding, e.g. ください after te), `status`, `importId`; plus a link table to the Structures that exemplify it.

### Capture

- **One photo per spread.** A lesson's grammar fits on one spread in the sample, so a single image usually covers it. Multi-photo import (`ImportPages`, "add another page") is only built if a later lesson's grammar runs past one spread.
- **The boxed pattern is a template.** The book's notation maps onto slot syntax: `N(Ort)` is a noun slot (place), `N(Person/Tier)` a noun slot (person or animal), `V` a verb slot, `～` the attachment point. The extractor proposes a Structure from it, and the numbered examples become that Structure's examples (their German translations, translated to English, become the meanings).
- **Most early points introduce glue, not forms**: へ, で, と, よ, the set phrase そうですね. Those go into `GrammarGlue` on approval. Forms arrive later in the course (て-form, ない-form), and they're what the Forms switch is waiting for.
- Cross-references ("s. L. 6") are kept in the summary as text, not linked.
- **The review card** shows the pattern, the summary (with the German prose collapsed beneath it), the forms and glue it introduces (each with an example conjugation from the Bunko), and the examples, so the extracted *rule* can be checked against concrete output rather than taken on trust.

### Effects of approving a grammar point

- Its glue surfaces go into `GrammarGlue`, bound as extracted (with its `importId`, same as D56 backfill).
- Its forms are switched on in `FormSettings`.
- The generator gets a **`RECENT GRAMMAR`** section: the last N lessons' points, with patterns and summaries. The form-focus clause favors their forms.
- The word lookup sheet links a conjugated token to the point that introduced its form ("て-form, Lesson 14").

---

## 5. Cross-cutting

- **Meanings are stored in English** (decided). The companion prints German, so every extraction prompt that reads a gloss (vocab list, verb table, grammar examples and prose) translates it to English. The meaning is stored as `meaning_source: translated_gloss`, which ranks with `printedGloss` for confidence tiering, and the German original stays in `Imports.rawDraftJson` and is shown beside the English on the review card. `Words.meaning` stays "English meaning" (`tables.dart:31`), so no column changes.
- **Vocab lists from the companion.** The worksheet prompt assumes worksheets (pictures, handwriting). The companion's lists are a clean three-column layout, so the vocab import gets a `vocabList` mode: the same schema, a prompt section for the layout (kanji column taken only where printed, German gloss translated, lesson read from the side tab, the `*` and `～` marks kept verbatim). This is small and independent, and can ship before A1.
- **Lessons.** `Imports.lesson` (nullable int, added in v4) is pre-filled from the page's side tab where one is visible, editable on the prep screen, and sticky to the last value used. Words, structures, drills and grammar points inherit it via their import. The current lesson (the highest one imported) gates new words from the verb table. That's enough for "practice Lesson 14" and "recent grammar" later, without a `Lessons` table until titles are needed.
- **Old worksheet data.** Untouched. Existing Structures stay valid. Existing verbs get a group by inference (A1) and a link to a table entry when the table is imported (A2).
- **Model choice.** Table, exercise and explanation extraction use `ModelConfig.extraction` like worksheets. No new model id.

---

## 6. Key decisions (to log as D75+ when implemented)

1. The prompt's form rule and the validator's `taughtForms` come from the same data; no hardcoded list of forbidden conjugations.
2. One form vocabulary: `SlotForm` is extended rather than adding a parallel enum.
3. A per-form switch is the final gate on taught forms, over all sources. New forms default to off, because the book prints forms ahead of the lessons that teach them.
4. Conjugated surfaces are data: a rule-based conjugator from a verb group, with the book's surfaces taking precedence. Only ます, て and ない are taken from the book; た is derived from て, たい from the ます stem, and the rest by regular inflection.
5. Auxiliaries (ください, います, …) are glue, not conjugation forms, and can be bound to follow a given form.
6. The verb group is derived from the printed ます and dictionary forms; the printed Gruppe heading only cross-checks it.
7. The verb table is reference data, not a word source: entries never enter scope on their own, words link to them, and only rows at or below the current lesson are offered as new words.
8. The Bunko word's kanji is the only authority on kanji; form kanji are built by okurigana prefix substitution, and the table's kanji are never written to `Words`.
9. Meanings are stored in English. German glosses are translated at import (`translatedGloss`), with the original kept in the raw draft.
10. The vocab list, verb table, exercises and grammar explanations each get their own extraction mode and prompt rather than widening the worksheet schema.
11. Exercise answers are model-generated (no answer key), verified by `factorLine` at import and confirmed on review; grading escalates to a Claude check for alternatives.
12. Step order is A1 → A2 → B → C, by how directly each fixes the repetition problem.

---

## 7. Open questions (for the user)

Answered on 2026-11-07: meanings are stored in English; the table prints forms the class hasn't been taught yet; there's no answer key; the verb table has no adjectives (so i-adjective forms come from the inflection table only, and nothing imports adjectives from it).

Still open:

1. **Picture items in 練習B**: include them (practice shows the illustration crop, answers proposed at low confidence and confirmed by you), or skip them and import cue items only? The design assumes include.
2. **Gruppe II and III pages**: the design assumes they share the Gruppe I layout. One photo of a Gruppe III page (with する/来る and the noun + します verbs) before A2 would confirm it, and would be the irregulars fixture.

---

## 8. Rough sizing

- **Vocab-list mode** (§5): one prompt section, `translatedGloss`, lesson pre-fill. Small; can go first.
- **A1**: v4 migration, conjugator + i-adjective table, bound glue in the segmenter, reading-aware pairs in rendering, Forms tab, data-driven prompt rule + TAUGHT FORMS + form focus (generation and free conversation), the measurement log. Medium, and the step that should visibly change generation variety.
- **A2**: v5 migration, verb-table extraction mode, consistency checks, linking (including the fix-up sheet lookup and the lookup-sheet tie picker), lesson gating. Medium.
- **B**: v6 migration, one extraction mode with two exercise shapes, one new practice screen reusing STT, a typed-answer grader.
- **C**: v7 migration, one extraction mode, pattern → Structure mapping, prompt section, lookup link. Multi-photo only if needed.

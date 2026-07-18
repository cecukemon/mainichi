# Feature: Reading Exercise

Closes the reading exercise described in spec §5, exercising the generation engine (§2, §10.3) with no audio — the cheapest test of whether the engine produces good, grammatical Japanese, and the first of the three exercise types to be built (§8, phase 2). Furigana rendering (§4) is already de-risked via a rendering spike (`lib/reading/`, `lib/japanese/okurigana.dart`); this feature is the actual exercise screen that spike was built to unblock.

**Visual design:** mocked up in Claude Design ("Reading Exercise Mockups", one direction — "Reader"). Screens saved standalone in this folder: `reading-home-entry.html`, `reading-loading.html`, `reading-error.html`, `reading-screen.html` (furigana on), `reading-screen-furigana-off.html`, `reading-word-lookup.html`.

---

## 1. Purpose

Reading is the simplest exercise: render a generated conversation, let the learner read it with furigana support, and get out of the way. There's no scoring, no check step — the value is in reading comprehension itself, and in surfacing generation-quality problems early (spec §8: "if slot typing is too loose, reading reveals it immediately").

---

## 2. Flow

**Step 1 — Entry.** A "Reading practice" action on the home screen. Replaces the temporary "Furigana preview (spike)" button (`FuriganaPreviewScreen`), which exists only to prove the rendering layout works.

**Step 2 — Generate.** Tapping in immediately requests a new conversation, constrained to known vocabulary and structures (spec §2/§10.3) — no topic picker, no setup step. A loading state covers the wait. On refusal or a scope-validation failure, show a plain error state ("couldn't generate that one") with **Try again** and **Exit** — never silently retry forever. A scope failure additionally surfaces its word-shaped unmatched surfaces as backfill chips (§5); a cached earlier conversation is offered as a reread fallback when one exists (`features/generated-cache.md`).

**Step 3 — Read.** The conversation renders script-style: each line's speaker name sits in a fixed left margin column, kanji with furigana to its right (toggle available, default on per §4, in the header). A vocab-linked token is underlined to show it's tappable; grammatical glue (は, です, か, particles) and punctuation are plain — there's nothing to define. Tapping an underlined word opens a bottom sheet with its reading (kana), a role chip (e.g. "verb"), and a meaning line that also carries its grammatical form when relevant ("to eat · negative, polite"); if the surface is a conjugated form (食べません), a separate "dictionary form" card shows the base form it conjugates from (食べる) with its own reading.

**Step 3, footer.** Below the conversation, a one-line hint reflects the furigana state ("Tap any word to look it up" / "Furigana hidden — tap a word if it hasn't stuck") above the **Next** button.

**Step 4 — Next / Exit.** **Next** immediately generates and loads another conversation (back to Step 2) — a continuous feed, not a fixed-length session. **Exit** returns home at any point. There is no completion state, rating step, or session counter; the learner reads as much or as little as they want in one sitting.

---

## 3. Key decisions

- **Continuous feed, not a fixed batch.** How many conversations make "a session" isn't a decision backed by any pedagogy yet, so the screen doesn't invent one — read one, tap Next for another, exit whenever. Simpler to build and doesn't pre-empt a number that would just be a guess.
- **No self-rating captured.** Reading stays a pure comprehension exercise (spec §5) — unlike speaking, there's no built-in check. Per-line or per-word self-grading is a real candidate for feeding SRS later, but that's an open, unresolved question in `project-status.md` ("SRS grading signal") that shapes its own UI; this screen deliberately doesn't guess at it now and add a rating step that would need to be redesigned anyway.
- **Script layout, not chat bubbles.** This is a reading passage on a page (spec §5's own wording), not a messaging thread — a name label per line keeps the visual metaphor "text you read," matching how the CLI renderer (`renderConversation`) already lays it out. Claude Design's mockup places the name in a fixed left margin column rather than an inline "Name: line" prefix — a book-marginalia feel rather than a transcript feel, still fundamentally script-style.
- **Word tap → a bottom sheet is the exercise's only real interactivity**, not an inline tooltip near the tapped word. Combined with the furigana toggle (hide it, tap anything you don't recognize), this is the screen's implicit self-test loop even without a scored check step. Sheet content always comes from the vocab store, never the model (spec §10.3) — same authority rule the renderer already follows. The mockup also folds the slot **form** into the meaning line (e.g. "to eat · negative, polite") rather than as a separate field — a refinement over the original plan, and one worth carrying into the data layer (the form info has to come from somewhere at render time, likely the slot the line's structure instantiated).
- **Punctuation is rendered from the line's `text`, not solely reconstructed from `tokens`.** Live testing found the model sometimes omits 、 from `tokens` while `text` has it (`project-status.md`, "Model tokenization variance on punctuation") — resolved here by always taking punctuation from `text` so a line can't silently lose a comma the model forgot to tokenize.
- **Hands-off generation in this pass.** The generator already supports an optional topic `focus`, but exposing a topic picker is a separate UI decision this feature doesn't take on — v1 is one tap, whatever the engine reaches for.
- **Errors surface, they don't retry silently.** Consistent with the capture loop's confidence-tiered review — never quietly succeed or fail; a refused or scope-invalid generation is shown as a real state with an explicit retry, not hidden behind an infinite loop.

---

## 4. Open questions

- **Generate-ahead vs. wait-and-spin.** Continuous feed means every **Next** pays live generation latency (prompt caching per §10.3 only discounts the stable vocab/structure prefix, not the per-call completion). Worth revisiting once this is exercised against the real API — pre-fetching the next conversation while the learner is still reading the current one could remove the wait entirely, but that's premature to design against unmeasured latency.
- **Where the `GenerationSeed` comes from.** The generator currently takes vocab/structures from a hand-built seed (CLI tool) or fixture — the real repository/query layer over the drift store is still `[planned]` (`project-status.md` §0). This screen needs it as a live dependency, not just a fixture, before it can run against a real Bunko.
- ~~Popover placement against the furigana band~~ — **resolved by the mockup:** the lookup is a full-width bottom sheet sliding up over the whole screen (dimmed scrim behind it), not an inline popover anchored to the tapped word, so it never has to fit next to a ruby band or collide with a neighboring line.
- ~~Where does the per-token grammatical form (e.g. "negative, polite" on 食べません) come from at render time?~~ — **resolved (D44): derived at render time from the store, never model-reported.** `detectTaughtForm` (`lib/japanese/segmenter.dart`) matches the tapped surface against the factoring segmenter's own taught-conjugation inventory and returns the slot-form wire value; `formAnnotation` (`lib/reading/form_label.dart`) maps it to the sheet's wording ("negative, polite"). Null (base form, untaught ending) means no form line — graceful, never wrong. `GenLine` and the generation schema are untouched, consistent with §10.3's store-authority rule.
- **Reading correctness is still store-only.** Reading-changing irregulars (来る) and the deferred contextual reading validation (spec §9) are open per `project-status.md` — the popover's reading field inherits whatever the store says, right or wrong, until that check exists.
- **Does Exit need confirmation mid-conversation?** Currently assumed no (continuous feed implies no "in-progress" state worth protecting), but may matter once practice streaks/stats (spec §6, not yet built) start caring whether a session was actually completed.

---

## 5. Scope-failure backfill (added 2026-07-18, D52/D53)

Live failures kept naming words the class *did* teach but no worksheet ever captured (その, while この was allowlisted). Rather than hand-editing constants, the error state turns those failures into a capture surface — the direction the grammar-glue open question in `project-status.md` predicted ("folding allowlist maintenance into the capture flow is the natural fix").

**Flow:** a scope failure lists its word-shaped unmatched surfaces as chips under "Missing from your Bunko?" (`ScopeReport.candidates`). Tapping one opens the capture flow's own `VocabReviewCard` in a bottom sheet, reframed: "Did your class teach this?", worksheet-comparison box hidden, Approve disabled until a meaning is entered. Approve commits through the normal capture commit (`ScopeBackfillService`, `lib/reading/scope_backfill.dart`) with reading-backfill provenance (null photo, generation model, `{"source": "reading-backfill"}` marker in `rawDraftJson` — no schema change, D52), then **re-validates the same rejected conversation against the fresh seed — if the added word was the only problem, it renders immediately** (the self-healing loop). Skip closes the sheet (chip stays); Discard removes the chip — the correct answer whenever the class didn't teach the word.

**Key decisions:**
- **Human confirmation is the Bunko's integrity rule, not worksheets per se.** The model nominates, the learner confirms — same contract as capture review. Guardrails against convenience bias (every approval makes an error disappear): one candidate at a time, no bulk approve, discard-friendly framing.
- **Glue relaxation, kana-only (D53):** a glue-tagged token matching a taught word's kana passes validation (a mislabel, not a leak — factoring still verifies every character); required, or the backfilled word could never rescue the conversation that flagged it. Kanji surfaces stay violations (they'd render without furigana). Acceptances are logged under `reading.scope`.

**Deferred:** single-character candidates (particles — wait for the glue-table promotion; they're silently filtered from chips today), kanji-bearing candidates (unknown reading; the card's kana entry is free-text rōmaji), and a merge UI for the role-variant near-duplicate case (same kana committed under a different role inserts a second row).

---

## 6. Status

`[in progress]` — implemented (D47), pending the live end-to-end simulator run. Already in place and directly reusable: the generation call and scope validation (`lib/generation/conversation_generator.dart`), and the furigana rendering widgets (`lib/reading/furigana_text.dart`, `lib/japanese/okurigana.dart`) proven via the temporary `FuriganaPreviewScreen` spike (`lib/reading/screens/furigana_preview_screen.dart`), which this feature replaces outright once built. Claude Design has delivered pixel-level mockups for every state (home entry, loading, error, read screen furigana on/off, word-lookup sheet — saved alongside this doc) that match every decision in §3 and additionally settle the two former open questions about popover placement (it's a bottom sheet, not an inline popover) and visual detail (margin-column speaker names, role chip, form annotation on the meaning line).

All parts are now built (D44–D47): the live `GenerationSeed` query (`SeedSource`/`DriftSeedSource`), the in-app generation transport (`GenerationService`/`LiveGenerationService`), the screen with all states (`lib/reading/screens/reading_exercise_screen.dart`), the word-tap lookup sheet with the derived form annotation, the D42 punctuation-from-`text` rendering (`lib/reading/line_display.dart`), and the home-screen entry replacing the spike button (spike screen deleted). Widget-tested against fakes end to end; the D24 reconstruction check was made punctuation-insensitive alongside (safe now that rendering doesn't depend on token punctuation). Remaining: the live end-to-end run on the simulator — first in-app generation call, the pending furigana visual check, and the latency measurement the generate-ahead question (§4) is waiting on.

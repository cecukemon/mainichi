# Feature: Reading Exercise

Closes the reading exercise described in spec §5, exercising the generation engine (§2, §10.3) with no audio — the cheapest test of whether the engine produces good, grammatical Japanese, and the first of the three exercise types to be built (§8, phase 2). Furigana rendering (§4) is already de-risked via a rendering spike (`lib/reading/`, `lib/japanese/okurigana.dart`); this feature is the actual exercise screen that spike was built to unblock.

---

## 1. Purpose

Reading is the simplest exercise: render a generated conversation, let the learner read it with furigana support, and get out of the way. There's no scoring, no check step — the value is in reading comprehension itself, and in surfacing generation-quality problems early (spec §8: "if slot typing is too loose, reading reveals it immediately").

---

## 2. Flow

**Step 1 — Entry.** A "Reading practice" action on the home screen. Replaces the temporary "Furigana preview (spike)" button (`FuriganaPreviewScreen`), which exists only to prove the rendering layout works.

**Step 2 — Generate.** Tapping in immediately requests a new conversation, constrained to known vocabulary and structures (spec §2/§10.3) — no topic picker, no setup step. A loading state covers the wait. On refusal or a scope-validation failure, show a plain error state ("couldn't generate that one") with **Try again** and **Exit** — never silently retry forever.

**Step 3 — Read.** The conversation renders script-style: each line prefixed by its speaker's name, kanji with furigana above (toggle available, default on per §4). Tapping a word that maps to a vocab entry opens a small popover with its reading, meaning, and role; if the surface is a conjugated form (食べます), the popover also shows the dictionary base form (食べる) it conjugates from. Grammatical glue (は, です, か, particles) and punctuation aren't tappable — there's nothing to define.

**Step 4 — Next / Exit.** **Next** immediately generates and loads another conversation (back to Step 2) — a continuous feed, not a fixed-length session. **Exit** returns home at any point. There is no completion state, rating step, or session counter; the learner reads as much or as little as they want in one sitting.

---

## 3. Key decisions

- **Continuous feed, not a fixed batch.** How many conversations make "a session" isn't a decision backed by any pedagogy yet, so the screen doesn't invent one — read one, tap Next for another, exit whenever. Simpler to build and doesn't pre-empt a number that would just be a guess.
- **No self-rating captured.** Reading stays a pure comprehension exercise (spec §5) — unlike speaking, there's no built-in check. Per-line or per-word self-grading is a real candidate for feeding SRS later, but that's an open, unresolved question in `project-status.md` ("SRS grading signal") that shapes its own UI; this screen deliberately doesn't guess at it now and add a rating step that would need to be redesigned anyway.
- **Script layout, not chat bubbles.** This is a reading passage on a page (spec §5's own wording), not a messaging thread — a name label per line keeps the visual metaphor "text you read," matching how the CLI renderer (`renderConversation`) already lays it out.
- **Word tap → full popover is the exercise's only real interactivity.** Combined with the furigana toggle (hide it, tap anything you don't recognize), this is the screen's implicit self-test loop even without a scored check step. Popover reading always comes from the vocab store, never the model (spec §10.3) — same authority rule the renderer already follows.
- **Punctuation is rendered from the line's `text`, not solely reconstructed from `tokens`.** Live testing found the model sometimes omits 、 from `tokens` while `text` has it (`project-status.md`, "Model tokenization variance on punctuation") — resolved here by always taking punctuation from `text` so a line can't silently lose a comma the model forgot to tokenize.
- **Hands-off generation in this pass.** The generator already supports an optional topic `focus`, but exposing a topic picker is a separate UI decision this feature doesn't take on — v1 is one tap, whatever the engine reaches for.
- **Errors surface, they don't retry silently.** Consistent with the capture loop's confidence-tiered review — never quietly succeed or fail; a refused or scope-invalid generation is shown as a real state with an explicit retry, not hidden behind an infinite loop.

---

## 4. Open questions

- **Generate-ahead vs. wait-and-spin.** Continuous feed means every **Next** pays live generation latency (prompt caching per §10.3 only discounts the stable vocab/structure prefix, not the per-call completion). Worth revisiting once this is exercised against the real API — pre-fetching the next conversation while the learner is still reading the current one could remove the wait entirely, but that's premature to design against unmeasured latency.
- **Where the `GenerationSeed` comes from.** The generator currently takes vocab/structures from a hand-built seed (CLI tool) or fixture — the real repository/query layer over the drift store is still `[planned]` (`project-status.md` §0). This screen needs it as a live dependency, not just a fixture, before it can run against a real Bunko.
- **Popover placement against the furigana band.** The ruby band already sits tight above each token (`FuriganaText`); a tap-popover needs room to render without covering neighboring lines, especially for a word near the top of the visible area. Visual layout call — flagged for Claude Design's pass rather than decided here.
- **Reading correctness is still store-only.** Reading-changing irregulars (来る) and the deferred contextual reading validation (spec §9) are open per `project-status.md` — the popover's reading field inherits whatever the store says, right or wrong, until that check exists.
- **Does Exit need confirmation mid-conversation?** Currently assumed no (continuous feed implies no "in-progress" state worth protecting), but may matter once practice streaks/stats (spec §6, not yet built) start caring whether a session was actually completed.

---

## 5. Status

`[planned]` — no screen built yet. Already in place and directly reusable: the generation call and scope validation (`lib/generation/conversation_generator.dart`), and the furigana rendering widgets (`lib/reading/furigana_text.dart`, `lib/japanese/okurigana.dart`) proven via the temporary `FuriganaPreviewScreen` spike (`lib/reading/screens/furigana_preview_screen.dart`), which this feature replaces outright once built.

Not yet built: the live `GenerationSeed` wiring (blocked on the repository/query layer, §4 above), the word-tap popover, the continuous-feed navigation shell (Next/Exit, loading and error states around a live generation call), and the home-screen entry point.

# Project Status

**Where we're at:** Both riskiest assumptions — worksheet extraction and constrained conversation generation — are prototyped and validated live, including a verb-conjugation stress test that surfaced and fixed two real scope-leak bugs. The §0 data model is drafted, tested, and connected on-device. The capture loop's review/commit UX is implemented end-to-end (all 5 screens, dedup, import-commit into the real schema — see `features/capture-loop.md`). A 2026-07-06 code-vs-spec review closed three gaps (text↔tokens validation, slot-form extraction, kanji-upgrade on merge — decision log D24–D26) and logged the rest under **Bugs** below. A same-day design handoff ("Capture Loop - Revised Cards") was then implemented: picture-derived words now have their own review card, a discard action, undoable bulk-approve, kana candidate-chips, and a dedup field-by-field match summary (decision log D27–D31). Session 5 closed iOS API key delivery (Settings screen + Keychain, confirmed live on the simulator, D32); session 6 wired a live `dio`-based extraction call with a minimal photo-picker entry point, so the capture loop can now run against a real photo instead of only the fixture draft (D33) — though not yet exercised against the real API or a real device camera. Session 8 completed the furigana rendering spike (D35–D37): okurigana solved *without* the expected data-model change (stem split derived from the existing kana/kanji pair, `lib/japanese/okurigana.dart`), a custom dependency-free `FuriganaText` widget with the toggle, the CLI renderer's base-form bug fixed, and the surface↔entry laundering gap closed in `validateScope` — visual simulator check still pending. Session 9 built the closed-vocabulary factoring segmenter and wired it into `validateScope` (D38): scope validation is no longer solely dependent on the model's self-report, validated live with zero false positives and a real catch (その) — the "word segmentation strategy" fork is resolved with no MeCab and no backend. Session 10 designed the reading exercise screen (no code): continuous feed of generated conversations, hands-off on topic, no self-rating step, script-style layout with a word-tap popover as the only interactivity, punctuation rendered from `text` (decision log D39–D42) — written up in `features/reading-exercise.md`, ready for Claude Design. Next: handing that off to Design and implementing the screen, in-app resize/auto-orient/crop, and the repository/query layer (also a blocker for the reading screen, which needs a live `GenerationSeed` from the real store).

This document is the re-orientation map for new sessions. It's organized around the spec's build order (§8): each numbered section is a build phase, broken into steps granular enough to tell at a glance whether they're done. Cross-cutting concerns that don't belong to one phase are at the bottom.

**Legend:** `[done]` · `[in progress]` · `[planned]` · `[deferred]` (intentionally postponed, not blocked)

---

## Open questions / unresolved forks
Decisions not yet made, surfaced here so they're visible on re-orientation. Resolved ones move to `decision-log.md`.

- **Scope validation independence** — *(the "word segmentation strategy" fork is resolved: the closed-vocabulary factoring segmenter is built and validated live — `lib/japanese/segmenter.dart`, D38 — no MeCab, no backend; the most likely backend trigger is dead.)* What remains interim: furigana/rendering still uses the model's per-token vocab-id attribution (which factoring does not independently verify — it proves every character is taught material, not that each token's *id* is the right entry). The planned contextual reading validation (spec §9) is the remaining check on that. Taught-endings map (`_verbSuffixes`) is curated like `knownGrammarGlue`: te-form and plain negative deliberately unmapped until taught — they flag loudly on first contact.
- **Model tokenization variance on punctuation** *(observed live, session 9)* — the model sometimes omits 、 from `tokens` while `text` has it, tripping the D24 reconstruction check. A rendering-fidelity discrepancy (renderer builds from tokens → learner would see the line without its commas), not a scope leak. **Resolved (session 10, D42):** the reading screen renders punctuation from `text`, not reconstructed from `tokens` — decided, not yet implemented (screen doesn't exist yet).
- **Grammar-glue allowlist scope** — the glue-token trust gap (さん slipping through as unverified "glue") is now closed via a curated, hand-maintained allowlist (`knownGrammarGlue`), validated live against all 4 structure families. Not yet promoted to a reviewable DB table alongside Words/Structures — currently a code constant, extended by hand as new grammar is introduced. One known residual gap: a vocab word fused directly into a glue token (not yet observed) would still false-positive; not pre-emptively widened. **Review 2026-07-06 upgraded the priority:** every new grammar point the class introduces (の, と, past tense, ます as taught material …) needs a hand edit or generation starts false-flagging valid output — grammar arrives on worksheets just like vocabulary, so folding allowlist maintenance into the capture flow is the natural fix.
- **SRS grading signal (phase 5, decide before building)** — SM-2 needs a per-item quality rating per review, but reading/listening a whole conversation gives at best a fuzzy self-assessed signal spread over a dozen items. How does one 6-line dialogue update the ease of each word it contains — self-grade buttons? per-line? Is SM-2 even the right scheduler vs something binary (Leitner)? Shapes the exercise UI, so resolve before phase 5 code exists. *(Session 10: the reading exercise's v1 design deliberately ships without any self-rating step rather than guess at this — `features/reading-exercise.md` §3/D40 — so this question is still fully open.)*

---

## Bugs
Known defects, from the 2026-07-06 code-vs-spec review. Real problems in code that exists today — distinct from open questions (decisions not yet made) and planned work. Remove entries as they're fixed.

- **"Not a match" can be silently overridden** — if the user rejects a dedup match but the item is an exact `(kana, kanji, role)` duplicate, the same-batch check in `runCommit` merges it anyway and reports it as merged, contradicting the explicit decision. (The capture-loop.md §4 open question, currently resolved implicitly against the user.) Should at least surface.
- **Model ids are stale** — `claude-sonnet-4-6` predates Sonnet 5 (`claude-sonnet-5`). The spec's "verify before shipping" trigger has arrived; re-run the Opus-ceiling/Sonnet-holds comparison on current ids when convenient.
- **Worksheet photo/crop boxes are always empty** — `WorksheetCropPlaceholder` (`lib/capture/widgets/worksheet_crop_placeholder.dart`) is a purely decorative labeled gray box; it was never wired to accept real image bytes. Triage's "worksheet photo" and the vocab/picture-word review cards' crop boxes render this placeholder for every import, demo or live — a live import now has a real photo (`draft.sourceImage`, the picked bytes) sitting right there unused. Noticed after wiring the live extractor call (session 6/7); not fixed yet.

## Foundations  [in progress]
- [done] Feature spec — `japanese-companion-app-spec.md` (living document)
- [done] Decision log — `decision-log.md`
- [done] Project status — this file
- [done] API key setup — `~/.config/anthropic/key`, read inline (never committed)
- [done] iOS API key delivery — Settings screen + Keychain storage behind an `ApiKeyStore` interface (`lib/settings/`, decision log D32), confirmed live on the iOS simulator; now wired into §1's live extraction call

## 0. Data model + structure library  [in progress]
- [done] drift schema — words, structures, slots (+ conjugation `form`), example sentences, imports, generated conversations (+ link tables), SRS cards (`lib/data/`)
- [done] codegen + invariant tests (dedup, slot form, cascades, SRS uniqueness)
- [done] enum ↔ extractor mapping helpers (`fromExtraction`)
- [done] on-device DB connection — `path_provider` + background-isolate `NativeDatabase`, wired into `main.dart` (`lib/data/connection.dart`)
- [planned] repository/query layer behind interfaces (per §10.1) — deferred to §1, built against the import-commit layer's real calls rather than speculatively (decision log D22)

## 1. Capture flow  [in progress]
Feature doc: `features/capture-loop.md` (flow, key decisions, mockups).
- [done] worksheet extraction call — vision + structured output, validated live (`lib/extraction/`, `tool/extract_worksheet.dart`)
- [done] extraction emits per-slot conjugation `form` — the D12 gap closed (schema + prompt, 2026-07-06); *not yet re-validated against a real worksheet with conjugated patterns*
- [done] import-commit layer — draft → DB rows, atomic `db.transaction` per photo, writing real provenance (source image, model, verbatim raw draft) to the Imports row (`lib/capture/commit_service.dart`, decision log D34)
- [done] dedup on import — kana-match proposal + confirm-in-review, merge attaches example (`lib/capture/dedup.dart`)
- [done] kanji/meaning upgrade on merge — a confirmed merge fills an empty kanji (clearing `kanaOnly`) or missing meaning on the existing entry, never overwriting taught values (D26, 2026-07-06); the kana-first-kanji-later class sequence no longer strands entries kana-only or forks duplicates
- [done] confidence-tiered review UI — all 5 screens (triage → queue → commit → done), Riverpod-driven, widget-tested (`lib/capture/screens/`)
- [done] handwritten-gloss surfacing — gloss offered as a tap-to-accept meaning chip on the review card
- [done] "Capture Loop - Revised Cards" design handoff implemented (2026-07-06, decision log D27–D31): picture-derived word split into its own `PictureWordReviewCard`/`QueueItemType.pictureWord`; "Discard extraction" added as a stronger, non-revisitable alternative to skip; bulk-approve is now staged/undoable on the triage screen; kana is candidate-chip-picked (mirrors the existing kanji pattern); dedup card shows a field-by-field (reading/meaning/role) match summary and all existing example sentences; template card shows the original printed sentence and hides the Form dropdown for non-conjugating slots; triage shows the worksheet photo/title/topic
- [done] live extractor call from the app — `dio`-based `LiveExtractionService` behind the offline-capable `ExtractionService` interface (D9), a minimal "New import from photo" camera/gallery entry point, and a pure extractor-JSON→`CaptureDraft` mapper (`lib/extraction/`, `lib/capture/draft_from_extraction.dart`, decision log D33); not yet exercised against the real Anthropic API or a real device camera (tested against fakes only)
- [planned] in-app image resize/auto-orient/crop before send — the live import today sends the picked photo as-is (aside from `image_picker`'s own `maxWidth` downscale); no custom orientation-correction or worksheet-crop UI yet
- [planned] extractor kanji candidates + image crop regions (capture-loop.md §4 — review card currently degrades to confirm-or-no-kanji)
- [planned] explicit close button on the photo/crop zoom dialog (`WorksheetCropPlaceholder._showZoom`, `lib/capture/widgets/worksheet_crop_placeholder.dart`) — today it only dismisses via tap-outside (`showDialog`'s default barrier), on both triage and the review cards
- [done] word segmentation for scope validation — closed-vocabulary factoring segmenter, no MeCab/backend needed (`lib/japanese/segmenter.dart`, D38; see §2)

## 2. Reading exercise  [in progress]
Feature doc: `features/reading-exercise.md` (flow, key decisions; visual mockups not yet done).
- [done] generation call — constrained, structured output, validated live (`lib/generation/`, `tool/generate_conversation.dart`)
- [done] scope-leakage validation of generated output (vocab-scope; interim, pending real segmentation)
- [done] verb-conjugation stress test — masu-form across 3 verb classes; found + fixed a kanji-leak bug and a glue-token honorific leak (see decision log D20)
- [done] glue-token trust gap closed — curated grammar-glue allowlist with factoring match (tolerates the model's variable tokenization granularity); confirmed live, no false positives across repeat runs (decision log D21)
- [done] text↔tokens reconstruction check — token surfaces must spell the line's `text` (whitespace-insensitive), closing the hole where a word in `text` but omitted from `tokens` was invisible to every per-token check and to the renderer (D24, 2026-07-06)
- [done] surface↔entry consistency check — a non-glue token's surface must be a recognizable form of its claimed entry (exact kana/kanji, or a stem-preserving conjugation for verb/adjective roles), closing the laundering gap where a hallucinated surface with a valid vocab id passed clean and would have rendered wrong furigana (D36, 2026-07-06)
- [done] closed-vocabulary factoring segmenter wired into `validateScope` — every character of each line's `text` must factor into taught vocabulary forms + taught conjugations (endings derived from the structure library's slot forms) + grammar glue + punctuation, fully independent of the model's token report (`lib/japanese/segmenter.dart`, D38). Validated live: 2 runs / 12 lines, zero false positives, and a genuine untaught-word catch (その) on the first run; a unit test pins the case only factoring can see (行きましょう — untaught ending on a taught stem)
- [in progress] generation coherence hardening — Q&A type-consistency + productive recombination (stance A)
- [done] furigana rendering spike — per-token kanji-over-kana layout via a custom dependency-free widget (`lib/reading/furigana_text.dart`: Wrap of unbreakable per-token reading-over-base stacks, ruby-band alignment, furigana toggle; `ruby_text` package evaluated and rejected as unmaintained — D37). **Okurigana solved without the expected data-model change:** the stem/okurigana split is derived at render time from the existing (kana, kanji) pair by longest-common-kana-suffix (`lib/japanese/okurigana.dart`, D35); the CLI renderer's base-form-substitution bug is fixed the same way. Known deferred limitation: reading-changing irregulars (来る), trigger = 来 taught in kanji. *Visual simulator check still pending* — home screen's "Furigana preview (spike)" button; the preview route is temporary until the real reading screen exists
- [planned] reading exercise screen — flow and key UX decided (`features/reading-exercise.md`, decision log D39–D42): continuous feed of generated conversations, hands-off on topic, no self-rating step, script-style layout with a word-tap popover (reading/meaning/role + dictionary form for conjugated surfaces) as the only interactivity, furigana toggle carried over from the spike. Not yet handed to Claude Design and not implemented; also blocked on a live `GenerationSeed` from the real store (repository/query layer, below)
- [planned] generated-content cache — persist conversations, link to vocab/structures

## 3. Listening exercise  [planned]
- [planned] Google Cloud Text-to-Speech integration
- [planned] audio cache (store synthesized audio on the conversation)
- [planned] listening exercise screen

## 4. Speaking exercise  [planned]
- [planned] mic capture (`record` package)
- [planned] Google Cloud Speech-to-Text
- [planned] answer grading — Claude semantic compare vs expected answer
- [planned] surface transcript + verdict together
- [planned] calibrate match strictness (expect iteration)

## 5. SRS + stats  [planned]
- [planned] SRS scheduler over per-item (word/structure) cards
- [planned] conversation selection to cover due items
- [planned] stats: growth, knowledge strength, consistency streak, speaking accuracy

## 6. Offline mode  [deferred]
- [planned] service-layer "unavailable offline" reporting (design as we go)
- [planned] offline toggle + cache fallback for reading/listening

## Cross-cutting / later
- [done] prompt caching for the constraint context (vocab + structure prefix) — confirmed live (cache_read hits across calls)
- [planned] contextual reading validation (independent reading check)
- [planned] dev-time generation quality gate (cross-check against Google Translate)
- [deferred] special paradigms (time / weekdays / numbers) — expected to fold into the word + structure model; revisit only if something doesn't slot-fill

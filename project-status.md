# Project Status

**Where we're at:** Both riskiest assumptions — worksheet extraction and constrained conversation generation — are prototyped and validated live, including a verb-conjugation stress test that surfaced and fixed two real scope-leak bugs. The §0 data model is drafted, tested, and connected on-device. The capture loop's review/commit UX is implemented end-to-end (all 5 screens, dedup, import-commit into the real schema — see `features/capture-loop.md`), currently driven by a fixture draft rather than a live photo → API call. A 2026-07-06 code-vs-spec review closed three gaps (text↔tokens validation, slot-form extraction, kanji-upgrade on merge — decision log D24–D26) and logged the rest under **Bugs** below. A same-day design handoff ("Capture Loop - Revised Cards") was then implemented: picture-derived words now have their own review card, a discard action, undoable bulk-approve, kana candidate-chips, and a dedup field-by-field match summary (decision log D27–D31). Next is wiring capture live (in-app photo + `dio` API client), the repository/query layer, and the furigana rendering spike.

This document is the re-orientation map for new sessions. It's organized around the spec's build order (§8): each numbered section is a build phase, broken into steps granular enough to tell at a glance whether they're done. Cross-cutting concerns that don't belong to one phase are at the bottom.

**Legend:** `[done]` · `[in progress]` · `[planned]` · `[deferred]` (intentionally postponed, not blocked)

---

## Open questions / unresolved forks
Decisions not yet made, surfaced here so they're visible on re-orientation. Resolved ones move to `decision-log.md`.

- **Furigana rendering approach** — existing ruby-text package vs custom `RichText`/`CustomPainter` per-token layout. Pending the rendering spike (phase 2). **New (review 2026-07-06): the spike must also solve okurigana.** D5's per-token "reading from the store" assumes a token's reading is the base-form kana — false for conjugated kanji words (in 行きます the kanji 行 reads い, not いく; the reading covers only the stem). The store has no stem/okurigana split, so expect the spike to force a data-model change, not just a widget. The prototype renderer already shows the failure: `renderConversation` replaces a conjugated surface with the base form when the entry has kanji (masked today only because demo verbs are kana-only).
- **Word segmentation strategy** — FFI-to-MeCab vs pure-Dart tokenizer vs backend, for scope validation once conjugation grows (§9). Deferred; the most likely trigger for ever adding a backend. **New option (review 2026-07-06): a closed-vocabulary factoring segmenter.** The vocabulary is small and *closed* — the premise of the app — so general morphological analysis may never be needed: greedy longest-match factoring of each line against known kanji/kana forms + conjugation stems + a closed set of taught endings + the glue allowlist (the same trick `_glueFactoring` already uses for glue) would be fully independent of the model's self-report and likely kills the backend argument entirely.
- **Interim scope validation** — before real segmentation exists, how far to trust the model's self-reported per-token vocab mapping. The verb round found and fixed a real leak (invented kanji on a conjugated content word); vocab-id attribution itself has been accurate every run. Still the model checking itself — keep watching. Two of the holes found in the 2026-07-06 review: the text↔tokens reconstruction gap is now closed (D24); the surface↔entry laundering gap (a hallucinated kana surface tagged with a *valid* in-scope vocab id passes clean, and would render the wrong furigana) is still open — cheap partial fix is exact surface==kana for non-conjugating roles plus a stem-prefix check for verbs/adjectives.
- **Grammar-glue allowlist scope** — the glue-token trust gap (さん slipping through as unverified "glue") is now closed via a curated, hand-maintained allowlist (`knownGrammarGlue`), validated live against all 4 structure families. Not yet promoted to a reviewable DB table alongside Words/Structures — currently a code constant, extended by hand as new grammar is introduced. One known residual gap: a vocab word fused directly into a glue token (not yet observed) would still false-positive; not pre-emptively widened. **Review 2026-07-06 upgraded the priority:** every new grammar point the class introduces (の, と, past tense, ます as taught material …) needs a hand edit or generation starts false-flagging valid output — grammar arrives on worksheets just like vocabulary, so folding allowlist maintenance into the capture flow is the natural fix.
- **SRS grading signal (phase 5, decide before building)** — SM-2 needs a per-item quality rating per review, but reading/listening a whole conversation gives at best a fuzzy self-assessed signal spread over a dozen items. How does one 6-line dialogue update the ease of each word it contains — self-grade buttons? per-line? Is SM-2 even the right scheduler vs something binary (Leitner)? Shapes the exercise UI, so resolve before phase 5 code exists.

---

## Bugs
Known defects, from the 2026-07-06 code-vs-spec review. Real problems in code that exists today — distinct from open questions (decisions not yet made) and planned work. Remove entries as they're fixed.

- **`runCommit` is not transactional** — capture-loop.md §3 promises "single commit transaction per photo", but `lib/capture/commit_service.dart` does ~2N sequential inserts with no `db.transaction(...)`. A crash mid-commit leaves a half-imported worksheet and a dangling Imports row.
- **The Imports row is written empty** — `runCommit` inserts `rawDraftJson: null` and no `sourceImage`/`model`, defeating the table's stated purpose (D13: re-review/debug an import without re-calling the API). Fixture-driven today; must be fixed when the live extractor call is wired up.
- **"Not a match" can be silently overridden** — if the user rejects a dedup match but the item is an exact `(kana, kanji, role)` duplicate, the same-batch check in `runCommit` merges it anyway and reports it as merged, contradicting the explicit decision. (The capture-loop.md §4 open question, currently resolved implicitly against the user.) Should at least surface.
- **iOS API key delivery is unaddressed** — the key lives at `~/.config/anthropic/key` for the CLI tools; that path doesn't exist on a phone. Live in-app extraction needs a story first (settings screen + Keychain via `flutter_secure_storage`, presumably).
- **Model ids are stale** — `claude-sonnet-4-6` predates Sonnet 5 (`claude-sonnet-5`). The spec's "verify before shipping" trigger has arrived; re-run the Opus-ceiling/Sonnet-holds comparison on current ids when convenient.

## Foundations  [in progress]
- [done] Feature spec — `japanese-companion-app-spec.md` (living document)
- [done] Decision log — `decision-log.md`
- [done] Project status — this file
- [done] API key setup — `~/.config/anthropic/key`, read inline (never committed)

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
- [done] import-commit layer — draft → DB rows, one commit per photo (`lib/capture/commit_service.dart`; see Bugs: not yet transactional, Imports row written empty)
- [done] dedup on import — kana-match proposal + confirm-in-review, merge attaches example (`lib/capture/dedup.dart`)
- [done] kanji/meaning upgrade on merge — a confirmed merge fills an empty kanji (clearing `kanaOnly`) or missing meaning on the existing entry, never overwriting taught values (D26, 2026-07-06); the kana-first-kanji-later class sequence no longer strands entries kana-only or forks duplicates
- [done] confidence-tiered review UI — all 5 screens (triage → queue → commit → done), Riverpod-driven, widget-tested (`lib/capture/screens/`)
- [done] handwritten-gloss surfacing — gloss offered as a tap-to-accept meaning chip on the review card
- [done] "Capture Loop - Revised Cards" design handoff implemented (2026-07-06, decision log D27–D31): picture-derived word split into its own `PictureWordReviewCard`/`QueueItemType.pictureWord`; "Discard extraction" added as a stronger, non-revisitable alternative to skip; bulk-approve is now staged/undoable on the triage screen; kana is candidate-chip-picked (mirrors the existing kanji pattern); dedup card shows a field-by-field (reading/meaning/role) match summary and all existing example sentences; template card shows the original printed sentence and hides the Form dropdown for non-conjugating slots; triage shows the worksheet photo/title/topic
- [planned] in-app image capture + resize/auto-orient before send (screens currently run on a fixture draft)
- [planned] live extractor call from the app — `dio`-based Anthropic client behind the offline-capable interface (D9)
- [planned] extractor kanji candidates + image crop regions (capture-loop.md §4 — review card currently degrades to confirm-or-no-kanji)
- [deferred] word segmentation / lemmatization for scope validation (see §9; not needed at beginner stage)

## 2. Reading exercise  [in progress]
- [done] generation call — constrained, structured output, validated live (`lib/generation/`, `tool/generate_conversation.dart`)
- [done] scope-leakage validation of generated output (vocab-scope; interim, pending real segmentation)
- [done] verb-conjugation stress test — masu-form across 3 verb classes; found + fixed a kanji-leak bug and a glue-token honorific leak (see decision log D20)
- [done] glue-token trust gap closed — curated grammar-glue allowlist with factoring match (tolerates the model's variable tokenization granularity); confirmed live, no false positives across repeat runs (decision log D21)
- [done] text↔tokens reconstruction check — token surfaces must spell the line's `text` (whitespace-insensitive), closing the hole where a word in `text` but omitted from `tokens` was invisible to every per-token check and to the renderer (D24, 2026-07-06)
- [planned] surface↔entry consistency check — a hallucinated kana surface tagged with a valid in-scope vocab id still passes and would render the wrong furigana (see open questions)
- [in progress] generation coherence hardening — Q&A type-consistency + productive recombination (stance A)
- [planned] furigana rendering spike — per-token kanji-over-kana layout (store round-trip proven in the generator; Flutter widget still to build). Must solve okurigana for conjugated kanji words — see open questions; expect a data-model change (stem/okurigana split)
- [planned] reading exercise screen (with furigana toggle)
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

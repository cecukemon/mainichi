# Decision Log

A running record of *why* key choices were made — design decisions, technical
decisions, anything the user weighed in on, and anything that seemed important
enough to remember later. Newest session at the bottom; within a session,
entries are roughly in the order they were decided.

Format per entry: **Title** — the decision. *Why:* the reasoning. *Notes:*
alternatives, who decided, or follow-ups where relevant.

---

## 2026-06-28 — Session 1 (spec review → extraction prototype → data model)

**D1. Mobile-only architecture, no backend.** The app talks directly to third-party APIs and stores everything locally.
*Why:* single user, single device. A backend adds hosting, a server DB, a deploy pipeline, and monitoring — real ops cost for benefits not needed yet (server-held keys, multi-device sync, batch jobs).
*Notes:* Decided with the user, who raised the complexity concern. Mitigation baked in: every external call and the validation/segmentation step sit behind an interface, so a thin serverless proxy can be introduced later without rearchitecting (spec §10.1).

**D2. REST via `dio`/`HttpClient`, not an SDK.** Call the Anthropic and Google APIs over plain REST.
*Why:* there is no official Anthropic Dart SDK (official SDKs exist only for Python, TS, Java, Go, Ruby, C#, PHP). The features needed — vision, structured outputs, prompt caching — are just JSON fields, so a typed SDK would add little. The user asked whether adding an SDK would help; it would not.

**D3. Model selection.** Extraction → `claude-opus-4-8` (accuracy matters, volume low). Generation & grading → `claude-sonnet-4-6` (frequent, latency-sensitive).
*Why:* match capability to the job; cost is irrelevant for one user.
*Notes:* Generation quality is the riskiest assumption (spec §8 step 2) — validate it on Opus first to set a quality ceiling, then confirm Sonnet holds. Model ids rotate; verify before shipping.

**D4. Structured outputs everywhere.** Extraction and generation use `output_config.format` (JSON schema) / strict tools, not prompt-only JSON.
*Why:* guarantees parseable, schema-conformant responses. Validated live in the extraction prototype.

**D5. Furigana from the authoritative store, rendered per token.** Readings come from the vocab store (reviewed at import), never from LLM-generated readings. Layout is per-token (reading-over-base), aligned to the vocab entry each word maps to.
*Why:* LLM readings can be wrong on ambiguous kanji; the store is the source of truth. Per-token keeps Flutter layout tractable (no built-in ruby-text widget).
*Notes:* Furigana matters a lot to the user for learning → treated as an early de-risking spike (spec §8 step 2). Paired with a **contextual reading validation** check (D6-adjacent) because the model's self-reported vocab mapping is not an independent verification.

**D6. Scope-leakage validation needs segmentation; deferred.** Generated output is segmented and each content word checked (by base form) against the known-vocab set.
*Why:* preserves the "only what I've learned" guarantee that a prompt constraint alone can't ensure. Japanese has no spaces and conjugates, so this needs morphological segmentation + lemmatization.
*Notes:* Not a problem at beginner stage (worksheets arrive pre-segmented, little conjugation). Solvable in Dart (FFI to MeCab, or a lighter tokenizer), but the mature analyzers are C/Java — **this is the single most likely reason a backend would ever be needed** (spec §9, §10.1).

**D7. Prompt caching for the constraint context.** The vocab + structure library injected into every generation call is cached (`cache_control`).
*Why:* it's a large stable prefix; caching cuts cost ~10× and reduces latency for the interactive exercises. The user asked to prioritise this. Distinct from the local generated-content cache.

**D8. Surface the raw STT transcript in the speaking exercise.** Show what the recognizer heard alongside the verdict.
*Why:* a wrong/empty result has two causes — mispronunciation or STT mishearing a correct utterance. Showing the transcript keeps an STT failure from reading as "you got it wrong." Decided with the user.

**D9. Offline mode is a later feature, but design for it now.** Every online call sits behind an interface that can report "unavailable offline"; the actual mode is built after the exercises exist.
*Why:* the user wants to use the app with limited connectivity. Cheap to design for early, expensive to retrofit. Falls back to the generated-content cache for reading/listening.

**D10. API key stored outside the repo.** Key lives at `~/.config/anthropic/key` (chmod 600), read inline at run time; never pasted into chat.
*Why:* can't be swept into a future `git add`; its value never lands in the transcript. Live extraction calls are real/billed.

**D11. Extraction prototype findings → encoded rules.** After validating extraction live on real worksheets:
- **Kanji captured only if printed** — the app never adds kanji you haven't been taught, even when the model knows it.
- **Printed vs handwritten non-Japanese text** are different: printed German glosses (textbook) are legitimate meanings; handwritten German (your notes) is separated out and recorded as skipped.
- **Unique slot names** within a template; a fixed word stays in template text, not a slot.
- **na-adjective kana** normalized to the bare reading (`きれい`, not `きれい(な)`).
*Why:* these are what the real worksheets actually look like (rotation, dense handwritten German, picture-only meanings, conjugation, suffix derivation). All confirmed working after prompt fixes.

**D12. Slots carry a conjugation `form`.** A template slot has a role *and* a form (dictionary / negative / polite / …).
*Why:* the prototype showed the model improvising `{i_adjective(-く)}` for negatives. Conjugation belongs in the slot schema, not baked into the placeholder string — so the vocab entry stays in base form while the slot demands the inflection.

**D13. Data model = drift/SQLite, with these choices.**
- **Dedup** vocab on `(kana, kanji, role)`; `kanji` defaults to `''` (not null) so kana-only words actually dedup. Same kana + different role is allowed (suffix じん vs a noun).
- **`draft` → `approved` status** on words and structures gates generation, so an un-reviewed extraction draft can never leak into practice.
- **`Imports` table** keeps the raw draft JSON per worksheet for re-review/debug without re-calling the API.
- **Generated conversations** are first-class cached objects with link tables to the vocab/structures they exercise.
- **Enums stored by name** (textEnum); the extractor's snake_case strings are mapped at the import boundary via `fromExtraction` helpers, so wire and storage formats evolve independently.

**D14. SRS reconciliation — state per word/structure; conversations as the delivery vehicle.** The spec was ambiguous (§6 says SRS schedules vocab/structures; §10.3 says it schedules cached conversations). Resolved as: knowledge strength and due dates live per word/structure (so growth and solid-vs-shaky stats are per item); cached conversations are selected to cover whichever items are due.
*Why:* keeps per-item stats direct and matches §6's framing while honoring §10.3's "stable items" intent (the cache provides stable content regardless of where SRS state lives). **Confirmed by the user.**

**D15. Documentation process.** Maintain `decision-log.md` (this file) and `project-status.md`.
*Why:* the user wants a durable record of rationale and a re-orientation map across sessions.
*Notes:* The decision log is updated proactively without being asked. `project-status.md` updates are proposed to the user for review before applying.

**D16. Named speakers in generated conversations.** Speakers are drawn from `name`-role vocabulary (鈴木/すずき, 田中/田なか, katakana スミス), not anonymous A/B.
*Why:* the user wants conversations to feel natural and to get reading practice on names. Names render with furigana from the store like any other word; foreign names in katakana are supported. Decided with the user.

**D17. Generation output = per-line speaker + per-token vocab mapping; vocab-scope is the hard guarantee.** The model returns each line's speaker (name id), the full text, the structure it instantiates (or 0), and the line split into tokens each tagged with the vocab id it came from (0 = grammatical glue). Furigana is rendered from the store via those ids; scope is validated by checking every id ∈ the known sets.
*Why:* gives furigana (D5) and scope-checking (D6) a concrete handle. Validated live: scope passed on every run, furigana round-tripped, negative slot form produced correct conjugation (おもしろく/ふるく).
*Notes:* Live testing showed the model **productively recombines** known pieces into patterns not literally in the structure library (e.g. `あれは {noun} ですか`, `それは {iadj} です`) while staying within known vocabulary. Treating **vocab-scope as the hard line and structure-match as soft** is the working stance — surfaced to the user as an open question (strict template-matching vs productive recombination).

**D18. Generation model: `claude-sonnet-4-6` confirmed.** The open tier question (D3) is resolved.
*Why:* live comparison on the same seed showed Sonnet's quality comparable to Opus for constrained generation (Sonnet actually handled the negative-adjective answer more coherently in one run). Sonnet is cheaper, faster, and its lower minimum cacheable size (2048 vs Opus 4096 tokens) means prompt caching engages sooner. Prompt caching confirmed working live (cache_read=2711 across calls).
*Notes:* Coherence finding to carry forward — generated answers sometimes mismatch the question type (はい to a what-question; a noun answer to an adjective question) because the structure library lacks some answer patterns. Generation coherence scales with how complete the captured answer-pattern set is; a prompt nudge to keep Q/A type-consistent is a cheap near-term improvement.

**D19. Productive recombination allowed; vocabulary is the only hard scope line.** The generator may recombine known particles, the copula です, the question marker か, and listed patterns into natural sentences that aren't literally in the structure library — as long as every *content word* comes from the vocabulary.
*Why:* the user chose this (stance A) for richer, more interesting practice. Recombining grammar you already know (は/です/か) isn't off-syllabus; the real "only what I've learned" line is the vocabulary. Resolves the open fork from D17. The generation prompt was updated to state this explicitly and to require answers to match their question type (the D18 coherence fix).

**D20. Verb round (quick validation, user-requested): two real scope-leak bugs found and fixed.** Extended the generation seed with verbs (たべる/のむ/いく — masu-form conjugation is a bigger surface-form change than the i-adjective negative already tested) and re-ran generation live.
- **Bug found:** the model rendered conjugated verbs in invented kanji (食べます) for a vocab entry with no kanji taught, even though the `vocab_id` attribution itself was correct — a real "only what I've learned" violation that the scope validator didn't catch (it only checked kanji hiding in *glue* tokens, not kanji in content tokens).
  *Fix:* validator now checks content tokens too, keyed on `kanji.isEmpty` (not the `kanaOnly` flag — a word can have real-world kanji not yet captured/taught, e.g. たべる/食べる, which is a distinct case from an intrinsically kana-only word like ある). Prompt updated to state the rule explicitly and to mark kana-only entries in the constraint context. Confirmed fixed live across 2 follow-up runs (16 lines, zero leaks).
- **Bug found:** the model added an honorific suffix (さん) not in vocabulary, tagged it as grammatical "glue" (vocab_id 0), which is invisible to the kanji-in-glue check since さん has no kanji.
  *Fix (partial):* added an explicit prompt rule against inventing honorifics/discourse particles. Confirmed no recurrence in follow-up runs.
  *Not fully solved:* any token tagged "glue" is currently unchecked *by design* (particles/copula are assumed safe) — there is no independent verification that a kana-only "glue" token is actually known grammar rather than an invented word. This is the self-report-reliability risk from D6/D17, now concretely demonstrated. A real fix (a curated allowlist of known grammar glue, validated per level) is deferred — see open questions in `project-status.md`.
- **Also confirmed:** verb conjugation was grammatically correct across all three verb classes (godan のむ→のみ-, godan いく→いき-, ichidan たべる→たべ-); Q&A coherence extended cleanly to verb yes/no questions after adding one instruction bullet; names correctly used both as speaker and inline in sentence text; prompt caching kept working as the seed grew.
- **Design principle recorded:** on a scope violation, the app's policy is to regenerate or flag (per spec §10.3) — the renderer should not try to silently repair bad model output (e.g. substituting store kana for leaked kanji), since that risks displaying a wrong conjugated form. The validator is the authoritative gate; a failing conversation is discarded, not patched.
*Why this round:* the user asked whether extending to verbs was worth it before moving on; agreed it was cheap and the best available stress test of self-reported token attribution. Recommendation validated — verbs surfaced two real, fixable bugs the copula-only seed could not have found.

**D21. Glue-token trust gap closed with a curated, reviewable grammar-glue allowlist (not template-derived).** Any token tagged "glue" (vocab_id 0) is now checked against `knownGrammarGlue` — an explicit, hand-maintained set of the particles/copula forms the structure library actually relies on (は, を, に, か, です, では, ありません, はい, いいえ, この) plus punctuation. A glue token that doesn't factor into these pieces is flagged.
*Why this design, not others considered:*
- **Not auto-derived from template text** — a template's fixed (non-slot) text can itself be real vocabulary (これ/それ/あれ/なん are written directly into several templates, not slotted), so "any substring of a template" isn't a safe definition of "pure grammar." An explicit set sidesteps that ambiguity.
- **Curated the same way as vocabulary** — grammar glue gets the same discipline as the vocab store (a small, explicit, extend-by-hand set) rather than being implicitly trusted. Promoting it into an actual reviewable DB table (alongside Words/Structures) is a reasonable future step, deferred for now — flagged as an open question.
- **Grounded empirically, not assumed** — the set was built from live `DEBUG_RAW` token dumps across all four structure families (copula, negative copula, i-adjective, verb), not from textbook-grammar assumptions.
*A real complication found and fixed during validation:* the model's tokenization granularity for these endings is **not stable across calls** — です/か and では/ありません were sometimes split into two tokens, sometimes fused into one (both observed live, same seed, same day). An exact-string allowlist match flagged the fused form (ではありません) as a false positive on a live run. Fixed by checking whether the surface **factors** into a concatenation of known pieces (regex alternation with backtracking) rather than requiring an exact match — this tolerates the model's variable granularity without weakening the actual check (every character still has to trace to known material). Confirmed: the exact failing case now passes on 3 repeat runs; さん (and a synthetic "さんは" adjacency case) are still correctly rejected.
*Known residual risk (documented, not solved):* the factoring check only recognizes known *grammar* pieces, not vocabulary — if the model ever fuses a vocab word directly into a "glue" token (e.g. hypothetically tagging これは as one vocab_id-0 token instead of splitting これ out), it would still be flagged as unrecognized even though it's benign. Not yet observed live; noted as a possible future false-positive source rather than pre-emptively widened, since widening the check to also factor in vocabulary kana would blur the vocab/grammar distinction this fix is built on.

---

## 2026-07-02 — Session 2 (on-device DB connection)

**D22. Repository/query layer deferred to §1, not built speculatively in §0.** Considered writing thin CRUD repository interfaces (per spec §10.1) for all 9 drift tables now, to close out §0 in one pass. Rejected: on inspection, `database_test.dart`'s "dedup" test only proves SQLite's unique constraint throws on a raw double-insert — there's no tested app-level lookup (`findExisting`/`findOrCreate`) to wrap yet, and 5+ tables (`ExampleSentences`, `Imports`, `GeneratedConversations`, both link tables) have zero callers today.
*Why:* writing repository methods with no real call site is exactly the premature-abstraction risk — the shape would be guessed, not derived, and the one method that actually matters (dedup-on-import: attach an example to an existing word rather than duplicating) doesn't exist as a proven pattern yet. Building it against the real import-commit layer in §1 gets the shape right the first time.
*Notes:* Decided with the user (chose "defer" over building partial repos now for the 3 tables with dedicated invariant tests). §0 stays `[in progress]` until the repository layer lands in §1.

**D23. On-device DB connection: `path_provider` + `NativeDatabase.createInBackground`.** `lib/data/connection.dart` resolves the app-support directory via `path_provider` and opens `mainichi.sqlite` there on a background isolate (drift's standard mobile recommendation, keeps DB I/O off the UI isolate). The directory→file-path composition is factored into a pure `dbFileIn()` function so it's unit-testable without mocking the `path_provider` platform channel; the one-line `getApplicationSupportDirectory()` call itself is left as thin, untested plumbing.
*Notes:* Wired into `main.dart` at startup (`AppDatabase(connectDb())` threaded into `MyApp` via constructor) even though no screen consumes it yet — user's call, in scope for this pass. `main.dart` is otherwise still the stock `flutter create` counter demo; untouched beyond the constructor change.

---

## 2026-07-06 — Session 3 (code-vs-spec review → three fixes)

**D24. Text↔tokens reconstruction check added to scope validation.** `validateScope` now verifies that each line's token surfaces, concatenated, spell the line's `text` (ignoring whitespace — `text` separates words with ASCII or ideographic spaces, tokens don't).
*Why:* every per-token check sees only what the model put in `tokens`, and the renderer builds the display from tokens too. A word present in `text` but omitted from `tokens` was invisible to all scope checks *and* meant the learner could be shown something other than the validated line. Found in a code-vs-spec review; fully deterministic, no segmentation needed.
*Notes:* the sibling hole — a hallucinated kana surface tagged with a *valid* in-scope vocab id passes clean and would render the wrong furigana — is recorded as an open item (surface↔entry consistency check), not yet fixed.

**D25. Extraction schema emits per-slot conjugation `form` (D12 finally propagated).** The slot object in `extractionSchema` gained a required `form` field on the closed set `dictionary / negative / polite / polite_negative / past / te` (wire values of `SlotForm`), plus a prompt rule with a worked example (the i-adjective negative pattern → slot role `i_adjective`, form `negative`).
*Why:* D12 decided slots carry a form, and the drift schema, draft models, and generator all had it — but the extractor, the one component that feeds the pipeline, couldn't express it. A worksheet teaching おもしろく ありません would have arrived with every slot silently defaulting to `dictionary` at import. A test pins that every wire value round-trips through `SlotForm.fromExtraction`.
*Notes:* not yet re-validated against a real worksheet with conjugated patterns — do that on the next live extraction run.

**D26. Confirmed merge upgrades an existing entry's kanji (and fills a missing meaning) — fill-empty-only, never overwrite.** In `runCommit`, a merge now writes the draft item's kanji onto the existing word *iff* the existing kanji is empty (also clearing `kanaOnly`, since the class evidently now teaches a kanji form), and writes the meaning *iff* the existing meaning is null. A differing already-taught kanji or existing meaning is never overwritten. Upgrades are counted (`kanjiUpgradedCount`) and surfaced on the commit and done screens.
*Why:* the class routinely teaches a word's kana weeks before its kanji — the spec's own kanji-only-if-printed rule guarantees the sequence — and merge previously attached the example but *discarded* the newly-taught kanji, stranding entries kana-only forever ("Not a match" instead forked a duplicate). This was the largest domain gap found in the review: the normal life cycle of nearly every word, not an edge case.
*Notes:* guarded UPDATEs (`where kanji = ''` / `where meaning is null`), so the exact-match same-batch merge path is a natural no-op. Residual: upgrading kanji could in principle collide with another row already holding `(kana, new kanji, role)` — the unique key would throw; not pre-handled, revisit if it ever occurs. The dedup review card doesn't yet *preview* the upgrade ("will add 食べる to this entry") — UI refinement for the live-wiring pass.

**Review findings not fixed this session** are recorded in `project-status.md`: a new **Bugs** section (non-transactional `runCommit`, empty Imports row, "Not a match" silently overridden by the exact-match merge, iOS key delivery unaddressed, stale model ids) and expanded open questions (okurigana furigana for conjugated kanji words — expect a data-model change at the rendering spike; SRS grading signal undefined for reading/listening; closed-vocabulary factoring segmenter as a likely MeCab-killer; surface↔entry consistency check).

---

## 2026-07-06 — Session 4 (Capture Loop "Revised Cards" design handoff implemented)

A Claude Design handoff (`Capture Loop - Revised Cards.dc.html`) mocked up deltas against all 5 existing review-loop screens; this session brought the Flutter implementation up to date with it.

**D27. Picture-derived word gets its own review card, closing the capture-loop.md §4 open question.** Previously picture-derived words reused `VocabReviewCard` with an `if (isPictureDerived)` branch (no distinct mockup existed yet). The design handoff supplied one, so a new `QueueItemType.pictureWord` and `PictureWordReviewCard` were added — drawing-led layout, chip-picked meaning (including the handwritten gloss folded in as one more chip, not a separate affordance, per capture-loop.md §2), kanji defaulting to "No kanji" since none is ever printed alongside a drawing.
*Why:* the two item types were diverging enough (meaning-as-chips vs meaning-as-text-field, kanji provenance) that the shared card's branching was becoming the source of bugs, not a simplification. The fixture's picture-derived item previously reused the exact same kana/kanji as the plain low-confidence vocab item (both はしる/走る) as a demo shortcut, which also happened to hide this exact contradiction — the picture item now has no kanji candidates at all (`kanaOnly: true`), matching what a drawing-only worksheet entry actually looks like.

**D28. "Discard" added as a terminal state distinct from skip.** A vocab/picture-word item can now be discarded outright via a "Discard extraction" action, tracked in a new `discardedRefs` set separate from `skippedRefs`. `commit_service.dart` excludes discarded items entirely — no DB write, no "skipped" summary entry on the commit/done screens.
*Why:* capture-loop.md §3 only had one non-approval outcome (skip = revisitable deferral); the design handoff calls for a second, stronger one for genuine junk that shouldn't linger as a "skipped" item forever. Kept separate from `ReviewStatus` (which still only tracks approved/skipped/pending) so the queue-navigation plumbing (`_resolve`) could be reused unchanged.

**D29. Bulk-approve confirmed cosmetic, made explicitly undoable.** Reading `runCommit` confirmed `ReviewStatus` was never actually consulted for high-confidence items — "approve all high-confidence" was already cosmetic, just not reversible. Added `bulkApproveStaged` + `undoBulkApprove()`, and the triage screen now shows a "N high-confidence staged / not saved yet" banner with an Undo button in place of the plain approve button once tapped.
*Why:* the design handoff's triage card explicitly calls out this gap ("bulk-approve shows an applied, undoable, staged state"). Confirming the action was already non-destructive meant undo could be implemented as a pure `ReviewStatus` revert, no new state needed beyond the one boolean flag.

**D30. Kana becomes a candidate-chip field, mirroring the existing kanji pattern.** Added `kanaCandidates` to `VocabDraftItem` (defaults to `[kana]` today, same extractor limitation already noted for `kanjiCandidates` — capture-loop.md §4). Both the vocab and picture-word cards now render kana as tap-to-pick chips with a "Type (rōmaji)" fallback, instead of a free-text field.
*Why:* the design handoff's stated rationale ("no IME needed") is the same one that already justified kanji-as-chips (capture-loop.md §3) — kana just hadn't been brought in line yet. Copy-adjust of an existing interaction rather than a new one.

**D31. Dedup card gets a field-by-field match summary; `ExistingWordMatch` gained a `role`.** The dedup card now computes and displays whether reading/meaning/role individually agree between the new item and the existing Bunko entry (green if all three match, amber otherwise), rather than only showing the two entries stacked for the user to eyeball. Required adding `role` to `ExistingWordMatch` (previously only kana/kanji/meaning/examples), populated from the matched `words` row in `dedup.dart`.
*Why:* the design handoff calls this "the false-match guard the spec calls for" (capture-loop.md §3: "a same-kana false match is a real risk") — the existing stacked-comparison UI made the user do the field-by-field check mentally; this makes it explicit. Deliberately handles the non-matching case (design mockup only showed the all-match example) rather than assuming agreement.

**Also from this handoff, no new decisions needed:** all example sentences now shown on the dedup card (was `.first` only); the template card now shows the original printed sentence (`TemplateDraftItem.example`, already existed but was unused) above the generalized template; a template slot's Form dropdown is now hidden for non-conjugating roles (noun, particle, etc. — verb/i-adjective/na-adjective are the only conjugating roles) in favor of a "doesn't conjugate" note; triage now renders the worksheet photo/title/topic (`CaptureDraft.worksheetTitle`/`worksheetTopic`, already existed but were unused) and the picture-word count. None of these needed a model or architecture change — the fields already existed or the pattern already existed elsewhere.

*Verification:* `flutter analyze` clean; `flutter test` — 51/51 passing, including 2 new widget tests (bulk-approve stage/undo, discard-excludes-from-commit) and the updated end-to-end flow test. Not visually verified in a browser — this app's `sqlite3`/`drift` FFI layer cannot compile for Flutter web at all (pre-existing, unrelated to this session), so browser preview isn't a viable path for this codebase; a real device/simulator (`flutter run -d macos`/`-d ios`) would be needed for a visual check.

---

## 2026-07-06 — Session 5 (iOS API key delivery)

**D32. API key storage: `flutter_secure_storage` behind an `ApiKeyStore` interface, plus a Settings screen.** Added `lib/settings/api_key_store.dart` (`ApiKeyStore` interface, `SecureApiKeyStore` impl — iOS Keychain via `flutter_secure_storage`, `first_unlock` accessibility), `lib/settings/settings_providers.dart` (`ApiKeyNotifier`/`ApiKeyState`, same shape as `capture_providers.dart`'s DB wiring), and `lib/settings/screens/settings_screen.dart` (paste-and-save form when no key is set, masked "key saved" card with a Remove action once one is). Wired a settings icon into `HomeScreen`'s `AppBar` in `main.dart`, overriding `apiKeyStoreProvider` with the real Keychain impl at the app root.
*Why:* closes the project-status.md Bugs entry "iOS API key delivery is unaddressed" — the CLI tools read the key from `~/.config/anthropic/key`, a path that doesn't exist on a phone, and live in-app extraction/generation can't be wired up at all without some on-device story for the key first.
*Notes:* scope is storage + UI only — this does not yet wire the key into an actual live `dio` HTTP call (`worksheet_extractor.dart`/`conversation_generator.dart` still only have CLI callers); that's the separate "live extractor call from the app" planned item. No key-format validation beyond non-empty-after-trim — Anthropic key formats aren't a contract worth hard-coding a regex against. Tested via an in-memory `FakeApiKeyStore` (`test/settings/`); the real `SecureApiKeyStore` isn't unit-tested since it needs the Keychain platform channel, unavailable under `flutter test` — matches how `connection.dart`'s real `path_provider` call is left untested in favor of testing the pure `dbFileIn()` logic around it.

*Verification:* `flutter analyze` clean; `flutter test` — 59/59 passing, including 8 new tests (5 provider-logic, 3 widget) in `test/settings/`. Not run on a simulator/device — same web-incompatibility as above blocks browser preview, and no iOS/macOS simulator was available in this session; worth a manual Keychain round-trip check (`flutter run -d ios`, enter key, background/foreground the app, confirm it's still there) before this is considered fully proven on-device.

**Confirmed live on the iOS simulator** (user-verified, start of next session): key storage + Settings screen round-trip works.

---

## 2026-07-06 — Session 6 (live extractor call from the app)

**D33. Live extraction: `dio`-based `LiveExtractionService`, plus a minimal "New import from photo" entry point.** project-status.md's two capture-flow items — "live extractor call from the app" and "in-app image capture" — were separate, but there's no way to exercise a live call from the UI without *some* photo source. Scoped with the user: build the real client and wire a thin `image_picker`-based picker now; leave resize/auto-orient (crop, rotation correction) as the still-separate follow-up. Added: `lib/extraction/extraction_client.dart` (`ExtractionService` interface, `LiveExtractionService` — `dio` instead of the CLI's `dart:io` `HttpClient`, key read fresh from `ApiKeyStore` per call so a key added mid-session works without a restart, `ApiKeyMissing` thrown distinctly from `ExtractionRefused`), `lib/extraction/extraction_providers.dart` (derives from the existing `apiKeyStoreProvider` — no new override needed at the app root), `lib/capture/draft_from_extraction.dart` (pure mapper: extractor JSON → `CaptureDraft`, reusing the `fromExtraction` enum helpers already used elsewhere), and `lib/capture/screens/photo_import_screen.dart` (camera/gallery buttons → loading state → routes into the same `TriageScreen` the fixture demo uses, or an inline error for `ApiKeyMissing`/`ExtractionRefused`/other failures). `HomeScreen` now has two buttons: the original "New import" (fixture demo) and "New import from photo" (live).
*Why:* this is project-status.md's last blocker before the whole capture loop is real rather than fixture-driven; extraction and generation were already validated live via the CLI tool (`tool/extract_worksheet.dart`), so the app just needed its own transport and a UI trigger.
*Notes:* also fixed a real bug this change exposed — `CaptureQueueNotifier`'s constructor used to seed a demo Bunko entry unconditionally (`_init()`), which would have run for a live import too (polluting the user's real vocabulary store with a fake たべる entry the moment `captureQueueProvider` was first touched, regardless of which button led there). Split into two explicit methods instead: `loadDemoFixture()` (seeds + loads the fixture, called by the demo button) and `loadFromExtraction(CaptureDraft)` (loads a live draft, never seeds). `test/capture/capture_flow_test.dart`'s four tests were updated to call `loadDemoFixture()` explicitly via a `ProviderContainer`/`UncontrolledProviderScope`, since the constructor no longer auto-loads anything.
Also added iOS's required `NSCameraUsageDescription`/`NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist` — missing entirely before this session; `image_picker` would have crashed the app on first camera/library access without them, not merely denied the permission.
`draft_from_extraction.dart`'s mapper deliberately leaves `handwrittenGloss`/`newExampleSentence` unset (unlike the hand-built fixture, which sets them directly as a demo shortcut) — the extractor doesn't attribute either to a specific vocab item yet (word-boundary matching, deferred per spec §9), so a live draft has neither until that's solved.
Refactored `tool/extract_worksheet.dart`'s private `_mediaTypeFor` into a shared `mediaTypeForPath` in `worksheet_extractor.dart`, reused by both the CLI and the new in-app client.
*Verification:* `flutter analyze` clean; `flutter test` — 71/71 passing, including 3 new suites (`extraction_client_test.dart` against a fake `dio` `HttpClientAdapter` — no real network call, this never hits the paid Anthropic API from automated tests; `draft_from_extraction_test.dart`; `capture_providers_test.dart` for the split load methods) plus a `photo_import_screen_test.dart` widget suite faking `ImagePickerPlatform` and `ExtractionService`. **Not exercised against the real Anthropic API or a real device camera** — that needs the user's own key and simulator, same as the Settings screen check in session 5.

---

## 2026-07-06 — Session 7 (two cheap correctness bugs: transactional commit + non-empty Imports row)

**D34. `runCommit` is now atomic, and it writes real import provenance.** Two of the project-status.md **Bugs** entries, fixed together since both touch the commit path.
- *Transaction:* `runCommit`'s body moved into a private `_runCommit`, wrapped in `db.transaction(...)`. The Imports insert plus all word/template/example writes now commit or roll back as one unit, so a crash (or a mid-commit throw) can no longer leave a half-imported worksheet with a dangling Imports row. Proven by a new test that forces a mid-commit collision (the unguarded kanji-upgrade unique-key clash noted in D26) and asserts both the earlier word insert *and* the Imports row are rolled back.
- *Provenance:* the Imports row was being inserted with `rawDraftJson: null` and no `sourceImage`/`model`, defeating the table's whole purpose (D13: re-review/debug an import without re-calling the API). `CaptureDraft` gained three nullable provenance fields (`sourceImage`, `model`, `rawDraftJson`); `draftFromExtraction` now captures the raw draft verbatim (`jsonEncode` of the extraction map) and threads the photo path + `extractionModel` through from `PhotoImportScreen`; `runCommit` writes all three onto the Imports row.
*Why:* both were flagged in the 2026-07-06 code-vs-spec review and explicitly deferred until the live extractor call existed (session 6) — the provenance fix in particular was meaningless while the pipeline was fixture-only. Now that a real photo/model/JSON flows through, the row can carry it.
*Notes:* provenance is null on the hand-built demo fixture (`buildSampleDraft`) — it has no real photo or model response behind it, so null is the honest value there, not a regression. The transaction wrapper doesn't change any success-path behaviour; all pre-existing commit tests pass unchanged. The residual D26 kanji-upgrade collision is still not *prevented* (only now exploited as a convenient way to force a rollback in the test) — it remains its own open item.
*Verification:* `flutter analyze` clean; `flutter test` — 75/75 passing, including 4 new tests (Imports-row provenance write, atomic rollback on mid-commit failure, and two `draftFromExtraction` provenance-capture cases).

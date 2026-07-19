# Feature: Capture Loop (Photo → Review → Commit)

Closes the loop described in spec §3. Extraction already works (`lib/extraction/worksheet_extractor.dart`); this feature is the UX for turning an extraction draft into committed store rows.

**Terminology:** on-screen, the vocabulary store is called **Bunko (文庫)** — "library/book repository." This is user-facing naming only; internal/technical docs (main app spec, decision log, drift schema) keep "vocabulary store" as the dev-facing term for the same underlying data.

---

## 1. Purpose

The capture step is load-bearing (spec §1, §3): if reviewing a worksheet is tedious, the app stops getting fed. The UI's job is to make approval of good extractions nearly free, and to focus your attention only on the items that actually need a human judgment call.

---

## 2. Flow

**Step 1 — Capture.** Photo picker/camera → send to extractor → loading state. (Existing.)

**Step 2 — Triage screen.** Landing screen after extraction returns. Shows a one-line summary of what was extracted (e.g. "12 vocab, 3 templates, 2 picture words — 9 high-confidence, 8 need review") and two actions:
- **Approve all high-confidence** — bulk-marks the pre-approved tier as approved. Does not commit yet (see §3).
- **Review queue →** — enters the focused review flow for everything else.

**Step 3 — Review queue.** One flagged item at a time, not a scrolling list — these are exactly the items where a scan-and-skip UI would defeat the purpose. Per item type:
- **Vocab** — kana / meaning / role editable as text/select fields. **Kanji is not free-text** (see §3 — no Japanese IME to assume): shown as a read-only value the model read off the worksheet, alongside a small crop of the source photo for visual comparison, with the model's reading and any alternate candidates offered as tappable chips, plus a **"No kanji"** chip to keep the word kana-only. If a handwritten gloss was recorded alongside, show it as a chip; tapping accepts it as the meaning.
- **Picture-derived word** — same field order as vocab (kanji → kana → meaning → role), with the drawing shown up top for context (worth flagging since these are the most likely to be wrong). No separate handwritten-gloss affordance here: if a margin note exists for a picture-only word, it's folded into the meaning candidate chips as just another option, not surfaced as its own "your note" chip the way the plain vocab card does.
- **Template** — sentence rendered with each slot as a colored inline token (e.g. `{food}`, `{verb_1}`), one color per slot so the sentence shape reads at a glance; fixed template text stays plain and uneditable. Below the sentence, one card per slot with **Role** and **Form** as dropdowns (not free text — slots only accept a fixed set of roles/forms, same reasoning as vocab's role field), color-matched to that slot's inline token.
- **Dedup match** — when a vocab item matches an existing Bunko entry: the new item (from this worksheet) and the existing Bunko entry are shown stacked, new on top, existing below and visually accented as the reference point, each with its example sentence(s) — kana alone isn't enough to judge a match, so the sentence context is what lets you actually tell. Actions are **Merge** (attaches the new example sentence to the existing word) or **Not a match** (keeps it as a new, separate entry).

Each item in the queue resolves to one of: **approved**, **corrected-and-approved**, or **skipped**. Skipped items are not discarded — they stay visible (e.g. a "Skipped (2)" affordance) and can be reopened any time before commit.

**Step 4 — Commit screen.** One photo → one commit. Nothing is written to your Bunko until you commit; "approve all high-confidence" and queue decisions all accumulate in the draft until then. Shows a breakdown of what's about to be written (new words / merged / new templates, not just a raw count) and calls out any skipped items with a "Review" jump-back link rather than silently dropping them. Commit is available once the queue has no unresolved items (skipped items must be explicitly left skipped or resolved — they don't block commit, they just won't be written).

**Step 5 — Done screen.** Confirmation summarizing what was added to your Bunko (e.g. "9 new words, 1 merged, 3 new templates") with a success icon. Any item still left skipped is shown here too (label + reason, e.g. "走る — picture-derived, low confidence") with its own "Review" action, since a skip should stay revisitable even past commit, not just during the queue. Two exits: **Done**, or straight into **Import another worksheet** (captures happen in batches of several per week).

---

## 3. Key decisions

- **Batch approval doesn't commit early.** "Approve all high-confidence" only marks items approved; the actual DB write happens once, at final commit, alongside everything from the review queue. Simpler to implement (single commit transaction per photo) and keeps "photo in → one clear commit out" as the mental model.
- **Skipped is revisitable, not deleted.** A skip during review queue is a deferral, not a rejection — you can reopen it any time before commit. There's no reject-forever action in this pass; if something's clearly garbage, skipping it and never revisiting has the same effect.
- **Discard is stronger than skip, for genuine junk.** A vocab or picture-word item can be discarded outright (distinct from skip): it's excluded entirely at commit, with no "skipped" summary entry and no revisit affordance. Skip stays the default deferral for anything not obviously junk.
- **Dedup merge requires confirmation**, not silent auto-merge — a same-kana false match (different word, same reading) is a real risk, so a merge is a proposal you confirm, not an assumption the app makes for you.
- **Kanji correction is candidate-picking, not typing.** The user is a beginner with no Japanese IME set up, and kanji only ever enters the app from what's printed on the worksheet (spec §3) — so the model has almost always already seen the right answer. The review UI's job is to let you confirm or pick an alternate, never to demand you type a kanji character from scratch. "No kanji" is a first-class option, not a fallback.

---

## 4. Open questions

- Does "Not a match" on a dedup card create a genuinely separate word entry that could itself collide later (e.g. two entries with identical kana/kanji/role)? Needs a rule once this is implemented against the drift schema.
- ~~Picture-derived words: retain/display the cropped drawing region, or just a text note?~~ — **resolved (D58):** the extractor now returns a per-item `region`, and `WorksheetPhotoBox(region: item.region)` crops the picture card's box to that snippet (falling back to the whole photo when the region is absent/degenerate).
- ~~**Extractor needs to return kanji candidates, not just one guess**~~ — **resolved (D58):** `extractionSchema` gained `kanji_candidates` (ranked, best-first, first == `kanji`) and a best-effort `region` per vocab item; `draft_from_extraction.dart` maps the ranked list (deduped, confirmed-kanji-first, singleton fallback for legacy payloads) into the chips the review card already renders, and the region into the photo box. Vision boxes are approximate, so the region is framing only, never a data source.
- Visual design: triage screen, and all four review-queue item variants (vocab with kanji-candidates, picture-derived word, template, dedup-merge) are mocked up in Claude Design ("Capture Loop - Revised Cards"). Picture-derived word now has its own distinct card (`PictureWordReviewCard`), separate from the plain vocab card.

---

## 5. Status

`[in progress]` — all 5 screens implemented in Flutter (`lib/capture/`), driven by a hand-written fixture draft rather than a live photo/API call (deferred, see §4). Riverpod (`CaptureQueueNotifier`) manages queue navigation and draft edits; `commit_service.dart` writes approved items into the real drift schema, including the same-batch and cross-import dedup paths. Picture-derived words route to their own queue item type (`QueueItemType.pictureWord`) and card. Covered by unit tests (`test/capture/dedup_test.dart`, `test/capture/commit_service_test.dart`) and an end-to-end widget test (`test/capture/capture_flow_test.dart`).

The live path is now wired end to end: `image_picker` capture, a pre-send prep step (bake orientation, downscale, viewport crop — D57, `lib/capture/image_prep.dart` + `PhotoPrepScreen`), the `dio`-based extractor client, and the extractor's kanji-candidate/crop-region output (D58). The prepared JPEG — the exact bytes sent — is persisted under `<app documents>/worksheets/import_<ts>.jpg` and recorded as the import's `sourceImage`, so it survives the picker's temp-dir cleanup and the crop regions index into an image that still exists. *Deferred:* a cleanup policy for those saved photos (they accumulate; small, so not urgent), per-worksheet chunking for pages over the 16000-token cap (D54), and the done-screen "Review" action on an already-committed skipped item (a read-only stub — reopening a skip post-commit needs its own design pass).

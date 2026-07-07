# Feature: Generated-content cache

Persists every valid generated conversation as a first-class cached object (spec §10.3), tagged with the vocabulary and structures it exercises. The spec gives the cache three jobs: **stable items for SRS** to reschedule (AI generation produces a fresh sentence each call; spaced repetition needs identities that persist), **instant/offline practice** (the fallback that makes §6's offline mode useful), and the anchor the **listening exercise's TTS audio** attaches to (`audioPath`, phase 3). The schema has existed since §0 (`GeneratedConversations` + `ConversationWords`/`ConversationStructures` link tables); this feature is the write path and the first, deliberately minimal read path.

---

## 1. UX stance

**The cache is invisible plumbing, with exactly one visible affordance.** No save button, no library screen, no cache indicator. The learner's experience of the reading exercise is unchanged in the success path; the only place the cache surfaces is where its absence currently hurts — the generation-failure error state.

---

## 2. Flow

**Write (invisible).** The moment a conversation passes `validateScope` and reaches the reading screen's ready state, it is persisted: full conversation payload verbatim (`payloadJson`), line count, and link rows for the vocab entries and structures it exercises. `lastPracticedAt` is set immediately — the conversation is on screen, which is the only practice signal a continuous feed with no completion state (D39) can honestly give. A persistence failure never interrupts reading (the conversation is already validated and on screen; losing one cache entry is the cheaper failure).

**Read (the one affordance).** When generation fails and the cache is non-empty, the error state gains a third action alongside **Try again** / **Exit**: **"Reread an earlier one"** — serving the least-recently-practiced cached conversation and updating its `lastPracticedAt`. Motivated directly by the observed 3-of-5 live failure rate on a small Bunko (project-status.md Open questions), and it is the same code path the deferred offline mode (§6) will use — graceful degradation arriving early where it already hurts, not speculative UI. When the cache is empty (fresh install), the error state looks exactly as it does today.

---

## 3. Key decisions

- **Write-through on success, no user interaction.** Every valid conversation is saved, including ones the learner immediately taps **Next** past — SRS needs stable items regardless of whether a conversation was savored, a barely-read conversation is still a good future practice item, and detecting "actually read" would add machinery the open SRS-grading-signal question hasn't justified. Single user + 6-line JSON payloads = no storage concern; no cap or eviction until phase 5 gives a reason.
- **The reading feed stays generate-first.** **Next** always requests a fresh generation when online; the cache never silently substitutes a repeat. Freshness is the exercise's point, and an unannounced repeat would read as a bug. Cached content re-enters the feed deliberately at phase 5 ("conversation selection to cover due items"), not implicitly here.
- **Link rows derive from the validated conversation, not the model's report.** Word links come from the non-glue token vocab ids, structure links from each line's `structureId` — the same authority discipline as everywhere else; the model's `used_vocab_ids`/`used_structure_ids` self-report is not the source.
- **Reread renders against the current store.** A cached conversation stores the full payload, but lookups (furigana, the word-tap sheet) resolve against the live seed at render time. If a referenced word has since been deleted, its token renders plain and untappable — the existing `line_display.dart` fallback — rather than resurrecting stale data.
- **No library/browse UI, no cache management.** Nothing needs it yet; a browsable history can grow out of the stats/SRS work (phase 5) where it has a real caller.

---

## 4. Open questions

- **Selection beyond least-recently-practiced.** LRU-by-practice is the obviously-right v1 for a fallback ("the one you've seen least recently"). Phase 5's SRS-driven selection (cover due items) replaces or augments it — decide there.
- **Cache staleness vs. the growing Bunko.** A conversation generated against a 20-word Bunko stays valid forever (its material only becomes *more* known), so there is no invalidation problem today. Revisit only if material can ever be *removed* from the store in a way that should retire conversations (currently: FK cascade on word delete removes the link row, not the conversation).

---

## 5. Status

`[done]` (2026-07-07, D49) — write-through persistence wired into the reading screen's ready state (`ConversationStore`/`DriftConversationStore`, `lib/data/conversation_cache.dart`; payload serialization via `GeneratedConversation.toJson`/`fromJson`), and the "Reread an earlier one" fallback action on the error state. Audio attachment (`audioPath`) untouched until the listening exercise; SRS selection untouched until phase 5.

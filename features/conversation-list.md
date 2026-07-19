# Feature: Conversation list

Turns the generated-content cache's blind "Re-read a previous one" button into a browsable list of past conversations, each with a topic title and timestamps, with the ability to delete conversations the learner doesn't want to see again. Grows the "deliberately minimal read path" of `features/generated-cache.md` into the library/browse UI that doc explicitly deferred ("a browsable history can grow out of the stats/SRS work") — pulled forward now because LRU-only reread feels random and gives the learner no control. The SRS tie-in (surfacing due-ness per conversation, SRS-driven selection) stays deferred to phase 5.

**Visual design:** to be mocked up in Claude Design. Screens needed: the list itself (populated), the list empty state, and the delete affordance/confirmation.

---

## 1. Purpose

The cache already stores every valid conversation, but the learner can't see it. This feature gives them a window: what conversations exist, what each is about, when it was generated and last practiced — and a way to prune ones that were bad (mis-generated, boring, too easy). Reread becomes a choice, not a lottery.

---

## 2. Flow

**Entry.** The home screen's **"Re-read a previous one"** button navigates to the conversation list screen instead of directly launching the LRU conversation.

**List.** A scrolling list, newest first (by `createdAt`). Each row shows:

- **Title** — the stored topic (see §3), e.g. "Ordering at a restaurant". One line, ellipsized.
- **Metadata line** — creation date and last-practiced date ("Jul 12 · practiced 3 days ago" or similar; exact treatment is Claude Design's call). A small line-count or audio-available indicator is optional flourish, not required.

**Tap a row** → opens the reading exercise screen showing exactly that conversation (same rendering path as today's reread: render against the live store, mark `lastPracticedAt`). **Next** from there behaves as it does today (fresh generation) — the list picks the starting conversation, it does not create a "playlist" mode.

**Delete.** Per-row delete (swipe-to-delete or an overflow/trash affordance — Claude Design's call), with a lightweight confirm (snackbar-undo or dialog). Deleting removes the DB row, its link rows, and its cached audio directory on disk. No multi-select in v1.

**Empty state.** Friendly one-liner ("Nothing here yet — conversations you read are saved automatically") with a button to start Reading practice.

---

## 3. Titles: stored at generation time

The generation schema gains a required **`topic`** field: a short (≤ ~40 char) noun-phrase description of what the conversation is about, in English, produced by the model alongside the conversation itself (e.g. "Making weekend plans", "At the post office"). It is display metadata only — it does not participate in scope validation, and the authority rule is unaffected (titles are cosmetic; vocab/structure links still derive from the validated conversation, never the model's self-report).

Stored in a new `title` column on `GeneratedConversations`.

**No backwards compatibility.** Existing cached rows have no title; the schema migration simply deletes all existing `GeneratedConversations` rows (and link rows; orphaned audio directories are cleaned up too, or left to the delete path — implementer's call, storage is trivial). Single-user app, cache is regenerable content — decided explicitly over any derive-a-title-from-vocab fallback.

---

## 4. Key decisions

- **Title from the model, not derived from linked vocab.** The model knows what scene it wrote; a vocab-derived name ("食べる, 水, …") is a word list, not a title. Cost is one small schema field on an existing call.
- **The list replaces the home button's LRU behavior; the error-state fallback keeps it.** The generation-failure "Reread an earlier one" action stays a one-tap LRU serve — in that moment the learner wants *something to read now*, not a browsing detour. `leastRecentlyPracticed()` keeps its one caller.
- **Delete is real deletion, including audio.** The row's `audioPath` (or the conventional `audio/conv_<id>` directory) is removed from disk so orphaned mp3s don't accumulate. A missing/never-synthesized directory is a silent no-op.
- **Read-only list otherwise.** No rename, no favorite, no sort options, no search — nothing has demonstrated a need yet, and SRS-driven ordering (phase 5) will likely reshape this screen anyway.
- **No cap/eviction still.** Delete is manual pruning; automatic eviction remains out of scope per `features/generated-cache.md`.

---

## 5. Open questions

- **Topic steer round-trip.** The generator's `focus` parameter already accepts a topic nudge; once titles exist, "generate another one like this" (feed a conversation's title back as `focus`) becomes a cheap feature. Not in v1.
- **SRS tie-in (phase 5).** The link tables make per-conversation due-ness computable — the list could badge or sort by "covers N due words," turning reread into a review action. Decided to wait for SRS to exist.

---

## 6. Status

`[done]` (2026-07-19) — implemented against the Claude Design mockups. The
generation schema gained a required `topic` field (`generationInstructions` +
`generationSchema`), carried on `GeneratedConversation.topic` and stored in the
new `GeneratedConversations.title` column (schema v3; the migration drops the
pre-title cache and its link rows — no backfill, §3). `ConversationStore` gained
`list()` (newest-first summaries), `byId()`, and `delete()` (row + link-row
cascade); `AudioStore.deleteAudio()` removes the on-disk `audio/conv_<id>`
directory. New `ConversationListScreen` (`lib/reading/screens/`) with the
`conversationListProvider` notifier: swipe-to-delete with snackbar-undo
(optimistic — the DB/disk removal commits only when the undo window lapses),
the empty state, and a row tap that opens the reading exercise via the new
`ReadingStart.conversation` entry (marks `lastPracticedAt`; **Next** generates
fresh, not a playlist). The home "Re-read a previous one" button now navigates
here; the generation-failure error state keeps its one-tap LRU reread.

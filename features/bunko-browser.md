# Feature: Bunko browser

A read-only screen to see the contents of the Bunko — the words, sentence structures, and grammar-glue entries the capture flow has added — grouped by type. Closes the standing opacity gap: today there is no way to verify what a worksheet import actually taught without reading the raw DB.

---

## 1. Purpose

The Bunko grows silently through the capture loop; nothing in the app lets the learner (or the developer) see what's in it. This feature gives a browsable window: what words exist by part of speech, what sentence structures and grammar glue have been taught, and the detail behind each entry (meaning, notes, example sentences). Read-only for v1 — no rename/edit/delete — but the data layer and detail views are shaped so edit functionality can land on the same interface later without a rewrite.

---

## 2. Flow

**Entry.** A fourth home-screen button, "Bunko", alongside Reading practice / Free conversation / New import from photo.

**Layout.** Three tabs: **Words** / **Structures** / **Glue**.

- **Words tab** — a horizontal row of filter chips ("All" + one per part-of-speech present, each labeled with its count, e.g. "Noun (12)"), above a list of every word (or the selected role's subset). Each row shows kanji (or kana if none), the reading and meaning as a subtitle, and the role.
- **Structures tab** — a list of templates, each row showing the template text and its slot count.
- **Glue tab** — a list of grammar-glue surfaces (particles, copula, …) with their kind.

**Detail.** Tapping a word or structure opens a read-only bottom sheet with everything the row doesn't show: meaning source, status, notes, created date, and example sentences (structures also list their typed slots). Glue rows have nothing further to show, so they're not tappable in v1.

**Sorting.** Newest first throughout (`createdAt`/`addedAt` desc) — the primary browse question is "what did my last worksheet add," and Japanese collation in SQLite isn't reliable enough to sort kana/kanji meaningfully.

**Status.** All rows are shown regardless of `ItemStatus` — the browser mirrors the store as-is rather than silently filtering to `approved` (nothing writes `draft` today outside the in-memory capture queue, so in practice this shows everything anyway).

---

## 3. Data layer

A new `BunkoStore` (`lib/data/bunko_store.dart`) — a read-only query class over the existing drift tables (`Words`, `Structures`, `Slots`, `GrammarGlue`, `ExampleSentences`), not new storage. It is a second read path alongside `SeedSource`/`DriftSeedSource`: that one feeds the generation engine and deliberately returns only `approved` items in a stripped shape (per D22, built per real caller); this one is for a human to look at and needs the fields the generator doesn't (notes, status, timestamps, examples).

List queries (`listWords`, `listStructures`, `listGlue`) load everything and are filtered by role in memory in the UI — the Bunko is small (hundreds of rows), so this keeps the chip filter instant with no extra query plumbing. Example sentences are per-item data the list never renders, so they're fetched lazily (`wordById`, `structureById`) only when a detail sheet opens.

Future edit methods (`updateWord`, `deleteWord`, …) have a natural home on this same interface, writing the same tables — there is no separate data model to keep in sync.

---

## 4. Key decisions

- **Second read path, not a new store.** Reusing `DriftSeedSource` would couple the generation engine's input shape to browser display needs; a dedicated query class keeps both callers simple (D22's "build against real calls" stance).
- **Load-all + in-memory filter over per-role queries.** At Bunko scale, the simplicity is worth it; a per-role query would only pay off at a size this app doesn't reach.
- **Lazy example-sentence fetch.** Examples are extracted from the worksheet photo at import time and written by `runCommit`; the list never shows them, so they're read on-demand in the detail sheet rather than eagerly joined into every list row.
- **Detail as a bottom sheet, not a pushed screen.** Matches the existing sheet pattern (`word_lookup_sheet.dart`, `glue_review_sheet.dart`) and keeps browsing lightweight (peek, dismiss, next row); an "Edit" action later fits the same sheet.
- **Show all statuses.** The browser's job is to faithfully mirror the DB; filtering would hide rows and make debugging harder for no real benefit today.

---

## 5. Status

`[done]` — implemented: `lib/data/bunko_store.dart` (`BunkoStore`/`DriftBunkoStore`), `lib/bunko/` (`bunko_providers.dart`, `role_label.dart`, `screens/bunko_screen.dart`, `widgets/word_detail_sheet.dart`, `widgets/structure_detail_sheet.dart`), home-screen entry in `lib/main.dart`. Edit functionality is not built — deferred to a later feature.

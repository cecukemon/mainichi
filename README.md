# mainichi 毎日

**A companion app for a real-life Japanese class.** mainichi doesn't ship a curriculum of its own: you photograph the worksheets your class hands out, the app turns them into a personal store of vocabulary and sentence patterns (the *Bunko*), and then it generates reading, listening and speaking practice that stays strictly inside what your class has actually taught you.

> Capture what class taught → practice it → arrive at the next class prepared.

Because every generated sentence is checked against your own Bunko, you never practice a word, kanji or grammar ending you haven't learned yet.

<!-- screenshot: home screen -->

---

## How it works

mainichi is built around two ingredients that it composes into practice material:

- **Vocabulary** — every word in dictionary form, with its kana reading, its kanji (only if your worksheet printed it), its meaning, and its role (noun, verb, adjective, place, food, …).
- **Sentence structures** — templates with typed slots, e.g. `わたしは {food} を たべます`, where each slot accepts only words of the right role and conjugation form.

From a modest pile of words and a handful of structures, the app (using Claude) generates short Q&A conversations. Every one of them is then validated independently before you ever see it.

---

## Features

### 📷 Capture: worksheets in, Bunko out

- **Photo import** — take a picture of a worksheet or pick one from your library. The app auto-orients and downscales it, and lets you crop it before sending.
- **One-shot extraction** — a single vision call reads the worksheet and proposes:
  - **vocabulary** in dictionary form, with reading, meaning and role,
  - **example sentences** turned into reusable slot templates, including the conjugation form each slot expects,
  - **picture-explained words**, with the meaning inferred from the drawing.
- **Taught kanji only** — kanji is captured only if the worksheet prints it. The app never adds kanji you haven't been shown.
- **Printed vs. handwritten** — printed translations count as worksheet content. Your own handwritten margin notes are kept separate, and the review card offers them as a one-tap meaning.
- **Review, not autopilot** — extraction only produces a draft:
  - **Triage** shows the worksheet and a summary, with an undoable bulk-approve for high-confidence items.
  - **Review queue** walks through anything flagged, with a dedicated card for each item type (vocabulary, picture word, template, possible duplicate). Each card shows a cropped snippet of where the item sits on the photo, and you can pick the kana and kanji from chips.
  - **Skip or discard** for items you don't want.
- **Smart deduplication** — if a word is already in your Bunko, the app shows a field-by-field match summary and attaches the new example sentence to the existing entry instead of creating a duplicate. If your class taught a word in kana first and in kanji later, the existing entry gets upgraded.
- **Atomic commit with provenance** — each photo's import is written in a single transaction and records its source image, the model used, and the raw draft.

<!-- screenshots: photo crop, triage, review card (vocab), review card (dedup), commit/done -->

### 📖 Reading practice

- **Generated conversations** — short Q&A dialogues built from your Bunko, laid out like a script with the speaker in a margin column and new conversations a tap away.
- **Furigana you control** — kanji with furigana by default. Turn the toggle off to check whether the readings have stuck. Okurigana is handled properly, so the reading sits over the kanji stem only (e.g. 食べます).
- **Tap any word** for a lookup sheet showing its reading, meaning and role, which conjugated form it's in, and its dictionary form.
- **Strict scope validation** — every line has to break down completely, character by character, into your taught vocabulary, taught conjugation endings, approved grammar glue (particles, copula, …) and punctuation. This check doesn't rely on the model's own account of what it wrote. A conversation that fails is thrown away and never shown.
- **Variety steering** — each request nudges generation toward different structures and topics and away from recent titles, so you don't get "Do you like X? Yes, I like X" over and over.
- **Self-healing when something fails** — if a conversation is rejected because of a word your class did teach but you never captured, that word shows up as a chip. Tap it, confirm it ("Did your class teach this?"), and it goes into your Bunko. The rejected conversation is then re-checked and shown on the spot if it now passes. Particles and other grammar glue get their own review sheet.
- **Conversation history** — every valid conversation is saved. Browse them newest first, reopen one to re-read it, or swipe to delete (with undo).

<!-- screenshots: reading screen (furigana on), reading screen (furigana off), word lookup sheet, scope-failure chips, conversation list -->

### 🎧 Listening

- **Text-to-speech for every conversation** using Google Cloud neural voices, with two voices for the two speakers. Audio is built from the same kana readings that drive the furigana, so if a reading in your data is wrong, you'll hear it.
- **Playback controls** — play the whole conversation or replay a single line, at 0.5×, 0.75× or 1× speed, with the current line highlighted and auto-scrolled into view.
- **Listening mode** blurs the text so you listen first, then tap a line to reveal it.
- **Cached audio** — each line is synthesized once and stored. If a reading gets corrected, its audio is regenerated automatically.

<!-- screenshots: audio bar + highlighted line, listening (blur) mode -->

### 🗣️ Speaking

Speaking practice comes in steps that build on each other:

- **Shadowing** — the app plays one line, then waits for you to say it aloud. There's no timer: you choose **Next line** or **Hear it again** when you're ready.
- **"Check me"** — an optional step during shadowing. Record yourself reading the line and Google Cloud speech-to-text grades it as *match*, *close* or *mismatch*. What the recognizer heard is always shown, so you can tell a mispronunciation apart from a mishearing. Grading copes with STT writing in kanji: if you read 私 as わたし and STT returns 私, that's still a match.
- **Free conversation** — chat out loud with a persona. Every reply you give gets a verdict, a short note and a corrected version, and the persona answers with a new line that is checked against your Bunko like everything else. Persona lines show furigana and support word lookup, and a **hear it** button plays each one aloud.

<!-- screenshots: shadowing hold row, Check me verdict + "Heard:" transcript, free conversation screen -->

### 📚 Bunko browser

- **See what's in your Bunko** across three tabs: **Words**, **Structures** and **Glue**. Words can be filtered by part of speech, and everything is sorted newest first, which answers "what did my last worksheet add?"
- **Detail sheets** show the meaning source, status, notes, date added and every example sentence. Structures also list their typed slots.
- **Verb fix-up** — a verb that was captured in polite form (たべます) instead of dictionary form (たべる) can be fixed with a guided correction.

<!-- screenshots: Bunko words tab with filter chips, word detail sheet, structures tab -->

### ⚙️ Settings

- API keys for Anthropic (extraction and generation) and Google Cloud (TTS and STT) are entered in the app and stored in the iOS Keychain. They are never stored in the repo.

---

## Tech overview

| Area | Choice |
| --- | --- |
| App | Flutter, Riverpod |
| Storage | SQLite via [drift](https://drift.simonbinder.eu/), on-device |
| Extraction & generation | Anthropic Claude API (vision + structured output, prompt caching on the Bunko context) via `dio` |
| Speech | Google Cloud Text-to-Speech and Speech-to-Text |
| Audio | `just_audio` (playback), `record` (mic capture) |
| Japanese text | Custom furigana widget and a closed-vocabulary segmenter. No MeCab and no backend. |

Models are configured in [`lib/config/model_config.dart`](lib/config/model_config.dart).

### Project layout

```
lib/
  capture/      photo import, crop, review queue, dedup, commit
  extraction/   worksheet extraction call
  generation/   conversation generation + scope validation
  japanese/     segmenter, okurigana split, polite-form helpers
  reading/      reading screen, furigana, lookup, backfill, conversation list
  listening/    TTS, audio cache, playback controller
  speaking/     shadowing check, STT grading, free conversation
  bunko/        Bunko browser + verb fix-up
  data/         drift schema, stores, migrations
  settings/     API key storage + settings screen
tool/           CLI prototypes for extraction and generation
features/       per-feature design docs and HTML mockups
```

## Getting started

Prerequisites: the Flutter SDK, Xcode (iOS is the main target), an Anthropic API key, and a Google Cloud API key with Text-to-Speech and Speech-to-Text enabled.

```bash
flutter pub get
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

```bash
flutter run
```

Once the app is running, open **Settings** and enter both API keys.

Run the tests:

```bash
flutter test
```

### CLI prototypes

There are two command-line tools for trying the AI steps outside the app:

```bash
ANTHROPIC_API_KEY=... dart run tool/extract_worksheet.dart path/to/worksheet.jpg
```

```bash
ANTHROPIC_API_KEY=... dart run tool/generate_conversation.dart tool/seed_demo.json 6
```

## Status & docs

mainichi is a personal project under active development. Capture, reading, listening and speaking all work. Spaced repetition and progress stats are next.

- [`japanese-companion-app-spec.md`](japanese-companion-app-spec.md) — the feature spec
- [`project-status.md`](project-status.md) — what's done, in progress and planned
- [`decision-log.md`](decision-log.md) — design decisions (D1–D74), referenced throughout the code
- [`features/`](features/) — per-feature design docs and mockups

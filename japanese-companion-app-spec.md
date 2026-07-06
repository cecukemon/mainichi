# Japanese Class-Companion App — Feature Spec

*A companion to a real-life Japanese class. Captures what you learn each week and helps you retain it through generated practice across reading, listening, and speaking.*

---

## 1. Guiding principle

The app does **not** ship a fixed curriculum. Its content follows your class. Every feature serves one loop: capture what class taught → retain it through review → practice it → arrive at the next class prepared. Because everything the app generates stays inside what you've actually learned, there's never a mismatch between what you study and what you're tested on.

The capture step is treated as load-bearing: if adding new material is tedious, the app stops getting fed and the whole concept stalls. So low-friction entry is a first-class concern, not an afterthought.

---

## 2. The generative engine

The core of the app is a generator, not a library of canned exercises. It has two ingredients and composes them:

**Vocabulary store** — every word tagged by role (noun/object, verb, adjective, place, direction, food, etc.). Each entry holds three content layers plus a flag:
- Kanji form
- Kana reading (used for furigana and for speech)
- Meaning
- A flag for kana-only words (やる, ある, grammar particles) that have no kanji form.

Entries are stored in dictionary (base) form. Surface forms in generated text are conjugated (`たべる` → `たべます` / `たべた`), so any later word-level matching against the store needs lemmatization, not string equality — see §9.

**Structure library** — sentence templates with typed slots, e.g. `わたしは {food} を たべます` or `わたしは {place} に {direction} います`. Each slot only accepts vocabulary of the matching role, which keeps generated sentences grammatical. A slot also carries a **form** — the conjugation it expects (dictionary, negative, polite, …) — so a template can demand a conjugated adjective or verb (e.g. the i-adjective negative `おもしろい → おもしろく ありません`) while still drawing from the same base-form vocabulary entry. Within a template every slot has a unique name (`{noun_1}`, `{noun_2}`); a word that never varies stays in the template text, not a slot. *(Both the form attribute and unique slot names came directly out of the extraction prototype — see §9.)*

From these two, the engine composes individual sentences and chains them into short Q/A conversations (**4–8 lines for now**, longer later). A modest pile of words plus a handful of structures yields a large space of valid practice material — all of it within scope.

**Special paradigms** — telling time, weekdays, numbers, etc. — *may* not need their own module. Current expectation: they fold naturally into the existing word + structure model (a weekday is a word with a role; a time expression is a structure). Left as a placeholder — revisit only if something genuinely doesn't slot-fill, in which case it becomes its own fixed-pattern module outside the generation path.

A useful property: because the engine generates a conversation, it already knows the expected/correct answer. That makes checking a spoken or comprehension answer far more tractable than open-ended evaluation.

---

## 3. Capture / entry experience

The primary way material enters the app is by **photographing class worksheets** (roughly 2–4 per week, mostly cleanly printed). Worksheets contain vocabulary (sometimes explained with pictures), example sentences, or both.

**Extraction pipeline:**
1. Photograph the worksheet.
2. A vision model extracts (one Claude call does OCR *and* interpretation):
   - **Vocabulary** — each word with a proposed kana reading, meaning, and role, stored in dictionary base form. **Kanji is captured only if the worksheet actually prints it** — the app never adds kanji you haven't been taught, even when the model knows it. (Clean printed Japanese extracts at high confidence.)
   - **Example sentences** — each proposed as a reusable template with typed slots and slot forms (§2).
   - **Picture-explained words** — meaning inferred from the drawing where there's no text gloss; flagged low-confidence because drawings are ambiguous.
3. **Two kinds of non-Japanese text are handled differently** (these are German-textbook worksheets):
   - *Printed* translations are legitimate worksheet content → used as the meaning, tagged as a printed gloss.
   - *Handwritten* margin notes (your own German/English scribbles) → separated out and not treated as content. The extraction step is explicitly instructed to tell printed from handwritten, and it records the handwriting it skipped so it can be surfaced later (see below).

**Prototype status:** the extraction step is validated live against real class worksheets (runnable prototype: `lib/extraction/worksheet_extractor.dart` + `tool/extract_worksheet.dart`). It reliably separates printed from handwritten text, tiers confidence, captures base-form vocab, and emits typed-slot templates. Word segmentation for scope validation (§9) is the one deferred piece.

**Review-not-autopilot:** extraction produces a *draft*, never a finished entry. The app shows what it pulled and you approve or correct each item. Correcting is much faster than typing from scratch, so friction stays low, and review is where the error-prone cases get caught.

**Confidence-tiered review** to keep review time minimal:
- High-confidence printed vocabulary → pre-approved by default.
- Lower-confidence items → flagged for your attention: template/slot guesses, and picture-derived meanings (drawings are ambiguous — "run" vs "jog", "happy" vs "smiling").

**Deduplication:** when a word already exists in the store, the app attaches the new example sentence to the existing entry rather than creating a duplicate. Your vocabulary stays clean and your set of example sentences per word grows over time.

**Handwritten gloss surfacing (lightweight, worth doing early):** the extractor already records the handwritten notes it skipped, so the review screen can show a scribbled German/English gloss next to the item for one-tap acceptance. Live testing showed this matters less than feared for *common* words — the model fills those meanings from general knowledge — but for genuinely ambiguous or picture-only items, your own margin note is often the clearest record. Cheap because the data is already captured; still a refinement, not a blocker.

---

## 4. Display

Default rendering is **kanji with furigana** (the small kana reading shown above/beside the kanji).

Furigana is a **toggle**, not a fixed mode. Early on you read the kana and absorb kanji shapes passively; later you hide the furigana to test whether the kanji readings have actually stuck. "Kanji + furigana" is the default state of that switch.

This is what drives the three-layer vocabulary data model in §2 — the kana reading layer exists precisely to render furigana and feed speech.

**Rendering approach (de-risked early).** Flutter has no built-in ruby-text widget, and furigana quality matters a lot for the learning goal, so rendering is treated as an explicit early spike (§8). Readings are rendered **per token, aligned to the vocab entry each word maps to** — not per character — which keeps layout tractable (each token is a small reading-over-base stack, composed into a wrapping line). The per-token mapping comes from the generation response (§10.3); the reading itself always comes from the authoritative store, never the model.

---

## 5. Exercises

Three exercise types, spanning the three skills the app covers. (Writing is out of scope — see §8.)

**Reading** — the app renders a generated conversation on the page (kanji + furigana toggle); you read and comprehend it.

**Listening** — the same generated conversations played through text-to-speech; you listen and comprehend. Side benefit: hearing the TTS read exactly what's in your data is a good way to catch errors in your kana readings.

**Speaking (challenge / response)** — the app prompts you with a question, you answer **out loud**, and the app records your speech and runs recognition to check whether you produced the right answer. Made tractable because the engine already knows the expected response (§2).

**Always surface the raw STT transcript** alongside the verdict. A wrong/empty result has two distinct causes — you mispronounced, *or* speech-to-text misheard a correct utterance (likely with beginner prosody). Showing what the recognizer actually heard keeps an STT failure from reading as "you got it wrong," and is a fast debugging signal while calibrating.

*Calibration caveat:* recognizing a beginner's imperfect pronunciation is genuinely hard. The first version of speaking-check should be treated as something to tune (how strict the match is) rather than something expected to work perfectly out of the gate.

---

## 6. Spaced repetition & stats

**Spaced repetition (SRS)** schedules review of vocabulary and structures by how well you know each item, surfacing material right before you'd forget it. This is the retention workhorse the class itself won't do for you. It layers in once exercises are generating data — not needed on day one.

**Progress stats** — deliberately simple, all derived from data the app already collects:
- **Growth** — count of words and structures learned over time (mirrors class progress; motivating).
- **Knowledge strength** — rough split of solid vs. shaky items, from SRS data. Doubles as a "what to review" signal.
- **Consistency** — a streak or simple calendar of which days you practiced.
- **Speaking accuracy** — trend of how often spoken answers are understood and correct.

---

## 7. Out of scope

**Writing / handwriting output** is intentionally excluded. Handwriting practice stays in the physical class via textbook drills, which is better for retention anyway. The app covers reading, listening, and speaking only.

The app also doesn't try to be a dictionary or content library of its own — its unique value is the class-aligned capture-and-review loop, so it should lean on existing data sources and TTS rather than authoring raw content.

---

## 8. Build order

Sequenced so each piece de-risks the next.

**0. Foundation — data model + structure library.** Vocabulary tagged by role with kanji/kana/meaning layers and the kana-only flag; templates with typed slots (each slot typed by role *and* conjugation form, §2). Nothing works until this exists.

**1. Capture flow.** Photo → extraction → confidence-tiered review draft → dedup. This is what keeps the app fed; build it early and invest in making structure/slot entry easy. *The extraction call is already prototyped and validated against real worksheets (`lib/extraction/`, `tool/extract_worksheet.dart`); what remains is the review/dedup UI and wiring it to the data model.*

**2. Reading exercise.** Exercises the entire engine with no audio. The cheapest test of the riskiest assumption: *does the engine generate good, grammatical Japanese?* If slot typing is too loose, reading reveals it immediately. Also a genuinely useful standalone milestone. **Includes a furigana-rendering spike** — prove the per-token kanji-over-kana layout (§4) works and looks right before building on it, since furigana is the default display mode and central to the learning goal.

**3. Listening exercise.** Small addition once reading works — generated conversations through TTS. Side benefit of catching kana-reading errors.

**4. Speaking exercise.** Highest effort and uncertainty (mic handling, speech recognition, fuzzy matching). Build last, on a proven engine and trusted content. Expect to calibrate.

**5. SRS + stats.** Layer in once exercises produce data.

**6. Offline mode (later).** A toggle that disables online-only features (generation, TTS, STT) so the app is usable with limited or no connectivity — falling back to the generated-content cache (§10.3) for reading and listening of already-generated material. Design the service layer for this from the start (every online call behind an interface that can report "unavailable offline"), but build the actual mode once the exercises exist.

**Special paradigms** (time, weekdays, numbers) — expected to fold into the word + structure model (§2), so likely no separate build step. Revisit only if something doesn't slot-fill.

---

## 9. Things to calibrate / open items

- **Speaking-check strictness** — how forgiving to be with imperfect pronunciation. Needs tuning with real use.
- **Template/slot inference quality** — *validated against real worksheets and good.* The model reliably generalises printed sentences into typed-slot templates; the prototype also surfaced two refinements now baked in — unique slot names and a per-slot conjugation **form** (§2). The review step remains the safety net for the occasional cosmetic OCR artifact (e.g. a stray comma in `ではありません`).
- **Picture-meaning ambiguity** — drawings flagged for review rather than auto-accepted.
- **Print vs. handwriting separation** — *validated:* across the test worksheets the extractor kept dense handwritten German out of the vocabulary while still using *printed* German glosses as meanings. Explicit instruction to the extraction step; soft skip caught by review if it slips.
- **Word segmentation / lemmatization** — scope validation (§10.3) checks generated words against the known-vocab set. Japanese has no spaces and conjugates, so this needs morphological segmentation + lemmatization, not string matching. *Not a problem at beginner stage* (class worksheets arrive already segmented and conjugation is minimal early), but it grows with the course. Solvable in Dart (FFI binding to MeCab, or a lighter pure-Dart tokenizer), but the mature analyzers are C/Java — if that binding proves painful, it is the single strongest argument for a thin backend (§10.1). Keep the validation layer behind an interface so it can move server-side without rearchitecting.
- **Contextual reading validation** — distinct from scope leakage. Kanji readings are context-dependent (日 = にち / ひ / か), and the app picks furigana from the store via the model's vocab-entry mapping. A lightweight semantic check — feed the rendered sentence (kanji + the chosen readings) back and ask "are these readings correct in this context?" — catches a wrong vocab-entry mapping or a context-wrong reading before it reaches the screen. Worthwhile precisely because the model's self-reported mapping is *not* an independent check (§10.3).
- **Generation quality gate (dev-time)** — during development, cross-check generated Japanese against the Google Cloud Translation API as a cheap external signal until confidence in the engine is established. A development aid, not a production dependency.

---

## 10. Tech stack & architecture

**Constraints shaping these choices:** single user (me), no concern for cost or traffic volume, software engineer building it. Heavy/complex capabilities (vision, generation, speech) are offloaded to third-party APIs rather than built in-house.

### 10.1 Client

- **Flutter + Dart** — single codebase, familiar to me.
- **Architecture:** fully client-side (mobile-only). The app talks directly to the third-party APIs and stores all data locally. No backend.
  - *Why mobile-only:* single user, single device. A backend would add hosting, a server database, a deploy pipeline, and monitoring — real operational complexity for one person — in exchange for benefits this project doesn't need yet (server-held keys, multi-device sync, central batch jobs). Not worth it now.
  - *Caveat 1 — keys:* API keys embedded in a client binary are extractable. Acceptable for a personal single-device app. If that ever changes, the standard upgrade is a thin serverless proxy that holds the keys.
  - *Caveat 2 — native libraries:* the one thing that could legitimately force a backend is a native dependency with no good Dart story — most plausibly a morphological analyzer for word segmentation (§9). To keep that option cheap, **put every third-party call and the validation/segmentation step behind an interface**, so a single component can later move server-side (thin serverless proxy) without rearchitecting the app.

### 10.2 Capability → service mapping

The split: **Claude (Anthropic) handles all language intelligence; Google handles all audio I/O.**

| Capability | Service | Notes |
|---|---|---|
| Worksheet extraction | **Claude** (vision + structured/JSON output) | One call does OCR *and* interpretation — reading, meaning, role, template inference. |
| Conversation generation | **Claude** (Messages API, JSON output) | Constrained to known vocab + structures injected as context. |
| Speaking-answer grading | **Claude** | Semantic comparison of STT transcript vs. expected answer — more forgiving than string match. |
| TTS (Japanese speech) | **Google Cloud Text-to-Speech** | Chosen deliberately for natural voice quality, which is a priority. Not the OS TTS. |
| STT (speaking exercise) | **Google Cloud Speech-to-Text** | Chosen for recognition quality. |

### 10.3 AI generation engine

Generation is **AI-driven**, not deterministic template-filling. The vocabulary store and structure library serve as **constraint context** injected into the generation prompt ("generate a natural N-line conversation using only these words and patterns"). The LLM supplies naturalness and grammatical glue; the data model is the leash that keeps output in scope.

Decisions baked in:

- **Structured outputs everywhere** — *confirmed.* Both extraction and generation use the API's structured-output mode (a JSON schema via `output_config.format`, or a strict tool) rather than asking for JSON in the prompt and hoping. This guarantees parseable responses for the extraction draft (vocab + typed slots) and the generation response (kanji text + per-word vocab-entry mapping).
- **Output validation against scope leakage** — *confirmed.* Generated output is segmented and every content word is checked (by base form) against the known-vocab set. On an out-of-vocabulary hit, regenerate or flag. This preserves the "only what I've learned" guarantee, which a prompt constraint alone can't fully ensure. (The segmentation this requires is the open item in §9.)
- **Furigana from the vocab store** — *confirmed.* Furigana is rendered from the authoritative readings already in the vocab store (reviewed at import), **not** from LLM-generated readings, which can be wrong on ambiguous kanji. The model returns kanji plus which vocab entries each word used; the app renders readings from the store and lays them out per token (§4).
- **Contextual reading validation** — a second, independent check on the chosen readings. The model's self-reported vocab-entry mapping is convenient for furigana but is *not* an independent verification of either scope or reading correctness — it's the model vouching for itself. A lightweight semantic pass (feed the rendered kanji + chosen readings back: "are these readings right in this context?") catches a mis-mapped entry or a context-wrong reading (日 = にち / ひ / か) before it's shown. See §9.
- **Prompt caching for the constraint context** — the vocab + structure library injected into every generation call is a large, stable prefix that changes only when new material is imported. Cache it (`cache_control`) so repeated generations pay ~10% of the input cost for that prefix and run faster. Low volume makes the cost savings modest, but it's cheap to set up and the latency win helps the interactive exercises — treat it as a first-class part of the generation path, not an afterthought. (Distinct from the local generated-content cache below.)
- **Generated-content cache (reconciles AI generation with SRS)** — AI generation produces a fresh sentence each call, but spaced repetition needs *stable items* to reschedule. Each generated conversation is therefore persisted as a first-class cached object, tagged with the vocab and structures it exercises. SRS schedules these cached objects. The cache also makes practice sessions instant and available offline (and is the fallback that makes the offline mode in §8 useful).

### 10.4 Model selection

Cost is irrelevant, so choose for quality/latency fit. Model identifiers rotate — verify against the docs (https://docs.claude.com) before shipping. Current strings:

- **Extraction:** most capable model (accuracy matters; volume is low). **`claude-opus-4-8`** (Opus-tier; vision + structured output).
- **Generation & grading:** fast mid-tier model (frequent, latency-sensitive). **`claude-sonnet-4-6`** (Sonnet-tier).
  - *Validate the tier choice for generation.* Generation quality is the riskiest assumption in the build (§8, step 2). Validate it on `claude-opus-4-8` first to establish a quality ceiling, then drop generation to `claude-sonnet-4-6` and confirm quality holds. Grading (semantic compare) is low-stakes and fine on the mid-tier from the start.
  - Use these exact strings — do not append date suffixes.

### 10.5 Flutter packages (starting point)

- **API calls:** `dio` (or `http`) — **there is no official Anthropic Dart SDK** (official SDKs exist only for Python, TypeScript, Java, Go, Ruby, C#, PHP). The Messages API is plain REST, and the features this app needs — vision (a base64 image content block), structured outputs (an `output_config` field), prompt caching (a `cache_control` field) — are all just JSON fields, so a typed SDK would add little here. Google APIs likewise via REST.
- **Local data:** `drift` (typed SQLite) — fits the relational data: words, structures, example sentences, SRS schedule, cached conversations.
- **Audio capture:** `record` — capture mic audio to send to Google STT.
- **Furigana rendering:** evaluate an existing ruby-text package first; fall back to a custom `RichText` / `CustomPainter` per-token layout (§4) if none is good enough. De-risk early (§8).
- **Word segmentation (when needed, §9):** an FFI binding to MeCab, or a lighter pure-Dart tokenizer — deferred until the course makes it necessary.
- **Dev-time generation check:** Google Cloud Translation API, used during development to sanity-check generated Japanese (§9) — not a production dependency.
- **State management:** implementer's choice.

---

*Spec complete. Ready to move toward implementation.*

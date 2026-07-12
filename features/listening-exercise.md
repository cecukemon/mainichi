# Feature: Listening Exercise

Closes the listening exercise described in spec §5 — the same generated conversations played through TTS — as phase 3 of the build order (§8: "small addition once reading works"). It takes §8's "small addition" literally: **listening is not a separate screen but an audio layer on the existing reading exercise**, plus a hide-text affordance that turns the same screen into a genuine hear-first comprehension exercise. Audio attaches to the generated-content cache (`features/generated-cache.md`), whose `audioPath` column has been waiting for this feature since §0.

Side benefit per spec §5: hearing the TTS read exactly what's in the store is a fast way to catch errors in the kana readings — which is why the TTS input is the store's kana, never the kanji (see §3).

---

## 1. Purpose

Listening comprehension on the material already being generated, with zero new generation machinery: every conversation that reaches the reading screen can be listened to, at the learner's own pace and speed, with the text hidden until they choose to check. No scoring, no check step — same stance as reading (D40): the value is comprehension itself.

---

## 2. Flow

**Playback controls on the reading screen.** Each conversation on the reading screen gains a compact player row: **play/pause** for the whole conversation and a **speed selector** (0.5× / 0.75× / 1.0×). Audio never starts automatically — the reading exercise is unchanged until the learner asks for sound. During playback the currently playing line is highlighted (when text is visible).

**Per-line replay.** Each line carries a small replay affordance in the speaker margin (below the speaker name). Tapping it plays just that line — this *is* the rewind control, at the only granularity that matters for a 6-line dialogue. Word taps (the lookup sheet) are untouched; the margin and the tokens are separate tap targets.

**Hide text ("listen first").** A listening-mode toggle blurs the conversation text — kanji, furigana, everything except the speaker margin. The learner plays the audio blind, then taps the blurred conversation to reveal the text and check comprehension. Blur is per-conversation state and resets to off for each new conversation; the default screen is still the reading exercise.

**First play synthesizes.** Audio is synthesized lazily, on the first play of a conversation (not at generation time): one Google Cloud TTS call per line, files written to the app's documents directory, `audioPath` set on the cached conversation row. A brief loading state on the player row covers the synthesis wait; subsequent plays (including reread from the cache) are instant from disk.

**Audio failure never blocks reading.** If synthesis fails (no key, no network, API error), the player row shows an inline error with retry — the conversation stays fully readable. Same isolation stance as the cache write-through (D49): audio is an enhancement layer, its failure is the cheaper failure.

---

## 3. Key decisions

- **Integrated into the reading screen, not a separate exercise screen.** The conversations, the layout, the lookup sheet, and the cache write-through are all shared; a separate listening screen would duplicate all of it to change only "text hidden by default." The blur toggle covers the pedagogical difference (hear first vs. read along) at near-zero cost. Spec §8 already frames listening as a small addition to a working reading exercise; this is the smallest honest reading of that.
- **Manual playback only — start, stop, per-line replay; no autoplay.** Consistent with the continuous feed's no-completion-state stance (D39): the screen doesn't decide when the learner is listening.
- **Per-line synthesis with two voices, not one whole-conversation blob.** These are two-speaker dialogues; distinct Google voices per speaker is a real comprehension aid, and per-line files make line replay trivial (no seeking) and let whole-conversation play be simple file chaining. Speaker→voice mapping is stable within a conversation (first distinct speaker → voice A, second → voice B).
- **TTS input is the store-assembled kana line, never the kanji text.** Each line's spoken text is its tokens' authoritative kana readings (the same store readings the furigana renderer uses) plus punctuation from `text` (D42). Feeding kanji would let Google apply its own readings and mask errors in the store — the spec's stated side benefit (catching kana-reading errors, §5) only works if the audio speaks *our* data. Same authority rule as everywhere else (§10.3).
- **Synthesize once at 1.0×; speed is client-side playback rate.** `just_audio`'s `setSpeed` (pitch-corrected AVPlayer rate on iOS) gives 0.5/0.75/1.0 from one synthesis — one API call per line ever, one cached file per line, and new speeds later are free. Google's `speakingRate` would mean a synthesis and a cache entry per speed for no quality gain at these factors.
- **Lazy synthesis on first play, not eager at generation time.** Eager would put a second external API in the reading success path, and a TTS failure must never block reading. Lazy also means conversations never listened to cost nothing. Trade-off accepted: a cache-reread (or, later, offline) conversation only has audio if it was played at least once while online — acceptable while offline mode itself is deferred (§6).
- **Audio files are content-addressed; `audioPath` points at a per-conversation directory.** Each line's filename is a hash of (synthesized kana string + voice id), so a kana reading corrected in the store after synthesis simply misses the cache and re-synthesizes that line on next play — stale audio self-invalidates, no invalidation bookkeeping. This mirrors the cache's render-against-current-store rule (D49): text always reflects the live store, and now audio converges to it too.
- **`TtsService` behind an interface; Google key alongside the Anthropic key.** Same pattern as `ExtractionService`/`GenerationService` (D9, D33, D46): a `dio`-based live implementation, fake-implementable for tests, able to report "unavailable" — the seam §6's offline toggle needs. The Google Cloud API key gets a second slot in the existing settings screen / Keychain store (`ApiKeyStore` pattern), read fresh per call.
- **Blur hides the text, keeps the speaker margin.** Knowing who's speaking is part of real listening (the two voices carry it anyway); the margin is scaffolding, not answer. Blur rather than collapse keeps the layout stable so reveal isn't a jarring reflow.

---

## 4. Open questions

- **Voice selection.** Which two Google voices (Neural2 vs. WaveNet, which names) sound best for beginner-paced Japanese — a calibrate-live item, like speaking-check strictness (§9). Voice ids should be constants in one place since they participate in the audio cache key.
- **Gaps between chained line files.** Whole-conversation play chains per-line files; whether the natural inter-file gap reads as a comfortable dialogue pause or needs tuning (explicit gap insertion, or SSML `<break>` within lines) — measure on device before adding machinery.
- **Kana-only input quality.** All-hiragana input occasionally risks wrong pitch accent or homograph prosody versus kanji input. Accepted deliberately (authority rule beats prosody at beginner stage), but if a rendering sounds badly off, revisit — possibly SSML `<sub>` (kanji text with forced reading) to get both.
- **Reveal granularity.** V1 reveal is whole-conversation (tap the blur once). Per-line reveal (check line by line as you listen) might be the better exercise, but it adds state and gesture ambiguity with word taps — wait for real use to ask for it.
- **Does blur state belong in listening stats?** When phase 5 asks what "practiced listening" means, "played audio while blurred" is probably the honest signal — noted here so the SRS-grading-signal question (project-status.md) can consider it; nothing captured now.

---

## 5. Status

`[in progress]` — implemented (D51, 2026-07-09), pending the live end-to-end simulator run. All pieces built in `lib/listening/`: `TtsService`/`LiveTtsService` (Google Cloud TTS via `dio`), kana line assembly reusing the reading screen's display mapping (`line_audio.dart`), the content-addressed audio file store (`audio_store.dart`, plus `ConversationStore.setAudioPath`), `ListeningController` over a `LineAudioPlayer` interface with the `just_audio` implementation, and the reading-screen UI (audio bar with play/stop + speed + listening-mode toggle, per-line margin replay, current-line highlight, blur with tap-to-reveal). Settings has the second key slot (`SecureApiKeyStore.google()`). One refinement over §2 as written: while blurred, tapping a word *reveals the text* rather than being inert — the natural check-what-you-heard gesture. Tested end to end against fakes (176/176). Remaining: the live run — real Google key, voice calibration (§4), and the chained-line gap check on device.

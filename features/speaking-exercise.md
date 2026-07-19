# Feature: Speaking Exercise

Covers the speaking exercise of spec §5 as phase 4 of the build order (§8: "highest effort and uncertainty… build last, on a proven engine and trusted content"). Designed 2026-07-19 (session 18, decision log D62–D65) as **a ladder of three modes**, each shipping on the previous one's plumbing rather than as one monolithic feature:

1. **Shadowing** — repeat each line after the TTS voice. Ungraded. Nearly free on the listening layer.
2. **Read-aloud** — read the conversation aloud line by line; grading is "did STT hear the expected words". Builds all the STT plumbing in the most controlled setting.
3. **Free conversation** — the app opens with one in-scope line, the learner replies free-form out loud, a combined Claude call grades the reply and produces the next line. The destination: the only mode that tests *production*, not reproduction.

The ladder honors §8's philosophy (each step de-risks the next): shadowing lands mic UX and recording permissions, read-aloud lands STT and the match-strictness calibration loop against *known* expected text, and free conversation then only adds the turn-based generation machinery on top of calibrated, trusted STT.

---

## 1. What "grading" means here (and what it doesn't)

**Pitch-accent grading is out of scope** (D62). Google STT normalizes pitch accent away in order to recognize words, and Claude only ever sees the transcript — neither can hear accent. What STT *does* give is an **intelligibility signal**: whether the recognizer heard the words the learner meant to say (びょういん vs. びよういん fails it honestly). All grading in this feature is built on that proxy — "was I intelligible and correct" — never on accent. True pitch-accent feedback (raw pitch-contour extraction against a TTS reference) is noted as an intriguing research direction, explicitly not a plannable feature.

Per spec §5, **the raw STT transcript is always surfaced** alongside any verdict, in every graded mode. A wrong result has two causes — mispronunciation, or STT mishearing a correct utterance with beginner prosody — and hiding the transcript makes an STT failure read as "you got it wrong". This is also the calibration instrument for match strictness (spec §9).

---

## 2. Mode 1 — Shadowing (ungraded, ships first)

A playback mode on the existing listening layer: play line → pause → the learner repeats aloud → advance to the next line. Explicitly **no recording analysis and no grading in v1** (D63) — shadowing is pedagogically well-supported even ungraded, and shipping it ungraded gets the mic permission flow and speaking UX in place without waiting on STT.

- Reuses the per-line audio files, voices, and playback controller from `lib/listening/` — the new piece is the paced advance (play, gap for the learner's repetition, next) rather than continuous playback.
- The repetition gap should be learner-controlled (tap-to-advance) rather than a timer, at least in v1 — no guessing how long a beginner needs.
- Optionally records the learner (for self-playback comparison), but even that can wait; the mode is useful with zero mic code.
- Known limitation, accepted: produces no data for phase 5's SRS and tests imitation, not production. That's what the higher rungs are for.

## 3. Mode 2 — Read-aloud (first graded mode) — *implemented, D67*

The learner reads the current conversation aloud, line by line; the app records, sends to Google Cloud Speech-to-Text, and compares the transcript against the expected line. This is the tractable shape spec §5 counted on: **the expected text is known**, so grading is transcript-vs-expected comparison, not open-ended judgment.

- **Verdict = "STT heard the right words"** (D64), shown per line as one of match / close / mismatch, with the raw transcript always visible beneath it. Match strictness is the calibration loop the spec warned about — the comparator (`gradeReadAloud`, `lib/speaking/read_aloud_grader.dart`) is a small pure function with its own tests and two documented threshold knobs (0.95 match / 0.7 close over normalized Levenshtein similarity), untuned until there's real spoken data.
- **What it compares — the load-bearing call:** Google STT for Japanese returns ordinary orthography (kanji+kana), *not* the kana the TTS speaks from. So the grader compares against each line's written `text`, **not** its `kanaLine`. Known limitation: a reading-correct but orthography-different transcript (お寿司 vs すし, 寿司 vs すし) can score below a strict match purely on character choice. This is precisely why the raw transcript is always surfaced (spec §5): the verdict is a hint, the transcript is the truth, and an orthography-only miss reads as "close — check what it heard", not a hard fail.
- Side value: with furigana off, reading aloud tests kanji **readings** — a skill no other exercise checks actively.
- STT is behind an `SttService` interface mirroring `TtsService` (`lib/speaking/stt_service.dart`, dio, key fresh per call). Cloud TTS and STT take the same API key, so the existing Google key slot is reused — no third slot.
- Mic capture is behind a `SpeechRecorder` interface (`lib/speaking/speech_recorder.dart`) over the `record` package; recordings are transient WAV input, deleted after transcription — no audio file store analogue. iOS mic permission declared in Info.plist.
- **UI:** a fourth audio-bar toggle (mic icon), mutually exclusive with shadowing and listening-mode. In read-aloud mode each line's margin shows a mic (→ stop while recording, spinner while transcribing) in place of the replay control, and the verdict badge + "Heard: …" transcript renders under the line. `ReadAloudController` (`lib/speaking/read_aloud_controller.dart`) runs one line at a time, keyed per conversation like the listening controller.

## 4. Mode 3 — Free conversation (the destination)

Turn-based spoken conversation. **The app always opens** (D65): it generates the first line and thereby sets an in-scope topic — the learner never has to invent an opening from a blank slate, and the engine keeps its authority over scope. Then, per turn: the learner replies free-form out loud → STT transcribes → **one combined Claude call** grades the reply (grammar, and does it make sense in this conversation) *and* generates the app's next line → repeat.

- **Latency stance:** turn-based, not real-time. The learner speaks, taps stop, and waits; 3–5 s of "thinking" is socially normal in conversation practice. One combined grade+next call (not two round trips), with the vocab/structure constraint prefix prompt-cached (already confirmed working), plus ~1–2 s of STT. Acceptable; no streaming machinery needed for v1.
- **Scope asymmetry:** the learner's reply is free-form and never scope-validated — but the app's next line goes through `validateScope` like any generation. Expect a **higher rejection rate** than the reading feed: the model now composes under two constraints (in scope *and* responsive to whatever the learner said). Retry handling needs to account for this; the reading screen's error-state machinery is the starting point.
- **Backfill hook:** if the learner's transcript contains an untaught word, that's a capture signal — they evidently produced it — surfaced through the D52 backfill machinery ("add this to your Bunko?") rather than treated as an error.
- **Grading verdict** is Claude's semantic judgment on the transcript (intelligibility already implied by STT having produced words). What the verdict looks like on screen (per-turn note? end-of-conversation summary?) is deliberately left to design when this rung is reached — modes 1–2 will have taught us what feedback feels right.
- **SRS cost, accepted:** the spec's original challenge/response variant existed partly for a clean per-item grading signal (known expected answer → binary correct). Free conversation yields a fuzzy, Claude-judged signal spread across whatever items the learner used. Since the SRS grading-signal question is still fully open (D40), this closes no doors — but phase 5 should know it's inheriting the fuzzier signal.

The spec §5 challenge/response mode (app asks, learner answers, engine knows the expected answer) is **not** a separate rung: free conversation subsumes it, and if the fuzzy-grading problem ever bites, constrained challenge/response is the fallback shape — same plumbing, narrower prompt.

---

## 5. Build order within the phase

1. **Shadowing mode** — *done (D66, 2026-07-19).* Built as a `shadowing` flag + `AudioStatus.awaitingRepeat` hold on the existing `ListeningController` rather than a new screen; toggle on the audio bar, "Your turn" hold row with Next line / Hear it again / Done, learner-paced (no timer), no mic code. Live simulator run pending.
2. **Read-aloud** — *done (D67, 2026-07-19).* `SttService` + `SpeechRecorder` behind interfaces (Google key slot reused, `record` package), pure `gradeReadAloud` comparator, per-line mic + verdict/transcript UI on the reading screen. Match strictness untuned by design; live device run (real mic + key) pending.
3. Free conversation (turn-based combined call, rejection handling, backfill hook, verdict UI design).

Each rung is independently shippable and independently useful; there is no need to commit to rung 3's open questions before rung 1 exists.

## 6. Open questions (deferred, not blocking rung 1)

- Read-aloud match strictness — the spec §9 calibration item; the two thresholds in `read_aloud_grader.dart` are the knobs, untuned until there's real spoken data. Related: the orthography-vs-kana comparison limitation (§3) — watch whether reading-correct-but-orthography-different transcripts produce annoying false "close"/"mismatch" verdicts in practice.
- Free-conversation verdict presentation (per-turn vs. summary) and conversation length/ending.
- Whether shadowing should record for self-comparison playback, and if so whether recordings are kept at all.
- Pitch-accent feedback — research direction only; revisit if the intelligibility proxy proves unsatisfying.

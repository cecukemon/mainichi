/// The read-aloud verdict (speaking rung 2, D67): did Google STT hear the
/// words the line was asking the learner to say?
///
/// This is deliberately a small, pure, well-tested function because match
/// strictness is *the* calibration item for this feature (spec §9,
/// features/speaking-exercise.md §1). The thresholds below are the knobs to
/// turn once there's real spoken data; nothing else here should need to move.
///
/// **What it compares, and how kanji are handled.** Google STT for Japanese
/// returns ordinary orthography (kanji + kana), not the kana the TTS speaks
/// from — and it writes common words in kanji (好き, 私) regardless of what
/// the line's own `text` used, so a word the Bunko taught kana-only (すき,
/// わたし) comes back in kanji and a naive character comparison scores a
/// *perfect* reading as merely "close". Biasing the recognizer toward kana
/// was tried and doesn't work — STT emits standard orthography anyway (D68).
///
/// So the comparison is deliberately **kanji-tolerant** (D68): a kanji in the
/// transcript is treated as an opaque stand-in for the reading it spells and
/// matches the expected kana it aligns with (including a single kanji
/// absorbing a short run of kana, 私 ↔ わたし) at no cost, while **kana still
/// has to match kana** — so a genuinely wrong reading (すき misread as きらい,
/// heard 嫌い) still trips on the surrounding kana and fails. The accepted
/// leniency: two *different* kanji can't be told apart without readings
/// (expected 本 vs a wrongly-read 水, both single kanji, look equal), so a
/// wrong reading of a kanji word whose neighbours all match can slip through.
/// This is why the raw transcript is *always* shown alongside the verdict
/// (spec §5): the verdict is a hint, the transcript is the truth.
library;

/// How close the recognized transcript was to the expected line. [match] and
/// [close] both mean "heard essentially right"; [close] flags that the
/// learner should glance at the transcript (an orthography variant or a
/// dropped particle). [mismatch] means it heard something materially
/// different (or nothing).
enum ReadAloudVerdict { match, close, mismatch }

/// Similarity at/above this is a clean [ReadAloudVerdict.match].
const double _matchThreshold = 0.95;

/// Similarity at/above this (but below [_matchThreshold]) is
/// [ReadAloudVerdict.close]; below it is [ReadAloudVerdict.mismatch].
const double _closeThreshold = 0.7;

/// Grades a recognized [transcript] against the [expected] line text. Both
/// are normalized (width-folded, whitespace and punctuation stripped) before
/// comparison, so punctuation the recognizer never emits and spacing never
/// count against the learner.
ReadAloudVerdict gradeReadAloud({
  required String expected,
  required String transcript,
}) {
  final e = normalizeForGrading(expected);
  final t = normalizeForGrading(transcript);
  if (e.isEmpty) return ReadAloudVerdict.mismatch; // nothing to grade against
  if (t.isEmpty) return ReadAloudVerdict.mismatch; // recognizer heard nothing
  if (e == t) return ReadAloudVerdict.match;

  final score = _similarity(e, t);
  if (score >= _matchThreshold) return ReadAloudVerdict.match;
  if (score >= _closeThreshold) return ReadAloudVerdict.close;
  return ReadAloudVerdict.mismatch;
}

/// Strips everything that shouldn't count toward the verdict: surrounding and
/// internal whitespace, and Japanese/ASCII punctuation. Full-width ASCII and
/// half-width kana are folded to a canonical form so width choices by the
/// recognizer don't register as differences.
String normalizeForGrading(String s) {
  final buffer = StringBuffer();
  for (final rune in s.runes) {
    final folded = _fold(rune);
    if (folded == null) continue; // dropped (space or punctuation)
    buffer.writeCharCode(folded);
  }
  return buffer.toString();
}

/// Returns the canonical code point for [rune], or null if it should be
/// dropped from the comparison (whitespace and punctuation).
int? _fold(int rune) {
  // Whitespace (ASCII + ideographic space).
  if (rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D ||
      rune == 0x3000) {
    return null;
  }
  // Full-width ASCII (！-～, U+FF01–U+FF5E) → half-width ASCII.
  if (rune >= 0xFF01 && rune <= 0xFF5E) {
    return _fold(rune - 0xFEE0);
  }
  // ASCII punctuation and symbols.
  if ((rune >= 0x21 && rune <= 0x2F) ||
      (rune >= 0x3A && rune <= 0x40) ||
      (rune >= 0x5B && rune <= 0x60) ||
      (rune >= 0x7B && rune <= 0x7E)) {
    return null;
  }
  // Common Japanese punctuation: 、。，．・「」『』（）！？…〜ー is kept
  // (ー is a real kana length mark, part of pronunciation), the rest dropped.
  const jpPunct = {
    0x3001, // 、
    0x3002, // 。
    0xFF0C, // ， (already folded above, defensive)
    0x30FB, // ・
    0x300C, 0x300D, // 「」
    0x300E, 0x300F, // 『』
    0xFF08, 0xFF09, // （）
    0x2026, // …
    0x301C, // 〜
  };
  if (jpPunct.contains(rune)) return null;
  return rune;
}

/// The most expected kana a single kanji is allowed to absorb for free (私 →
/// わたし is 3). Bounds the leniency: without it a lone kanji could match an
/// arbitrarily long line for free; capped, a stray kanji can only account for
/// a plausible one-word reading and the rest of the line still has to line up.
const int _maxKanjiSpan = 4;

/// Kanji-tolerant similarity in [0, 1]: 1 − editDistance / longerLen, where a
/// kanji matches the kana it stands for at no cost (see the library doc).
double _similarity(String a, String b) {
  if (a == b) return 1.0;
  final ra = a.runes.toList(), rb = b.runes.toList();
  final longer = ra.length >= rb.length ? ra.length : rb.length;
  if (longer == 0) return 1.0;
  return 1.0 - _tolerantDistance(ra, rb) / longer;
}

/// CJK ideograph (an opaque reading, matched freely against the kana it
/// spells): the main block + Extension A, plus the iteration mark 々. Kana
/// and katakana are intentionally excluded — they must match literally.
bool _isKanji(int rune) =>
    (rune >= 0x3400 && rune <= 0x9FFF) || rune == 0x3005;

/// Cost of aligning one expected rune with one transcript rune: free when they
/// match, free when either is a kanji standing in for the other's kana, but
/// charged for two *different* kanji (no readings to compare) and for two
/// mismatched kana (the skeleton that catches a genuinely wrong reading).
int _subCost(int e, int t) {
  if (e == t) return 0;
  final ek = _isKanji(e), tk = _isKanji(t);
  if (ek && tk) return 1; // different kanji — can't assume the same reading
  if (ek || tk) return 0; // kanji vs kana — opaque reading, free
  return 1; // two different kana
}

/// Edit distance with the kanji rules, over rune lists [e] (expected) and [t]
/// (transcript). Beyond ordinary substitute/insert/delete, a kanji may absorb
/// a run of up to [_maxKanjiSpan] runes on the other side for free, so a
/// single kanji can stand for a multi-kana reading (私 ↔ わたし).
int _tolerantDistance(List<int> e, List<int> t) {
  final m = e.length, n = t.length;
  if (m == 0) return n;
  if (n == 0) return m;
  final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
  for (var i = 0; i <= m; i++) {
    dp[i][0] = i;
  }
  for (var j = 0; j <= n; j++) {
    dp[0][j] = j;
  }
  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      var best = dp[i - 1][j - 1] + _subCost(e[i - 1], t[j - 1]);
      final del = dp[i - 1][j] + 1;
      if (del < best) best = del;
      final ins = dp[i][j - 1] + 1;
      if (ins < best) best = ins;
      // A kanji absorbs a run of *kana* on the other side for free (私 ↔
      // わたし) — but never another kanji: stopping at one keeps a kanji from
      // swallowing a dropped particle that sits before its own exact match
      // (食 must not eat the を in すしを食べます vs すし食べます).
      if (_isKanji(t[j - 1])) {
        final maxK = i < _maxKanjiSpan ? i : _maxKanjiSpan;
        for (var k = 1; k <= maxK; k++) {
          if (_isKanji(e[i - k])) break;
          if (dp[i - k][j - 1] < best) best = dp[i - k][j - 1];
        }
      }
      if (_isKanji(e[i - 1])) {
        final maxK = j < _maxKanjiSpan ? j : _maxKanjiSpan;
        for (var k = 1; k <= maxK; k++) {
          if (_isKanji(t[j - k])) break;
          if (dp[i - 1][j - k] < best) best = dp[i - 1][j - k];
        }
      }
      dp[i][j] = best;
    }
  }
  return dp[m][n];
}

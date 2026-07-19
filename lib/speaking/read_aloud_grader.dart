/// The read-aloud verdict (speaking rung 2, D67): did Google STT hear the
/// words the line was asking the learner to say?
///
/// This is deliberately a small, pure, well-tested function because match
/// strictness is *the* calibration item for this feature (spec §9,
/// features/speaking-exercise.md §1). The thresholds below are the knobs to
/// turn once there's real spoken data; nothing else here should need to move.
///
/// **What it compares, and the known limitation.** Google STT for Japanese
/// returns ordinary orthography (kanji + kana), not the kana the TTS speaks
/// from — so the expected side is the line's written `text`, normalized, not
/// its `kanaLine`. That makes the comparison vulnerable to *reading-correct
/// but orthography-different* transcripts (お寿司 vs すし, 寿司 vs すし): a
/// perfectly pronounced line can score below a strict match purely because
/// the recognizer chose different characters for the same sound. This is why
/// the raw transcript is *always* shown alongside the verdict (spec §5): the
/// verdict is a hint, the transcript is the truth, and an orthography-only
/// miss reads as "close, see what it heard" rather than a hard fail.
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

/// Normalized Levenshtein similarity in [0, 1]: 1 − editDistance / longerLen.
double _similarity(String a, String b) {
  if (a == b) return 1.0;
  final longer = a.length >= b.length ? a.length : b.length;
  if (longer == 0) return 1.0;
  return 1.0 - _levenshtein(a, b) / longer;
}

int _levenshtein(String a, String b) {
  final la = a.length, lb = b.length;
  if (la == 0) return lb;
  if (lb == 0) return la;
  var prev = List<int>.generate(lb + 1, (i) => i);
  var curr = List<int>.filled(lb + 1, 0);
  for (var i = 1; i <= la; i++) {
    curr[0] = i;
    for (var j = 1; j <= lb; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final del = prev[j] + 1;
      final ins = curr[j - 1] + 1;
      final sub = prev[j - 1] + cost;
      curr[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[lb];
}

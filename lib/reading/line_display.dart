/// Maps a generated line to display tokens for the reading screen.
///
/// Punctuation authority is the line's `text`, not the token list (D42): the
/// model sometimes omits 、 from `tokens` while `text` has it, so tokens are
/// located inside `text` and whatever they don't cover renders as plain
/// segments. Tokens only supply the per-word furigana mapping and tap targets.
library;

import '../generation/conversation_generator.dart';
import '../japanese/okurigana.dart';

class DisplayToken {
  const DisplayToken(this.surface, this.segments, [this.entry]);

  final String surface;
  final List<FuriganaSegment> segments;

  /// The vocab entry behind this token — the tap target's data. Null for
  /// glue, punctuation, and anything whose surface can't be reconciled with
  /// its claimed entry (renders plain, per the okurigana module's contract).
  final SeedWord? entry;

  bool get isTappable => entry != null;
}

/// The kana reading of a displayed surface, for the lookup sheet's reading
/// line (食べません → たべません): ruby where a segment has one, the (kana)
/// base otherwise.
String readingOf(List<FuriganaSegment> segments) =>
    segments.map((s) => s.ruby ?? s.base).join();

List<DisplayToken> displayTokens(GenLine line, GenerationSeed seed) {
  final text = line.text;
  final result = <DisplayToken>[];
  var pos = 0;

  void plain(String s) {
    if (s.isNotEmpty) result.add(DisplayToken(s, [FuriganaSegment(s)]));
  }

  for (final token in line.tokens) {
    final idx = text.indexOf(token.surface, pos);
    if (idx >= 0) {
      plain(text.substring(pos, idx));
      pos = idx + token.surface.length;
    }
    // idx < 0 (token absent from text) shouldn't survive validateScope's
    // reconstruction check; render the surface anyway rather than drop it.

    final entry = token.isGlue ? null : seed.vocabById[token.vocabId];
    if (entry == null) {
      plain(token.surface);
      continue;
    }
    final segments = furiganaSegments(
      surface: token.surface,
      kana: entry.kana,
      kanji: entry.kanji,
      conjugates: conjugatingRoles.contains(entry.role),
    );
    result.add(segments == null
        ? DisplayToken(token.surface, [FuriganaSegment(token.surface)])
        : DisplayToken(token.surface, segments, entry));
  }
  plain(text.substring(pos));
  return result;
}

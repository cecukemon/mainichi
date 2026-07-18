/// Closed-vocabulary factoring segmenter (spec §9, the D6 endgame).
///
/// Factors a line of generated text into taught material — vocabulary base
/// forms, taught conjugations of them, the grammar-glue allowlist, and
/// punctuation — by greedy longest-match with backtracking, the same trick
/// `_glueFactoring` already uses for glue alone. Because the vocabulary is
/// small and *closed* (the premise of the app), this replaces general
/// morphological analysis: every character of the line must trace to taught
/// material, fully independently of the model's self-reported token mapping.
///
/// Conjugation stems are the written base form minus its final kana — the
/// same last-char-only insight behind `okurigana.dart` (conjugation touches
/// only the final syllable at this level). Endings are generated per taught
/// form; since a verb's class (godan/ichidan) isn't stored, both candidate
/// connectors are generated and accepted. That is deliberately slightly
/// over-permissive (たべります would pass), but everything accepted is still
/// composed purely of taught stems + taught endings — the check's actual
/// guarantee. Same curation discipline as `knownGrammarGlue`: forms not
/// mapped yet (te-form, plain negative — both irregular-prone) flag as
/// unmatched when they first appear, which is the prompt to extend the map.
library;

import 'package:meta/meta.dart';

/// One taught word, as the segmenter needs it. Deliberately not the
/// generator's `SeedWord` or the DB row — this module stays dependency-free
/// for its three callers (scope validation, and later capture/import checks).
@immutable
class LexiconEntry {
  const LexiconEntry({
    required this.id,
    required this.kana,
    this.kanji = '',
    required this.role,
  });

  final int id;
  final String kana;
  final String kanji;
  final String role;
}

enum SegmentKind { word, glue, punctuation }

@immutable
class LineSegment {
  const LineSegment(this.surface, this.kind, {this.wordId});

  final String surface;
  final SegmentKind kind;

  /// The lexicon entry this segment traces to; null for glue/punctuation.
  final int? wordId;

  @override
  String toString() =>
      '$surface(${kind.name}${wordId == null ? '' : '#$wordId'})';
}

@immutable
class SegmentationResult {
  const SegmentationResult.ok(List<LineSegment> this.segments)
      : unmatchedFrom = null;
  const SegmentationResult.fail(String this.unmatchedFrom) : segments = null;

  final List<LineSegment>? segments;

  /// On failure: the remainder of the line from the furthest position any
  /// factoring attempt reached — the first material nothing taught explains.
  final String? unmatchedFrom;

  bool get ok => segments != null;
}

/// Polite-form connector by the base form's final kana (the godan i-row).
/// Ichidan verbs (final る) connect with nothing; both candidates are tried.
const Map<String, String> _iRow = {
  'う': 'い', 'く': 'き', 'ぐ': 'ぎ', 'す': 'し', 'つ': 'ち',
  'ぬ': 'に', 'ぶ': 'び', 'む': 'み', 'る': 'り',
};

/// Suffixes per taught slot form. Extend as the course teaches new forms;
/// an unmapped form simply never matches, so its first worksheet flags
/// loudly rather than passing silently. te-form and the verbs' plain
/// negative are deliberately unmapped for now (both need per-class
/// irregular handling, e.g. 行く→行って).
const Map<String, List<String>> _verbSuffixes = {
  'polite': ['ます'],
  'polite_negative': ['ません'],
  'past': ['ました'],
};

Iterable<({String form, String surface})> _conjugatedForms(
    LexiconEntry e, Set<String> taughtForms) sync* {
  final bases = [e.kana, if (e.kanji.isNotEmpty) e.kanji];
  if (e.role == 'verb') {
    for (final base in bases) {
      if (base.length < 2) continue;
      final last = base[base.length - 1];
      final stem = base.substring(0, base.length - 1);
      final connectors = [
        if (last == 'る') '', // ichidan candidate
        if (_iRow.containsKey(last)) _iRow[last]!, // godan candidate
      ];
      for (final MapEntry(key: form, value: suffixes) in _verbSuffixes.entries) {
        if (!taughtForms.contains(form)) continue;
        for (final connector in connectors) {
          for (final suffix in suffixes) {
            yield (form: form, surface: '$stem$connector$suffix');
          }
        }
      }
    }
  } else if (e.role == 'i_adjective' && taughtForms.contains('negative')) {
    // おもしろい → おもしろく (negation continues with glue ありません).
    for (final base in bases) {
      if (base.endsWith('い') && base.length >= 2) {
        yield (form: 'negative', surface: '${base.substring(0, base.length - 1)}く');
      }
    }
  }
}

/// Characters treated as sentence punctuation everywhere scope validation and
/// segmentation run. Both the full-width Japanese marks and their ASCII
/// equivalents, since the model emits either (e.g. a line ending in `?` vs
/// `？`, observed live 2026-07-19). Meant to be dropped into a regex character
/// class as `[$punctuationChars]`; `\s` covers whitespace, `　` the ideographic
/// space explicitly.
const String punctuationChars = r'、。，．・…？！?!.,\s　';

final RegExp _leadingPunct = RegExp('^[$punctuationChars]+');
final RegExp _trailingPunct = RegExp('[$punctuationChars]+\$');

/// Identifies which taught form a conjugated [surface] of [entry] is —
/// the slot-form wire value ('polite', 'polite_negative', ...) — or null
/// when the surface is the base form itself or nothing taught matches.
///
/// This is the reading screen's source for the lookup sheet's form
/// annotation: derived from the store's base forms and the taught-forms
/// inventory, never from the model's self-report (spec §10.3 authority
/// rule). Null degrades gracefully — the sheet simply shows no form line.
String? detectTaughtForm(
  String surface, {
  required LexiconEntry entry,
  required Set<String> taughtForms,
}) {
  final core = surface
      .replaceFirst(_leadingPunct, '')
      .replaceFirst(_trailingPunct, '');
  if (core.isEmpty || core == entry.kana || core == entry.kanji) return null;
  for (final c in _conjugatedForms(entry, taughtForms)) {
    if (c.surface == core) return c.form;
  }
  return null;
}

final RegExp _punctuationRun = RegExp('^[$punctuationChars]+');

/// Factors [text] into taught material, or reports where it got stuck.
///
/// [taughtForms] is the set of slot-form wire values the structure library
/// actually uses (`dictionary`, `polite`, ...) — a conjugation is only in
/// scope once a taught pattern demands it. [glue] is the grammar allowlist
/// (`knownGrammarGlue` for generation).
SegmentationResult factorLine(
  String text, {
  required List<LexiconEntry> lexicon,
  required Set<String> taughtForms,
  required Set<String> glue,
}) {
  // Every matchable piece, longest first so the greedy pass prefers whole
  // words over fragments (backtracking handles the rare wrong greedy pick).
  final pieces = <LineSegment>[
    for (final g in glue) LineSegment(g, SegmentKind.glue),
    for (final e in lexicon) ...[
      LineSegment(e.kana, SegmentKind.word, wordId: e.id),
      if (e.kanji.isNotEmpty) LineSegment(e.kanji, SegmentKind.word, wordId: e.id),
      for (final c in _conjugatedForms(e, taughtForms))
        LineSegment(c.surface, SegmentKind.word, wordId: e.id),
    ],
  ]..sort((a, b) => b.surface.length.compareTo(a.surface.length));

  final dead = <int>{}; // positions proven unfactorable — prunes backtracking
  var furthest = 0;

  List<LineSegment>? factor(int pos) {
    if (pos >= text.length) return const [];
    if (dead.contains(pos)) return null;
    if (pos > furthest) furthest = pos;

    final punct = _punctuationRun.firstMatch(text.substring(pos));
    if (punct != null) {
      final run = punct.group(0)!;
      final rest = factor(pos + run.length);
      if (rest != null) {
        return [LineSegment(run, SegmentKind.punctuation), ...rest];
      }
      dead.add(pos);
      return null;
    }

    for (final piece in pieces) {
      if (piece.surface.isEmpty || !text.startsWith(piece.surface, pos)) continue;
      final rest = factor(pos + piece.surface.length);
      if (rest != null) return [piece, ...rest];
    }
    dead.add(pos);
    return null;
  }

  final segments = factor(0);
  if (segments != null) return SegmentationResult.ok(segments);
  return SegmentationResult.fail(text.substring(furthest));
}

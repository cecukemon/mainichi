/// Stem/okurigana handling for furigana rendering and surface validation
/// (spec §4 furigana, decision D5 per-token rendering).
///
/// The store keeps every word's base-form `kana` (いく) and `kanji` (行く).
/// Their **longest common kana suffix** is the okurigana; what precedes it is
/// the kanji stem (行) and its reading (い). For regular verbs and adjectives
/// the kanji stem is invariant across conjugation — only the kana tail changes
/// (行きます, 行きません) — so a conjugated surface decomposes into
/// stem + pure-kana tail with no conjugation engine at all: ruby the stem
/// reading over the stem, render the tail plain.
///
/// This is deliberately a pure, Flutter-free module with three consumers:
/// the furigana widget (`lib/reading/`), the scope validator's surface↔entry
/// consistency check, and (later) the closed-vocabulary factoring segmenter,
/// which needs exactly this stem inventory (see project-status.md open
/// questions).
///
/// Known limitation, deferred: reading-*changing* irregulars (来る/くる →
/// 来ます/きます — the stem reading く is wrong under 来 in conjugated forms).
/// This only bites once 来 is actually taught in kanji; the kanji-only-if-
/// printed rule (spec §3) protects until then. Add an override when it arrives.
library;

import 'package:meta/meta.dart';

/// One display run of a token: [base] text with an optional [ruby] reading
/// rendered above it. A token maps to 1–3 segments (stem + tail, plus any
/// surrounding punctuation).
@immutable
class FuriganaSegment {
  const FuriganaSegment(this.base, [this.ruby]);

  final String base;
  final String? ruby;

  @override
  bool operator ==(Object other) =>
      other is FuriganaSegment && other.base == base && other.ruby == ruby;

  @override
  int get hashCode => Object.hash(base, ruby);

  @override
  String toString() => ruby == null ? base : '$base[$ruby]';
}

/// A token surface reconciled against the vocab entry it claims to be.
///
/// [base] is the part attributed to the entry and [trailing] the grammar glue
/// the model fused onto the end of the token (D74) — empty for a cleanly
/// tokenized surface. Callers that care about word boundaries (the reading
/// screen's tap targets) render the two separately; callers that only ask
/// "does this reconcile?" (the scope validator) just check for null.
@immutable
class SurfaceMatch {
  const SurfaceMatch({
    required this.base,
    required this.segments,
    required this.trailing,
  });

  /// The leading part of the surface that belongs to the entry (先生).
  final String base;

  /// Furigana display segments for [base] alone.
  final List<FuriganaSegment> segments;

  /// Fused grammar glue and any trailing punctuation (は、), or '' when the
  /// surface needed no peeling.
  final String trailing;

  bool get hadFusedGlue => trailing.isNotEmpty;
}

/// Base-form decomposition of a word's kanji form against its kana reading.
@immutable
class OkuriganaSplit {
  const OkuriganaSplit({
    required this.kanjiStem,
    required this.stemReading,
    required this.okurigana,
  });

  /// The written stem, e.g. 行 (may itself contain kana, e.g. 田 for 田なか).
  final String kanjiStem;

  /// The reading of [kanjiStem] alone, e.g. い.
  final String stemReading;

  /// The base form's kana tail shared by both forms, e.g. く. Empty for words
  /// with no trailing kana (鈴木).
  final String okurigana;
}

/// Longest-common-suffix split of a base form. [kana] is all kana by
/// definition, so the common suffix is necessarily kana.
OkuriganaSplit splitOkurigana({required String kana, required String kanji}) {
  var common = 0;
  while (common < kana.length &&
      common < kanji.length &&
      kana[kana.length - 1 - common] == kanji[kanji.length - 1 - common]) {
    common++;
  }
  return OkuriganaSplit(
    kanjiStem: kanji.substring(0, kanji.length - common),
    stemReading: kana.substring(0, kana.length - common),
    okurigana: kana.substring(kana.length - common),
  );
}

final RegExp _kanaOnly = RegExp(r'^[぀-ゟ゠-ヿー]+$');

bool _isPureKana(String s) => s.isNotEmpty && _kanaOnly.hasMatch(s);

/// Decomposes a token [surface] into furigana display segments, given the
/// vocab entry it claims to be ([kana]/[kanji] base forms) and whether that
/// entry's role [conjugates] (verb / i-adjective / na-adjective).
///
/// Returns null when the surface cannot be reconciled with the entry — a
/// hallucinated surface or a wrong vocab id. Callers treat null as: renderer
/// falls back to the plain surface; validator flags a violation.
List<FuriganaSegment>? furiganaSegments({
  required String surface,
  required String kana,
  required String kanji,
  required bool conjugates,
}) =>
    matchSurface(
      surface: surface,
      kana: kana,
      kanji: kanji,
      conjugates: conjugates,
    )?.segments;

/// Longest fused tail the glue peel will consider, in characters. Bounds the
/// backtracking factorization below and keeps the peel to plausible particle
/// runs (は, には, ますか) rather than swallowing half a line.
const int _maxFusedGlueChars = 6;

/// Reconciles a token [surface] with the vocab entry it claims to be, the way
/// [furiganaSegments] does, but additionally tolerating grammar glue the model
/// fused into the content token (D74) when [trailingGlue] supplies the known
/// glue inventory.
///
/// The peel is a **fallback only** — attempted after a direct match fails, so a
/// legitimately tokenized conjugation is never split apart just because its
/// ending also appears in the glue set (飲みます stays one token even though
/// ます is glue). Returns null when nothing reconciles the surface with the
/// entry, exactly as before.
SurfaceMatch? matchSurface({
  required String surface,
  required String kana,
  required String kanji,
  required bool conjugates,
  Set<String> trailingGlue = const {},
}) {
  // Peel surrounding punctuation into plain segments.
  var core = surface;
  var lead = '';
  var trail = '';
  final leadMatch = RegExp(r'^[、。？！・\s　]+').firstMatch(core);
  if (leadMatch != null) {
    lead = leadMatch.group(0)!;
    core = core.substring(lead.length);
  }
  final trailMatch = RegExp(r'[、。？！・\s　]+$').firstMatch(core);
  if (trailMatch != null) {
    trail = trailMatch.group(0)!;
    core = core.substring(0, core.length - trail.length);
  }
  if (core.isEmpty) return null; // pure punctuation is not a content word

  List<FuriganaSegment> wrap(List<FuriganaSegment> match, String tail) => [
        if (lead.isNotEmpty) FuriganaSegment(lead),
        ...match,
        if (tail.isNotEmpty) FuriganaSegment(tail),
      ];

  final direct = _matchCore(core, kana, kanji, conjugates);
  if (direct != null) {
    return SurfaceMatch(
      base: surface,
      segments: wrap(direct, trail),
      trailing: '',
    );
  }
  if (trailingGlue.isEmpty) return null;

  // Fused-glue fallback: walk split points from the longest head down, taking
  // the first where the head reconciles with the entry and the tail factors
  // entirely into known glue. Longest head first keeps the peel minimal — a
  // defensive ordering more than an observable one, since an entry's own match
  // rule usually admits just one head (a non-conjugating entry must match its
  // kana exactly, and a conjugating one absorbs any kana tail directly, never
  // reaching this loop at all).
  for (var i = core.length - 1;
      i >= 1 && core.length - i <= _maxFusedGlueChars;
      i--) {
    final tail = core.substring(i);
    if (!_factorsIntoGlue(tail, trailingGlue)) continue;
    final head = core.substring(0, i);
    final segments = _matchCore(head, kana, kanji, conjugates);
    if (segments == null) continue;
    return SurfaceMatch(
      base: lead + head,
      segments: [
        if (lead.isNotEmpty) FuriganaSegment(lead),
        ...segments,
      ],
      trailing: tail + trail,
    );
  }
  return null;
}

/// Whether [s] is a concatenation of one or more surfaces from [glue].
/// Backtracking, because glue surfaces overlap (は / には) — bounded by
/// [_maxFusedGlueChars] at the only call site.
bool _factorsIntoGlue(String s, Set<String> glue) {
  if (s.isEmpty) return true;
  for (final g in glue) {
    if (g.isNotEmpty &&
        s.startsWith(g) &&
        _factorsIntoGlue(s.substring(g.length), glue)) {
      return true;
    }
  }
  return false;
}

List<FuriganaSegment>? _matchCore(
  String core,
  String kana,
  String kanji,
  bool conjugates,
) {
  final split = kanji.isEmpty || kanji == kana
      ? null
      : splitOkurigana(kana: kana, kanji: kanji);

  // No usable kanji form: the surface must be the kana itself, or (for a
  // conjugating role) a pure-kana form sharing the kana stem.
  if (split == null || split.kanjiStem.isEmpty) {
    if (core == kana) return [FuriganaSegment(core)];
    if (conjugates && _sharesKanaStem(core, kana)) return [FuriganaSegment(core)];
    return null;
  }

  // Written with the kanji stem: ruby over the stem, kana tail plain. The
  // base form itself takes this path too (行く → 行[い]く), which is also
  // typographically tighter than whole-word ruby for names like 田なか.
  if (core.startsWith(split.kanjiStem)) {
    final tail = core.substring(split.kanjiStem.length);
    final tailOk =
        tail == split.okurigana || (conjugates && _isPureKana(tail));
    if (tailOk) {
      return [
        FuriganaSegment(split.kanjiStem, split.stemReading),
        if (tail.isNotEmpty) FuriganaSegment(tail),
      ];
    }
  }

  // Written in kana despite a taught kanji form — never wrong, just plain.
  if (core == kana) return [FuriganaSegment(core)];
  if (conjugates && _sharesKanaStem(core, kana)) return [FuriganaSegment(core)];

  return null;
}

/// Whether [core] is a plausible pure-kana conjugated form of base [kana]:
/// conjugation changes at most the base form's final kana (たべる→たべます,
/// のむ→のみます, おもしろい→おもしろく), so the shared prefix must reach
/// kana.length - 1. Deliberately no ending inventory yet — that arrives with
/// the factoring segmenter.
bool _sharesKanaStem(String core, String kana) {
  if (kana.length < 2) return false;
  final stem = kana.substring(0, kana.length - 1);
  return _isPureKana(core) && core.startsWith(stem) && core != stem;
}

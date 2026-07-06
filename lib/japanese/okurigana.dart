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

  final match = _matchCore(core, kana, kanji, conjugates);
  if (match == null) return null;
  return [
    if (lead.isNotEmpty) FuriganaSegment(lead),
    ...match,
    if (trail.isNotEmpty) FuriganaSegment(trail),
  ];
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

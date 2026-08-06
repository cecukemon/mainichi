/// Heuristics for spotting a verb captured in polite form (ます-paradigm)
/// instead of dictionary form, and suggesting dictionary-form candidates.
///
/// Godan vs. ichidan can't be told apart from the polite surface alone
/// (きます could deconjugate to the godan く or the ichidan きる/来る) — this
/// module offers plausible candidates for a human to confirm, it never
/// guesses silently. Shared by capture-time validation and the Bunko
/// base-form fix-up flow.
library;

/// How confidently [politeFormSuspicion] can call a kana surface polite-form.
enum PoliteFormSuspicion {
  /// No polite-paradigm suffix detected.
  none,

  /// Ends in ます — could be polite form, but also a legitimate dictionary
  /// form (励ます, 済ます), so this only warrants a warning.
  ambiguousMasu,

  /// Ends in ません / ました / ませんでした — no dictionary-form verb ends
  /// this way, so this is unambiguously a polite conjugation.
  unambiguous,
}

/// Longest-match-first so ませんでした isn't mistaken for a ません match.
const List<String> _unambiguousSuffixes = ['ませんでした', 'ました', 'ません'];
const String _ambiguousSuffix = 'ます';

/// Inverse of `segmenter.dart`'s `_iRow`: maps a polite stem's final i-row
/// kana back to the u-row kana that ends the godan dictionary form (のみ →
/// のむ). Ichidan verbs don't need this — their polite stem is just the
/// dictionary form with る dropped, so the stem itself plus る round-trips.
const Map<String, String> _uRowFromIRow = {
  'い': 'う', 'き': 'く', 'ぎ': 'ぐ', 'し': 'す', 'ち': 'つ',
  'に': 'ぬ', 'び': 'ぶ', 'み': 'む', 'り': 'る',
};

({String stem, String suffix})? _stripPoliteSuffix(String surface) {
  for (final suffix in _unambiguousSuffixes) {
    if (surface.length > suffix.length && surface.endsWith(suffix)) {
      return (stem: surface.substring(0, surface.length - suffix.length), suffix: suffix);
    }
  }
  if (surface.length > _ambiguousSuffix.length && surface.endsWith(_ambiguousSuffix)) {
    return (
      stem: surface.substring(0, surface.length - _ambiguousSuffix.length),
      suffix: _ambiguousSuffix
    );
  }
  return null;
}

/// Classifies [kana] (a word's stored kana reading) by how confidently it
/// looks like a polite-paradigm conjugation rather than dictionary form.
/// A bare suffix with no stem (e.g. "ます" alone) is not a verb at all, so
/// it reports [PoliteFormSuspicion.none].
PoliteFormSuspicion politeFormSuspicion(String kana) {
  final stripped = _stripPoliteSuffix(kana);
  if (stripped == null) return PoliteFormSuspicion.none;
  return stripped.suffix == _ambiguousSuffix
      ? PoliteFormSuspicion.ambiguousMasu
      : PoliteFormSuspicion.unambiguous;
}

/// Plausible dictionary-form candidates for a polite [surface] — empty when
/// [surface] doesn't end in a recognized polite suffix. Ordering is a
/// heuristic (godan before ichidan for an i-row stem, since it's the more
/// common pattern), not a guarantee; the caller should let a human pick.
List<String> baseFormCandidates(String surface) {
  final stripped = _stripPoliteSuffix(surface);
  if (stripped == null || stripped.stem.isEmpty) return const [];
  final stem = stripped.stem;

  // する／来る(くる)／着る(きる) are irregular: the regular stem+u-row
  // transform doesn't spell them correctly, so special-case the two polite
  // stems short enough to be one of these irregulars.
  if (stem == 'し') return const ['する'];
  if (stem == 'き') return const ['くる', 'きる'];

  final last = stem[stem.length - 1];
  final godanEnding = _uRowFromIRow[last];
  final ichidan = '$stemる';
  final candidates = <String>[
    if (godanEnding != null) '${stem.substring(0, stem.length - 1)}$godanEnding',
    ichidan,
  ];
  return {...candidates}.toList(); // de-dupe, preserve order
}

/// Applies the same polite-suffix strip to a word's [kanji] surface, picking
/// the candidate whose final kana matches [chosenKanaBase] (the dictionary
/// form the user picked for the kana reading). Returns null when [kanji]
/// doesn't end in the same polite suffix as the kana surface, or shares no
/// ending with the chosen candidate — signaling the caller to leave kanji
/// for manual edit rather than writing a guessed value.
String? transformKanjiBaseForm(String kanji, String chosenKanaBase) {
  if (kanji.isEmpty || chosenKanaBase.isEmpty) return null;
  if (_stripPoliteSuffix(kanji) == null) return null;
  final chosenEnding = chosenKanaBase[chosenKanaBase.length - 1];
  for (final candidate in baseFormCandidates(kanji)) {
    if (candidate.isNotEmpty && candidate[candidate.length - 1] == chosenEnding) {
      return candidate;
    }
  }
  return null;
}

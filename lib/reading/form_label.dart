/// Display labels for the word-lookup sheet's form annotation
/// (features/reading-exercise.md — "to eat · negative, polite").
///
/// Maps the slot-form wire values that `detectTaughtForm` returns to the
/// learner-facing wording from the design mockup. Presentation only; the
/// detection itself lives with the taught-endings inventory in
/// `lib/japanese/segmenter.dart` so there is a single source of truth for
/// which forms exist.
library;

const Map<String, String> _formLabels = {
  'polite': 'polite',
  'polite_negative': 'negative, polite',
  'past': 'past, polite', // ました — the taught past is the polite one
  'negative': 'negative', // i-adjective く form
};

/// Label for a detected form, or null when the form is unknown (an ending
/// taught to the segmenter before a label was added — show nothing rather
/// than a wire value).
String? formAnnotation(String? wireForm) =>
    wireForm == null ? null : _formLabels[wireForm];

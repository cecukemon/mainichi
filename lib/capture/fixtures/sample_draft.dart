/// Hand-written extraction draft used to drive the capture loop UI without a
/// live photo/API call (deferred — see capture-loop.md §4). Mirrors the shape
/// `worksheet_extractor.dart` would produce and matches the content used in
/// the features/*.html mockups, so the built screens can be checked against them.
library;

import '../../data/enums.dart';
import '../models.dart';

CaptureDraft buildSampleDraft() {
  return CaptureDraft(
    worksheetTitle: 'たべもの・うごき',
    worksheetTopic: 'food vocabulary, verbs',
    vocabulary: [
      const VocabDraftItem(
        kana: 'すし',
        kanji: '',
        romaji: 'sushi',
        meaning: 'sushi',
        role: WordRole.noun,
        kanaOnly: false,
        meaningSource: MeaningSource.printedGloss,
        confidence: ConfidenceTier.high,
      ),
      // Dedup candidate: matches the demo Bunko entry seeded by
      // seedDemoBunko(), re-extracted here with a new example sentence.
      const VocabDraftItem(
        kana: 'たべる',
        kanji: '食べる',
        romaji: 'taberu',
        meaning: 'to eat',
        role: WordRole.verb,
        kanaOnly: false,
        meaningSource: MeaningSource.printedGloss,
        confidence: ConfidenceTier.high,
        kanjiCandidates: ['食べる'],
        newExampleSentence: 'わたしは すしを たべます。',
      ),
      // Low-confidence vocab: kanji guess needs candidate-picking, not typing.
      const VocabDraftItem(
        kana: 'はしる',
        kanji: '走る',
        romaji: 'hashiru',
        meaning: 'to jog',
        role: WordRole.verb,
        kanaOnly: false,
        meaningSource: MeaningSource.inferred,
        confidence: ConfidenceTier.low,
        notes: 'reading uncertain, sheet is smudged',
        kanjiCandidates: ['走る', '趣る'],
      ),
      // Picture-derived: meaning is a guess from a drawing, plus a margin gloss.
      const VocabDraftItem(
        kana: 'はしる',
        kanji: '走る',
        romaji: 'hashiru',
        meaning: 'to jog',
        role: WordRole.verb,
        kanaOnly: false,
        meaningSource: MeaningSource.picture,
        confidence: ConfidenceTier.low,
        notes: 'shown with a picture of someone running',
        kanjiCandidates: ['走る', '趣る'],
        meaningCandidates: ['to jog', 'to run', 'to rush'],
        handwrittenGloss: 'rennen',
      ),
    ],
    templates: [
      const TemplateDraftItem(
        template: 'わたしは {food} を {verb_1} ます',
        slots: [
          SlotDraft(name: 'food', role: WordRole.noun),
          SlotDraft(name: 'verb_1', role: WordRole.verb, form: SlotForm.polite),
        ],
        example: 'わたしは すしを たべます。',
        confidence: ConfidenceTier.low,
        notes: 'template/slot generalisation is a judgement call',
      ),
    ],
    ignoredHandwrittenNotes: ['rennen'],
  );
}

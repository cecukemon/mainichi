import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/capture/draft_from_extraction.dart';
import 'package:mainichi/capture/models.dart';
import 'package:mainichi/data/enums.dart';

Map<String, dynamic> _sampleExtraction() {
  return {
    'worksheet': {
      'title': 'たべもの',
      'topic': 'food vocabulary',
      'orientation_note': 'upright',
    },
    'vocabulary': [
      {
        'kana': 'すし',
        'kanji': '',
        'romaji': 'sushi',
        'meaning': 'sushi',
        'role': 'noun',
        'kana_only': true,
        'meaning_source': 'printed_gloss',
        'confidence': 'high',
        'notes': '',
      },
      {
        'kana': 'おもしろい',
        'kanji': '面白い',
        'romaji': '',
        'meaning': 'interesting',
        'role': 'i_adjective',
        'kana_only': false,
        'meaning_source': 'inferred',
        'confidence': 'low',
        'notes': 'negative stem also printed',
      },
    ],
    'structures': [
      {
        'template': 'その ほんは {i_adjective_1} ありません',
        'slots': [
          {'name': 'i_adjective_1', 'role': 'i_adjective', 'form': 'negative'},
        ],
        'example': 'その ほんは おもしろく ありません。',
        'confidence': 'low',
        'notes': '',
      },
    ],
    'handwriting': {
      'detected': true,
      'ignored_notes': ['interessant'],
    },
  };
}

void main() {
  test('maps worksheet metadata', () {
    final draft = draftFromExtraction(_sampleExtraction());
    expect(draft.worksheetTitle, 'たべもの');
    expect(draft.worksheetTopic, 'food vocabulary');
    expect(draft.ignoredHandwrittenNotes, ['interessant']);
  });

  test('maps a kana-only high-confidence vocab item', () {
    final draft = draftFromExtraction(_sampleExtraction());
    final sushi = draft.vocabulary[0];
    expect(sushi.kana, 'すし');
    expect(sushi.kanji, '');
    expect(sushi.kanaOnly, isTrue);
    expect(sushi.role, WordRole.noun);
    expect(sushi.meaningSource, MeaningSource.printedGloss);
    expect(sushi.confidence, ConfidenceTier.high);
    expect(sushi.kanjiCandidates, isEmpty);
    expect(sushi.kanaCandidates, ['すし']);
    expect(sushi.meaningCandidates, ['sushi']);
  });

  test('maps a kanji vocab item with low confidence', () {
    final draft = draftFromExtraction(_sampleExtraction());
    final omoshiroi = draft.vocabulary[1];
    expect(omoshiroi.kanji, '面白い');
    expect(omoshiroi.role, WordRole.iAdjective);
    expect(omoshiroi.meaningSource, MeaningSource.inferred);
    expect(omoshiroi.confidence, ConfidenceTier.low);
    expect(omoshiroi.kanjiCandidates, ['面白い']);
  });

  test('does not attribute a handwritten gloss or example to any vocab item', () {
    final draft = draftFromExtraction(_sampleExtraction());
    for (final v in draft.vocabulary) {
      expect(v.handwrittenGloss, isNull);
      expect(v.newExampleSentence, isNull);
    }
  });

  test('captures import provenance: source image, model, and verbatim raw draft', () {
    final draft = draftFromExtraction(
      _sampleExtraction(),
      sourceImage: '/tmp/sheet.jpg',
      model: 'claude-opus-4-8',
    );
    expect(draft.sourceImage, '/tmp/sheet.jpg');
    expect(draft.model, 'claude-opus-4-8');
    // Re-decoding the stored raw draft yields the original extraction map.
    expect(jsonDecode(draft.rawDraftJson!), _sampleExtraction());
  });

  test('leaves provenance null when none is passed (e.g. a non-live caller)', () {
    final draft = draftFromExtraction(_sampleExtraction());
    expect(draft.sourceImage, isNull);
    expect(draft.model, isNull);
    // The raw draft is still captured — it's derivable from the input alone.
    expect(draft.rawDraftJson, isNotNull);
  });

  test('legacy payload (no kanji_candidates/region) falls back to singletons '
      'and a null region', () {
    // _sampleExtraction predates D58 — the fallback must still hold.
    final draft = draftFromExtraction(_sampleExtraction());
    expect(draft.vocabulary[0].region, isNull);
    expect(draft.vocabulary[1].kanjiCandidates, ['面白い']);
    expect(draft.vocabulary[1].region, isNull);
  });

  test('maps ranked kanji_candidates, deduped with the confirmed kanji first',
      () {
    final draft = draftFromExtraction({
      'worksheet': {'title': '', 'topic': '', 'orientation_note': 'upright'},
      'vocabulary': [
        {
          'kana': 'はし',
          'kanji': '橋',
          'kanji_candidates': ['橋', '箸', '橋'], // includes a dup
          'romaji': '',
          'meaning': 'bridge',
          'role': 'noun',
          'kana_only': false,
          'meaning_source': 'inferred',
          'confidence': 'low',
          'region': [0.1, 0.2, 0.5, 0.35],
          'notes': '',
        },
      ],
      'structures': <Object>[],
      'handwriting': {'detected': false, 'ignored_notes': <String>[]},
    });
    final hashi = draft.vocabulary.single;
    expect(hashi.kanjiCandidates, ['橋', '箸']); // deduped, confirmed first
    expect(hashi.region, isNotNull);
    expect(hashi.region!.left, closeTo(0.1, 1e-9));
    expect(hashi.region!.bottom, closeTo(0.35, 1e-9));
  });

  group('CropRegion.tryParse', () {
    test('parses a valid [l,t,r,b] box', () {
      final r = CropRegion.tryParse([0.1, 0.2, 0.6, 0.7])!;
      expect(r.left, closeTo(0.1, 1e-9));
      expect(r.top, closeTo(0.2, 1e-9));
      expect(r.right, closeTo(0.6, 1e-9));
      expect(r.bottom, closeTo(0.7, 1e-9));
    });

    test('clamps out-of-range values and swaps inverted edges', () {
      final r = CropRegion.tryParse([0.6, 1.5, 0.2, -0.3])!;
      expect(r.left, closeTo(0.2, 1e-9));
      expect(r.right, closeTo(0.6, 1e-9));
      expect(r.top, closeTo(0.0, 1e-9)); // -0.3 clamped to 0
      expect(r.bottom, closeTo(1.0, 1e-9)); // 1.5 clamped to 1
    });

    test('rejects wrong arity, non-numbers, and degenerate boxes', () {
      expect(CropRegion.tryParse(null), isNull);
      expect(CropRegion.tryParse(const []), isNull);
      expect(CropRegion.tryParse([0.1, 0.2, 0.3]), isNull); // 3 elements
      expect(CropRegion.tryParse([0.1, 0.2, 'x', 0.4]), isNull);
      expect(CropRegion.tryParse([0.5, 0.5, 0.505, 0.9]), isNull); // <2% wide
    });
  });

  test('maps a template with a slot form', () {
    final draft = draftFromExtraction(_sampleExtraction());
    final template = draft.templates.single;
    expect(template.template, 'その ほんは {i_adjective_1} ありません');
    expect(template.example, 'その ほんは おもしろく ありません。');
    expect(template.confidence, ConfidenceTier.low);
    final slot = template.slots.single;
    expect(slot.name, 'i_adjective_1');
    expect(slot.role, WordRole.iAdjective);
    expect(slot.form, SlotForm.negative);
  });
}

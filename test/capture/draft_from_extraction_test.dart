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

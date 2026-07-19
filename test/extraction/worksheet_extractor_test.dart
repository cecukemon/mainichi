import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/extraction/worksheet_extractor.dart';

/// The vocab item's schema node, dug out of the nested structured-output map.
Map<String, dynamic> _vocabItemSchema() {
  final props = extractionSchema['properties'] as Map<String, dynamic>;
  final vocab = props['vocabulary'] as Map<String, dynamic>;
  return (vocab['items'] as Map<String, dynamic>);
}

void main() {
  test('vocab schema requires kanji_candidates and region (D58)', () {
    final item = _vocabItemSchema();
    final required = (item['required'] as List).cast<String>();
    expect(required, containsAll(['kanji_candidates', 'region']));

    final props = item['properties'] as Map<String, dynamic>;
    expect((props['kanji_candidates'] as Map)['type'], 'array');
    final region = props['region'] as Map<String, dynamic>;
    expect(region['type'], 'array');
    expect(region['maxItems'], 4); // [l, t, r, b]
  });

  test('the prompt instructs on candidates and regions', () {
    expect(extractionSystemPrompt, contains('kanji_candidates'));
    expect(extractionSystemPrompt, contains('region'));
  });

  test('parseExtractionResponse round-trips the new fields', () {
    final payload = {
      'worksheet': {'title': 't', 'topic': 'x', 'orientation_note': 'upright'},
      'vocabulary': [
        {
          'kana': 'はし',
          'kanji': '橋',
          'kanji_candidates': ['橋', '箸'],
          'romaji': '',
          'meaning': 'bridge',
          'role': 'noun',
          'kana_only': false,
          'meaning_source': 'inferred',
          'confidence': 'low',
          'region': [0.1, 0.2, 0.5, 0.4],
          'notes': '',
        },
      ],
      'structures': <Object>[],
      'handwriting': {'detected': false, 'ignored_notes': <String>[]},
    };
    final parsed = parseExtractionResponse({
      'stop_reason': 'end_turn',
      'content': [
        {'type': 'text', 'text': jsonEncode(payload)},
      ],
    });
    final item = (parsed['vocabulary'] as List).first as Map<String, dynamic>;
    expect(item['kanji_candidates'], ['橋', '箸']);
    expect(item['region'], [0.1, 0.2, 0.5, 0.4]);
  });
}

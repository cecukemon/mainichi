import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/enums.dart';
import 'package:mainichi/extraction/worksheet_extractor.dart';

void main() {
  group('buildExtractionRequest', () {
    final req = buildExtractionRequest(base64Image: 'QUJD'); // "ABC"

    test('targets the extraction model with structured output', () {
      expect(req['model'], extractionModel);
      final format = (req['output_config'] as Map)['format'] as Map;
      expect(format['type'], 'json_schema');
      expect(format['schema'], extractionSchema);
    });

    test('sends the image as a base64 block before the text prompt', () {
      final content =
          ((req['messages'] as List).first as Map)['content'] as List;
      expect(content.first['type'], 'image');
      expect((content.first['source'] as Map)['data'], 'QUJD');
      expect(content.last['type'], 'text');
    });

    test('schema keeps vocab and slot roles on the same closed set', () {
      final props = extractionSchema['properties'] as Map;
      final vocabRole = ((props['vocabulary']['items'] as Map)['properties']
          as Map)['role'] as Map;
      final slotItem =
          (props['structures']['items']['properties']['slots']['items']) as Map;
      final slotRole = (slotItem['properties'] as Map)['role'] as Map;
      expect(vocabRole['enum'], vocabRoles);
      expect(slotRole['enum'], vocabRoles);
    });

    test('every slot carries a required conjugation form (decision D12)', () {
      final props = extractionSchema['properties'] as Map;
      final slotItem =
          (props['structures']['items']['properties']['slots']['items']) as Map;
      expect(slotItem['required'], contains('form'));
      final form = (slotItem['properties'] as Map)['form'] as Map;
      expect(form['enum'], slotForms);
      // The wire values must all round-trip into the storage enum; a form the
      // schema allows but fromExtraction doesn't know would silently degrade
      // to dictionary at import.
      expect(slotForms, contains('dictionary'));
      for (final wire in slotForms) {
        final mapped = SlotForm.fromExtraction(wire);
        expect(mapped.name.toLowerCase(),
            wire.replaceAll('_', '').toLowerCase(),
            reason: '"$wire" should map to a matching SlotForm');
      }
    });
  });

  group('parseExtractionResponse', () {
    test('decodes the JSON text block', () {
      final draft = {
        'worksheet': {'title': '', 'topic': 'demonstratives', 'orientation_note': 'upright'},
        'vocabulary': const [],
        'structures': const [],
        'handwriting': {'detected': false, 'ignored_notes': const []},
      };
      final response = {
        'stop_reason': 'end_turn',
        'content': [
          {'type': 'text', 'text': jsonEncode(draft)},
        ],
      };
      expect(parseExtractionResponse(response), draft);
    });

    test('skips leading thinking blocks', () {
      final response = {
        'stop_reason': 'end_turn',
        'content': [
          {'type': 'thinking', 'thinking': 'looking at the sheet...'},
          {'type': 'text', 'text': '{"ok":true}'},
        ],
      };
      expect(parseExtractionResponse(response), {'ok': true});
    });

    test('throws on a refusal before touching content', () {
      final response = {
        'stop_reason': 'refusal',
        'stop_details': {'category': 'other'},
        'content': const [],
      };
      expect(
        () => parseExtractionResponse(response),
        throwsA(isA<ExtractionRefused>()),
      );
    });

    test('throws when there is no text block', () {
      final response = {
        'stop_reason': 'end_turn',
        'content': [
          {'type': 'thinking', 'thinking': 'only thinking, no answer'},
        ],
      };
      expect(
        () => parseExtractionResponse(response),
        throwsA(isA<StateError>()),
      );
    });
  });
}

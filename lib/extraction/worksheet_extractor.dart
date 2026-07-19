/// Worksheet extraction: turns a photographed class worksheet into a structured
/// review draft (vocabulary + sentence templates), grounded in what the class
/// actually taught.
///
/// This is the §3 / §10.2 capture step from the spec. It is deliberately
/// transport-agnostic: it builds the request body and parses the response, but
/// does not make the HTTP call itself — that lives behind an interface (the CLI
/// in `tool/extract_worksheet.dart` today; a `dio` client in the app later), so
/// the same logic can move server-side if word segmentation ever forces a
/// backend (spec §10.1).
library;

import 'dart:convert';

import '../config/model_config.dart';

/// Roles a vocabulary item or template slot can take. Closed set so generated
/// sentences stay grammatical (spec §2). Extend as the course introduces more.
const List<String> vocabRoles = [
  'noun',
  'verb',
  'i_adjective',
  'na_adjective',
  'pronoun',
  'demonstrative',
  'particle',
  'question_word',
  'suffix',
  'number',
  'name',
  'other',
];

/// Conjugation forms a template slot can demand of the word that fills it
/// (decision D12). Wire values for `SlotForm` — keep in sync with
/// `SlotForm.fromExtraction` in `lib/data/enums.dart`. Extend as the course
/// introduces more conjugations.
const List<String> slotForms = [
  'dictionary',
  'negative',
  'polite',
  'polite_negative',
  'past',
  'te',
];

/// JSON Schema for the structured-output response. Every field is `required`
/// and objects set `additionalProperties: false` — both mandated by the
/// structured-outputs API. Absent values are the empty string rather than null,
/// which sidesteps nullable-type support questions in the constrained decoder.
final Map<String, dynamic> extractionSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['worksheet', 'vocabulary', 'structures', 'handwriting'],
  'properties': {
    'worksheet': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['title', 'topic', 'orientation_note'],
      'properties': {
        'title': {
          'type': 'string',
          'description':
              'Printed header of the sheet, verbatim if present, else "".',
        },
        'topic': {
          'type': 'string',
          'description':
              'Grammatical theme, e.g. "na-adjectives", "demonstratives '
                  'kore/sore/are", "countries & nationalities".',
        },
        'orientation_note': {
          'type': 'string',
          'description': 'e.g. "upright" or "rotated 90 deg clockwise".',
        },
      },
    },
    'vocabulary': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': [
          'kana',
          'kanji',
          'kanji_candidates',
          'romaji',
          'meaning',
          'role',
          'kana_only',
          'meaning_source',
          'confidence',
          'region',
          'notes',
        ],
        'properties': {
          'kana': {
            'type': 'string',
            'description':
                'Hiragana/katakana reading, always in dictionary (base) form.',
          },
          'kanji': {
            'type': 'string',
            'description': 'Kanji form if the sheet shows one, else "". Must '
                'equal the first entry of kanji_candidates when that is '
                'non-empty.',
          },
          'kanji_candidates': {
            'type': 'array',
            'items': {'type': 'string'},
            'description':
                'Plausible printed kanji forms, best guess first, up to 3. '
                    'Offer more than one ONLY when the print is genuinely '
                    'ambiguous (low resolution, similar kanji); the first '
                    'entry must equal kanji. Empty [] when no kanji is printed.',
          },
          'romaji': {
            'type': 'string',
            'description':
                'Romaji only if printed on the sheet as a reading aid, else "". '
                    'Cross-check for the kana reading; not stored long-term.',
          },
          'meaning': {
            'type': 'string',
            'description':
                'Best English meaning, often inferred from a picture; "" if '
                    'undeterminable.',
          },
          'role': {'type': 'string', 'enum': vocabRoles},
          'kana_only': {
            'type': 'boolean',
            'description':
                'True for words with no kanji form (やる, ある, particles).',
          },
          'meaning_source': {
            'type': 'string',
            'enum': ['printed_gloss', 'picture', 'inferred', 'none'],
          },
          'confidence': {
            'type': 'string',
            'enum': ['high', 'low'],
            'description':
                'high = clean printed kana vocab; low = anything resting on a '
                    'guess (picture-derived meaning, uncertain reading).',
          },
          'region': {
            'type': 'array',
            'items': {'type': 'number'},
            // No maxItems: the structured-output (constrained-decoding) schema
            // rejects array length bounds with a 400. The "exactly 4 numbers"
            // shape is stated in the description and enforced by
            // CropRegion.tryParse, which treats anything else as no region.
            'description':
                'Approximate bounding box of where this item (and its picture, '
                    'if any) appears on the image, as exactly four numbers '
                    '[left, top, right, bottom], fractions 0–1 of the image '
                    'width/height, top-left origin. Best-effort framing for the '
                    'review UI, not exact. Empty [] when unsure.',
          },
          'notes': {
            'type': 'string',
            'description':
                'e.g. "shown with a picture of a clock", "negative stem '
                    'おもしろく also printed", else "".',
          },
        },
      },
    },
    'structures': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['template', 'slots', 'example', 'confidence', 'notes'],
        'properties': {
          'template': {
            'type': 'string',
            'description':
                'Sentence pattern with typed slots in braces, e.g. '
                    '"これは {noun} です".',
          },
          'slots': {
            'type': 'array',
            'items': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['name', 'role', 'form'],
              'properties': {
                'name': {'type': 'string'},
                'role': {'type': 'string', 'enum': vocabRoles},
                'form': {
                  'type': 'string',
                  'enum': slotForms,
                  'description':
                      'Conjugation the pattern demands of the word filling '
                          'this slot; "dictionary" when the base form fits '
                          'as-is.',
                },
              },
            },
          },
          'example': {
            'type': 'string',
            'description': 'A concrete printed instance of the pattern, else "".',
          },
          'confidence': {
            'type': 'string',
            'enum': ['high', 'low'],
          },
          'notes': {'type': 'string'},
        },
      },
    },
    'handwriting': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['detected', 'ignored_notes'],
      'properties': {
        'detected': {'type': 'boolean'},
        'ignored_notes': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'Handwritten margin notes that were deliberately NOT extracted '
                  '(usually German/English glosses), surfaced only so the '
                  'learner can optionally re-add them by hand later.',
        },
      },
    },
  },
};

/// Instructions for the extractor. Encodes the spec rules plus everything the
/// real worksheets in images-for-import revealed: rotation, German/English
/// handwriting, picture-or-handwriting meanings, printed romaji, conjugation
/// forms, and reverse-side bleed-through.
const String extractionSystemPrompt = '''
You extract structured study data from photographs of Japanese class worksheets for a beginner learner.

Rules:
- Extract ONLY printed worksheet content. The learner adds handwritten margin notes in German and English (e.g. "Sprache", "Mensch", "schoen + sauber", "praktisch", "Negation"). Do NOT treat handwriting as worksheet content. Record the handwritten notes you saw, verbatim, in handwriting.ignored_notes and set handwriting.detected accordingly. They are surfaced only so the learner can optionally re-add them by hand later.
- Photos are usually rotated 90 degrees. Read them regardless and record the orientation in worksheet.orientation_note.
- Faint mirror-image text bleeding through from the back of the page is not content. Ignore it.

Vocabulary:
- Record each printed vocabulary item once, in dictionary (base) form. If a conjugated form is also shown (e.g. the i-adjective おもしろい with its negative stem おもしろく, or the irregular いい to よく), keep the base form in kana and describe the conjugation in notes.
- kana is the hiragana/katakana reading, always required, in dictionary base form. For na-adjectives, kana is the bare reading without the な / (な) marker (e.g. きれい, not きれい(な)) — the role records that it is a na-adjective and the な is handled by templates.
- kanji is the kanji form ONLY if it is actually printed on the sheet. Do NOT supply kanji the worksheet does not show, even if you know it — a beginner sees only what the sheet prints. Otherwise "".
- kanji_candidates lists plausible readings of the printed kanji, best first, and its first entry must equal kanji. Give more than one ONLY when the print is genuinely ambiguous (low resolution, look-alike kanji); otherwise a single entry (or [] when no kanji is printed) is correct. Do not pad it with kanji you merely know.
- region is the approximate location of the item on the image (including its picture, if it has one) as [left, top, right, bottom] fractions of the image size, top-left origin. It is a best-effort frame for the review UI — approximate is fine, and [] is acceptable when you cannot place it. The image has already been rotated upright, so use the image's own axes as you see them.
- romaji is the romaji only if printed on the sheet as a reading aid (these sheets often have it), otherwise "".
- Worksheets rarely print a translation. Infer meaning (in English) from an accompanying picture when there is one and set meaning_source to "picture" with confidence "low" (drawings are ambiguous: "clock" vs "watch", "house" vs "home"). Use "printed_gloss" only if a non-handwritten translation is actually printed. If you cannot tell, set meaning to "" and meaning_source to "none".
- Clean printed kana vocabulary is confidence "high". Anything resting on a guess (picture-derived meaning, uncertain reading) is "low".

Structures:
- Generalise printed example sentences into reusable templates with typed slots in braces, e.g. "これは {noun} です", "それは {noun} ではありません", "{noun} は なん ですか". Put the concrete printed instance in example. Template/slot generalisation is a judgement call: mark these confidence "low" unless the pattern is unambiguous.
- Every slot in a template must have a unique name. When a template repeats a role, suffix the names, e.g. "{noun_1} は {noun_2} です". A fixed word that does not vary (e.g. なん in a what-question) is part of the template text, not a slot.
- Every slot has a form: the conjugation the pattern demands of the word that fills it. Use "dictionary" when the base form fits as-is. When the printed pattern requires an inflected word, keep the slot generic and record the inflection as the form — e.g. その ほんは {i_adjective_1} ありません has one slot with role "i_adjective" and form "negative" (おもしろい fills it as おもしろく). Never encode conjugation into the slot name or the template text.

Do not invent vocabulary or patterns that are not on the sheet.
''';

const String extractionUserPrompt =
    'Extract the study data from this worksheet.';

/// Builds the Messages API request body for one worksheet image.
///
/// [base64Image] must be base64 of an image already resized to a sane size
/// (~2000px long edge); the caller owns resizing. Thinking is left off for a
/// predictable, bounded JSON response; flip on `thinking: {type: "adaptive"}`
/// plus `output_config.effort: "high"` for a possible accuracy bump (the
/// response parser already tolerates leading thinking blocks).
Map<String, dynamic> buildExtractionRequest({
  required String base64Image,
  String mediaType = 'image/jpeg',
  String model = ModelConfig.extraction,
  // A dense worksheet's JSON draft can exceed 8000 output tokens, truncating
  // the response mid-object (observed live 2026-07-18: FormatException at
  // char 17506). 16000 covers a full worksheet while staying in the safe
  // non-streaming range — the live client makes a single blocking `dio` POST,
  // and larger caps risk HTTP timeouts without switching to streaming.
  // The D58 kanji_candidates + region fields add only ~10-20 output tokens
  // per item (a dense 40-item sheet ≈ +1k), so the cap is unchanged.
  int maxTokens = 16000,
}) {
  return {
    'model': model,
    'max_tokens': maxTokens,
    'output_config': {
      'format': {'type': 'json_schema', 'schema': extractionSchema},
    },
    'system': extractionSystemPrompt,
    'messages': [
      {
        'role': 'user',
        'content': [
          {
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': mediaType,
              'data': base64Image,
            },
          },
          {'type': 'text', 'text': extractionUserPrompt},
        ],
      },
    ],
  };
}

/// Guesses the Messages API media type from a file extension. Shared by the
/// CLI transport (`tool/extract_worksheet.dart`) and the in-app one
/// (`lib/extraction/extraction_client.dart`).
String mediaTypeForPath(String path) {
  final p = path.toLowerCase();
  if (p.endsWith('.png')) return 'image/png';
  if (p.endsWith('.webp')) return 'image/webp';
  if (p.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

/// Thrown when the model declines the request (spec §10.3 / Fable-style refusal
/// handling — guard before reading content).
class ExtractionRefused implements Exception {
  ExtractionRefused(this.details);
  final Object? details;
  @override
  String toString() => 'ExtractionRefused: $details';
}

/// Thrown when the model hit the `max_tokens` cap before finishing the JSON.
/// The response carries a partial, unparseable text block; caught here so the
/// user sees an actionable message instead of a raw `FormatException`.
class ExtractionTruncated implements Exception {
  ExtractionTruncated();
  @override
  String toString() =>
      'ExtractionTruncated: the worksheet was too long to extract in one pass '
      '(hit the output token limit)';
}

/// Parses a decoded Messages API response into the extraction draft.
///
/// Checks `stop_reason` first (a refusal carries no usable content, and a
/// `max_tokens` stop carries only partial JSON), then pulls the text block —
/// skipping any leading thinking blocks — and decodes the schema-constrained
/// JSON.
Map<String, dynamic> parseExtractionResponse(Map<String, dynamic> response) {
  if (response['stop_reason'] == 'refusal') {
    throw ExtractionRefused(response['stop_details']);
  }
  // A `max_tokens` stop means the JSON was cut off mid-object — decoding it
  // would throw an opaque FormatException, so surface the real cause instead.
  if (response['stop_reason'] == 'max_tokens') {
    throw ExtractionTruncated();
  }
  final content = (response['content'] as List).cast<Map<String, dynamic>>();
  final textBlock = content.firstWhere(
    (b) => b['type'] == 'text',
    orElse: () => throw StateError(
      'no text block in response (stop_reason=${response['stop_reason']})',
    ),
  );
  return jsonDecode(textBlock['text'] as String) as Map<String, dynamic>;
}

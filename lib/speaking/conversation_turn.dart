/// Free conversation: the combined grade+generate engine (speaking rung 3,
/// D69, `features/speaking-exercise.md` §4).
///
/// Turn-based spoken practice. The app opens with one in-scope line and plays a
/// fixed persona; the learner replies out loud; a *single* Claude call grades
/// that reply (grammar-in-scope + contextual sense) **and** produces the
/// persona's next line. Like the generator, this is transport-agnostic — it
/// builds the request, parses the response, and validates the next line's
/// scope, but makes no HTTP call (that's `conversation_client.dart`).
///
/// It deliberately reuses the generation stack: the next line is a [GenLine]
/// (same schema sub-object), scope is checked by the existing [validateScope],
/// and — the load-bearing detail — the cached system prefix is
/// [constraintContext] *verbatim*, so prompt-caching hits across turns and
/// shares the reading feed's cache breakpoint (D7). The growing conversation
/// history rides in the uncached user message.
library;

import 'dart:convert';

import '../config/model_config.dart';
import '../generation/conversation_generator.dart';

// ---------------------------------------------------------------------------
// Output types (parsed from the model's structured response).
// ---------------------------------------------------------------------------

/// How the learner's spoken reply landed. One verdict folds grammar and
/// contextual sense together (D69); the raw transcript is always shown beside
/// it (spec §5), and [rewrite] offers a natural in-scope version.
enum TurnVerdict { good, awkward, off }

class TurnGrade {
  const TurnGrade({
    required this.verdict,
    required this.note,
    required this.rewrite,
  });

  final TurnVerdict verdict;

  /// One short English sentence explaining the verdict.
  final String note;

  /// A natural, preferably in-scope Japanese rendering of what the learner
  /// meant — advisory display text, never scope-validated (like the
  /// transcript). Empty when the reply was already good.
  final String rewrite;

  factory TurnGrade.fromJson(Map<String, dynamic> j) => TurnGrade(
        verdict: _verdictFromWire(j['verdict'] as String?),
        note: (j['note'] as String?) ?? '',
        rewrite: (j['rewrite'] as String?) ?? '',
      );

  static TurnVerdict _verdictFromWire(String? s) => switch (s) {
        'good' => TurnVerdict.good,
        'awkward' => TurnVerdict.awkward,
        _ => TurnVerdict.off, // null/unknown degrades to the safest "off"
      };
}

/// One parsed turn from the combined call: the persona's next [reply] line
/// (always present) plus a [grade] of the learner's reply (absent on the
/// opening call, when the learner hasn't spoken yet).
class ConversationTurn {
  const ConversationTurn({required this.reply, this.grade});

  final GenLine reply;
  final TurnGrade? grade;
}

// ---------------------------------------------------------------------------
// Request / response
// ---------------------------------------------------------------------------

/// The next-line object — identical in shape to one item of
/// [generationSchema]'s `lines` array, so [ConversationTurn.reply] parses with
/// the same [GenLine.fromJson]-style mapping and validates with [validateScope]
/// unchanged. Kept in sync with the generator by construction: the fields are
/// spelled out here rather than reaching into the generation schema's nested
/// map (which has no stable public handle), and a round-trip test pins both.
final Map<String, dynamic> _replyLineSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': [
    'speaker_name_id',
    'speaker_surface',
    'text',
    'structure_id',
    'tokens',
  ],
  'properties': {
    'speaker_name_id': {
      'type': 'integer',
      'description': "id of the name-role vocab entry speaking this line "
          "(the app's persona)",
    },
    'speaker_surface': {
      'type': 'string',
      'description': "the persona's name as written",
    },
    'text': {'type': 'string', 'description': 'the full Japanese line'},
    'structure_id': {
      'type': 'integer',
      'description': 'id of the structure this line instantiates, or 0 if none',
    },
    'tokens': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['surface', 'vocab_id'],
        'properties': {
          'surface': {'type': 'string'},
          'vocab_id': {
            'type': 'integer',
            'description': 'id of the vocab entry, or 0 for grammatical glue '
                '(particles, copula, conjugation endings)',
          },
        },
      },
    },
  },
};

final Map<String, dynamic> conversationTurnSchema = {
  'type': 'object',
  'additionalProperties': false,
  // Only `reply` is always required — the opening call has nothing to grade.
  'required': ['reply'],
  'properties': {
    'grade': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['verdict', 'note', 'rewrite'],
      'properties': {
        'verdict': {
          'type': 'string',
          'enum': ['good', 'awkward', 'off'],
          'description':
              'how the learner\'s latest reply landed: "good" (grammatical in '
                  'the grammar they know and a sensible response), "awkward" '
                  '(understandable but off in grammar or phrasing), "off" '
                  '(wrong grammar or does not answer the line)',
        },
        'note': {
          'type': 'string',
          'description':
              'one short English sentence explaining the verdict for the learner',
        },
        'rewrite': {
          'type': 'string',
          'description':
              'a natural Japanese version of what the learner meant, using only '
                  'taught vocabulary and grammar where possible and kana for '
                  'kana-only words; empty string if the reply was already good',
        },
      },
    },
    'reply': _replyLineSchema,
  },
};

const String conversationInstructions = '''
You run a short, spoken Japanese practice conversation for a beginner learner, using ONLY the vocabulary and sentence patterns they have been taught. You play one fixed persona (a name-role speaker); the learner plays the other side and speaks their replies aloud.

Scope — the one hard rule for every line YOU write (the persona's lines):
- Use ONLY content words from the VOCABULARY list. Never introduce a noun, adjective, verb, name, or kanji that is not in it. If a line needs a word you don't have, choose a different one.
- A VOCABULARY entry marked "kana_only": true has NEVER been taught in kanji. Write it, and every conjugated form of it, entirely in kana — for example if たべる is kana_only, write たべます / たべません, never 食べます / 食べません. Only write kanji for a word whose entry actually has a "kanji" field (e.g. 鈴木 for すずき), and write exactly that kanji form.
- You MAY freely recombine the grammar the learner already knows — the particles, copula forms, and other pieces in the GRAMMAR GLUE list (は, です, ...), and the patterns in STRUCTURES — into natural sentences, including combinations not written out as a literal STRUCTURE.
- Do NOT add honorifics, sentence-final particles, or any other word not in VOCABULARY or GRAMMAR GLUE (e.g. さん, ね, よ).
- Respect each slot's form.

The conversation:
- Keep the SAME persona for the whole conversation — the speaker_name_id you choose on the first line stays fixed. Pick a persona from the VOCABULARY entries whose role is "name".
- On the opening turn (no learner reply yet) write one natural in-scope line that invites the learner to respond — a question they can answer with what they know. Do NOT include a "grade".
- On every later turn, your line must be a natural, in-scope response to what the learner just said, and should keep the conversation going (usually by asking something answerable).

Grading the learner's latest reply (later turns only):
- The reply is a raw speech-to-text transcript of free speech — it may contain kanji the learner did not choose, and minor recognition noise. Grade what they evidently meant, not orthography.
- verdict: "good" (grammatical in the grammar they know AND a sensible answer to your previous line), "awkward" (understood but grammar/phrasing is off), or "off" (wrong grammar, or does not answer the line).
- note: one short English sentence for the learner.
- rewrite: a natural Japanese version of what they meant, preferring taught vocabulary and grammar and kana for kana-only words; empty string if the reply was already good. (This is advisory display text; it is not scope-checked, but stay in taught material when you can.)

For your persona's line, report: speaker_name_id and speaker_surface (which name is speaking), text (the full line), structure_id (which listed structure it instantiates, or 0 if recombined), and tokens (the line split into words). Each token's vocab_id is the id of the vocabulary entry it comes from, or 0 for grammatical glue (particles like は/を, the copula です, conjugation endings, the question marker か). A name used in the text is vocabulary — tag it with its id.
''';

/// One exchange already spoken: the persona's line text, then the learner's
/// transcript reply to it (null for the final, not-yet-answered line — not used
/// in history formatting, but the shape keeps callers honest).
class TurnHistory {
  const TurnHistory({required this.personaLine, required this.learnerReply});
  final String personaLine;
  final String? learnerReply;
}

/// Builds the combined grade+generate request. With [history] empty and
/// [latestReply] null it asks only for the opening line (no grade); otherwise
/// it replays the exchange so far plus the latest learner [latestReply] and
/// asks for a grade + the persona's next line.
///
/// [personaSurface] pins the persona's display name in the replayed history
/// once the opening call has chosen it (null on the opening call itself).
Map<String, dynamic> buildConversationTurnRequest({
  required GenerationSeed seed,
  List<TurnHistory> history = const [],
  String? latestReply,
  String? personaSurface,
  String model = ModelConfig.conversation,

  /// A grade plus one tokenized line is far smaller than a full 6-line
  /// conversation; 4000 is generous headroom. `max_tokens` is a ceiling, not a
  /// target (same reasoning as generation's cap, D58), and truncation is
  /// surfaced via [GenerationTruncated].
  int maxTokens = 4000,
}) {
  final persona = personaSurface ?? 'the persona';
  final buf = StringBuffer();
  if (history.isEmpty && (latestReply == null || latestReply.isEmpty)) {
    buf.writeln(
        'Start the conversation. Choose your persona and write one natural, '
        'in-scope opening line that invites the learner to respond. Do not '
        'include a grade.');
  } else {
    buf.writeln('Conversation so far:');
    for (final turn in history) {
      buf.writeln('$persona: ${turn.personaLine}');
      if (turn.learnerReply != null) {
        buf.writeln(
            'Learner (heard by speech recognition): ${turn.learnerReply}');
      }
    }
    buf.writeln(
        'Learner (heard by speech recognition): ${latestReply ?? ''}');
    buf.writeln();
    buf.writeln(
        "Grade the learner's last reply, then write $persona's next line "
        '(in scope, responding to what they said).');
  }

  return {
    'model': model,
    'max_tokens': maxTokens,
    'output_config': {
      'format': {'type': 'json_schema', 'schema': conversationTurnSchema},
    },
    'system': [
      {'type': 'text', 'text': conversationInstructions},
      // Byte-identical to the generation prefix so the cache breakpoint is
      // shared (D7): same seed → same block → cache hit across turns.
      {
        'type': 'text',
        'text': constraintContext(seed),
        'cache_control': {'type': 'ephemeral'},
      },
    ],
    'messages': [
      {'role': 'user', 'content': buf.toString()},
    ],
  };
}

ConversationTurn parseConversationTurn(Map<String, dynamic> response) {
  // Same failure surfaces as the generator (reused exceptions): a refusal or a
  // max_tokens truncation must not read as an opaque parse error.
  if (response['stop_reason'] == 'refusal') {
    throw GenerationRefused(response['stop_details']);
  }
  if (response['stop_reason'] == 'max_tokens') {
    throw GenerationTruncated();
  }
  final content = (response['content'] as List).cast<Map<String, dynamic>>();
  final textBlock = content.firstWhere(
    (b) => b['type'] == 'text',
    orElse: () => throw StateError(
      'no text block in response (stop_reason=${response['stop_reason']})',
    ),
  );
  final json = jsonDecode(textBlock['text'] as String) as Map<String, dynamic>;
  final gradeJson = json['grade'] as Map<String, dynamic>?;
  return ConversationTurn(
    reply: _lineFromJson(json['reply'] as Map<String, dynamic>),
    grade: gradeJson == null ? null : TurnGrade.fromJson(gradeJson),
  );
}

/// Parses one persona line. Mirrors [GeneratedConversation.fromJson]'s per-line
/// mapping (kept local since that mapping isn't exposed standalone).
GenLine _lineFromJson(Map<String, dynamic> m) => GenLine(
      speakerNameId: m['speaker_name_id'] as int,
      speakerSurface: m['speaker_surface'] as String,
      text: m['text'] as String,
      structureId: m['structure_id'] as int,
      tokens: (m['tokens'] as List).map((t) {
        final tm = t as Map<String, dynamic>;
        return GenToken(
          surface: tm['surface'] as String,
          vocabId: tm['vocab_id'] as int,
        );
      }).toList(),
    );

/// Scope-validates the persona's next [line] by wrapping it in a single-line
/// [GeneratedConversation] and running the existing [validateScope] — no
/// separate scope logic. `used_*` ids are derived from the line's own tokens
/// and structure (an in-scope line's are in-scope by construction), so the
/// model needn't self-report conversation-level totals for one line.
ScopeReport validateNextLine(GenLine line, GenerationSeed seed) {
  final convo = GeneratedConversation(
    lines: [line],
    usedVocabIds: [
      for (final t in line.tokens)
        if (!t.isGlue) t.vocabId,
    ],
    usedStructureIds: line.structureId == 0 ? const [] : [line.structureId],
  );
  return validateScope(convo, seed);
}

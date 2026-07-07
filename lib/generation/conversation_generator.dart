/// Conversation generation: the core engine (spec §2 / §10.3).
///
/// Composes the vocabulary store + structure library into a short, natural Q/A
/// conversation between named speakers, constrained to *only* what's been
/// learned. Like the extractor, this is transport-agnostic — it builds the
/// request, parses the response, and validates scope, but does not make the
/// HTTP call (that's the CLI today, a `dio` client in the app later).
///
/// The model returns kanji text plus, per token, which vocab entry it used;
/// furigana is rendered from the store's authoritative readings, never from the
/// model (spec §10.3 / decision D5). Scope is then validated against the known
/// sets — strong but not fully independent until real segmentation exists (D6).
library;

import 'dart:convert';

import '../japanese/okurigana.dart';
import '../japanese/segmenter.dart';

/// Fast mid-tier model for frequent, latency-sensitive generation (decision D3).
/// Validate quality on `claude-opus-4-8` first, then confirm this holds.
const String generationModel = 'claude-sonnet-4-6';

// ---------------------------------------------------------------------------
// Constraint inputs (the "what's been learned" set). Mirrors the DB shape but
// stands alone so the generator can be exercised before the import-commit layer
// exists — the prototype seeds it from real extracted worksheet vocab.
// ---------------------------------------------------------------------------

class SeedWord {
  const SeedWord({
    required this.id,
    required this.kana,
    required this.role,
    this.kanji = '',
    this.meaning = '',
    this.kanaOnly = false,
  });

  final int id;
  final String kana;
  final String kanji;
  final String role;
  final String meaning;
  final bool kanaOnly;

  factory SeedWord.fromJson(Map<String, dynamic> j) => SeedWord(
        id: j['id'] as int,
        kana: j['kana'] as String,
        kanji: (j['kanji'] as String?) ?? '',
        role: j['role'] as String,
        meaning: (j['meaning'] as String?) ?? '',
        kanaOnly: (j['kana_only'] as bool?) ?? false,
      );
}

class SeedSlot {
  const SeedSlot({required this.name, required this.role, this.form = 'dictionary'});
  final String name;
  final String role;
  final String form;

  factory SeedSlot.fromJson(Map<String, dynamic> j) => SeedSlot(
        name: j['name'] as String,
        role: j['role'] as String,
        form: (j['form'] as String?) ?? 'dictionary',
      );
}

class SeedStructure {
  const SeedStructure({required this.id, required this.template, required this.slots});
  final int id;
  final String template;
  final List<SeedSlot> slots;

  factory SeedStructure.fromJson(Map<String, dynamic> j) => SeedStructure(
        id: j['id'] as int,
        template: j['template'] as String,
        slots: (j['slots'] as List)
            .map((s) => SeedSlot.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class GenerationSeed {
  const GenerationSeed({required this.vocab, required this.structures});
  final List<SeedWord> vocab;
  final List<SeedStructure> structures;

  factory GenerationSeed.fromJson(Map<String, dynamic> j) => GenerationSeed(
        vocab: (j['vocab'] as List)
            .map((v) => SeedWord.fromJson(v as Map<String, dynamic>))
            .toList(),
        structures: (j['structures'] as List)
            .map((s) => SeedStructure.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  Map<int, SeedWord> get vocabById => {for (final w in vocab) w.id: w};
  Set<int> get vocabIds => vocab.map((w) => w.id).toSet();
  Set<int> get structureIds => structures.map((s) => s.id).toSet();
  Set<int> get nameIds =>
      vocab.where((w) => w.role == 'name').map((w) => w.id).toSet();
}

// ---------------------------------------------------------------------------
// Generated output (parsed from the model's structured response).
// ---------------------------------------------------------------------------

class GenToken {
  const GenToken({required this.surface, required this.vocabId});
  final String surface;

  /// Id of the vocab entry this word came from, or 0 for grammatical glue
  /// (particles, copula, conjugation endings). 0 sidesteps nullable types in
  /// the structured-output schema.
  final int vocabId;

  bool get isGlue => vocabId == 0;
}

class GenLine {
  const GenLine({
    required this.speakerNameId,
    required this.speakerSurface,
    required this.text,
    required this.structureId,
    required this.tokens,
  });
  final int speakerNameId;
  final String speakerSurface;
  final String text;
  final int structureId; // 0 = no matching structure
  final List<GenToken> tokens;
}

class GeneratedConversation {
  const GeneratedConversation({
    required this.lines,
    required this.usedVocabIds,
    required this.usedStructureIds,
  });
  final List<GenLine> lines;
  final List<int> usedVocabIds;
  final List<int> usedStructureIds;
}

/// Thrown when the model declines the request (check before reading content).
class GenerationRefused implements Exception {
  GenerationRefused(this.details);
  final Object? details;
  @override
  String toString() => 'GenerationRefused: $details';
}

// ---------------------------------------------------------------------------
// Request / response
// ---------------------------------------------------------------------------

final Map<String, dynamic> generationSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['lines', 'used_vocab_ids', 'used_structure_ids'],
  'properties': {
    'lines': {
      'type': 'array',
      'items': {
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
            'description': 'id of the name-role vocab entry speaking this line',
          },
          'speaker_surface': {
            'type': 'string',
            'description': "the speaker's name as written",
          },
          'text': {'type': 'string', 'description': 'the full Japanese line'},
          'structure_id': {
            'type': 'integer',
            'description':
                'id of the structure this line instantiates, or 0 if none',
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
                  'description':
                      'id of the vocab entry, or 0 for grammatical glue '
                          '(particles, copula, conjugation endings)',
                },
              },
            },
          },
        },
      },
    },
    'used_vocab_ids': {
      'type': 'array',
      'items': {'type': 'integer'},
    },
    'used_structure_ids': {
      'type': 'array',
      'items': {'type': 'integer'},
    },
  },
};

const String generationInstructions = '''
You generate a short, natural Japanese practice conversation for a beginner learner, from the vocabulary and sentence patterns provided.

Scope — the one hard rule:
- Use ONLY content words from the VOCABULARY list. Never introduce a noun, adjective, verb, name, or kanji that is not in it. If a line needs a word you don't have, choose a different one.
- A VOCABULARY entry marked "kana_only": true has NEVER been taught in kanji. Write it, and every conjugated form of it, entirely in kana — for example if たべる is kana_only, write たべます / たべません, never 食べます / 食べません. Only write kanji for a word whose entry actually has a "kanji" field (e.g. 鈴木 for すずき), and write exactly that kanji form, nothing else.
- You MAY freely recombine the grammar the learner already knows — the particles (は, etc.), the copula です, the question marker か, and the patterns in STRUCTURES — into natural sentences, including combinations not written out as a literal STRUCTURE. Prefer the listed STRUCTURES, but a sentence built only from known vocabulary plus these known grammar pieces is in scope even when it is not a listed pattern.
- Do NOT add honorifics, sentence-final particles, or any other word not in VOCABULARY (e.g. さん, ね, よ) — these have not necessarily been taught yet either, even though they seem minor.
- Respect each slot's form: a slot with form "negative" takes the negated form (i-adjective おもしろい → おもしろく).

Make it one coherent question-and-answer dialogue:
- Speakers are the VOCABULARY entries whose role is "name". Use at least two; have them take turns naturally.
- Every answer must fit its question:
  - A なん ("what") question is NOT yes/no — answer by identifying the thing (それは {noun} です), never with はい/いいえ.
  - A yes/no question about an i-adjective (この … は {adjective} ですか) is answered about that adjective — はい、{adjective} です / いいえ、{adjective-negative} ありません — not by switching to an unrelated noun.
  - A yes/no question about a thing (これは {noun} ですか) is answered はい、それは {noun} です / いいえ、それは {noun} ではありません, keeping the same thing in view.
  - A yes/no question about an action (…を {verb}ますか) is answered about that same action — はい、{verb in polite form} / いいえ、{verb in polite negative form} — keeping the same object in view, not switching to an unrelated action or object.
- The exchange should read like one connected conversation, not disconnected sentences.

For every line report: speaker_name_id and speaker_surface (which name is speaking), text (the full line), structure_id (which listed structure it instantiates, or 0 if it is a recombined sentence), and tokens (the line split into words). Each token's vocab_id is the id of the vocabulary entry it comes from, or 0 for grammatical glue (particles like は/を, the copula です, conjugation endings, the question marker か). A name used in the text is vocabulary — tag it with its id.
''';

/// The stable constraint context (cacheable prefix, decision D7). At prototype
/// scale this sits below the model's minimum cacheable size, so caching won't
/// actually engage until the real vocab store is large enough — the breakpoint
/// is placed correctly regardless.
String constraintContext(GenerationSeed seed) {
  final vocab = seed.vocab
      .map((w) => {
            'id': w.id,
            'kana': w.kana,
            if (w.kanji.isNotEmpty) 'kanji': w.kanji,
            if (w.kanji.isEmpty) 'kana_only': true,
            'role': w.role,
            if (w.meaning.isNotEmpty) 'meaning': w.meaning,
          })
      .toList();
  final structures = seed.structures
      .map((s) => {
            'id': s.id,
            'template': s.template,
            'slots': s.slots
                .map((sl) => {'name': sl.name, 'role': sl.role, 'form': sl.form})
                .toList(),
          })
      .toList();
  const enc = JsonEncoder.withIndent('  ');
  return 'VOCABULARY:\n${enc.convert(vocab)}\n\nSTRUCTURES:\n${enc.convert(structures)}';
}

Map<String, dynamic> buildGenerationRequest({
  required GenerationSeed seed,
  int lineCount = 6,
  String model = generationModel,
  int maxTokens = 4000,

  /// Optional topic/vocabulary steer, e.g. "eating, drinking, and going
  /// somewhere". Doesn't relax scope — just nudges which in-scope material the
  /// model reaches for. Useful for validation runs that need to exercise
  /// specific vocabulary/structures rather than whatever the model defaults to.
  String? focus,
}) {
  final instruction = StringBuffer('Generate a $lineCount-line conversation.');
  if (focus != null && focus.isNotEmpty) {
    instruction.write(' Favor vocabulary and patterns about: $focus.');
  }
  return {
    'model': model,
    'max_tokens': maxTokens,
    'output_config': {
      'format': {'type': 'json_schema', 'schema': generationSchema},
    },
    'system': [
      {'type': 'text', 'text': generationInstructions},
      {
        'type': 'text',
        'text': constraintContext(seed),
        'cache_control': {'type': 'ephemeral'},
      },
    ],
    'messages': [
      {'role': 'user', 'content': instruction.toString()},
    ],
  };
}

GeneratedConversation parseGenerationResponse(Map<String, dynamic> response) {
  if (response['stop_reason'] == 'refusal') {
    throw GenerationRefused(response['stop_details']);
  }
  final content = (response['content'] as List).cast<Map<String, dynamic>>();
  final textBlock = content.firstWhere(
    (b) => b['type'] == 'text',
    orElse: () => throw StateError(
      'no text block in response (stop_reason=${response['stop_reason']})',
    ),
  );
  final j = jsonDecode(textBlock['text'] as String) as Map<String, dynamic>;
  return GeneratedConversation(
    lines: (j['lines'] as List).map((l) {
      final m = l as Map<String, dynamic>;
      return GenLine(
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
    }).toList(),
    usedVocabIds: (j['used_vocab_ids'] as List).cast<int>(),
    usedStructureIds: (j['used_structure_ids'] as List).cast<int>(),
  );
}

// ---------------------------------------------------------------------------
// Scope validation (decision D6). Independently re-checks the model's report
// against the known sets. Until real segmentation exists this leans partly on
// the model's self-reported token mapping — see the prototype findings.
// ---------------------------------------------------------------------------

/// Grammatical "glue" the learner is assumed to already know — particles,
/// copula forms, and the like that the current STRUCTURES library relies on
/// as fixed template text. A glue-tagged token (vocab_id 0) is only trusted if
/// it's here (or pure punctuation); anything else is flagged, closing the gap
/// where an untaught word (an honorific, a discourse particle, ...) could hide
/// behind "it's just glue" because it carried no kanji (decision D20).
///
/// Deliberately curated by hand, the same discipline as the vocabulary store,
/// rather than auto-derived from template text — a template's fixed text can
/// itself be real vocabulary (これ/それ/あれ/なん are literal, unslotted text
/// in several structures), so "any substring of a template" is not a safe
/// derivation. Grounded in what generation actually emitted across every
/// structure in `tool/seed_demo.json` (verified live, decision D21). Extend
/// this set by hand whenever a new structure introduces grammar not already
/// listed — a future refinement is promoting this into a reviewable table
/// alongside Words/Structures rather than a hardcoded constant (open question
/// in `project-status.md`).
const Set<String> knownGrammarGlue = {
  'は', 'を', 'に', 'か', // particles
  'です', 'では', 'ありません', // copula + negative copula
  'はい', 'いいえ', // yes/no
  'この', // adnominal "this" (distinct from the standalone pronoun これ)
};

/// Matches a whole surface built entirely out of known glue pieces and/or
/// punctuation, in any combination (e.g. では + ありません = ではありません).
///
/// Live runs showed the model's tokenization granularity for these endings is
/// *not* stable across calls — です/か and では/ありません are sometimes split
/// into two tokens, sometimes fused into one (both observed live). Matching
/// on exact set membership alone flagged the fused form as a false positive.
/// Factoring the surface into known pieces (via regex alternation with
/// backtracking) tolerates that instability without weakening what's actually
/// being checked: every character must still trace back to known grammar.
final RegExp _glueFactoring = RegExp(
  '^(?:${knownGrammarGlue.map(RegExp.escape).join('|')}|[、。？！・\\s])+\$',
);

/// Whether an ungrounded (vocab_id 0) token is safe to pass through as known
/// grammar, vs. something that slipped in unvetted.
bool isKnownGlue(String surface) =>
    surface.isNotEmpty && _glueFactoring.hasMatch(surface);

/// Roles whose surface forms legitimately differ from the stored base form.
/// Everything else (nouns, names, particles, ...) must match its entry
/// exactly. Mirrors the capture UI's notion of conjugating roles
/// (`template_review_card.dart`).
const Set<String> conjugatingRoles = {'verb', 'i_adjective', 'na_adjective'};

class ScopeReport {
  ScopeReport(this.violations);
  final List<String> violations;
  bool get ok => violations.isEmpty;
}

ScopeReport validateScope(GeneratedConversation convo, GenerationSeed seed) {
  final violations = <String>[];
  final vocabIds = seed.vocabIds;
  final structureIds = seed.structureIds;
  final nameIds = seed.nameIds;
  final byId = seed.vocabById;

  // Inputs for the factoring check (below): the closed lexicon, and the
  // conjugation forms the structure library actually teaches — a ます-form
  // is only in scope once a taught pattern demands it (dictionary always is).
  final lexicon = [
    for (final w in seed.vocab)
      LexiconEntry(id: w.id, kana: w.kana, kanji: w.kanji, role: w.role),
  ];
  final taughtForms = {
    'dictionary',
    for (final s in seed.structures)
      for (final sl in s.slots) sl.form,
  };

  for (var i = 0; i < convo.lines.length; i++) {
    final line = convo.lines[i];
    final n = i + 1;
    if (!nameIds.contains(line.speakerNameId)) {
      violations.add(
          'line $n: speaker id ${line.speakerNameId} ("${line.speakerSurface}") is not a known name');
    }
    if (line.structureId != 0 && !structureIds.contains(line.structureId)) {
      violations.add('line $n: structure id ${line.structureId} is unknown');
    }
    // Every per-token check below sees only what the model put in `tokens`.
    // If `text` and the token surfaces disagree, a word could sit in `text`
    // unvalidated. Whitespace is ignored (`text` separates words with spaces,
    // tokens don't), and so is punctuation: the model sometimes omits 、 from
    // tokens (observed live, session 9), the factoring check already covers
    // every character of `text` including punctuation, and the reading screen
    // renders punctuation from `text`, not tokens (D42) — so a punctuation
    // mismatch is no longer a display or validation hole, just noise.
    final reconstructed =
        _comparable(line.tokens.map((t) => t.surface).join());
    if (reconstructed != _comparable(line.text)) {
      violations.add(
          'line $n: tokens do not reconstruct the line text — tokens spell '
          '"$reconstructed" but text is "${line.text}"');
    }
    // Independent factoring check (the D6 endgame): every character of the
    // line must trace to taught material — vocabulary forms, conjugations a
    // taught pattern demands, grammar glue, punctuation — with no reference
    // to the model's self-reported tokens at all. Catches what the
    // token-level checks structurally cannot: an untaught conjugation on a
    // taught stem (行きましょう), or consistent lying across text and tokens.
    final factoring = factorLine(
      line.text,
      lexicon: lexicon,
      taughtForms: taughtForms,
      glue: knownGrammarGlue,
    );
    if (!factoring.ok) {
      violations.add(
          'line $n: text does not factor into taught material — unmatched '
          'from "${factoring.unmatchedFrom}"');
    }
    for (final tok in line.tokens) {
      if (tok.vocabId != 0 && !vocabIds.contains(tok.vocabId)) {
        violations.add(
            'line $n: token "${tok.surface}" maps to unknown vocab id ${tok.vocabId}');
        continue;
      }
      // A glue-tagged token must be recognized grammar, not just "not kanji"
      // (decision D20/D21) — this catches both an invented kanji glue token
      // and a kana-only invented word like an untaught honorific (さん),
      // which the old kanji-only check could not distinguish from real glue.
      if (tok.isGlue && !isKnownGlue(tok.surface)) {
        violations.add(
            'line $n: token "${tok.surface}" is tagged as glue (vocab_id 0) but '
            'is not recognized grammar — likely an untaught word (e.g. a '
            'particle, ending, or honorific) that slipped in');
      }
      // A content token must not surface kanji for a vocab entry whose
      // `kanji` field is empty — that's "not taught in kanji", whether
      // because the word is intrinsically kana-only (kanaOnly: true) or
      // simply hasn't had kanji captured yet. Check kanji-emptiness directly
      // rather than the kanaOnly flag, which only covers the former case
      // (spec §3 kanji-only-if-printed, extended here to generated surface
      // forms).
      if (!tok.isGlue) {
        final word = byId[tok.vocabId];
        if (word == null) continue;
        if (word.kanji.isEmpty && _hasKanji(tok.surface)) {
          violations.add(
              'line $n: token "${tok.surface}" uses kanji for vocab id ${tok.vocabId} '
              '("${word.kana}"), which has no kanji taught yet');
          continue; // the surface check below would flag the same token again
        }
        // Surface↔entry consistency: the surface must actually be a form of
        // the entry it claims — its kana/kanji, or (for a conjugating role) a
        // stem-preserving conjugation of it. Closes the laundering gap where
        // a hallucinated surface tagged with a *valid* in-scope vocab id
        // passed every id-based check and would have rendered the wrong
        // furigana (the sibling hole of the D24 reconstruction check).
        final segments = furiganaSegments(
          surface: tok.surface,
          kana: word.kana,
          kanji: word.kanji,
          conjugates: conjugatingRoles.contains(word.role),
        );
        if (segments == null) {
          violations.add(
              'line $n: token "${tok.surface}" is not a recognizable form of '
              'vocab id ${tok.vocabId} ("${word.kana}"'
              '${word.kanji.isEmpty ? '' : ' / "${word.kanji}"'}) — possible '
              'hallucinated surface or wrong vocab id');
        }
      }
    }
  }
  for (final id in convo.usedVocabIds) {
    if (!vocabIds.contains(id)) {
      violations.add('used_vocab_ids contains unknown id $id');
    }
  }
  for (final id in convo.usedStructureIds) {
    if (!structureIds.contains(id)) {
      violations.add('used_structure_ids contains unknown id $id');
    }
  }
  return ScopeReport(violations);
}

bool _hasKanji(String s) => s.runes.any((r) => r >= 0x4E00 && r <= 0x9FFF);

/// Normalization for the text↔tokens compare: drops whitespace (ASCII and the
/// ideographic space U+3000, used interchangeably between words) and
/// punctuation (see the comment at the check for why that's safe).
String _comparable(String s) => s.replaceAll(RegExp(r'[、。？！・\s　]+'), '');

// ---------------------------------------------------------------------------
// Display (validates that furigana round-trips from the store, not the model).
// ---------------------------------------------------------------------------

/// Renders the conversation for a terminal: `Name: line` with furigana shown
/// as `stem[reading]` per segment, the reading taken from the store (the
/// seed), never from the model. Uses the okurigana split so a conjugated
/// surface keeps its conjugation (行きます → 行[い]きます) instead of being
/// replaced by the base form — the D5 okurigana fix.
String renderConversation(GeneratedConversation convo, GenerationSeed seed) {
  final byId = seed.vocabById;
  final buf = StringBuffer();
  for (final line in convo.lines) {
    final speaker = byId[line.speakerNameId];
    final speakerLabel = speaker != null
        ? _renderToken(speaker.kanji.isNotEmpty ? speaker.kanji : speaker.kana, speaker)
        : line.speakerSurface;
    final rendered =
        line.tokens.map((t) => _renderToken(t.surface, byId[t.vocabId])).join();
    buf.writeln('$speakerLabel: $rendered');
  }
  return buf.toString();
}

String _renderToken(String surface, SeedWord? w) {
  if (w == null || w.kanji.isEmpty) return surface;
  final segments = furiganaSegments(
    surface: surface,
    kana: w.kana,
    kanji: w.kanji,
    conjugates: conjugatingRoles.contains(w.role),
  );
  if (segments == null) return surface; // unreconcilable — validator flags it
  return segments
      .map((s) => s.ruby == null ? s.base : '${s.base}[${s.ruby}]')
      .join();
}

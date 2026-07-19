import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/capture/commit_service.dart' show CommitResult;
import 'package:mainichi/capture/models.dart';
import 'package:mainichi/data/conversation_cache.dart';
import 'package:mainichi/data/enums.dart';
import 'package:mainichi/data/seed_repository.dart';
import 'package:mainichi/generation/conversation_generator.dart';
import 'package:mainichi/generation/generation_client.dart';
import 'package:mainichi/listening/audio_store.dart';
import 'package:mainichi/listening/line_audio.dart';
import 'package:mainichi/listening/listening_providers.dart';
import 'package:mainichi/listening/playback_controller.dart';
import 'package:mainichi/reading/reading_providers.dart';
import 'package:mainichi/reading/scope_backfill.dart';
import 'package:mainichi/reading/screens/reading_exercise_screen.dart';

const _seed = GenerationSeed(
  vocab: [
    SeedWord(id: 20, kana: 'すずき', kanji: '鈴木', role: 'name'),
    SeedWord(id: 21, kana: 'たなか', kanji: '田中', role: 'name'),
    SeedWord(id: 5, kana: 'すし', role: 'noun', meaning: 'sushi'),
    SeedWord(id: 31, kana: 'たべる', kanji: '食べる', role: 'verb', meaning: 'to eat'),
  ],
  structures: [
    SeedStructure(id: 1, template: '{name_1} は {noun_1} を {verb_1} か', slots: [
      SeedSlot(name: 'name_1', role: 'name'),
      SeedSlot(name: 'noun_1', role: 'noun'),
      SeedSlot(name: 'verb_1', role: 'verb', form: 'polite'),
      SeedSlot(name: 'verb_2', role: 'verb', form: 'polite_negative'),
    ]),
  ],
);

/// Passes validateScope against [_seed]. Line 2's tokens omit the 、 that its
/// text carries — the observed live variance the screen must tolerate (D42).
final _conversation = GeneratedConversation(
  lines: const [
    GenLine(
      speakerNameId: 20,
      speakerSurface: '鈴木',
      text: '田中は すしを 食べますか。',
      structureId: 1,
      tokens: [
        GenToken(surface: '田中', vocabId: 21),
        GenToken(surface: 'は', vocabId: 0),
        GenToken(surface: 'すし', vocabId: 5),
        GenToken(surface: 'を', vocabId: 0),
        GenToken(surface: '食べます', vocabId: 31),
        GenToken(surface: 'か', vocabId: 0),
      ],
    ),
    GenLine(
      speakerNameId: 21,
      speakerSurface: '田中',
      text: 'いいえ、すしを 食べません。',
      structureId: 0,
      tokens: [
        GenToken(surface: 'いいえ', vocabId: 0),
        GenToken(surface: 'すし', vocabId: 5),
        GenToken(surface: 'を', vocabId: 0),
        GenToken(surface: '食べません', vocabId: 31),
      ],
    ),
  ],
  usedVocabIds: [5, 20, 21, 31],
  usedStructureIds: [1],
);

/// Out-of-scope against [_seed]: ねこ is untaught, glue-tagged (the model's
/// usual laundering of an unknown word). Both the glue check and factoring
/// reject it; ねこ is the word-shaped backfill candidate.
final _leakyConversation = GeneratedConversation(
  lines: const [
    GenLine(
      speakerNameId: 20,
      speakerSurface: '鈴木',
      text: 'ねこは すしを 食べます。',
      structureId: 0,
      tokens: [
        GenToken(surface: 'ねこ', vocabId: 0),
        GenToken(surface: 'は', vocabId: 0),
        GenToken(surface: 'すし', vocabId: 5),
        GenToken(surface: 'を', vocabId: 0),
        GenToken(surface: '食べます', vocabId: 31),
      ],
    ),
  ],
  usedVocabIds: const [5, 31],
  usedStructureIds: const [],
);

/// Out-of-scope against [_seed] over a single character: が is an untaught
/// particle (glue-tagged, not in the seed glue), the D56 backfill case. The
/// single-char candidate routes to the glue review sheet.
final _particleLeakyConversation = GeneratedConversation(
  lines: const [
    GenLine(
      speakerNameId: 20,
      speakerSurface: '鈴木',
      text: '田中が すしを 食べます。',
      structureId: 0,
      tokens: [
        GenToken(surface: '田中', vocabId: 21),
        GenToken(surface: 'が', vocabId: 0),
        GenToken(surface: 'すし', vocabId: 5),
        GenToken(surface: 'を', vocabId: 0),
        GenToken(surface: '食べます', vocabId: 31),
      ],
    ),
  ],
  usedVocabIds: const [5, 21, 31],
  usedStructureIds: const [],
);

class FakeSeedSource implements SeedSource {
  FakeSeedSource(this.seed);

  /// Mutable so a backfill test can enlarge the seed mid-flight, mimicking
  /// the real store growing when a word is committed.
  GenerationSeed seed;
  @override
  Future<GenerationSeed> loadGenerationSeed() async => seed;
}

/// Records commits; [onCommit] lets a test grow the fake seed the way a real
/// commit grows the store. No db involved.
class FakeScopeBackfillService implements ScopeBackfillService {
  FakeScopeBackfillService({this.onCommit, this.onCommitGlue});
  final void Function(VocabDraftItem approved, String surface)? onCommit;
  final void Function(String surface, GlueKind kind)? onCommitGlue;
  final List<String> committedSurfaces = [];
  final List<(String, GlueKind)> committedGlue = [];
  Object? error;

  @override
  VocabDraftItem draftForSurface(String surface) => VocabDraftItem(
        kana: surface,
        kanji: '',
        romaji: '',
        meaning: '',
        role: WordRole.other,
        kanaOnly: false,
        meaningSource: MeaningSource.none,
        confidence: ConfidenceTier.low,
      );

  @override
  Future<CommitResult> commit(VocabDraftItem approved,
      {required String surface}) async {
    if (error != null) throw error!;
    committedSurfaces.add(surface);
    onCommit?.call(approved, surface);
    return const CommitResult(
        newWordCount: 1, mergedCount: 0, newTemplateCount: 0, skipped: []);
  }

  @override
  Future<void> commitGlue(
      {required String surface, required GlueKind kind}) async {
    if (error != null) throw error!;
    committedGlue.add((surface, kind));
    onCommitGlue?.call(surface, kind);
  }
}

class FakeGenerationService implements GenerationService {
  FakeGenerationService(this.results);

  /// One entry per expected call: a [GeneratedConversation] to return or an
  /// [Exception] to throw. The last entry repeats.
  final List<Object> results;
  int calls = 0;

  @override
  Future<GeneratedConversation> generate({
    required GenerationSeed seed,
    int lineCount = 6,
    String? focus,
  }) async {
    final result = results[calls < results.length ? calls : results.length - 1];
    calls++;
    if (result is Exception) throw result;
    return result as GeneratedConversation;
  }
}

/// In-memory cache; conversations are practiced in insertion order for LRU.
class FakeConversationStore implements ConversationStore {
  final List<GeneratedConversation> saved = [];
  final List<int> practiced = [];

  @override
  Future<int> save(
    GeneratedConversation conversation, {
    required Set<int> wordIds,
    required Set<int> structureIds,
  }) async {
    saved.add(conversation);
    return saved.length - 1;
  }

  @override
  Future<CachedConversation?> leastRecentlyPracticed() async => saved.isEmpty
      ? null
      : CachedConversation(id: 0, conversation: saved.first);

  @override
  Future<void> markPracticed(int id) async => practiced.add(id);

  @override
  Future<void> setAudioPath(int id, String path) async =>
      audioPaths[id] = path;

  final Map<int, String> audioPaths = {};
}

/// In-memory [AudioStore] — the real one touches the filesystem, which
/// deadlocks under testWidgets' fake clock. Content-addressed caching is the
/// real store's own tested concern (test/listening/audio_store_test.dart);
/// here we only record what the screen asks for.
class FakeAudioStore implements AudioStore {
  final List<List<LineAudioSpec>> requests = [];
  Object? error;

  @override
  Future<List<String>> ensureAudio({
    required int conversationId,
    required List<LineAudioSpec> lines,
  }) async {
    if (error != null) throw error!;
    requests.add(lines);
    return [for (var i = 0; i < lines.length; i++) 'conv_$conversationId/$i.mp3'];
  }
}

class FakeLinePlayer implements LineAudioPlayer {
  final List<String> played = [];
  double? speed;
  bool disposed = false;

  @override
  Future<bool> playFile(String path) async {
    played.add(path);
    return true;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> setSpeed(double value) async => speed = value;

  @override
  Future<void> dispose() async => disposed = true;
}

Future<FakeGenerationService> _pumpScreen(
  WidgetTester tester, {
  GenerationSeed seed = _seed,
  FakeSeedSource? seedSource,
  List<Object>? results,
  FakeConversationStore? cache,
  FakeAudioStore? audio,
  FakeLinePlayer? player,
  FakeScopeBackfillService? backfill,
  ReadingStart start = ReadingStart.generate,
}) async {
  final service = FakeGenerationService(results ?? [_conversation]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seedSourceProvider
            .overrideWithValue(seedSource ?? FakeSeedSource(seed)),
        generationServiceProvider.overrideWithValue(service),
        conversationStoreProvider
            .overrideWithValue(cache ?? FakeConversationStore()),
        conversationAudioStoreProvider
            .overrideWithValue(audio ?? FakeAudioStore()),
        lineAudioPlayerFactoryProvider
            .overrideWithValue(() => player ?? FakeLinePlayer()),
        scopeBackfillProvider
            .overrideWithValue(backfill ?? FakeScopeBackfillService()),
      ],
      child: MaterialApp(home: ReadingExerciseScreen(start: start)),
    ),
  );
  return service;
}

void main() {
  // The fake conversation must stay a valid one — the whole screen flow
  // depends on it passing the real validator.
  test('fixture conversation passes validateScope', () {
    expect(validateScope(_conversation, _seed).violations, isEmpty);
  });

  testWidgets('loads on entry: spinner first, then the conversation',
      (tester) async {
    await _pumpScreen(tester);
    expect(find.text('Generating a conversation…'), findsOneWidget);

    await tester.pump();
    expect(find.text('鈴木'), findsOneWidget); // speaker margin column
    expect(find.text('食べます'), findsNothing); // segmented: 食 + べます
    expect(find.text('べます'), findsOneWidget);
    expect(find.text('Tap any word to look it up'), findsOneWidget);
  });

  testWidgets('renders punctuation from text even when tokens omit it (D42)',
      (tester) async {
    await _pumpScreen(tester);
    await tester.pump();
    // Line 2's tokens have no 、 — it must still show, from `text`.
    expect(find.text('、'), findsOneWidget);
  });

  testWidgets('word tap opens the lookup sheet with store data and form',
      (tester) async {
    await _pumpScreen(tester);
    await tester.pump();

    await tester.tap(find.text('べません'));
    await tester.pumpAndSettle();

    expect(find.text('MEANING'), findsOneWidget);
    expect(find.textContaining('to eat'), findsOneWidget);
    expect(find.textContaining('negative, polite'), findsOneWidget); // D44
    expect(find.text('たべません'), findsOneWidget); // conjugated reading
    expect(find.text('DICTIONARY FORM'), findsOneWidget);
    expect(find.text('たべる'), findsOneWidget);
    expect(find.text('verb'), findsOneWidget); // role chip
  });

  testWidgets('a base-form word gets no form annotation or dictionary card',
      (tester) async {
    await _pumpScreen(tester);
    await tester.pump();

    await tester.tap(find.text('すし').first);
    await tester.pumpAndSettle();

    expect(find.text('MEANING'), findsOneWidget);
    expect(find.text('sushi'), findsOneWidget);
    expect(find.textContaining('·'), findsNothing);
    expect(find.text('DICTIONARY FORM'), findsNothing);
  });

  testWidgets('glue is not tappable', (tester) async {
    await _pumpScreen(tester);
    await tester.pump();

    await tester.tap(find.text('は').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('MEANING'), findsNothing);
  });

  testWidgets('furigana toggle hides readings and flips the footer hint',
      (tester) async {
    await _pumpScreen(tester);
    await tester.pump();
    expect(find.text('たなか'), findsOneWidget); // ruby over the 田中 token

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('たなか'), findsNothing);
    expect(find.text('田中'), findsNWidgets(2)); // token + margin name remain
    expect(find.textContaining("hasn't stuck"), findsOneWidget);
  });

  testWidgets('Next generates a fresh conversation', (tester) async {
    final service = await _pumpScreen(tester);
    await tester.pump();

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump();
    expect(service.calls, 2);
    expect(find.text('べません'), findsOneWidget);
  });

  testWidgets('refusal shows the error state; Try again recovers',
      (tester) async {
    final service = await _pumpScreen(
      tester,
      results: [GenerationRefused('declined'), _conversation],
    );
    await tester.pump();

    expect(find.text("Couldn't generate that one"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(service.calls, 2);
    expect(find.text('べません'), findsOneWidget);
  });

  // The catch-all in loadNext no longer blames the connection for every
  // failure — it classifies the caught error so the intermittent-failure
  // question can be told apart on-screen (features/reading-exercise.md).
  DioException dioStatus(int status) => DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: status,
        ),
        type: DioExceptionType.badResponse,
      );

  testWidgets('connection failure keeps the check-your-connection message',
      (tester) async {
    await _pumpScreen(tester, results: [
      DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.text("Couldn't generate that one"), findsOneWidget);
    expect(find.textContaining('Check your connection'), findsOneWidget);
  });

  testWidgets('a 429 reads as busy, not a connection problem', (tester) async {
    await _pumpScreen(tester, results: [dioStatus(429)]);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('rate limit'), findsOneWidget);
    expect(find.textContaining('Check your connection'), findsNothing);
  });

  testWidgets('a 5xx reads as overloaded', (tester) async {
    await _pumpScreen(tester, results: [dioStatus(529)]);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('overloaded'), findsOneWidget);
  });

  testWidgets('a 401 points at the API key', (tester) async {
    await _pumpScreen(tester, results: [dioStatus(401)]);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('API key'), findsOneWidget);
  });

  testWidgets('an unparseable reply reads as a bad response, not offline',
      (tester) async {
    await _pumpScreen(tester, results: [const FormatException('bad json')]);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('could not be read'), findsOneWidget);
    expect(find.textContaining('Check your connection'), findsNothing);
  });

  testWidgets('out-of-scope output is discarded, never shown', (tester) async {
    await _pumpScreen(tester, results: [_leakyConversation]);
    await tester.pump();

    expect(find.textContaining('in scope'), findsOneWidget);
    // The conversation itself is never rendered (no speaker margin, no line
    // text) — the only place the untaught surface may appear is the backfill
    // chip below.
    expect(find.text('鈴木'), findsNothing);
    expect(find.text('べます'), findsNothing);
  });

  testWidgets('scope failure offers the unmatched word as a backfill chip',
      (tester) async {
    await _pumpScreen(tester, results: [_leakyConversation]);
    await tester.pump();

    expect(find.text('Missing from your Bunko?'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'ねこ'), findsOneWidget);
  });

  testWidgets('non-scope errors show no backfill chips', (tester) async {
    await _pumpScreen(tester, results: [GenerationRefused('declined')]);
    await tester.pump();
    await tester.pump();

    expect(find.text("Couldn't generate that one"), findsOneWidget);
    expect(find.text('Missing from your Bunko?'), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('backfill approve requires a meaning', (tester) async {
    await _pumpScreen(tester, results: [_leakyConversation]);
    await tester.pump();

    await tester.tap(find.widgetWithText(ActionChip, 'ねこ'));
    await tester.pumpAndSettle();

    expect(find.text('Did your class teach this?'), findsOneWidget);
    final approve = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Approve'));
    expect(approve.onPressed, isNull); // disabled: meaning still empty

    // TextFields in the sheet: kanji free-text (no candidates), then meaning.
    await tester.enterText(find.byType(TextField).at(1), 'cat');
    await tester.pump();
    final enabled = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Approve'));
    expect(enabled.onPressed, isNotNull);
  });

  testWidgets('approving a backfill word self-heals the rejected conversation',
      (tester) async {
    final seedSource = FakeSeedSource(_seed);
    final backfill = FakeScopeBackfillService(
      onCommit: (approved, surface) {
        // A real commit grows the store; grow the fake seed the same way.
        seedSource.seed = GenerationSeed(
          vocab: [
            ..._seed.vocab,
            SeedWord(id: 99, kana: surface, role: 'noun', meaning: approved.meaning),
          ],
          structures: _seed.structures,
        );
      },
    );
    final cache = FakeConversationStore();
    await _pumpScreen(tester,
        seedSource: seedSource,
        results: [_leakyConversation],
        backfill: backfill,
        cache: cache);
    await tester.pump();

    await tester.tap(find.widgetWithText(ActionChip, 'ねこ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'cat');
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Approve'));
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    expect(backfill.committedSurfaces, ['ねこ']);
    // The previously rejected conversation now renders — the mislabeled-glue
    // ねこ passes via the D53 relaxation, factoring covers it via the seed.
    expect(find.text('ねこ'), findsOneWidget);
    expect(find.text('べます'), findsOneWidget);
    expect(cache.saved, [_leakyConversation]); // persisted like any valid one
  });

  testWidgets('backfill with remaining untaught material returns to the error',
      (tester) async {
    // Two untaught words; adding one still leaves the other.
    final doubleLeaky = GeneratedConversation(
      lines: [
        GenLine(
          speakerNameId: 20,
          speakerSurface: '鈴木',
          text: 'ねこは いぬを 食べますか。',
          structureId: 0,
          tokens: const [
            GenToken(surface: 'ねこ', vocabId: 0),
            GenToken(surface: 'は', vocabId: 0),
            GenToken(surface: 'いぬ', vocabId: 0),
            GenToken(surface: 'を', vocabId: 0),
            GenToken(surface: '食べます', vocabId: 31),
            GenToken(surface: 'か', vocabId: 0),
          ],
        ),
      ],
      usedVocabIds: const [31],
      usedStructureIds: const [],
    );
    final seedSource = FakeSeedSource(_seed);
    final backfill = FakeScopeBackfillService(
      onCommit: (approved, surface) {
        seedSource.seed = GenerationSeed(
          vocab: [
            ..._seed.vocab,
            SeedWord(id: 99, kana: surface, role: 'noun'),
          ],
          structures: _seed.structures,
        );
      },
    );
    await _pumpScreen(tester,
        seedSource: seedSource, results: [doubleLeaky], backfill: backfill);
    await tester.pump();

    expect(find.widgetWithText(ActionChip, 'ねこ'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'いぬ'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'ねこ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'cat');
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Approve'));
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    // Progress, not success: distinct message, the added word's chip is gone,
    // the remaining one stays actionable.
    expect(find.textContaining('still uses other untaught material'),
        findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'ねこ'), findsNothing);
    expect(find.widgetWithText(ActionChip, 'いぬ'), findsOneWidget);
  });

  testWidgets('backfill discard removes the chip; skip keeps it',
      (tester) async {
    await _pumpScreen(tester, results: [_leakyConversation]);
    await tester.pump();

    // Skip: sheet closes, chip stays.
    await tester.tap(find.widgetWithText(ActionChip, 'ねこ'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Skip'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Skip'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, 'ねこ'), findsOneWidget);

    // Discard: chip goes away, nothing committed.
    await tester.tap(find.widgetWithText(ActionChip, 'ねこ'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Discard extraction'));
    await tester.tap(find.text('Discard extraction'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, 'ねこ'), findsNothing);
    expect(find.text('Missing from your Bunko?'), findsNothing);
  });

  testWidgets('a single-char chip opens the glue sheet; approving commits '
      'glue and self-heals (D56)', (tester) async {
    final seedSource = FakeSeedSource(_seed);
    final backfill = FakeScopeBackfillService(
      onCommitGlue: (surface, kind) {
        // A real commit grows the glue table; grow the fake seed's glue.
        seedSource.seed = GenerationSeed(
          vocab: _seed.vocab,
          structures: _seed.structures,
          glue: {...seedGrammarGlue, surface},
        );
      },
    );
    final cache = FakeConversationStore();
    await _pumpScreen(tester,
        seedSource: seedSource,
        results: [_particleLeakyConversation],
        backfill: backfill,
        cache: cache);
    await tester.pump();

    await tester.tap(find.widgetWithText(ActionChip, 'が'));
    await tester.pumpAndSettle();
    // The glue-flavored sheet, defaulting to particle — not the word card.
    expect(find.text('What kind of grammar?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    expect(backfill.committedGlue, [('が', GlueKind.particle)]);
    expect(backfill.committedSurfaces, isEmpty); // glue path, not the word one
    // The previously rejected conversation now renders and is persisted.
    expect(find.text('べます'), findsOneWidget);
    expect(cache.saved, [_particleLeakyConversation]);
  });

  testWidgets('the glue sheet toggles to word mode, committing through the '
      'word path instead', (tester) async {
    final seedSource = FakeSeedSource(_seed);
    final backfill = FakeScopeBackfillService(
      onCommit: (approved, surface) {
        seedSource.seed = GenerationSeed(
          vocab: [
            ..._seed.vocab,
            SeedWord(id: 99, kana: surface, role: 'noun'),
          ],
          structures: _seed.structures,
        );
      },
    );
    await _pumpScreen(tester,
        seedSource: seedSource,
        results: [_particleLeakyConversation],
        backfill: backfill);
    await tester.pump();

    await tester.tap(find.widgetWithText(ActionChip, 'が'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    // Word mode: the capture card with its meaning requirement.
    expect(find.text('What kind of grammar?'), findsNothing);
    await tester.enterText(find.byType(TextField).at(1), 'mosquito');
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Approve'));
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    expect(backfill.committedSurfaces, ['が']);
    expect(backfill.committedGlue, isEmpty);
  });

  testWidgets('a valid conversation is written through to the cache',
      (tester) async {
    final cache = FakeConversationStore();
    await _pumpScreen(tester, cache: cache);
    await tester.pump();
    await tester.pump();

    expect(cache.saved, hasLength(1));
    // Link data derives from validated tokens/lines, not the model's report.
    expect(cache.saved.single.tokenVocabIds, {5, 21, 31});
    expect(cache.saved.single.lineStructureIds, {1});
  });

  testWidgets('error state offers a reread when the cache has content',
      (tester) async {
    final cache = FakeConversationStore()..saved.add(_conversation);
    await _pumpScreen(tester,
        results: [GenerationRefused('declined')], cache: cache);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Reread an earlier one'));
    await tester.pump();
    await tester.pump();

    expect(find.text('べません'), findsOneWidget); // cached conversation shown
    expect(cache.practiced, [0]); // lastPracticedAt rotated
  });

  testWidgets('no reread offer on an empty cache', (tester) async {
    await _pumpScreen(tester, results: [GenerationRefused('declined')]);
    await tester.pump();
    await tester.pump();

    expect(find.text("Couldn't generate that one"), findsOneWidget);
    expect(find.text('Reread an earlier one'), findsNothing);
  });

  testWidgets('reread entry serves a cached conversation without generating',
      (tester) async {
    final cache = FakeConversationStore()..saved.add(_conversation);
    final service = await _pumpScreen(
        tester, cache: cache, start: ReadingStart.reread);
    await tester.pump();
    await tester.pump();

    expect(find.text('べません'), findsOneWidget); // cached conversation shown
    expect(service.calls, 0); // reread never touches the generator
    expect(cache.practiced, [0]); // lastPracticedAt rotated
  });

  testWidgets('reread Next rotates within the cache, never generating',
      (tester) async {
    final cache = FakeConversationStore()..saved.add(_conversation);
    final service = await _pumpScreen(
        tester, cache: cache, start: ReadingStart.reread);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump();

    expect(service.calls, 0); // still no generation
    expect(cache.practiced, [0, 0]); // rotated again
  });

  testWidgets('reread entry with an empty cache explains itself',
      (tester) async {
    final service =
        await _pumpScreen(tester, start: ReadingStart.reread);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Nothing cached yet'), findsOneWidget);
    expect(service.calls, 0);
  });

  testWidgets('audio bar renders with speed control; nothing plays unasked',
      (tester) async {
    final audio = FakeAudioStore();
    await _pumpScreen(tester, audio: audio);
    await tester.pump();
    await tester.pump();

    expect(find.byTooltip('Play'), findsOneWidget);
    expect(find.text('0.5×'), findsOneWidget);
    expect(find.text('1×'), findsOneWidget);
    expect(audio.requests, isEmpty); // lazy: nothing fetched before first play
  });

  testWidgets('play requests store-kana audio and plays the lines in order',
      (tester) async {
    final audio = FakeAudioStore();
    final player = FakeLinePlayer();
    await _pumpScreen(tester, audio: audio, player: player);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('Play'));
    await tester.pumpAndSettle();

    // TTS input is the store's kana with punctuation from text, never kanji.
    expect(audio.requests.single.map((s) => s.kana).toList(),
        ['たなかは すしを たべますか。', 'いいえ、すしを たべません。']);
    // Two speakers, two voices.
    expect(audio.requests.single.map((s) => s.voice).toSet(), hasLength(2));
    expect(player.played, ['conv_0/0.mp3', 'conv_0/1.mp3']);

    // The margin affordance replays a single line.
    await tester.tap(find.byTooltip('Play this line').last);
    await tester.pumpAndSettle();
    expect(player.played.last, 'conv_0/1.mp3');
    expect(player.played, hasLength(3));
  });

  testWidgets('speed selection reaches the player', (tester) async {
    final player = FakeLinePlayer();
    await _pumpScreen(tester, player: player);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('0.5×'));
    await tester.pumpAndSettle();
    expect(player.speed, 0.5);
  });

  testWidgets('listening mode blurs the text and a tap reveals it',
      (tester) async {
    await _pumpScreen(tester);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('Listening mode (hide text)'));
    await tester.pumpAndSettle();
    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.textContaining('tap the text to reveal'), findsOneWidget);

    // While blurred, tapping a word reveals the text instead of opening the
    // lookup sheet — the check-what-you-heard gesture.
    await tester.tap(find.text('すし').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('MEANING'), findsNothing);
    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.text('Tap any word to look it up'), findsOneWidget);
  });

  testWidgets('a failed synthesis shows an inline audio error, text stays',
      (tester) async {
    final audio = FakeAudioStore()..error = Exception('boom');
    await _pumpScreen(tester, audio: audio);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('Play'));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't fetch the audio"), findsOneWidget);
    expect(find.text('べません'), findsOneWidget); // reading unaffected
  });

  testWidgets('an empty Bunko explains itself without calling the API',
      (tester) async {
    final service = await _pumpScreen(
      tester,
      seed: const GenerationSeed(vocab: [], structures: []),
    );
    await tester.pump();

    expect(find.textContaining('import a worksheet'), findsOneWidget);
    expect(service.calls, 0);
  });
}

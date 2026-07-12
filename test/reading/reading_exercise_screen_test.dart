import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/conversation_cache.dart';
import 'package:mainichi/data/seed_repository.dart';
import 'package:mainichi/generation/conversation_generator.dart';
import 'package:mainichi/generation/generation_client.dart';
import 'package:mainichi/listening/audio_store.dart';
import 'package:mainichi/listening/line_audio.dart';
import 'package:mainichi/listening/listening_providers.dart';
import 'package:mainichi/listening/playback_controller.dart';
import 'package:mainichi/reading/reading_providers.dart';
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

class FakeSeedSource implements SeedSource {
  FakeSeedSource(this.seed);
  final GenerationSeed seed;
  @override
  Future<GenerationSeed> loadGenerationSeed() async => seed;
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
  List<Object>? results,
  FakeConversationStore? cache,
  FakeAudioStore? audio,
  FakeLinePlayer? player,
}) async {
  final service = FakeGenerationService(results ?? [_conversation]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seedSourceProvider.overrideWithValue(FakeSeedSource(seed)),
        generationServiceProvider.overrideWithValue(service),
        conversationStoreProvider
            .overrideWithValue(cache ?? FakeConversationStore()),
        conversationAudioStoreProvider
            .overrideWithValue(audio ?? FakeAudioStore()),
        lineAudioPlayerFactoryProvider
            .overrideWithValue(() => player ?? FakeLinePlayer()),
      ],
      child: const MaterialApp(home: ReadingExerciseScreen()),
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

  testWidgets('out-of-scope output is discarded, never shown', (tester) async {
    final leaky = GeneratedConversation(
      lines: [
        GenLine(
          speakerNameId: 20,
          speakerSurface: '鈴木',
          text: 'ねこは すしを 食べます。', // ねこ is untaught
          structureId: 0,
          tokens: const [
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
    await _pumpScreen(tester, results: [leaky]);
    await tester.pump();

    expect(find.textContaining('in scope'), findsOneWidget);
    expect(find.text('ねこ'), findsNothing);
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

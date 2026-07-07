import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/seed_repository.dart';
import 'package:mainichi/generation/conversation_generator.dart';
import 'package:mainichi/generation/generation_client.dart';
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

Future<FakeGenerationService> _pumpScreen(
  WidgetTester tester, {
  GenerationSeed seed = _seed,
  List<Object>? results,
}) async {
  final service = FakeGenerationService(results ?? [_conversation]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seedSourceProvider.overrideWithValue(FakeSeedSource(seed)),
        generationServiceProvider.overrideWithValue(service),
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

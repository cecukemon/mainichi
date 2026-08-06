import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/seed_repository.dart';
import 'package:mainichi/generation/conversation_generator.dart';
import 'package:mainichi/listening/line_audio.dart' show LineAudioSpec;
import 'package:mainichi/listening/playback_controller.dart' show LineAudioPlayer;
import 'package:mainichi/reading/reading_providers.dart' show seedSourceProvider;
import 'package:mainichi/speaking/conversation_client.dart';
import 'package:mainichi/speaking/conversation_turn.dart';
import 'package:mainichi/speaking/free_conv_audio.dart';
import 'package:mainichi/speaking/free_conv_audio_store.dart';
import 'package:mainichi/speaking/screens/free_conversation_screen.dart';
import 'package:mainichi/speaking/speaking_providers.dart';
import 'package:mainichi/speaking/speech_recorder.dart';
import 'package:mainichi/speaking/stt_service.dart';

const _seed = GenerationSeed(
  vocab: [
    SeedWord(id: 20, kana: 'すずき', kanji: '鈴木', role: 'name'),
    SeedWord(id: 4, kana: 'ほん', role: 'noun', meaning: 'book'),
  ],
  structures: [],
);

ConversationTurn _turn(String text, {TurnGrade? grade}) => ConversationTurn(
      reply: GenLine(
        speakerNameId: 20,
        speakerSurface: 'すずき',
        text: text,
        structureId: 0,
        tokens: const [
          GenToken(surface: 'ほん', vocabId: 4),
          GenToken(surface: 'です', vocabId: 0),
          GenToken(surface: 'か', vocabId: 0),
        ],
      ),
      grade: grade,
    );

class _FakeSeedSource implements SeedSource {
  _FakeSeedSource(this.seed);
  final GenerationSeed seed;
  @override
  Future<GenerationSeed> loadGenerationSeed() async => seed;
}

class _FakeRecorder implements SpeechRecorder {
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<void> start() async {}
  @override
  Future<List<int>?> stop() async => [1, 2, 3];
  @override
  Future<void> cancel() async {}
  @override
  Future<void> dispose() async {}
}

class _FakeStt implements SttService {
  _FakeStt(this.transcript);
  final String transcript;
  @override
  Future<String> transcribe(List<int> audioContent) async => transcript;
}

/// A player whose completion the test controls, mirroring
/// `free_conv_audio_test.dart`'s `_ScriptedPlayer`.
class _ScriptedPlayer implements LineAudioPlayer {
  final List<String> played = [];
  Completer<bool>? _current;

  void finishCurrent() {
    final c = _current;
    _current = null;
    c?.complete(true);
  }

  @override
  Future<bool> playFile(String path) {
    played.add(path);
    _current = Completer<bool>();
    return _current!.future;
  }

  @override
  Future<void> stop() async {
    final c = _current;
    _current = null;
    c?.complete(false);
  }

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> dispose() async {}
}

/// An in-memory store — no real filesystem access, so it's safe under the
/// widget test framework's fake clock (see `free_conv_audio_store.dart`).
class _FakeStore implements FreeConvAudioStore {
  final List<LineAudioSpec> synthesized = [];

  @override
  Future<String> ensureFile(LineAudioSpec spec) async {
    if (!synthesized.contains(spec)) synthesized.add(spec);
    return 'fake/${spec.kana}-${spec.voice}.mp3';
  }

  @override
  Future<void> clear() async {}
}

class _FakeConversation implements ConversationService {
  _FakeConversation(this.results);
  final List<ConversationTurn> results;
  int calls = 0;

  @override
  Future<ConversationTurn> turn({
    required GenerationSeed seed,
    List<TurnHistory> history = const [],
    String? latestReply,
    String? personaSurface,
  }) async {
    final r = results[calls < results.length ? calls : results.length - 1];
    calls++;
    return r;
  }
}

Widget _launcher(
  ConversationService service, {
  GenerationSeed seed = _seed,
  String transcript = 'はい',
  FreeConvAudioStore? store,
  LineAudioPlayer? player,
}) {
  return ProviderScope(
    overrides: [
      seedSourceProvider.overrideWithValue(_FakeSeedSource(seed)),
      sttServiceProvider.overrideWithValue(_FakeStt(transcript)),
      speechRecorderFactoryProvider.overrideWithValue(() => _FakeRecorder()),
      conversationServiceProvider.overrideWithValue(service),
      freeConvAudioControllerFactoryProvider.overrideWithValue(
        (seed) => FreeConvAudioController(
          store: store ?? _FakeStore(),
          player: player ?? _ScriptedPlayer(),
          seed: seed,
        ),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const FreeConversationScreen()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('opens with an in-scope line rendered with furigana',
      (tester) async {
    await tester.pumpWidget(_launcher(_FakeConversation([_turn('ほんですか')])));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('すずき'), findsOneWidget); // persona label
    expect(find.text('ほん'), findsWidgets); // the noun token's base
  });

  testWidgets('the app line never plays automatically', (tester) async {
    final store = _FakeStore();
    await tester.pumpWidget(
        _launcher(_FakeConversation([_turn('ほんですか')]), store: store));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(store.synthesized, isEmpty);
    expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
  });

  testWidgets('tapping the speak button plays the line, then returns to idle',
      (tester) async {
    final store = _FakeStore();
    final player = _ScriptedPlayer();
    await tester.pumpWidget(_launcher(_FakeConversation([_turn('ほんですか')]),
        store: store, player: player));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.volume_up_outlined));
    await tester.pump();
    await tester.pump();
    expect(store.synthesized, hasLength(1));
    expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);

    player.finishCurrent();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
    expect(find.byIcon(Icons.stop_circle_outlined), findsNothing);
  });

  testWidgets('a spoken reply shows the transcript, verdict, and rewrite',
      (tester) async {
    final service = _FakeConversation([
      _turn('ほんですか'), // opening
      _turn('ほんですか',
          grade: const TurnGrade(
              verdict: TurnVerdict.good,
              note: 'Nice.',
              rewrite: 'はい、そうです')),
    ]);
    await tester.pumpWidget(_launcher(service));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mic)); // start recording
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.stop), findsOneWidget);

    await tester.tap(find.byIcon(Icons.stop)); // stop → transcribe → submit
    await tester.pumpAndSettle();

    expect(find.textContaining('You: はい'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.textContaining('Try saying: はい、そうです'), findsOneWidget);
  });

  testWidgets('close ends the conversation and pops', (tester) async {
    await tester.pumpWidget(_launcher(_FakeConversation([_turn('ほんですか')])));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('すずき'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('すずき'), findsNothing);
    expect(find.text('open'), findsOneWidget); // back at the launcher
  });

  testWidgets('an empty Bunko explains itself without a mic', (tester) async {
    await tester.pumpWidget(_launcher(
      _FakeConversation([_turn('ほんですか')]),
      seed: const GenerationSeed(vocab: [], structures: []),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Import a worksheet'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsNothing);
  });
}

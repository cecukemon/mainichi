import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/generation/conversation_generator.dart';
import 'package:mainichi/settings/api_key_store.dart';
import 'package:mainichi/speaking/conversation_client.dart';
import 'package:mainichi/speaking/conversation_turn.dart';
import 'package:mainichi/speaking/free_conversation_controller.dart';
import 'package:mainichi/speaking/speech_recorder.dart';
import 'package:mainichi/speaking/stt_service.dart';

const _seed = GenerationSeed(
  vocab: [
    SeedWord(id: 20, kana: 'すずき', kanji: '鈴木', role: 'name'),
    SeedWord(id: 4, kana: 'ほん', role: 'noun', meaning: 'book'),
  ],
  structures: [],
);

// A seed with no name-role word — a conversation has no possible persona.
const _noNameSeed = GenerationSeed(
  vocab: [SeedWord(id: 4, kana: 'ほん', role: 'noun')],
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

// An out-of-scope reply (unknown vocab id) — fails validateNextLine.
ConversationTurn _badTurn() => ConversationTurn(
      reply: const GenLine(
        speakerNameId: 20,
        speakerSurface: 'すずき',
        text: 'ねこです',
        structureId: 0,
        tokens: [
          GenToken(surface: 'ねこ', vocabId: 999),
          GenToken(surface: 'です', vocabId: 0),
        ],
      ),
      grade: const TurnGrade(verdict: TurnVerdict.good, note: '', rewrite: ''),
    );

const _goodGrade =
    TurnGrade(verdict: TurnVerdict.good, note: 'Nice.', rewrite: '');

class _FakeRecorder implements SpeechRecorder {
  bool permission = true;
  List<int>? bytes = [1, 2, 3];
  bool disposed = false;

  @override
  Future<bool> hasPermission() async => permission;
  @override
  Future<void> start() async {}
  @override
  Future<List<int>?> stop() async => bytes;
  @override
  Future<void> cancel() async {}
  @override
  Future<void> dispose() async => disposed = true;
}

class _FakeStt implements SttService {
  _FakeStt(this.transcript);
  String transcript;
  Object? error;

  @override
  Future<String> transcribe(List<int> audioContent) async {
    if (error != null) throw error!;
    return transcript;
  }
}

class _FakeConversation implements ConversationService {
  _FakeConversation(this.results);

  /// One entry per call: a [ConversationTurn] to return or an [Object] to
  /// throw. The last entry repeats (so a persistent scope failure exhausts
  /// the retries).
  final List<Object> results;
  int calls = 0;
  final List<String?> latestReplies = [];
  final List<String?> personas = [];

  @override
  Future<ConversationTurn> turn({
    required GenerationSeed seed,
    List<TurnHistory> history = const [],
    String? latestReply,
    String? personaSurface,
  }) async {
    latestReplies.add(latestReply);
    personas.add(personaSurface);
    final r = results[calls < results.length ? calls : results.length - 1];
    calls++;
    if (r is ConversationTurn) return r;
    throw r;
  }
}

void main() {
  test('start loads the opening app line, no grade, no reply sent', () async {
    final service = _FakeConversation([_turn('ほんですか')]);
    final c = FreeConversationController(
      recorder: _FakeRecorder(),
      stt: _FakeStt('はい'),
      service: service,
      seed: _seed,
    );
    await c.start();

    expect(c.status, FreeConvStatus.idle);
    expect(c.turns, hasLength(1));
    expect(c.turns.single.appLine.text, 'ほんですか');
    expect(c.turns.single.answered, isFalse);
    expect(c.personaSurface, 'すずき');
    expect(service.latestReplies, [null]); // opening carries no reply
  });

  test('a spoken reply appends the learner turn, its grade, and the next line',
      () async {
    final service = _FakeConversation([
      _turn('ほんですか'), // opening, no grade
      _turn('ほんですか', grade: _goodGrade), // graded turn + next line
    ]);
    final c = FreeConversationController(
      recorder: _FakeRecorder(),
      stt: _FakeStt('はい'),
      service: service,
      seed: _seed,
    );
    await c.start();

    await c.toggleMic(); // start recording
    expect(c.status, FreeConvStatus.recording);
    await c.toggleMic(); // stop → transcribe → submit

    expect(c.status, FreeConvStatus.idle);
    expect(c.turns, hasLength(2));
    expect(c.turns[0].answered, isTrue);
    expect(c.turns[0].learnerTranscript, 'はい');
    expect(c.turns[0].grade!.verdict, TurnVerdict.good);
    expect(c.turns[1].answered, isFalse);
    expect(service.latestReplies, [null, 'はい']);
    expect(service.personas.last, 'すずき'); // persona pinned into the turn call
  });

  test('an out-of-scope next line retries, then errors without appending',
      () async {
    final service = _FakeConversation([
      _turn('ほんですか'), // opening ok
      _badTurn(), // every turn call returns an out-of-scope line (repeats)
    ]);
    final c = FreeConversationController(
      recorder: _FakeRecorder(),
      stt: _FakeStt('はい'),
      service: service,
      seed: _seed,
    );
    await c.start();
    await c.toggleMic();
    await c.toggleMic();

    expect(c.status, FreeConvStatus.error);
    // opening (1) + submit's 1 try + 2 retries (3) = 4 calls.
    expect(service.calls, 4);
    expect(c.turns, hasLength(1)); // nothing appended
    expect(c.turns.single.answered, isFalse);
  });

  test('retry resends the held reply after a transport error', () async {
    final service = _FakeConversation([
      _turn('ほんですか'), // opening
      DioException(requestOptions: RequestOptions(path: '')), // submit throws
      _turn('ほんですか', grade: _goodGrade), // retry succeeds
    ]);
    final c = FreeConversationController(
      recorder: _FakeRecorder(),
      stt: _FakeStt('はい'),
      service: service,
      seed: _seed,
    );
    await c.start();
    await c.toggleMic();
    await c.toggleMic();
    expect(c.status, FreeConvStatus.error);

    await c.retry();
    expect(c.status, FreeConvStatus.idle);
    expect(c.turns, hasLength(2));
    expect(c.turns[0].learnerTranscript, 'はい');
  });

  test('denied microphone permission is an error, nothing recorded', () async {
    final recorder = _FakeRecorder()..permission = false;
    final service = _FakeConversation([_turn('ほんですか')]);
    final c = FreeConversationController(
      recorder: recorder,
      stt: _FakeStt('はい'),
      service: service,
      seed: _seed,
    );
    await c.start();
    await c.toggleMic();

    expect(c.status, FreeConvStatus.error);
    expect(c.errorMessage, contains('Microphone'));
  });

  test('an empty transcript is a try-again error, not a turn', () async {
    final service = _FakeConversation([_turn('ほんですか')]);
    final c = FreeConversationController(
      recorder: _FakeRecorder(),
      stt: _FakeStt(''), // recognizer heard nothing
      service: service,
      seed: _seed,
    );
    await c.start();
    await c.toggleMic();
    await c.toggleMic();

    expect(c.status, FreeConvStatus.error);
    expect(service.calls, 1); // never reached the combined call
  });

  test('a missing Google key on transcription points at Settings', () async {
    final service = _FakeConversation([_turn('ほんですか')]);
    final c = FreeConversationController(
      recorder: _FakeRecorder(),
      stt: _FakeStt('はい')..error = ApiKeyMissing('Google'),
      service: service,
      seed: _seed,
    );
    await c.start();
    await c.toggleMic();
    await c.toggleMic();

    expect(c.status, FreeConvStatus.error);
    expect(c.errorMessage, contains('Settings'));
  });

  test('an empty Bunko explains itself without calling the service', () async {
    final service = _FakeConversation([_turn('ほんですか')]);
    final c = FreeConversationController(
      recorder: _FakeRecorder(),
      stt: _FakeStt('はい'),
      service: service,
      seed: _noNameSeed,
    );
    await c.start();

    expect(c.status, FreeConvStatus.error);
    expect(service.calls, 0);
  });

  test('dispose releases the recorder', () async {
    final recorder = _FakeRecorder();
    final c = FreeConversationController(
      recorder: recorder,
      stt: _FakeStt('はい'),
      service: _FakeConversation([_turn('ほんですか')]),
      seed: _seed,
    );
    c.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(recorder.disposed, isTrue);
  });
}

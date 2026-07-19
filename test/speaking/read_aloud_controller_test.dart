import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/settings/api_key_store.dart';
import 'package:mainichi/speaking/read_aloud_controller.dart';
import 'package:mainichi/speaking/read_aloud_grader.dart';
import 'package:mainichi/speaking/speech_recorder.dart';
import 'package:mainichi/speaking/stt_service.dart';

class _FakeRecorder implements SpeechRecorder {
  bool permission = true;
  List<int>? bytes = [1, 2, 3];
  int starts = 0;
  int cancels = 0;
  bool disposed = false;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start() async => starts++;

  @override
  Future<List<int>?> stop() async => bytes;

  @override
  Future<void> cancel() async => cancels++;

  @override
  Future<void> dispose() async => disposed = true;
}

class _FakeStt implements SttService {
  _FakeStt(this.transcript);
  String transcript;
  Object? error;
  Completer<String>? gate; // when set, transcribe blocks on it

  @override
  Future<String> transcribe(List<int> audioContent) async {
    if (gate != null) return gate!.future;
    if (error != null) throw error!;
    return transcript;
  }
}

void main() {
  const lines = ['すしを食べます', 'はい、食べます'];

  late _FakeRecorder recorder;
  late _FakeStt stt;
  late ReadAloudController controller;

  ReadAloudController build() => ReadAloudController(
        recorder: recorder,
        stt: stt,
        expectedLines: lines,
      );

  setUp(() {
    recorder = _FakeRecorder();
    stt = _FakeStt('すしを食べます');
    controller = build();
  });

  tearDown(() => controller.dispose());

  test('record then stop transcribes and grades the line', () async {
    await controller.toggleLine(0);
    expect(controller.status, ReadAloudStatus.recording);
    expect(controller.activeLine, 0);
    expect(recorder.starts, 1);

    await controller.toggleLine(0);
    expect(controller.status, ReadAloudStatus.idle);
    expect(controller.activeLine, isNull);
    final result = controller.resultFor(0)!;
    expect(result.verdict, ReadAloudVerdict.match);
    expect(result.transcript, 'すしを食べます');
  });

  test('an empty transcript grades as a mismatch, not an error', () async {
    stt.transcript = '';
    await controller.toggleLine(0);
    await controller.toggleLine(0);
    expect(controller.status, ReadAloudStatus.idle);
    expect(controller.resultFor(0)!.verdict, ReadAloudVerdict.mismatch);
    expect(controller.resultFor(0)!.transcript, '');
  });

  test('denied permission is an error on the line, no recording', () async {
    recorder.permission = false;
    await controller.toggleLine(0);
    expect(controller.status, ReadAloudStatus.error);
    expect(controller.activeLine, 0);
    expect(controller.errorMessage, contains('Microphone'));
    expect(recorder.starts, 0);
  });

  test('no captured audio is a try-again error', () async {
    recorder.bytes = null;
    await controller.toggleLine(0);
    await controller.toggleLine(0);
    expect(controller.status, ReadAloudStatus.error);
    expect(controller.errorMessage, contains('try again'));
  });

  test('a missing key points at Settings', () async {
    stt.error = ApiKeyMissing('Google');
    await controller.toggleLine(0);
    await controller.toggleLine(0);
    expect(controller.status, ReadAloudStatus.error);
    expect(controller.errorMessage, contains('Settings'));
  });

  test('a transport failure is a connection error', () async {
    stt.error = Exception('network');
    await controller.toggleLine(0);
    await controller.toggleLine(0);
    expect(controller.status, ReadAloudStatus.error);
    expect(controller.errorMessage, contains('connection'));
  });

  test('re-recording a line clears its previous result', () async {
    await controller.toggleLine(0);
    await controller.toggleLine(0);
    expect(controller.resultFor(0), isNotNull);

    await controller.toggleLine(0); // start again
    expect(controller.status, ReadAloudStatus.recording);
    expect(controller.resultFor(0), isNull);
  });

  test('tapping another line while one is recording does nothing', () async {
    await controller.toggleLine(0);
    expect(controller.status, ReadAloudStatus.recording);
    expect(controller.activeLine, 0);

    await controller.toggleLine(1); // ignored
    expect(controller.activeLine, 0);
    expect(controller.status, ReadAloudStatus.recording);
    expect(recorder.starts, 1);
  });

  test('shows the transcribing state while STT is in flight', () async {
    stt.gate = Completer<String>();
    await controller.toggleLine(0);
    final grading = controller.toggleLine(0); // stop → transcribe (blocked)
    await Future<void>.delayed(Duration.zero);
    expect(controller.status, ReadAloudStatus.transcribing);

    stt.gate!.complete('すしを食べます');
    await grading;
    expect(controller.status, ReadAloudStatus.idle);
    expect(controller.resultFor(0)!.verdict, ReadAloudVerdict.match);
  });

  test('cancel abandons an in-flight recording', () async {
    await controller.toggleLine(0);
    await controller.cancel();
    expect(controller.status, ReadAloudStatus.idle);
    expect(controller.activeLine, isNull);
    expect(recorder.cancels, 1);
  });

  test('a result finishing after cancel is discarded (session guard)',
      () async {
    stt.gate = Completer<String>();
    await controller.toggleLine(0);
    final grading = controller.toggleLine(0); // transcribe blocks
    await Future<void>.delayed(Duration.zero);

    await controller.cancel(); // invalidates the in-flight grade
    stt.gate!.complete('すしを食べます');
    await grading;

    expect(controller.status, ReadAloudStatus.idle);
    expect(controller.resultFor(0), isNull); // never applied
  });

  test('dispose releases the recorder', () async {
    controller.dispose();
    expect(recorder.disposed, isTrue);
    controller = build(); // tearDown disposes a live one
  });
}

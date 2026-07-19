/// Per-line read-aloud state (speaking rung 2, D67): the learner taps a
/// line's mic, reads it aloud, taps stop; the recording goes to Google STT
/// and the transcript is graded against the line. One controller per
/// displayed conversation, created alongside the listening controller and
/// keyed the same way (features/speaking-exercise.md §3).
///
/// At most one line is active at a time — recording or transcribing. Other
/// lines' mics are inert until it resolves. Each line keeps its own last
/// result so verdicts persist as the learner works down the conversation.
library;

import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../settings/api_key_store.dart' show ApiKeyMissing;
import 'read_aloud_grader.dart';
import 'speech_recorder.dart';
import 'stt_service.dart';

enum ReadAloudStatus { idle, recording, transcribing, error }

@immutable
class ReadAloudResult {
  const ReadAloudResult({required this.verdict, required this.transcript});

  final ReadAloudVerdict verdict;

  /// The raw recognizer output, always surfaced beside the verdict (spec §5):
  /// an empty string means the recognizer heard nothing.
  final String transcript;
}

class ReadAloudController extends ChangeNotifier {
  ReadAloudController({
    required this._recorder,
    required this._stt,
    required this.expectedLines,
  });

  final SpeechRecorder _recorder;
  final SttService _stt;

  /// The written `text` of each line — the grading target (orthography, not
  /// kana; see read_aloud_grader.dart for why).
  final List<String> expectedLines;

  ReadAloudStatus status = ReadAloudStatus.idle;

  /// The line currently recording/transcribing, or the line an error belongs
  /// to. Null when idle with no error.
  int? activeLine;

  String errorMessage = '';

  final Map<int, ReadAloudResult> _results = {};

  ReadAloudResult? resultFor(int index) => _results[index];

  /// Monotonic token: a cancel or a new recording invalidates the in-flight
  /// transcription of a previous one (same guard as ListeningController).
  int _session = 0;
  bool _disposed = false;

  /// The mic affordance on line [index]: starts recording when idle, stops
  /// and grades when it's the line already recording. A tap on any other
  /// line while one is active does nothing.
  Future<void> toggleLine(int index) async {
    if (status == ReadAloudStatus.transcribing) return;
    if (status == ReadAloudStatus.recording) {
      if (activeLine == index) await _stopAndGrade(index);
      return;
    }
    await _startRecording(index);
  }

  /// Abandons an in-flight recording (the learner backed out), back to idle.
  Future<void> cancel() async {
    _session++;
    await _recorder.cancel();
    if (_disposed) return;
    status = ReadAloudStatus.idle;
    activeLine = null;
    errorMessage = '';
    notifyListeners();
  }

  Future<void> _startRecording(int index) async {
    final session = ++_session;
    final granted = await _recorder.hasPermission();
    if (_disposed || session != _session) return;
    if (!granted) {
      _fail(session, index,
          'Microphone access is off — enable it for this app in Settings.');
      return;
    }
    try {
      await _recorder.start();
    } catch (_) {
      _fail(session, index, "Couldn't start recording.");
      return;
    }
    if (_disposed || session != _session) return;
    status = ReadAloudStatus.recording;
    activeLine = index;
    errorMessage = '';
    _results.remove(index); // re-recording a line clears its old verdict
    notifyListeners();
  }

  Future<void> _stopAndGrade(int index) async {
    final session = _session; // continue the recording's session
    status = ReadAloudStatus.transcribing;
    notifyListeners();

    List<int>? bytes;
    try {
      bytes = await _recorder.stop();
    } catch (_) {
      _fail(session, index, "Couldn't finish the recording.");
      return;
    }
    if (_disposed || session != _session) return;
    if (bytes == null || bytes.isEmpty) {
      _fail(session, index, "Didn't catch any audio — try again.");
      return;
    }

    String transcript;
    try {
      transcript = await _stt.transcribe(bytes);
    } on ApiKeyMissing {
      _fail(session, index, 'No Google Cloud API key — add one in Settings.');
      return;
    } catch (error, stack) {
      // Log the raw error under `speaking.transcribe` for diagnosis, then
      // give the case-appropriate message — a rejected key or a disabled
      // Speech-to-Text API (both 403) is not a connectivity problem, and
      // "check your connection" would send the learner chasing the wrong
      // thing. Only a request that never reached the server warrants it.
      developer.log('transcription failed',
          name: 'speaking.transcribe', error: error, stackTrace: stack);
      _fail(session, index, _transcribeFailureMessage(error));
      return;
    }
    if (_disposed || session != _session) return;

    _results[index] = ReadAloudResult(
      verdict: gradeReadAloud(
          expected: expectedLines[index], transcript: transcript),
      transcript: transcript,
    );
    status = ReadAloudStatus.idle;
    activeLine = null;
    notifyListeners();
  }

  /// Maps a transcription transport failure to a learner-facing message.
  /// A 401/403 means the key was rejected or the Cloud Speech-to-Text API is
  /// not enabled for the project (it must be enabled separately from
  /// Text-to-Speech, even though they share the key); only a request that
  /// never got a response is a genuine connectivity failure.
  String _transcribeFailureMessage(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        return 'The recognizer rejected the key. Make sure the Cloud '
            'Speech-to-Text API is enabled for it in Settings.';
      }
      if (status == 429) {
        return 'The recognizer is busy right now. Wait a moment and try again.';
      }
      if (status != null && status >= 500) {
        return 'The recognizer is temporarily overloaded. Try again shortly.';
      }
      if (status != null) {
        return 'The recognizer returned an error ($status). Try again.';
      }
    }
    // No response = the request never completed: offline, DNS, or timeout.
    return "Couldn't reach the recognizer. Check your connection.";
  }

  void _fail(int session, int index, String message) {
    if (_disposed || session != _session) return;
    status = ReadAloudStatus.error;
    activeLine = index; // error renders under the line it belongs to
    errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _session++;
    _recorder.dispose();
    super.dispose();
  }
}

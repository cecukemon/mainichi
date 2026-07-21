/// The free-conversation turn loop (speaking rung 3, D69,
/// `features/speaking-exercise.md` §4).
///
/// Owns one spoken conversation: the app opens with an in-scope line and plays
/// a fixed persona; the learner taps the mic, replies aloud, taps stop; the
/// reply is transcribed and sent — with the whole exchange so far — to one
/// combined Claude call that grades it and returns the persona's next line,
/// which is scope-validated before it's shown. Ephemeral: nothing is persisted
/// (no cache/SRS in v1).
///
/// Same session-guard idiom as `ListeningController`/`ReadAloudController`
/// (`int _session` + `bool _disposed`, re-checked after every await), and it
/// reuses their `SpeechRecorder`/`SttService` record→stop→transcribe sequence.
library;

import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../generation/conversation_generator.dart'
    show GenerationSeed, GenLine, GenerationRefused, GenerationTruncated;
import '../settings/api_key_store.dart' show ApiKeyMissing;
import 'conversation_client.dart';
import 'conversation_turn.dart';
import 'speech_recorder.dart';
import 'stt_service.dart';

enum FreeConvStatus {
  loadingOpening,
  idle,
  recording,
  transcribing,
  thinking,
  error,
}

/// One exchange in the conversation: the persona's [appLine], plus — once the
/// learner has answered it — their [learnerTranscript] and the [grade] the
/// combined call returned for that reply. The most recent turn has a null
/// transcript until the learner answers it.
@immutable
class ConvTurn {
  const ConvTurn({required this.appLine, this.learnerTranscript, this.grade});

  final GenLine appLine;
  final String? learnerTranscript;
  final TurnGrade? grade;

  bool get answered => learnerTranscript != null;

  ConvTurn withReply(String transcript, TurnGrade? grade) => ConvTurn(
        appLine: appLine,
        learnerTranscript: transcript,
        grade: grade,
      );
}

class FreeConversationController extends ChangeNotifier {
  FreeConversationController({
    required this._recorder,
    required this._stt,
    required this._service,
    required this.seed,
  });

  final SpeechRecorder _recorder;
  final SttService _stt;
  final ConversationService _service;
  final GenerationSeed seed;

  /// The next line is composed under two constraints (in scope *and* responsive
  /// to the learner), so scope rejection is likelier here than in the reading
  /// feed (spec §4). Retry the whole call a couple of times before surfacing an
  /// error the learner has to act on.
  static const int _maxScopeRetries = 2;

  FreeConvStatus status = FreeConvStatus.loadingOpening;

  /// The exchange, oldest first. The last entry is the persona's current line,
  /// unanswered until the learner replies.
  final List<ConvTurn> turns = [];

  String errorMessage = '';

  String? _personaSurface;

  /// The transcript of an in-flight/failed reply, kept so [retry] can resend it
  /// without re-recording. Null before any reply and after a clean turn.
  String? _pendingReply;

  int _session = 0;
  bool _disposed = false;

  /// The persona's display name once the opening line has set it.
  String get personaSurface => _personaSurface ?? '';

  /// Generates the opening line (no grade) and starts the conversation.
  Future<void> start() async {
    final session = ++_session;
    status = FreeConvStatus.loadingOpening;
    errorMessage = '';
    _pendingReply = null;
    turns.clear();
    notifyListeners();
    // A conversation needs a persona — a name-role word — and something to talk
    // about. Guard before spending an API call on a doomed request (mirrors the
    // reading screen's empty-Bunko guard).
    if (seed.nameIds.isEmpty || seed.vocab.isEmpty) {
      _fail(session,
          'Import a worksheet first — a conversation needs some vocabulary and '
          'at least one name to talk with.');
      return;
    }
    try {
      final turn = await _attempt(session);
      if (_disposed || session != _session) return;
      if (turn == null) {
        _fail(session, "Couldn't start an in-scope conversation. Try again.");
        return;
      }
      _personaSurface = turn.reply.speakerSurface;
      turns.add(ConvTurn(appLine: turn.reply));
      status = FreeConvStatus.idle;
      notifyListeners();
    } on ApiKeyMissing {
      _fail(session, 'No API key — add one in Settings.');
    } on GenerationRefused {
      _fail(session, 'The model declined to start. Try again.');
    } on GenerationTruncated {
      _fail(session, 'That ran long and got cut off. Try again.');
    } catch (error, stack) {
      developer.log('opening failed',
          name: 'speaking.conversation', error: error, stackTrace: stack);
      _fail(session, _turnFailureMessage(error));
    }
  }

  /// Mic affordance: start recording when idle, stop-and-submit when already
  /// recording. Inert while the app is transcribing, thinking, or opening.
  Future<void> toggleMic() async {
    switch (status) {
      case FreeConvStatus.transcribing:
      case FreeConvStatus.thinking:
      case FreeConvStatus.loadingOpening:
        return;
      case FreeConvStatus.recording:
        await _stopAndSubmit();
      case FreeConvStatus.idle:
      case FreeConvStatus.error:
        await _startRecording();
    }
  }

  /// Retries whatever failed: the pending reply if one is held, else the
  /// opening. Wired to the error state's "Try again".
  Future<void> retry() async {
    final pending = _pendingReply;
    if (pending != null) {
      await submitReply(pending);
    } else {
      await start();
    }
  }

  /// (Re)submits a transcript as the learner's reply. Public so the error
  /// state's retry can resend without re-recording.
  Future<void> submitReply(String transcript) =>
      _submit(++_session, transcript);

  Future<void> _startRecording() async {
    final session = ++_session;
    final granted = await _recorder.hasPermission();
    if (_disposed || session != _session) return;
    if (!granted) {
      _fail(session,
          'Microphone access is off — enable it for this app in Settings.');
      return;
    }
    try {
      await _recorder.start();
    } catch (_) {
      _fail(session, "Couldn't start recording.");
      return;
    }
    if (_disposed || session != _session) return;
    status = FreeConvStatus.recording;
    errorMessage = '';
    notifyListeners();
  }

  Future<void> _stopAndSubmit() async {
    final session = _session; // continue the recording's session
    status = FreeConvStatus.transcribing;
    notifyListeners();

    List<int>? bytes;
    try {
      bytes = await _recorder.stop();
    } catch (_) {
      _fail(session, "Couldn't finish the recording.");
      return;
    }
    if (_disposed || session != _session) return;
    if (bytes == null || bytes.isEmpty) {
      _fail(session, "Didn't catch any audio — try again.");
      return;
    }

    String transcript;
    try {
      transcript = await _stt.transcribe(bytes);
    } on ApiKeyMissing {
      _fail(session, 'No Google Cloud API key — add one in Settings.');
      return;
    } catch (error, stack) {
      developer.log('transcription failed',
          name: 'speaking.conversation', error: error, stackTrace: stack);
      _fail(session, _transcribeFailureMessage(error));
      return;
    }
    if (_disposed || session != _session) return;
    if (transcript.isEmpty) {
      _fail(session, "Didn't catch any speech — try again.");
      return;
    }
    await _submit(session, transcript);
  }

  Future<void> _submit(int session, String transcript) async {
    _pendingReply = transcript;
    status = FreeConvStatus.thinking;
    errorMessage = '';
    notifyListeners();
    try {
      final turn = await _attempt(session, latestReply: transcript);
      if (_disposed || session != _session) return;
      if (turn == null) {
        _fail(session, "Couldn't continue in scope — tap retry to try again.");
        return;
      }
      // Attach the reply + its grade to the open turn, then append the
      // persona's new (validated) line as the next open turn.
      final open = turns.removeLast();
      turns.add(open.withReply(transcript, turn.grade));
      turns.add(ConvTurn(appLine: turn.reply));
      _pendingReply = null;
      status = FreeConvStatus.idle;
      notifyListeners();
    } on ApiKeyMissing {
      _fail(session, 'No API key — add one in Settings.');
    } on GenerationRefused {
      _fail(session, 'The model declined — tap retry.');
    } on GenerationTruncated {
      _fail(session, 'That ran long and got cut off — tap retry.');
    } catch (error, stack) {
      developer.log('turn failed',
          name: 'speaking.conversation', error: error, stackTrace: stack);
      _fail(session, _turnFailureMessage(error));
    }
  }

  /// One combined call plus scope validation of the returned line, retried up
  /// to [_maxScopeRetries] times on an out-of-scope line. Returns a turn whose
  /// reply is in scope, or null if every attempt leaked scope. Transport
  /// exceptions propagate to the caller's handler.
  Future<ConversationTurn?> _attempt(int session, {String? latestReply}) async {
    final history = [
      for (final t in turns)
        TurnHistory(personaLine: t.appLine.text, learnerReply: t.learnerTranscript),
    ];
    for (var i = 0; i <= _maxScopeRetries; i++) {
      final turn = await _service.turn(
        seed: seed,
        history: history,
        latestReply: latestReply,
        personaSurface: _personaSurface,
      );
      if (_disposed || session != _session) return null;
      final report = validateNextLine(turn.reply, seed);
      if (report.ok) return turn;
      developer.log(
        'next line out of scope (attempt ${i + 1}): '
        '${report.violations.join('; ')}',
        name: 'speaking.conversation',
      );
    }
    return null;
  }

  /// Maps a Google STT transport failure to a learner-facing message (same
  /// mapping as [ReadAloudController]).
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
    return "Couldn't reach the recognizer. Check your connection.";
  }

  /// Maps an Anthropic combined-call transport failure to a learner-facing
  /// message. A 401/403 is a rejected key (a Settings problem), not a network
  /// one.
  String _turnFailureMessage(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        return 'The key was rejected — check your Anthropic key in Settings.';
      }
      if (status == 429) {
        return 'The service is busy right now. Wait a moment and try again.';
      }
      if (status != null && status >= 500) {
        return 'The service is temporarily overloaded. Try again shortly.';
      }
      if (status != null) {
        return 'The service returned an error ($status). Try again.';
      }
    }
    return "Couldn't reach the service. Check your connection.";
  }

  void _fail(int session, String message) {
    if (_disposed || session != _session) return;
    status = FreeConvStatus.error;
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

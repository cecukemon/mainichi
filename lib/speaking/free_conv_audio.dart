/// Per-line "hear it" playback for free conversation's persona lines (D72,
/// features/speaking-exercise.md §6). Ephemeral: nothing here persists past
/// the screen, matching the rest of free conversation.
///
/// Same session-guard idiom as `ListeningController`/`ReadAloudController`.
library;

import 'package:flutter/foundation.dart';

import '../generation/conversation_generator.dart'
    show GenLine, GenerationSeed;
import '../listening/line_audio.dart' show LineAudioSpec, kanaLine;
import '../listening/playback_controller.dart' show LineAudioPlayer;
import '../listening/tts_service.dart' show speakerVoiceA;
import '../settings/api_key_store.dart' show ApiKeyMissing;
import 'free_conv_audio_store.dart';

enum FreeConvAudioStatus { idle, preparing, playing, error }

class FreeConvAudioController extends ChangeNotifier {
  FreeConvAudioController({
    required this._store,
    required this._player,
    required this._seed,
  });

  final FreeConvAudioStore _store;
  final LineAudioPlayer _player;
  final GenerationSeed _seed;

  FreeConvAudioStatus status = FreeConvAudioStatus.idle;

  /// The turn index this status belongs to — the line currently prepping,
  /// sounding, or holding an error. Null when idle with no error.
  int? activeTurn;

  String errorMessage = '';

  /// Monotonic token: any new play/stop invalidates a previous one, so an
  /// interrupted line's late callback never overwrites the interrupter.
  int _session = 0;
  bool _disposed = false;

  /// Plays [line]'s persona voice. A tap on any line — including one already
  /// playing — stops whatever is sounding first, so switching lines is always
  /// one tap.
  Future<void> playTurn(int turnIndex, GenLine line) async {
    final session = ++_session;
    await _player.stop();
    if (_disposed) return;

    status = FreeConvAudioStatus.preparing;
    activeTurn = turnIndex;
    errorMessage = '';
    notifyListeners();

    final spec =
        LineAudioSpec(kana: kanaLine(line, _seed), voice: speakerVoiceA);
    String path;
    try {
      path = await _store.ensureFile(spec);
    } on ApiKeyMissing {
      _fail(session, turnIndex,
          'No Google Cloud API key — add one in Settings.');
      return;
    } catch (_) {
      _fail(
          session, turnIndex, "Couldn't fetch the audio. Check your connection.");
      return;
    }
    if (_disposed || session != _session) return;

    status = FreeConvAudioStatus.playing;
    notifyListeners();
    await _player.playFile(path);
    if (_disposed || session != _session) return;
    status = FreeConvAudioStatus.idle;
    activeTurn = null;
    notifyListeners();
  }

  Future<void> stop() async {
    _session++;
    await _player.stop();
    if (_disposed) return;
    status = FreeConvAudioStatus.idle;
    activeTurn = null;
    notifyListeners();
  }

  void _fail(int session, int turnIndex, String message) {
    if (_disposed || session != _session) return;
    status = FreeConvAudioStatus.error;
    activeTurn = turnIndex;
    errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _session++;
    _player.dispose();
    _store.clear().catchError((_) {}); // best-effort, nothing depends on it
    super.dispose();
  }
}

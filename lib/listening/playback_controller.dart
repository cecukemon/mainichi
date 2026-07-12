/// Playback state for one conversation's audio layer (D50): manual start/
/// stop, per-line replay, client-side speed. One controller per displayed
/// conversation; the reading screen recreates it when the conversation
/// changes.
///
/// Synthesis is lazy — the first play walks the audio store, which only
/// calls TTS for lines not already on disk. A synthesis failure becomes an
/// inline error state on the player row; reading is never affected.
library;

import 'package:flutter/foundation.dart';

import '../settings/api_key_store.dart' show ApiKeyMissing;
import 'audio_store.dart';
import 'line_audio.dart';

/// What the controller needs from a player — implemented by
/// `JustAudioLinePlayer`, faked in tests (no platform channels).
abstract class LineAudioPlayer {
  /// Plays [path] to the end; false when interrupted by [stop].
  Future<bool> playFile(String path);

  Future<void> stop();
  Future<void> setSpeed(double speed);
  Future<void> dispose();
}

enum AudioStatus { idle, preparing, playing, error }

const listeningSpeeds = [0.5, 0.75, 1.0];

class ListeningController extends ChangeNotifier {
  ListeningController({
    required this._audioStore,
    required this._player,
    required this.conversationId,
    required this.lines,
  });

  final AudioStore _audioStore;
  final LineAudioPlayer _player;
  final int conversationId;
  final List<LineAudioSpec> lines;

  AudioStatus status = AudioStatus.idle;
  int? currentLine;
  double speed = 1.0;
  String errorMessage = '';

  /// Monotonic token: any new play/stop invalidates the loop of the previous
  /// one, so an interrupted chain never overwrites the interrupter's state.
  int _session = 0;
  bool _disposed = false;

  Future<void> playAll() => _play(from: 0, chain: true);

  Future<void> playLine(int index) => _play(from: index, chain: false);

  Future<void> stop() async {
    _session++;
    await _player.stop();
    if (_disposed) return;
    status = AudioStatus.idle;
    currentLine = null;
    notifyListeners();
  }

  Future<void> setSpeed(double value) async {
    speed = value;
    notifyListeners();
    await _player.setSpeed(value);
  }

  Future<void> _play({required int from, required bool chain}) async {
    final session = ++_session;
    await _player.stop();
    if (_disposed) return;
    status = AudioStatus.preparing;
    errorMessage = '';
    currentLine = null;
    notifyListeners();

    List<String> paths;
    try {
      paths = await _audioStore.ensureAudio(
        conversationId: conversationId,
        lines: lines,
      );
    } on ApiKeyMissing {
      _fail(session, 'No Google Cloud API key — add one in Settings.');
      return;
    } catch (_) {
      _fail(session, "Couldn't fetch the audio. Check your connection.");
      return;
    }
    if (_disposed || session != _session) return;

    status = AudioStatus.playing;
    final until = chain ? lines.length : from + 1;
    for (var i = from; i < until; i++) {
      currentLine = i;
      notifyListeners();
      final finished = await _player.playFile(paths[i]);
      if (_disposed || session != _session) return;
      if (!finished) break;
    }
    status = AudioStatus.idle;
    currentLine = null;
    notifyListeners();
  }

  void _fail(int session, String message) {
    if (_disposed || session != _session) return;
    status = AudioStatus.error;
    errorMessage = message;
    currentLine = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _session++;
    _player.dispose();
    super.dispose();
  }
}

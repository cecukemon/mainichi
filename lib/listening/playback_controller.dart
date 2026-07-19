/// Playback state for one conversation's audio layer (D50): manual start/
/// stop, per-line replay, client-side speed. One controller per displayed
/// conversation; the reading screen recreates it when the conversation
/// changes.
///
/// Also carries shadowing mode (D63, features/speaking-exercise.md §2):
/// with [shadowing] on, playback holds in [AudioStatus.awaitingRepeat] after
/// each line while the learner repeats it aloud — advance is learner-
/// controlled (tap, not a timer), ungraded by design, no mic involved.
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

enum AudioStatus { idle, preparing, playing, awaitingRepeat, error }

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

  /// Shadowing mode (D63): when on, play holds after each line for the
  /// learner's repetition instead of chaining straight through.
  bool shadowing = false;

  /// Whether the line currently held (or sounding) is the conversation's
  /// last — the advance affordance finishes the pass instead of continuing.
  bool get onLastLine => currentLine == lines.length - 1;

  /// Monotonic token: any new play/stop invalidates the loop of the previous
  /// one, so an interrupted chain never overwrites the interrupter's state.
  int _session = 0;
  bool _disposed = false;

  /// Resolved once per controller: later plays (every shadowing advance)
  /// reuse the paths instead of re-walking the store, so only the first play
  /// shows the preparing state. Stays null after a failure, so retry
  /// re-fetches.
  List<String>? _paths;

  Future<void> playAll() =>
      shadowing ? _playShadow(from: 0) : _play(from: 0, chain: true);

  /// In shadowing mode a margin replay re-enters the chain at that line
  /// (play it, hold for the repeat, continue from there) rather than
  /// dropping out of the session.
  Future<void> playLine(int index) =>
      shadowing ? _playShadow(from: index) : _play(from: index, chain: false);

  /// Continues past the held line; past the last one, ends the pass.
  Future<void> advanceShadow() => _playShadow(from: (currentLine ?? -1) + 1);

  /// Replays the held line and holds again.
  Future<void> repeatShadowLine() => _playShadow(from: currentLine ?? 0);

  void setShadowing(bool value) {
    if (shadowing == value) return;
    shadowing = value;
    if (status == AudioStatus.playing || status == AudioStatus.awaitingRepeat) {
      stop(); // notifies
    } else {
      notifyListeners();
    }
  }

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
    final paths = await _ensurePaths(session);
    if (paths == null) return;

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

  /// One shadowing step: play line [from], then hold in
  /// [AudioStatus.awaitingRepeat] with [currentLine] still on the spoken
  /// line. [from] past the last line ends the pass.
  Future<void> _playShadow({required int from}) async {
    final session = ++_session;
    await _player.stop();
    if (_disposed) return;
    final paths = await _ensurePaths(session);
    if (paths == null) return;

    if (from >= paths.length) {
      status = AudioStatus.idle;
      currentLine = null;
      notifyListeners();
      return;
    }

    status = AudioStatus.playing;
    currentLine = from;
    notifyListeners();
    final finished = await _player.playFile(paths[from]);
    if (_disposed || session != _session) return;
    if (finished) {
      status = AudioStatus.awaitingRepeat; // currentLine stays on the line
    } else {
      status = AudioStatus.idle;
      currentLine = null;
    }
    notifyListeners();
  }

  /// Resolves the per-line audio paths, walking the store (lazy synthesis)
  /// only on the first call. Null when the fetch failed (error state already
  /// set) or this play was superseded/disposed meanwhile.
  Future<List<String>?> _ensurePaths(int session) async {
    final cached = _paths;
    if (cached != null) return cached;
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
      return null;
    } catch (_) {
      _fail(session, "Couldn't fetch the audio. Check your connection.");
      return null;
    }
    if (_disposed || session != _session) return null;
    _paths = paths;
    return paths;
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

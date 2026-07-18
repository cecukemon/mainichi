/// The real [LineAudioPlayer]: `just_audio` over AVPlayer. Speed is applied
/// as playback rate (pitch-corrected on iOS) — synthesis always happens at
/// 1.0×, per D50.
library;

import 'package:just_audio/just_audio.dart';

import 'playback_controller.dart';

class JustAudioLinePlayer implements LineAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<bool> playFile(String path) async {
    await _player.setFilePath(path);
    // A completed track leaves `playing` true, so setFilePath auto-starts the
    // next one from wherever it loads; seek to the top so it plays in full.
    await _player.seek(Duration.zero);
    // Can't trust play()'s future to await completion: it returns immediately
    // when `playing` is already true (which it stays after the previous line
    // finished), so from the second line on it would report "not finished" and
    // the caller's play-all loop would stop. Wait for the state to reach
    // completed (natural end → true) or idle (stop() interrupted us → false).
    // Subscribe before play() so a short clip's completion isn't missed.
    final done = _player.processingStateStream
        .firstWhere((s) =>
            s == ProcessingState.completed || s == ProcessingState.idle)
        .then<bool>((s) => s == ProcessingState.completed)
        .catchError((Object _) => false); // stream closed (dispose) → stopped
    await _player.play();
    return done;
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> dispose() => _player.dispose();
}

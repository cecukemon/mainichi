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
    // play() resolves when playback completes or something interrupts it
    // (stop/pause/another load) — the processing state tells which.
    await _player.play();
    return _player.processingState == ProcessingState.completed;
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> dispose() => _player.dispose();
}

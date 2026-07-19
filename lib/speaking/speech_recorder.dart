/// Mic capture for read-aloud (speaking rung 2, D67), behind an interface so
/// the platform-channel `record` package can be faked in tests — same pattern
/// as [LineAudioPlayer]/`JustAudioLinePlayer`.
///
/// Records to a temporary WAV file (LINEAR16 at [sttSampleRateHertz], the
/// format [SttService] expects) and hands back the bytes. Recordings are
/// transient grading input, not saved content — there is no audio store for
/// them; the caller deletes the temp file after transcription.
library;

import 'dart:io';

import 'package:record/record.dart';

import 'stt_service.dart' show sttSampleRateHertz;

/// What the read-aloud controller needs from the mic — implemented by
/// [RecordSpeechRecorder], faked in tests.
abstract class SpeechRecorder {
  /// Whether the mic permission is granted, requesting it if undetermined.
  Future<bool> hasPermission();

  /// Starts recording to a fresh temp file. Overwrites any in-flight capture.
  Future<void> start();

  /// Stops recording and returns the captured WAV bytes, or null if nothing
  /// was captured. Deletes the temp file before returning — the bytes are the
  /// only thing the caller keeps.
  Future<List<int>?> stop();

  /// Discards an in-flight recording without producing bytes (the learner
  /// backed out). Safe to call when not recording.
  Future<void> cancel();

  Future<void> dispose();
}

class RecordSpeechRecorder implements SpeechRecorder {
  RecordSpeechRecorder({required this.tempDirectory});

  /// Where transient recordings land — the OS temp dir in production.
  final Future<Directory> Function() tempDirectory;

  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    final dir = await tempDirectory();
    final path =
        '${dir.path}/readaloud_${DateTime.now().microsecondsSinceEpoch}.wav';
    _path = path;
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav, // LINEAR16 PCM, no transcoding for STT
        sampleRate: sttSampleRateHertz,
        numChannels: 1,
      ),
      path: path,
    );
  }

  @override
  Future<List<int>?> stop() async {
    final path = await _recorder.stop() ?? _path;
    _path = null;
    if (path == null) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    try {
      await file.delete();
    } catch (_) {
      // A leftover temp file is harmless; never fail a recording over cleanup.
    }
    return bytes;
  }

  @override
  Future<void> cancel() async {
    await _recorder.cancel();
    final path = _path;
    _path = null;
    if (path != null) {
      try {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}

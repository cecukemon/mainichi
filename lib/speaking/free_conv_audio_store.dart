/// Where free conversation's per-line audio lives once synthesized
/// (D72, features/speaking-exercise.md §6). Ephemeral and un-cached — free
/// conversation turns have no conversation id — so unlike
/// `ConversationAudioStore` this scratch directory isn't keyed per
/// conversation and is wiped when the controller that owns it disposes.
/// Content-addressed via the listening layer's `audioFileName` scheme, so
/// replaying a line already spoken this session skips synthesis.
///
/// Interface so widget tests can stay off the real filesystem (real IO
/// deadlocks under the test framework's fake clock — mirrors `AudioStore`
/// in `lib/listening/audio_store.dart`).
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../listening/audio_store.dart' show audioFileName;
import '../listening/line_audio.dart' show LineAudioSpec;
import '../listening/tts_service.dart' show TtsService;

abstract class FreeConvAudioStore {
  /// Resolves [spec]'s playable file path, synthesizing only on a cache miss.
  Future<String> ensureFile(LineAudioSpec spec);

  /// Removes the scratch directory. A never-synthesised / already-gone
  /// directory is a silent no-op.
  Future<void> clear();
}

class DiskFreeConvAudioStore implements FreeConvAudioStore {
  DiskFreeConvAudioStore({required this.rootDir, required this.tts});

  final Future<Directory> Function() rootDir;
  final TtsService tts;

  Future<Directory> _dir() async {
    final root = await rootDir();
    return Directory(p.join(root.path, 'audio', 'freeconv'));
  }

  @override
  Future<String> ensureFile(LineAudioSpec spec) async {
    final dir = await _dir();
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, audioFileName(spec)));
    if (!await file.exists()) {
      final bytes = await tts.synthesize(text: spec.kana, voice: spec.voice);
      await file.writeAsBytes(bytes, flush: true);
    }
    return file.path;
  }

  @override
  Future<void> clear() async {
    final dir = await _dir();
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

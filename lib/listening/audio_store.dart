/// The audio file store (features/listening-exercise.md §3): synthesized
/// line audio on disk, lazily filled on first play.
///
/// Files are content-addressed — the filename is a hash of (voice, kana) —
/// so a kana reading corrected in the store after synthesis simply misses the
/// cache and re-synthesizes on the next play; stale audio self-invalidates
/// with no bookkeeping. `audioPath` on the conversation row points at the
/// per-conversation directory.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../data/conversation_cache.dart';
import 'line_audio.dart';
import 'tts_service.dart';

String audioFileName(LineAudioSpec spec) =>
    '${sha1.convert(utf8.encode('${spec.voice}|${spec.kana}')).toString()}.mp3';

/// What the playback controller needs: playable file paths for a
/// conversation's lines. Interface so widget tests can stay off the real
/// filesystem (real IO deadlocks under the test framework's fake clock).
abstract class AudioStore {
  Future<List<String>> ensureAudio({
    required int conversationId,
    required List<LineAudioSpec> lines,
  });
}

class ConversationAudioStore implements AudioStore {
  ConversationAudioStore({
    required this.rootDir,
    required this._tts,
    required this._conversations,
  });

  /// Resolved lazily per call (the documents directory lookup is async).
  final Future<Directory> Function() rootDir;
  final TtsService _tts;
  final ConversationStore _conversations;

  /// Returns one playable file path per line, synthesizing whichever lines
  /// aren't on disk yet. Throws on the first synthesis failure (the player
  /// row shows an inline error with retry); files already written stay — a
  /// retry only pays for what's still missing.
  @override
  Future<List<String>> ensureAudio({
    required int conversationId,
    required List<LineAudioSpec> lines,
  }) async {
    final root = await rootDir();
    final dir =
        Directory(p.join(root.path, 'audio', 'conv_$conversationId'));
    await dir.create(recursive: true);

    final paths = <String>[];
    var synthesizedAny = false;
    for (final spec in lines) {
      final file = File(p.join(dir.path, audioFileName(spec)));
      if (!await file.exists()) {
        final bytes =
            await _tts.synthesize(text: spec.kana, voice: spec.voice);
        await file.writeAsBytes(bytes, flush: true);
        synthesizedAny = true;
      }
      paths.add(file.path);
    }

    if (synthesizedAny) {
      try {
        await _conversations.setAudioPath(conversationId, dir.path);
      } catch (_) {
        // The files exist and play either way; audioPath is bookkeeping for
        // later phases (offline mode), not a playback dependency.
      }
    }
    return paths;
  }
}

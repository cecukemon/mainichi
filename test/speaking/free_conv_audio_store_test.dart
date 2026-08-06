import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/listening/line_audio.dart';
import 'package:mainichi/listening/tts_service.dart';
import 'package:mainichi/speaking/free_conv_audio_store.dart';

class _RecordingTts implements TtsService {
  final List<(String, String)> calls = [];
  Object? error;

  @override
  Future<List<int>> synthesize(
      {required String text, required String voice}) async {
    if (error != null) throw error!;
    calls.add((text, voice));
    return utf8.encode(text);
  }
}

void main() {
  late Directory tempDir;
  late _RecordingTts tts;
  late DiskFreeConvAudioStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('free_conv_audio_store_test');
    tts = _RecordingTts();
    store = DiskFreeConvAudioStore(rootDir: () async => tempDir, tts: tts);
  });

  tearDown(() => tempDir.delete(recursive: true));

  const spec = LineAudioSpec(kana: 'ほんですか。', voice: speakerVoiceA);

  test('first call synthesizes and writes the file', () async {
    final path = await store.ensureFile(spec);
    expect(File(path).existsSync(), isTrue);
    expect(path, contains('freeconv'));
    expect(tts.calls, hasLength(1));
  });

  test('a second call serves from disk — no new synthesis', () async {
    final first = await store.ensureFile(spec);
    final second = await store.ensureFile(spec);
    expect(second, first);
    expect(tts.calls, hasLength(1));
  });

  test('a different voice is a different file', () async {
    const other = LineAudioSpec(kana: 'ほんですか。', voice: speakerVoiceB);
    final a = await store.ensureFile(spec);
    final b = await store.ensureFile(other);
    expect(a, isNot(b));
    expect(tts.calls, hasLength(2));
  });

  test('clear deletes the scratch directory', () async {
    final path = await store.ensureFile(spec);
    expect(File(path).existsSync(), isTrue);

    await store.clear();
    expect(File(path).existsSync(), isFalse);
  });

  test('clear on a never-synthesized store is a silent no-op', () async {
    await store.clear(); // no throw
  });
}

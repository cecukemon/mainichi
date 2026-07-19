import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/conversation_cache.dart';
import 'package:mainichi/generation/conversation_generator.dart';
import 'package:mainichi/listening/audio_store.dart';
import 'package:mainichi/listening/line_audio.dart';
import 'package:mainichi/listening/tts_service.dart';

class _RecordingTts implements TtsService {
  final List<(String, String)> calls = [];
  Object? throwOn; // kana string that should fail

  @override
  Future<List<int>> synthesize(
      {required String text, required String voice}) async {
    if (text == throwOn) throw Exception('synthesis failed');
    calls.add((text, voice));
    return utf8.encode(text);
  }
}

class _RecordingConversations implements ConversationStore {
  final Map<int, String> audioPaths = {};

  @override
  Future<void> setAudioPath(int id, String path) async =>
      audioPaths[id] = path;

  @override
  Future<int> save(GeneratedConversation conversation,
          {required Set<int> wordIds, required Set<int> structureIds}) =>
      throw UnimplementedError();

  @override
  Future<CachedConversation?> leastRecentlyPracticed() =>
      throw UnimplementedError();

  @override
  Future<List<ConversationSummary>> list() => throw UnimplementedError();

  @override
  Future<CachedConversation?> byId(int id) => throw UnimplementedError();

  @override
  Future<void> delete(int id) => throw UnimplementedError();

  @override
  Future<void> markPracticed(int id) => throw UnimplementedError();
}

void main() {
  late Directory tempDir;
  late _RecordingTts tts;
  late _RecordingConversations conversations;
  late ConversationAudioStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('audio_store_test');
    tts = _RecordingTts();
    conversations = _RecordingConversations();
    store = ConversationAudioStore(
      rootDir: () async => tempDir,
      tts: tts,
      conversations: conversations,
    );
  });

  tearDown(() => tempDir.delete(recursive: true));

  const lines = [
    LineAudioSpec(kana: 'たなかは たべます。', voice: speakerVoiceA),
    LineAudioSpec(kana: 'いいえ。', voice: speakerVoiceB),
  ];

  test('first play synthesizes each line and records audioPath', () async {
    final paths = await store.ensureAudio(conversationId: 7, lines: lines);

    expect(paths, hasLength(2));
    for (final path in paths) {
      expect(File(path).existsSync(), isTrue);
      expect(path, contains('conv_7'));
    }
    expect(tts.calls, hasLength(2));
    expect(tts.calls.first.$2, speakerVoiceA);
    expect(conversations.audioPaths[7], paths.first.substring(0, paths.first.lastIndexOf('/')));
  });

  test('a second play serves from disk — no new synthesis', () async {
    final first = await store.ensureAudio(conversationId: 7, lines: lines);
    final second = await store.ensureAudio(conversationId: 7, lines: lines);

    expect(second, first);
    expect(tts.calls, hasLength(2));
  });

  test('a corrected kana reading misses the cache and re-synthesizes', () async {
    await store.ensureAudio(conversationId: 7, lines: lines);
    final corrected = [
      const LineAudioSpec(kana: 'たなかは たべました。', voice: speakerVoiceA),
      lines[1],
    ];

    final paths = await store.ensureAudio(conversationId: 7, lines: corrected);

    expect(tts.calls, hasLength(3)); // only the changed line re-synthesized
    expect(File(paths.first).readAsStringSync(), 'たなかは たべました。');
  });

  test('same kana with a different voice is a different file', () {
    const a = LineAudioSpec(kana: 'すし。', voice: speakerVoiceA);
    const b = LineAudioSpec(kana: 'すし。', voice: speakerVoiceB);
    expect(audioFileName(a), isNot(audioFileName(b)));
    expect(audioFileName(a), audioFileName(a)); // deterministic
  });

  test('a mid-conversation failure keeps earlier files; retry pays only the rest',
      () async {
    tts.throwOn = lines[1].kana;
    await expectLater(
      store.ensureAudio(conversationId: 7, lines: lines),
      throwsException,
    );
    expect(tts.calls, hasLength(1)); // line 1 written before the failure

    tts.throwOn = null;
    final paths = await store.ensureAudio(conversationId: 7, lines: lines);
    expect(paths, hasLength(2));
    expect(tts.calls, hasLength(2)); // line 1 not re-synthesized
  });
}

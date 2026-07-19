import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/conversation_cache.dart';
import 'package:mainichi/generation/conversation_generator.dart';
import 'package:mainichi/listening/audio_store.dart';
import 'package:mainichi/listening/line_audio.dart';
import 'package:mainichi/listening/playback_controller.dart';
import 'package:mainichi/listening/tts_service.dart';
import 'package:mainichi/settings/api_key_store.dart';

/// A player whose per-file completion the test controls: `finishCurrent`
/// ends the current file normally, `stop` interrupts it.
class _ScriptedPlayer implements LineAudioPlayer {
  final List<String> played = [];
  final List<double> speeds = [];
  Completer<bool>? _current;
  bool disposed = false;

  void finishCurrent() {
    final c = _current;
    _current = null;
    c?.complete(true);
  }

  @override
  Future<bool> playFile(String path) {
    played.add(path);
    _current = Completer<bool>();
    return _current!.future;
  }

  @override
  Future<void> stop() async {
    final c = _current;
    _current = null;
    c?.complete(false);
  }

  @override
  Future<void> setSpeed(double speed) async => speeds.add(speed);

  @override
  Future<void> dispose() async => disposed = true;
}

class _FakeTts implements TtsService {
  Object? error;
  @override
  Future<List<int>> synthesize(
      {required String text, required String voice}) async {
    if (error != null) throw error!;
    return [0];
  }
}

class _NoopConversations implements ConversationStore {
  @override
  Future<void> setAudioPath(int id, String path) async {}
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

const _lines = [
  LineAudioSpec(kana: 'こんにちは。', voice: speakerVoiceA),
  LineAudioSpec(kana: 'すし。', voice: speakerVoiceB),
];

void main() {
  late Directory tempDir;
  late _ScriptedPlayer player;
  late _FakeTts tts;
  late ListeningController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('playback_test');
    player = _ScriptedPlayer();
    tts = _FakeTts();
    controller = ListeningController(
      audioStore: ConversationAudioStore(
        rootDir: () async => tempDir,
        tts: tts,
        conversations: _NoopConversations(),
      ),
      player: player,
      conversationId: 1,
      lines: _lines,
    );
  });

  tearDown(() async {
    controller.dispose();
    await tempDir.delete(recursive: true);
  });

  /// Lets the controller's async play loop advance between scripted steps.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('playAll walks the lines in order, highlighting each', () async {
    final playAll = controller.playAll();
    while (player.played.isEmpty) {
      await settle();
    }
    expect(controller.status, AudioStatus.playing);
    expect(controller.currentLine, 0);

    player.finishCurrent();
    while (player.played.length < 2) {
      await settle();
    }
    expect(controller.currentLine, 1);

    player.finishCurrent();
    await playAll;
    expect(controller.status, AudioStatus.idle);
    expect(controller.currentLine, isNull);
    expect(player.played, hasLength(2));
  });

  test('stop interrupts the chain', () async {
    final playAll = controller.playAll();
    while (player.played.isEmpty) {
      await settle();
    }

    await controller.stop();
    await playAll;
    expect(controller.status, AudioStatus.idle);
    expect(player.played, hasLength(1)); // line 2 never started
  });

  test('playLine plays exactly one line', () async {
    final playLine = controller.playLine(1);
    while (player.played.isEmpty) {
      await settle();
    }
    expect(controller.currentLine, 1);

    player.finishCurrent();
    await playLine;
    expect(player.played, hasLength(1));
    expect(controller.status, AudioStatus.idle);
  });

  test('a replay during playAll takes over cleanly', () async {
    final playAll = controller.playAll();
    while (player.played.isEmpty) {
      await settle();
    }

    final playLine = controller.playLine(1);
    player.finishCurrent(); // let whichever is waiting proceed
    await playAll;
    while (player.played.length < 2) {
      await settle();
    }
    expect(controller.currentLine, 1);
    player.finishCurrent();
    await playLine;
    expect(controller.status, AudioStatus.idle);
  });

  test('missing Google key becomes a Settings-pointing error', () async {
    tts.error = ApiKeyMissing('Google');
    await controller.playAll();
    expect(controller.status, AudioStatus.error);
    expect(controller.errorMessage, contains('Settings'));
    expect(player.played, isEmpty);
  });

  test('a transport failure becomes the generic audio error', () async {
    tts.error = Exception('network');
    await controller.playAll();
    expect(controller.status, AudioStatus.error);
    expect(controller.errorMessage, contains('connection'));
  });

  test('setSpeed forwards to the player and sticks', () async {
    await controller.setSpeed(0.75);
    expect(controller.speed, 0.75);
    expect(player.speeds, [0.75]);
  });

  test('dispose releases the player', () async {
    controller.dispose();
    expect(player.disposed, isTrue);
    controller = ListeningController(
      // tearDown disposes again; give it a fresh one
      audioStore: ConversationAudioStore(
        rootDir: () async => tempDir,
        tts: tts,
        conversations: _NoopConversations(),
      ),
      player: _ScriptedPlayer(),
      conversationId: 1,
      lines: _lines,
    );
  });
}

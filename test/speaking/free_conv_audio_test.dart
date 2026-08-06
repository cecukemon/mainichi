import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/generation/conversation_generator.dart';
import 'package:mainichi/listening/line_audio.dart' show LineAudioSpec;
import 'package:mainichi/listening/playback_controller.dart' show LineAudioPlayer;
import 'package:mainichi/settings/api_key_store.dart';
import 'package:mainichi/speaking/free_conv_audio.dart';
import 'package:mainichi/speaking/free_conv_audio_store.dart';

/// A player whose per-file completion the test controls, mirroring
/// `playback_controller_test.dart`'s `_ScriptedPlayer`.
class _ScriptedPlayer implements LineAudioPlayer {
  final List<String> played = [];
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
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> dispose() async => disposed = true;
}

/// An in-memory store: each spec maps to a synthetic path, synthesizing
/// (recording the call) only on the first request.
class _FakeStore implements FreeConvAudioStore {
  final List<LineAudioSpec> synthesized = [];
  final List<String> cleared = [];
  Object? error;

  @override
  Future<String> ensureFile(LineAudioSpec spec) async {
    if (error != null) throw error!;
    if (!synthesized.contains(spec)) synthesized.add(spec);
    return 'fake/${spec.kana}-${spec.voice}.mp3';
  }

  @override
  Future<void> clear() async => cleared.add('cleared');
}

const _seed = GenerationSeed(
  vocab: [SeedWord(id: 4, kana: 'ほん', role: 'noun', meaning: 'book')],
  structures: [],
);

GenLine _line(String text) => GenLine(
      speakerNameId: 20,
      speakerSurface: 'すずき',
      text: text,
      structureId: 0,
      tokens: const [GenToken(surface: 'ほん', vocabId: 4)],
    );

void main() {
  late _ScriptedPlayer player;
  late _FakeStore store;
  late FreeConvAudioController controller;

  setUp(() {
    player = _ScriptedPlayer();
    store = _FakeStore();
    controller =
        FreeConvAudioController(store: store, player: player, seed: _seed);
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('playTurn synthesizes, plays, then returns to idle', () async {
    final play = controller.playTurn(0, _line('ほんですか'));
    while (player.played.isEmpty) {
      await settle();
    }
    expect(controller.status, FreeConvAudioStatus.playing);
    expect(controller.activeTurn, 0);
    expect(store.synthesized, hasLength(1));

    player.finishCurrent();
    await play;
    expect(controller.status, FreeConvAudioStatus.idle);
    expect(controller.activeTurn, isNull);
  });

  test('replaying the same line within a session skips synthesis', () async {
    final first = controller.playTurn(0, _line('ほんですか'));
    while (player.played.isEmpty) {
      await settle();
    }
    player.finishCurrent();
    await first;
    expect(store.synthesized, hasLength(1));

    final second = controller.playTurn(0, _line('ほんですか'));
    while (player.played.length < 2) {
      await settle();
    }
    expect(store.synthesized, hasLength(1)); // cache hit — same spec
    player.finishCurrent();
    await second;
  });

  test('tapping a different line stops the one playing and switches',
      () async {
    final first = controller.playTurn(0, _line('ほんですか'));
    while (player.played.isEmpty) {
      await settle();
    }
    expect(controller.activeTurn, 0);

    final second = controller.playTurn(1, _line('すきです'));
    player.finishCurrent(); // whichever await is pending proceeds
    await first;
    while (player.played.length < 2) {
      await settle();
    }
    expect(controller.activeTurn, 1);
    player.finishCurrent();
    await second;
    expect(controller.status, FreeConvAudioStatus.idle);
  });

  test('stop interrupts playback and resets to idle', () async {
    final play = controller.playTurn(0, _line('ほんですか'));
    while (player.played.isEmpty) {
      await settle();
    }
    await controller.stop();
    await play;
    expect(controller.status, FreeConvAudioStatus.idle);
    expect(controller.activeTurn, isNull);
  });

  test('missing Google key becomes a Settings-pointing error', () async {
    store.error = ApiKeyMissing('Google');
    await controller.playTurn(0, _line('ほんですか'));
    expect(controller.status, FreeConvAudioStatus.error);
    expect(controller.activeTurn, 0);
    expect(controller.errorMessage, contains('Settings'));
    expect(player.played, isEmpty);
  });

  test('a transport failure becomes the generic connection error', () async {
    store.error = Exception('network');
    await controller.playTurn(0, _line('ほんですか'));
    expect(controller.status, FreeConvAudioStatus.error);
    expect(controller.errorMessage, contains('connection'));
  });

  test('dispose releases the player and clears the store', () async {
    controller.dispose();
    expect(player.disposed, isTrue);
    await settle();
    expect(store.cleared, isNotEmpty);
  });
}

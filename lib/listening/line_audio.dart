/// Assembles what each line of a conversation should *sound* like (D50).
///
/// The TTS input is the store's kana, never the line's kanji text: Google
/// applying its own readings would mask errors in our data, and hearing the
/// store's readings is the listening exercise's stated side benefit (spec §5).
/// Reuses the reading screen's display mapping, so audio and furigana speak
/// from the same authority: token readings from the store, punctuation from
/// `text` (D42), glue as-is.
library;

import 'package:meta/meta.dart';

import '../generation/conversation_generator.dart';
import '../reading/line_display.dart';
import 'tts_service.dart';

@immutable
class LineAudioSpec {
  const LineAudioSpec({required this.kana, required this.voice});

  final String kana;
  final String voice;

  @override
  bool operator ==(Object other) =>
      other is LineAudioSpec && other.kana == kana && other.voice == voice;

  @override
  int get hashCode => Object.hash(kana, voice);
}

/// The kana rendition of one line: each display token's reading, joined.
/// Plain segments (glue, punctuation, unreconcilable surfaces) contribute
/// their surface unchanged — glue is already kana, punctuation is spoken as
/// pause/intonation by the synthesizer.
String kanaLine(GenLine line, GenerationSeed seed) =>
    displayTokens(line, seed).map((t) => readingOf(t.segments)).join();

/// One spec per line, with voices assigned per speaker: first distinct
/// speaker → [speakerVoiceA], second → [speakerVoiceB] (stable within the
/// conversation; a third speaker wraps around rather than failing).
List<LineAudioSpec> lineAudioSpecs(
    GeneratedConversation convo, GenerationSeed seed) {
  const voices = [speakerVoiceA, speakerVoiceB];
  final speakerOrder = <int>[];
  return [
    for (final line in convo.lines)
      LineAudioSpec(
        kana: kanaLine(line, seed),
        voice: voices[_speakerIndex(speakerOrder, line.speakerNameId) %
            voices.length],
      ),
  ];
}

int _speakerIndex(List<int> order, int speakerNameId) {
  var idx = order.indexOf(speakerNameId);
  if (idx < 0) {
    order.add(speakerNameId);
    idx = order.length - 1;
  }
  return idx;
}

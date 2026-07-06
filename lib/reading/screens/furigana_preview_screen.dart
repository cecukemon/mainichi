/// Rendering-spike preview: hardcoded sample lines through the real
/// okurigana-split + FuriganaText pipeline, with the furigana toggle.
/// Exists so the layout can be eyeballed on a simulator (spec §8 phase 2:
/// "prove the per-token kanji-over-kana layout works and looks right before
/// building on it"); the actual reading exercise screen replaces this.
library;

import 'package:flutter/material.dart';

import '../../japanese/okurigana.dart';
import '../furigana_text.dart';

/// (surface, kana, kanji, conjugates) — the shapes the store can produce:
/// conjugated kanji verbs, whole-kanji and mixed-script names, kana-only
/// words, glue, punctuation.
const _sampleLines = [
  [
    ('鈴木', 'すずき', '鈴木', false),
    ('は', '', '', false), // glue
    ('学校', 'がっこう', '学校', false),
    ('に', '', '', false),
    ('行きます', 'いく', '行く', true),
    ('。', '', '', false),
  ],
  [
    ('田なか', 'たなか', '田なか', false),
    ('は', '', '', false),
    ('すし', 'すし', '', false),
    ('を', '', '', false),
    ('食べません', 'たべる', '食べる', true),
    ('。', '', '', false),
  ],
  [
    ('この', '', '', false),
    ('ほん', 'ほん', '', false),
    ('は', '', '', false),
    ('面白く', 'おもしろい', '面白い', true),
    ('ありません', '', '', false),
    ('。', '', '', false),
  ],
];

class FuriganaPreviewScreen extends StatefulWidget {
  const FuriganaPreviewScreen({super.key});

  @override
  State<FuriganaPreviewScreen> createState() => _FuriganaPreviewScreenState();
}

class _FuriganaPreviewScreenState extends State<FuriganaPreviewScreen> {
  bool _showFurigana = true;

  List<List<FuriganaSegment>> _tokensOf(List<(String, String, String, bool)> line) {
    return [
      for (final (surface, kana, kanji, conjugates) in line)
        kana.isEmpty
            ? [FuriganaSegment(surface)] // glue/punctuation: no entry, plain
            : furiganaSegments(
                    surface: surface,
                    kana: kana,
                    kanji: kanji,
                    conjugates: conjugates) ??
                [FuriganaSegment(surface)],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Furigana preview (spike)')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            title: const Text('Furigana'),
            subtitle: const Text('default on; hide to test kanji recall (spec §4)'),
            value: _showFurigana,
            onChanged: (v) => setState(() => _showFurigana = v),
          ),
          const SizedBox(height: 16),
          for (final line in _sampleLines) ...[
            FuriganaText(tokens: _tokensOf(line), showFurigana: _showFurigana),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

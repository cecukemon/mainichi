/// Per-token furigana rendering (spec §4, decision D5): each token is a small
/// reading-over-base stack, composed into a wrapping line.
///
/// Custom rather than the `ruby_text` package — evaluated per the spec's
/// §10.5 plan, but the package is unmaintained (last published 3 years ago)
/// and pulls in flutter_hooks/equatable/tuple for what is a small layout.
///
/// The widget is deliberately dumb: it takes pre-computed
/// [FuriganaSegment] lists (from `japanese/okurigana.dart`) and knows nothing
/// about vocab entries or conversations. Each token renders as one
/// unbreakable Row of segment stacks, so a line can never wrap in the middle
/// of a word (行 on one line, きます on the next).
library;

import 'package:flutter/material.dart';

import '../japanese/okurigana.dart';

class FuriganaText extends StatelessWidget {
  const FuriganaText({
    super.key,
    required this.tokens,
    this.showFurigana = true,
    this.baseStyle,
    this.rubyStyle,
  });

  /// One inner list per token; each token wraps as a unit.
  final List<List<FuriganaSegment>> tokens;

  /// The furigana toggle (spec §4): readings shown by default, hidden to test
  /// whether the kanji have stuck. The ruby band collapses when hidden.
  final bool showFurigana;

  final TextStyle? baseStyle;
  final TextStyle? rubyStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = baseStyle ??
        theme.textTheme.headlineSmall ??
        const TextStyle(fontSize: 24);
    final ruby = rubyStyle ??
        theme.textTheme.bodySmall?.copyWith(
          fontSize: (base.fontSize ?? 24) * 0.5,
          color: theme.colorScheme.onSurfaceVariant,
        ) ??
        TextStyle(fontSize: (base.fontSize ?? 24) * 0.5);
    // Every stack reserves the same ruby band so bases align across tokens
    // with and without readings on the same line.
    final rubyBandHeight = (ruby.fontSize ?? 12) * 1.4;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final token in tokens)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final segment in token)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showFurigana)
                      SizedBox(
                        height: rubyBandHeight,
                        child: segment.ruby == null
                            ? null
                            : Text(segment.ruby!, style: ruby),
                      ),
                    Text(segment.base, style: base),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}

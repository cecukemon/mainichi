import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/japanese/okurigana.dart';
import 'package:mainichi/reading/furigana_text.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  // 鈴木は行きます。 — whole-kanji ruby, plain glue, stem-ruby + conjugated tail.
  final tokens = [
    [const FuriganaSegment('鈴木', 'すずき')],
    [const FuriganaSegment('は')],
    [const FuriganaSegment('行', 'い'), const FuriganaSegment('きます')],
    [const FuriganaSegment('。')],
  ];

  testWidgets('renders every base segment and its ruby reading', (tester) async {
    await _pump(tester, FuriganaText(tokens: tokens));

    for (final base in ['鈴木', 'は', '行', 'きます', '。']) {
      expect(find.text(base), findsOneWidget);
    }
    expect(find.text('すずき'), findsOneWidget);
    expect(find.text('い'), findsOneWidget);
  });

  testWidgets('ruby text is styled smaller than the base text', (tester) async {
    await _pump(tester, FuriganaText(tokens: tokens));

    final ruby = tester.widget<Text>(find.text('すずき'));
    final base = tester.widget<Text>(find.text('鈴木'));
    expect(ruby.style!.fontSize!, lessThan(base.style!.fontSize!));
  });

  testWidgets('the furigana toggle hides all readings but keeps the base text', (tester) async {
    await _pump(tester, FuriganaText(tokens: tokens, showFurigana: false));

    expect(find.text('すずき'), findsNothing);
    expect(find.text('い'), findsNothing);
    expect(find.text('鈴木'), findsOneWidget);
    expect(find.text('きます'), findsOneWidget);
  });

  testWidgets('a multi-segment token is one unbreakable Row', (tester) async {
    await _pump(tester, FuriganaText(tokens: tokens));

    // 行 and きます must live in the same Row so the word can't wrap apart.
    final row = find.ancestor(of: find.text('行'), matching: find.byType(Row)).first;
    expect(
      find.descendant(of: row, matching: find.text('きます')),
      findsOneWidget,
    );
  });
}

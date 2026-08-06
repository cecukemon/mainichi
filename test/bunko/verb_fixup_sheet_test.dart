import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/bunko/bunko_providers.dart';
import 'package:mainichi/bunko/widgets/verb_fixup_sheet.dart';
import 'package:mainichi/data/bunko_store.dart';
import 'package:mainichi/data/enums.dart';

class FakeBunkoStore implements BunkoStore {
  FakeBunkoStore({required List<BunkoWordRow> words}) : words = [...words];

  final List<BunkoWordRow> words;

  @override
  Future<List<BunkoWordRow>> listWords() async => words;

  @override
  Future<List<BunkoStructureRow>> listStructures() async => const [];

  @override
  Future<List<BunkoGlueRow>> listGlue() async => const [];

  @override
  Future<BunkoWordDetail?> wordById(int id) async => null;

  @override
  Future<BunkoStructureDetail?> structureById(int id) async => null;

  @override
  Future<FixWordResult> fixWordBaseForm(int id,
      {required String kana, required String kanji}) async {
    final index = words.indexWhere((w) => w.id == id);
    if (index == -1) return const FixWordResult.notFound();
    final w = words[index];
    words[index] = BunkoWordRow(
      id: w.id,
      kana: kana,
      kanji: kanji,
      meaning: w.meaning,
      role: w.role,
      kanaOnly: w.kanaOnly,
      meaningSource: w.meaningSource,
      status: w.status,
      notes: w.notes,
      createdAt: w.createdAt,
    );
    return const FixWordResult.updated();
  }

  @override
  Future<void> dismissBaseFormSuspicion(int id) async {}
}

BunkoWordRow _verb(int id, String kana) => BunkoWordRow(
      id: id,
      kana: kana,
      kanji: '',
      meaning: null,
      role: WordRole.verb,
      kanaOnly: true,
      meaningSource: MeaningSource.inferred,
      status: ItemStatus.approved,
      notes: null,
      createdAt: DateTime(2026, 8, 1),
    );

void main() {
  testWidgets(
      'fixing one suspect does not leave the next one greyed out '
      '(list-position state-reuse regression)', (tester) async {
    final store = FakeBunkoStore(words: [
      _verb(1, 'もらいます'),
      _verb(2, 'たべます'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [bunkoStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(home: Scaffold(body: VerbFixupSheet())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('もらいます'), findsOneWidget);
    expect(find.text('たべます'), findsOneWidget);

    // Fix the first suspect — it should be removed from the list, leaving
    // the second suspect's card fully interactive, not greyed out.
    await tester.tap(find.widgetWithText(ActionChip, 'もらう').first);
    await tester.pumpAndSettle();

    expect(find.text('もらいます'), findsNothing);
    expect(find.text('たべます'), findsOneWidget);

    final opacity = tester.widget<Opacity>(
      find
          .ancestor(of: find.text('たべます'), matching: find.byType(Opacity))
          .first,
    );
    expect(opacity.opacity, 1.0);

    final ignorePointer = tester.widget<IgnorePointer>(
      find
          .ancestor(
              of: find.text('たべます'), matching: find.byType(IgnorePointer))
          .first,
    );
    expect(ignorePointer.ignoring, isFalse);

    // The remaining card's chips must still be tappable.
    expect(find.widgetWithText(ActionChip, 'たべる'), findsOneWidget);
  });
}

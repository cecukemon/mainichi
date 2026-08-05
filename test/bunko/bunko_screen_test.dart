import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/bunko/bunko_providers.dart';
import 'package:mainichi/bunko/screens/bunko_screen.dart';
import 'package:mainichi/data/bunko_store.dart';
import 'package:mainichi/data/enums.dart';

class FakeBunkoStore implements BunkoStore {
  FakeBunkoStore({
    List<BunkoWordRow>? words,
    List<BunkoStructureRow>? structures,
    List<BunkoGlueRow>? glue,
    this.throwOnLoad = false,
  })  : words = words ?? [],
        structures = structures ?? [],
        glue = glue ?? [];

  final List<BunkoWordRow> words;
  final List<BunkoStructureRow> structures;
  final List<BunkoGlueRow> glue;
  final bool throwOnLoad;

  @override
  Future<List<BunkoWordRow>> listWords() async {
    if (throwOnLoad) throw Exception('boom');
    return words;
  }

  @override
  Future<List<BunkoStructureRow>> listStructures() async => structures;

  @override
  Future<List<BunkoGlueRow>> listGlue() async => glue;

  @override
  Future<BunkoWordDetail?> wordById(int id) async {
    for (final w in words) {
      if (w.id == id) {
        return BunkoWordDetail(word: w, examples: const ['すしを食べる。']);
      }
    }
    return null;
  }

  @override
  Future<BunkoStructureDetail?> structureById(int id) async {
    for (final s in structures) {
      if (s.id == id) return BunkoStructureDetail(structure: s, examples: const []);
    }
    return null;
  }

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
  Future<void> dismissBaseFormSuspicion(int id) async {
    final index = words.indexWhere((w) => w.id == id);
    if (index == -1) return;
    final w = words[index];
    words[index] = BunkoWordRow(
      id: w.id,
      kana: w.kana,
      kanji: w.kanji,
      meaning: w.meaning,
      role: w.role,
      kanaOnly: w.kanaOnly,
      meaningSource: w.meaningSource,
      status: w.status,
      notes: '${w.notes ?? ''} $baseFormCheckedMarker'.trim(),
      createdAt: w.createdAt,
    );
  }
}

BunkoWordRow _word(int id, {
  required String kana,
  String kanji = '',
  String? meaning,
  WordRole role = WordRole.noun,
}) =>
    BunkoWordRow(
      id: id,
      kana: kana,
      kanji: kanji,
      meaning: meaning,
      role: role,
      kanaOnly: kanji.isEmpty,
      meaningSource: MeaningSource.printedGloss,
      status: ItemStatus.approved,
      notes: null,
      createdAt: DateTime(2026, 7, 18),
    );

Future<FakeBunkoStore> _pump(
  WidgetTester tester, {
  List<BunkoWordRow>? words,
  List<BunkoStructureRow>? structures,
  List<BunkoGlueRow>? glue,
  bool throwOnLoad = false,
}) async {
  final store = FakeBunkoStore(
    words: words,
    structures: structures,
    glue: glue,
    throwOnLoad: throwOnLoad,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [bunkoStoreProvider.overrideWithValue(store)],
      child: const MaterialApp(home: BunkoScreen()),
    ),
  );
  return store;
}

void main() {
  testWidgets('shows a spinner before the load resolves', (tester) async {
    await _pump(tester, words: [_word(1, kana: 'すし')]);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump();
  });

  testWidgets('shows an error view with retry on load failure', (tester) async {
    await _pump(tester, throwOnLoad: true);
    await tester.pump();

    expect(find.text("Couldn't load your Bunko"), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
  });

  testWidgets('words tab shows rows (kanji-else-kana) and role chips',
      (tester) async {
    await _pump(tester, words: [
      _word(1, kana: 'すし', kanji: '寿司', meaning: 'sushi', role: WordRole.noun),
      _word(2, kana: 'たべる', role: WordRole.verb),
    ]);
    await tester.pump();

    expect(find.text('寿司'), findsOneWidget);
    expect(find.text('たべる'), findsOneWidget);
    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('Noun (1)'), findsOneWidget);
    expect(find.text('Verb (1)'), findsOneWidget);
  });

  testWidgets('tapping a role chip filters the list; All restores',
      (tester) async {
    await _pump(tester, words: [
      _word(1, kana: 'すし', kanji: '寿司', role: WordRole.noun),
      _word(2, kana: 'たべる', role: WordRole.verb),
    ]);
    await tester.pump();

    await tester.tap(find.text('Verb (1)'));
    await tester.pump();
    expect(find.text('たべる'), findsOneWidget);
    expect(find.text('寿司'), findsNothing);

    await tester.tap(find.text('All (2)'));
    await tester.pump();
    expect(find.text('たべる'), findsOneWidget);
    expect(find.text('寿司'), findsOneWidget);
  });

  testWidgets('structures and glue tabs show their rows and empty states',
      (tester) async {
    await _pump(
      tester,
      words: [_word(1, kana: 'すし')],
      structures: [
        BunkoStructureRow(
          id: 1,
          template: 'これは {noun_1} です',
          notes: null,
          status: ItemStatus.approved,
          createdAt: DateTime(2026, 7, 18),
          slots: const [],
        ),
      ],
      glue: const [],
    );
    await tester.pump();

    await tester.tap(find.text('Structures'));
    await tester.pumpAndSettle();
    expect(find.text('これは {noun_1} です'), findsOneWidget);

    await tester.tap(find.text('Glue'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('tapping a word row opens the detail sheet with meaning and examples',
      (tester) async {
    await _pump(tester, words: [
      _word(1, kana: 'すし', kanji: '寿司', meaning: 'sushi'),
    ]);
    await tester.pump();

    await tester.tap(find.text('寿司'));
    await tester.pumpAndSettle();

    expect(find.text('sushi'), findsOneWidget);
    expect(find.text('すしを食べる。'), findsOneWidget);
  });
}

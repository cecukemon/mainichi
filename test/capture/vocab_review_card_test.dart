import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/capture/capture_providers.dart';
import 'package:mainichi/capture/models.dart';
import 'package:mainichi/capture/widgets/vocab_review_card.dart';
import 'package:mainichi/capture/widgets/worksheet_photo_box.dart';
import 'package:mainichi/data/database.dart';
import 'package:mainichi/data/enums.dart';

const _item = VocabDraftItem(
  kana: 'その',
  kanji: '',
  romaji: '',
  meaning: '',
  role: WordRole.other,
  kanaOnly: false,
  meaningSource: MeaningSource.none,
  confidence: ConfidenceTier.low,
);

Future<void> _pumpCard(
  WidgetTester tester, {
  VocabDraftItem item = _item,
  bool showWorksheetComparison = true,
  bool requireMeaning = false,
  void Function(VocabDraftItem edited)? onApprove,
}) async {
  // WorksheetPhotoBox reads the capture queue, so the card needs a provider
  // scope with a database behind it even standalone.
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: Scaffold(
          body: VocabReviewCard(
            item: item,
            showWorksheetComparison: showWorksheetComparison,
            requireMeaning: requireMeaning,
            onApprove: onApprove ?? (_) {},
            onSkip: () {},
            onDiscard: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the worksheet comparison box by default (capture flow)',
      (tester) async {
    await _pumpCard(tester);
    expect(find.text('Compare with the worksheet'), findsOneWidget);
    expect(find.byType(WorksheetPhotoBox), findsOneWidget);
  });

  testWidgets('showWorksheetComparison: false hides the box (backfill flow)',
      (tester) async {
    await _pumpCard(tester, showWorksheetComparison: false);
    expect(find.text('Compare with the worksheet'), findsNothing);
    expect(find.byType(WorksheetPhotoBox), findsNothing);
  });

  testWidgets('requireMeaning disables Approve until a meaning is entered',
      (tester) async {
    VocabDraftItem? approved;
    await _pumpCard(tester,
        requireMeaning: true, onApprove: (edited) => approved = edited);

    final approveFinder = find.widgetWithText(FilledButton, 'Approve');
    expect(tester.widget<FilledButton>(approveFinder).onPressed, isNull);

    // TextFields in order: kanji free-text (no candidates), then meaning.
    await tester.enterText(find.byType(TextField).at(1), 'that (near you)');
    await tester.pump();
    expect(tester.widget<FilledButton>(approveFinder).onPressed, isNotNull);

    await tester.ensureVisible(approveFinder);
    await tester.tap(approveFinder);
    expect(approved?.meaning, 'that (near you)');
  });

  testWidgets('without requireMeaning, Approve stays enabled on an empty '
      'meaning (capture default)', (tester) async {
    await _pumpCard(tester);
    final approveFinder = find.widgetWithText(FilledButton, 'Approve');
    expect(tester.widget<FilledButton>(approveFinder).onPressed, isNotNull);
  });

  group('polite-form verb base-form validation', () {
    const unambiguousItem = VocabDraftItem(
      kana: 'もらいました',
      kanji: '',
      romaji: '',
      meaning: 'to receive',
      role: WordRole.verb,
      kanaOnly: false,
      meaningSource: MeaningSource.inferred,
      confidence: ConfidenceTier.high,
    );
    const ambiguousItem = VocabDraftItem(
      kana: 'もらいます',
      kanji: '',
      romaji: '',
      meaning: 'to receive',
      role: WordRole.verb,
      kanaOnly: false,
      meaningSource: MeaningSource.inferred,
      confidence: ConfidenceTier.high,
    );

    testWidgets(
        'an unambiguous polite ending (ました) disables Approve until fixed',
        (tester) async {
      VocabDraftItem? approved;
      await _pumpCard(tester,
          item: unambiguousItem, onApprove: (edited) => approved = edited);

      expect(find.textContaining('dictionary (base) form'), findsOneWidget);
      final approveFinder = find.widgetWithText(FilledButton, 'Approve');
      expect(tester.widget<FilledButton>(approveFinder).onPressed, isNull);

      await tester.tap(find.widgetWithText(ActionChip, 'もらう'));
      await tester.pump();
      expect(tester.widget<FilledButton>(approveFinder).onPressed, isNotNull);

      await tester.ensureVisible(approveFinder);
      await tester.tap(approveFinder);
      expect(approved?.kana, 'もらう');
    });

    testWidgets('an ambiguous ます ending warns but leaves Approve enabled',
        (tester) async {
      await _pumpCard(tester, item: ambiguousItem);

      expect(find.textContaining('if this is the polite form'), findsOneWidget);
      final approveFinder = find.widgetWithText(FilledButton, 'Approve');
      expect(tester.widget<FilledButton>(approveFinder).onPressed, isNotNull);

      await tester.tap(find.widgetWithText(ActionChip, 'もらう'));
      await tester.pump();
      // Still enabled after picking a candidate; the field just updates.
      expect(tester.widget<FilledButton>(approveFinder).onPressed, isNotNull);
    });

    testWidgets('changing role away from verb clears the warning and gate',
        (tester) async {
      await _pumpCard(tester, item: unambiguousItem);
      expect(find.textContaining('dictionary (base) form'), findsOneWidget);

      final dropdownFinder = find.byType(DropdownButtonFormField<WordRole>);
      await tester.ensureVisible(dropdownFinder);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text(WordRole.noun.name).last);
      await tester.pumpAndSettle();

      expect(find.textContaining('dictionary (base) form'), findsNothing);
      final approveFinder = find.widgetWithText(FilledButton, 'Approve');
      expect(tester.widget<FilledButton>(approveFinder).onPressed, isNotNull);
    });
  });

  testWidgets('ranked kanji candidates each render as a chip, plus "No kanji" '
      '(D58)', (tester) async {
    await _pumpCard(
      tester,
      item: const VocabDraftItem(
        kana: 'はし',
        kanji: '橋',
        romaji: '',
        meaning: 'bridge',
        role: WordRole.noun,
        kanaOnly: false,
        meaningSource: MeaningSource.inferred,
        confidence: ConfidenceTier.low,
        kanjiCandidates: ['橋', '箸'],
      ),
    );
    expect(find.widgetWithText(ChoiceChip, '橋'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '箸'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'No kanji'), findsOneWidget);
  });
}

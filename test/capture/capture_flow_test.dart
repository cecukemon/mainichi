import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/capture/capture_providers.dart';
import 'package:mainichi/capture/screens/triage_screen.dart';
import 'package:mainichi/data/database.dart';

/// Review cards are tall (chips + fields + role dropdown); give the test
/// surface phone-sized room so buttons aren't scrolled off the fake viewport.
void _usePhoneSizedSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('triage -> review queue -> commit -> done, end to end', (tester) async {
    _usePhoneSizedSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: TriageScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Triage screen: 4 items need review (1 dedup + 2 vocab + 1 template).
    expect(find.textContaining('Review queue (4)'), findsOneWidget);
    await _tap(tester, find.textContaining('Review queue (4)'));

    // 1. Dedup card for たべる — merge it.
    expect(find.text('Possible match in your Bunko'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Merge'));

    // 2. Low-confidence vocab card for はしる — approve as-is.
    expect(find.text('Vocabulary — low confidence'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Approve'));

    // 3. Picture-derived word card — approve as-is.
    expect(find.text('Picture-derived · meaning inferred'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Approve'));

    // 4. Template card — approve as-is.
    expect(find.text('Template — slot guess'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Approve'));

    // Queue exhausted.
    expect(find.text('Continue to commit'), findsOneWidget);
    await _tap(tester, find.text('Continue to commit'));

    // Commit screen: nothing written yet (just the seeded demo entry).
    expect(await db.select(db.words).get(), hasLength(1));
    // すし was never in the queue (high-confidence, no dedup) but is still
    // committed by default — "pre-approved" per spec §3 — so the total is 5:
    // すし + はしる(vocab, 走る) + はしる(picture, no kanji) + たべる merge + 1 template.
    expect(find.text('Commit 5 items'), findsOneWidget);
    await _tap(tester, find.text('Commit 5 items'));

    // Done screen.
    expect(find.text('Added to your Bunko'), findsOneWidget);

    final words = await db.select(db.words).get();
    expect(words, hasLength(4)); // 食べる (seeded, merged) + すし + はしる(走る) + はしる(no kanji)
    expect(await db.select(db.structures).get(), hasLength(1));
  });

  testWidgets('skip is revisitable before commit', (tester) async {
    _usePhoneSizedSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: TriageScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.textContaining('Review queue (4)'));

    // Skip the dedup check.
    await _tap(tester, find.widgetWithText(OutlinedButton, 'Skip'));
    expect(find.text('Skipped (1)'), findsOneWidget);

    // Reopen it from the skipped list.
    await _tap(tester, find.text('Skipped (1)'));
    await _tap(tester, find.text('食べる (たべる)'));

    expect(find.text('Possible match in your Bunko'), findsOneWidget);
  });

  testWidgets('approve all high-confidence stages, and undo reverts it', (tester) async {
    _usePhoneSizedSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: TriageScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await _tap(tester, find.textContaining('Approve all high-confidence'));
    expect(find.textContaining('high-confidence staged'), findsOneWidget);
    expect(find.textContaining('Approve all high-confidence'), findsNothing);

    await _tap(tester, find.text('Undo'));
    expect(find.textContaining('high-confidence staged'), findsNothing);
    expect(find.textContaining('Approve all high-confidence'), findsOneWidget);
  });

  testWidgets('discarding a vocab item excludes it entirely from commit', (tester) async {
    _usePhoneSizedSurface(tester);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: TriageScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.textContaining('Review queue (4)'));

    // 1. Dedup card — skip past it.
    await _tap(tester, find.widgetWithText(OutlinedButton, 'Skip'));

    // 2. Low-confidence vocab card for はしる — discard it as junk.
    expect(find.text('Vocabulary — low confidence'), findsOneWidget);
    await _tap(tester, find.text('Discard extraction'));

    // 3. Picture-derived word card — approve as-is.
    expect(find.text('Picture-derived · meaning inferred'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Approve'));

    // 4. Template card — approve as-is.
    expect(find.text('Template — slot guess'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Approve'));

    await _tap(tester, find.text('Continue to commit'));

    // Discarded item is excluded entirely — not written, not listed as skipped
    // (unlike the still-skipped dedup check for たべる).
    expect(find.textContaining('走る'), findsNothing);
    expect(find.text('1 item(s) skipped won\'t be saved'), findsOneWidget);

    await _tap(tester, find.textContaining('Commit'));

    final words = await db.select(db.words).get();
    // 食べる (seeded, untouched — dedup was skipped) + すし + はしる (picture, no kanji).
    // 走る (the discarded vocab item) is not written.
    expect(words.map((w) => w.kanji), isNot(contains('走る')));
    expect(words, hasLength(3));
  });
}

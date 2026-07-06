import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mainichi/capture/capture_providers.dart';
import 'package:mainichi/capture/screens/photo_import_screen.dart';
import 'package:mainichi/capture/screens/triage_screen.dart';
import 'package:mainichi/data/database.dart';
import 'package:mainichi/extraction/extraction_client.dart';
import 'package:mainichi/extraction/extraction_providers.dart';

import 'fake_extraction_service.dart';
import 'fake_image_picker_platform.dart';

Map<String, dynamic> _extraction() {
  return {
    'worksheet': {'title': 'live sheet', 'topic': 'topic', 'orientation_note': 'upright'},
    'vocabulary': <Object>[],
    'structures': <Object>[],
    'handwriting': {'detected': false, 'ignored_notes': <String>[]},
  };
}

/// TriageScreen's content overflows the default test viewport (same fix as
/// capture_flow_test.dart's `_usePhoneSizedSurface`).
void _usePhoneSizedSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    ImagePickerPlatform.instance = FakeImagePickerPlatform.cancelled();
  });

  testWidgets('picking a photo extracts it and lands on TriageScreen with the live draft', (tester) async {
    _usePhoneSizedSurface(tester);
    ImagePickerPlatform.instance =
        FakeImagePickerPlatform.returningImage(Uint8List.fromList([1, 2, 3]));
    final fakeService = FakeExtractionService.returning(_extraction());
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          extractionServiceProvider.overrideWithValue(fakeService),
        ],
        child: MaterialApp(home: PhotoImportScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Take photo'));
    await tester.pumpAndSettle();

    expect(find.byType(TriageScreen), findsOneWidget);
    expect(fakeService.lastImageBytes, [1, 2, 3]);
  });

  testWidgets('shows an error and stays put when no API key is configured', (tester) async {
    ImagePickerPlatform.instance =
        FakeImagePickerPlatform.returningImage(Uint8List.fromList([1, 2, 3]));
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          extractionServiceProvider.overrideWithValue(FakeExtractionService.throwing(ApiKeyMissing())),
        ],
        child: MaterialApp(home: PhotoImportScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Take photo'));
    await tester.pumpAndSettle();

    expect(find.byType(TriageScreen), findsNothing);
    expect(find.textContaining('No API key set'), findsOneWidget);
  });

  testWidgets('cancelling the picker leaves the source-picker screen showing', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: PhotoImportScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Take photo'));
    await tester.pumpAndSettle();

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.byType(TriageScreen), findsNothing);
  });
}

import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mainichi/capture/capture_providers.dart';
import 'package:mainichi/capture/image_prep.dart';
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

/// A real 100×100 JPEG — `normalizeImage` now decodes the picked bytes, so a
/// placeholder byte list would fail.
Uint8List sampleJpeg() {
  final image = img.Image(width: 100, height: 100);
  img.fill(image, color: img.ColorRgb8(90, 90, 90));
  return Uint8List.fromList(img.encodeJpg(image));
}

/// Test seams: no isolates, no platform channels (both deadlock/unavailable
/// under the fake test clock).
Future<NormalizedImage> _directNormalize(Uint8List b) async => normalizeImage(b);
Future<Uint8List> _directCrop(CropRequest r) async => cropAndEncode(r);

/// TriageScreen's content overflows the default test viewport (same fix as
/// capture_flow_test.dart's `_usePhoneSizedSurface`).
void _usePhoneSizedSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

PhotoImportScreen _screen(Directory docs) => PhotoImportScreen(
      imageNormalizer: _directNormalize,
      cropper: _directCrop,
      documentsDirectory: () async => docs,
    );

void main() {
  late Directory docs;
  setUp(() {
    ImagePickerPlatform.instance = FakeImagePickerPlatform.cancelled();
    docs = Directory.systemTemp.createTempSync('mainichi_import_test');
    addTearDown(() => docs.deleteSync(recursive: true));
  });

  testWidgets('picking a photo prepares it, sends the cropped JPEG, and lands '
      'on TriageScreen with the saved sourceImage', (tester) async {
    _usePhoneSizedSurface(tester);
    ImagePickerPlatform.instance =
        FakeImagePickerPlatform.returningImage(sampleJpeg());
    final fakeService = FakeExtractionService.returning(_extraction());
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          extractionServiceProvider.overrideWithValue(fakeService),
        ],
        child: MaterialApp(home: _screen(docs)),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Take photo'));
    await tester.pumpAndSettle();

    // The prep screen is shown; confirm the frame.
    expect(find.text('Send to extractor'), findsOneWidget);
    await tester.tap(find.text('Send to extractor'));
    await tester.pumpAndSettle();

    expect(find.byType(TriageScreen), findsOneWidget);
    // The extractor received a decodable JPEG (the prepared bytes), not the
    // raw picker bytes verbatim.
    expect(img.decodeImage(Uint8List.fromList(fakeService.lastImageBytes!)),
        isNotNull);
    // The prepared JPEG was persisted under the injected documents dir, and
    // the loaded draft's sourceImage points at it (the Imports row itself is
    // written later, on review commit).
    final container = ProviderScope.containerOf(
        tester.element(find.byType(TriageScreen)));
    final sourceImage = container.read(captureQueueProvider).draft?.sourceImage;
    expect(sourceImage, startsWith(docs.path));
    expect(File(sourceImage!).existsSync(), isTrue);
    expect(img.decodeImage(File(sourceImage).readAsBytesSync()), isNotNull);
  });

  testWidgets('shows an error and stays put when no API key is configured',
      (tester) async {
    ImagePickerPlatform.instance =
        FakeImagePickerPlatform.returningImage(sampleJpeg());
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          extractionServiceProvider.overrideWithValue(
              FakeExtractionService.throwing(ApiKeyMissing())),
        ],
        child: MaterialApp(home: _screen(docs)),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Take photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to extractor'));
    await tester.pumpAndSettle();

    expect(find.byType(TriageScreen), findsNothing);
    expect(find.textContaining('No API key set'), findsOneWidget);
  });

  testWidgets('backing out of the prep screen returns to the source picker',
      (tester) async {
    ImagePickerPlatform.instance =
        FakeImagePickerPlatform.returningImage(sampleJpeg());
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: _screen(docs)),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Take photo'));
    await tester.pumpAndSettle();
    // On the prep screen — back out.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.byType(TriageScreen), findsNothing);
  });

  testWidgets('cancelling the picker leaves the source-picker screen showing',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: _screen(docs)),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Take photo'));
    await tester.pumpAndSettle();

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.byType(TriageScreen), findsNothing);
  });
}

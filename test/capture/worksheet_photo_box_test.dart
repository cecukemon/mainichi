import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/capture/capture_providers.dart';
import 'package:mainichi/capture/models.dart';
import 'package:mainichi/capture/widgets/worksheet_photo_box.dart';
import 'package:mainichi/data/database.dart';

/// A valid 1x1 transparent PNG, so Image.file has something decodable.
const _tinyPng = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

CaptureDraft _draft({String? sourceImage}) => CaptureDraft(
      worksheetTitle: 't',
      worksheetTopic: 'topic',
      vocabulary: const [],
      templates: const [],
      sourceImage: sourceImage,
    );

Future<void> _pump(WidgetTester tester, {CaptureDraft? draft}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  addTearDown(container.dispose);
  if (draft != null) {
    await container.read(captureQueueProvider.notifier).loadFromExtraction(draft);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: WorksheetPhotoBox(label: 'worksheet photo')),
      ),
    ),
  );
}

void main() {
  testWidgets('no photo on the draft: labeled placeholder, no image',
      (tester) async {
    await _pump(tester, draft: _draft());
    expect(find.text('worksheet photo'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('live import photo renders in the box and zooms', (tester) async {
    final file = File(
        '${Directory.systemTemp.createTempSync('mainichi_test').path}/w.png')
      ..writeAsBytesSync(_tinyPng);
    addTearDown(() => file.parent.deleteSync(recursive: true));

    await _pump(tester, draft: _draft(sourceImage: file.path));
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('worksheet photo'), findsNothing);

    await tester.tap(find.byIcon(Icons.zoom_in));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2)); // box + zoom dialog
  });

  testWidgets('a stale path falls back to the placeholder', (tester) async {
    await _pump(tester,
        draft: _draft(sourceImage: '/no/such/photo/anywhere.jpg'));
    expect(find.text('worksheet photo'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}

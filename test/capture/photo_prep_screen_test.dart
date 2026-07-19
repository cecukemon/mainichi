import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mainichi/capture/image_prep.dart';
import 'package:mainichi/capture/screens/photo_prep_screen.dart';

img.Image quadrants(int w, int h) {
  final image = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final c = y < h ~/ 2
          ? (x < w ~/ 2
              ? img.ColorRgb8(255, 0, 0)
              : img.ColorRgb8(0, 255, 0))
          : (x < w ~/ 2
              ? img.ColorRgb8(0, 0, 255)
              : img.ColorRgb8(255, 255, 255));
      image.setPixel(x, y, c);
    }
  }
  return image;
}

NormalizedImage normalized(int w, int h) {
  final image = quadrants(w, h);
  return NormalizedImage(
      jpegBytes: Uint8List.fromList(img.encodeJpg(image)),
      width: w,
      height: h);
}

// Synchronous stand-in for the isolate cropper (compute deadlocks under the
// fake test clock).
Future<Uint8List> directCrop(CropRequest r) async => cropAndEncode(r);

void main() {
  testWidgets('Send with the default fit returns (approximately) the whole '
      'image', (tester) async {
    Uint8List? popped;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => popped = await Navigator.of(context)
              .push<Uint8List>(MaterialPageRoute(
                  builder: (_) => PhotoPrepScreen(
                      image: normalized(200, 400), cropper: directCrop))),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send to extractor'));
    await tester.pumpAndSettle();

    expect(popped, isNotNull);
    final out = img.decodeImage(popped!)!;
    // Fit-to-view of a 200×400 image centered in the frame keeps the whole
    // image visible, so the crop is the full image (within rounding).
    expect(out.width, closeTo(200, 4));
    expect(out.height, closeTo(400, 4));
  });

  testWidgets('an injected zoomed transform crops to the visible sub-rect',
      (tester) async {
    // Scale 2 about the origin: only the top-left quarter is visible. For a
    // 200×400 image in a viewport of the same size, that's a 100×200 crop of
    // the red/blue left column.
    final controller = TransformationController(
      Matrix4.identity()..scaleByDouble(2.0, 2.0, 1, 1),
    );
    Uint8List? popped;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => popped = await Navigator.of(context)
              .push<Uint8List>(MaterialPageRoute(
                  builder: (_) => PhotoPrepScreen(
                      image: normalized(200, 400),
                      controller: controller,
                      cropper: directCrop))),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send to extractor'));
    await tester.pumpAndSettle();

    expect(popped, isNotNull);
    final out = img.decodeImage(popped!)!;
    // The 800px-wide test surface is wider than the 200px image even at 2×,
    // so width stays full; the zoom crops height. Assert the crop shrank
    // vertically and kept the top-left (red) content.
    expect(out.height, lessThan(400)); // zoom took effect
    final topLeft = out.getPixel(1, 1);
    expect(topLeft.r, greaterThan(180)); // red TL quadrant
    expect(topLeft.g, lessThan(80));
  });

  testWidgets('backing out pops null', (tester) async {
    Uint8List? popped;
    var returned = false;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            popped = await Navigator.of(context).push<Uint8List>(
                MaterialPageRoute(
                    builder: (_) =>
                        PhotoPrepScreen(image: normalized(100, 100))));
            returned = true;
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The AppBar back button.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(returned, isTrue);
    expect(popped, isNull);
  });
}

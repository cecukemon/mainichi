import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mainichi/capture/image_prep.dart';

/// A solid-color [w]×[h] JPEG.
Uint8List solidJpeg(int w, int h, img.Color color) {
  final image = img.Image(width: w, height: h);
  img.fill(image, color: color);
  return img.encodeJpg(image);
}

/// A four-quadrant image: TL red, TR green, BL blue, BR white.
img.Image quadrants(int w, int h) {
  final image = img.Image(width: w, height: h);
  final red = img.ColorRgb8(255, 0, 0);
  final green = img.ColorRgb8(0, 255, 0);
  final blue = img.ColorRgb8(0, 0, 255);
  final white = img.ColorRgb8(255, 255, 255);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final c = y < h ~/ 2
          ? (x < w ~/ 2 ? red : green)
          : (x < w ~/ 2 ? blue : white);
      image.setPixel(x, y, c);
    }
  }
  return image;
}

void main() {
  group('normalizeImage', () {
    test('downscales the long edge to 2000, preserving aspect', () {
      final raw = solidJpeg(4000, 1000, img.ColorRgb8(120, 120, 120));
      final out = normalizeImage(raw);
      expect(out.width, 2000);
      expect(out.height, 500);
      final round = img.decodeImage(out.jpegBytes)!;
      expect(round.width, 2000);
      expect(round.height, 500);
    });

    test('leaves an already-small image at its own dimensions', () {
      final raw = solidJpeg(800, 600, img.ColorRgb8(10, 20, 30));
      final out = normalizeImage(raw);
      expect(out.width, 800);
      expect(out.height, 600);
    });

    test('bakes EXIF orientation 6 (90° CW) into the pixels', () {
      // A wide image tagged "rotate 90° CW" should come out tall, with the
      // original top-left landing on the top-right after the rotation.
      final image = quadrants(40, 20);
      image.exif.imageIfd['Orientation'] = 6;
      final raw = img.encodeJpg(image);

      final out = normalizeImage(raw);
      expect(out.width, 20); // dimensions swapped
      expect(out.height, 40);

      final baked = img.decodeImage(out.jpegBytes)!;
      // Original TL (red) rotates to the new top-right corner.
      final topRight = baked.getPixel(baked.width - 1, 0);
      expect(topRight.r, greaterThan(180));
      expect(topRight.g, lessThan(80));
      expect(topRight.b, lessThan(80));
    });

    test('throws ImageDecodeFailed on undecodable bytes', () {
      expect(() => normalizeImage(Uint8List.fromList([1, 2, 3, 4])),
          throwsA(isA<ImageDecodeFailed>()));
    });
  });

  group('cropAndEncode', () {
    test('crops to the requested quadrant', () {
      final jpeg = img.encodeJpg(quadrants(100, 100));
      final out = cropAndEncode(CropRequest(
        jpeg,
        const PixelRect(left: 0, top: 0, width: 50, height: 50),
      ));
      final cropped = img.decodeImage(out)!;
      expect(cropped.width, 50);
      expect(cropped.height, 50);
      // Whole crop is the red TL quadrant.
      final center = cropped.getPixel(25, 25);
      expect(center.r, greaterThan(180));
      expect(center.g, lessThan(80));
    });

    test('clamps an out-of-bounds rect to the image', () {
      final jpeg = img.encodeJpg(quadrants(100, 100));
      final out = cropAndEncode(CropRequest(
        jpeg,
        const PixelRect(left: 80, top: 80, width: 999, height: 999),
      ));
      final cropped = img.decodeImage(out)!;
      expect(cropped.width, 20);
      expect(cropped.height, 20);
    });

    test('a full-frame rect returns the input bytes unchanged', () {
      final jpeg = img.encodeJpg(quadrants(64, 48));
      final out = cropAndEncode(CropRequest(
        jpeg,
        const PixelRect(left: 0, top: 0, width: 64, height: 48),
      ));
      expect(identical(out, jpeg), isTrue);
    });
  });

  group('cropRectFromTransform', () {
    const viewport = Size(200, 400);
    const imageSize = Size(200, 400);

    test('identity transform maps to the whole image', () {
      final rect = cropRectFromTransform(
        transform: Matrix4.identity(),
        viewport: viewport,
        imageSize: imageSize,
      );
      expect(rect, isNotNull);
      expect(rect!.left, 0);
      expect(rect.top, 0);
      expect(rect.width, 200);
      expect(rect.height, 400);
    });

    test('scale 2 about the origin shows the top-left quarter', () {
      final rect = cropRectFromTransform(
        transform: Matrix4.identity()..scaleByDouble(2.0, 2.0, 1, 1),
        viewport: viewport,
        imageSize: imageSize,
      );
      expect(rect, isNotNull);
      expect(rect!.left, 0);
      expect(rect.top, 0);
      expect(rect.width, 100);
      expect(rect.height, 200);
    });

    test('a translate offsets the visible source rect', () {
      // Panning the image up-left by (scaled) 100px reveals content further
      // right/down. With scale 2 and translate -100, the visible source rect
      // starts at 50px in image space.
      final rect = cropRectFromTransform(
        transform: Matrix4.identity()
          ..translateByDouble(-100.0, -100.0, 0, 1)
          ..scaleByDouble(2.0, 2.0, 1, 1),
        viewport: viewport,
        imageSize: imageSize,
      );
      expect(rect, isNotNull);
      expect(rect!.left, 50);
      expect(rect.top, 50);
    });

    test('an image panned fully out of frame is degenerate (null)', () {
      final rect = cropRectFromTransform(
        // Push the image far off to the left of the viewport.
        transform: Matrix4.identity()..translateByDouble(-100000.0, 0.0, 0, 1),
        viewport: viewport,
        imageSize: imageSize,
      );
      expect(rect, isNull);
    });
  });
}

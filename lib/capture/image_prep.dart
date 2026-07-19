/// Pre-send image preparation for the live worksheet import (D57).
///
/// The extractor contract says the caller owns resizing/orientation
/// (`ExtractionService`), so this is that owner: decode the picked photo, bake
/// its EXIF orientation into the pixels (vision models read pixels, not EXIF),
/// downscale to a sane long edge, and — after the user frames it on the prep
/// screen — crop to what they chose. Everything here is pure and UI-free so it
/// runs on a background isolate via `compute()` (top-level functions,
/// serializable args) and so the crop math is unit-testable without widgets.
///
/// The crop regions feature (D58) depends on this: regions are coordinates
/// into the exact bytes we send, which is why the sent/stored image is the
/// baked-and-cropped one, not the raw pick.
library;

import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Matrix4, MatrixUtils, Offset, Size;
import 'package:image/image.dart' as img;

/// Longest edge (px) the sent image is downscaled to. A vision model gains
/// nothing from more, and it keeps the base64 payload and decode cost down.
const int maxLongEdge = 2000;

/// Thrown when the picked bytes can't be decoded as an image — a corrupt file
/// or an unsupported format the platform picker somehow returned.
class ImageDecodeFailed implements Exception {
  const ImageDecodeFailed();
  @override
  String toString() => 'ImageDecodeFailed: could not decode the picked image';
}

/// A normalized (upright, downscaled) JPEG plus its pixel dimensions — what
/// the prep screen displays and computes crop coordinates against.
class NormalizedImage {
  const NormalizedImage(
      {required this.jpegBytes, required this.width, required this.height});
  final Uint8List jpegBytes;
  final int width;
  final int height;

  Size get size => Size(width.toDouble(), height.toDouble());
}

/// Decode → bake EXIF orientation → downscale to [maxLongEdge] → re-encode
/// JPEG. Idempotent on already-upright, already-small input (baking is a
/// no-op without EXIF; resize is skipped when it already fits). A `compute()`
/// entry point: top-level, one arg, serializable result.
NormalizedImage normalizeImage(Uint8List raw) {
  final decoded = _decodeOrThrow(raw);

  var image = img.bakeOrientation(decoded);
  final longEdge = image.width > image.height ? image.width : image.height;
  if (longEdge > maxLongEdge) {
    // copyResize preserves aspect ratio when only one dimension is given.
    image = image.width >= image.height
        ? img.copyResize(image, width: maxLongEdge)
        : img.copyResize(image, height: maxLongEdge);
  }

  return NormalizedImage(
    jpegBytes: img.encodeJpg(image, quality: 85),
    width: image.width,
    height: image.height,
  );
}

/// Integer crop rectangle in image-pixel space.
class PixelRect {
  const PixelRect(
      {required this.left,
      required this.top,
      required this.width,
      required this.height});
  final int left, top, width, height;
}

/// Argument record for the [cropAndEncode] `compute()` entry point (compute
/// takes a single serializable message).
class CropRequest {
  const CropRequest(this.jpegBytes, this.rect);
  final Uint8List jpegBytes;
  final PixelRect rect;
}

/// Crop a normalized JPEG to [CropRequest.rect] (clamped to bounds) and
/// re-encode. A rect covering the whole image short-circuits to the input
/// bytes. No re-downscale: a crop of a ≤[maxLongEdge] image is still within
/// bounds. A `compute()` entry point.
Uint8List cropAndEncode(CropRequest req) {
  final decoded = _decodeOrThrow(req.jpegBytes);

  final left = req.rect.left.clamp(0, decoded.width - 1);
  final top = req.rect.top.clamp(0, decoded.height - 1);
  final width = req.rect.width.clamp(1, decoded.width - left);
  final height = req.rect.height.clamp(1, decoded.height - top);

  if (left == 0 &&
      top == 0 &&
      width == decoded.width &&
      height == decoded.height) {
    return req.jpegBytes;
  }

  final cropped =
      img.copyCrop(decoded, x: left, y: top, width: width, height: height);
  return img.encodeJpg(cropped, quality: 85);
}

/// Decodes to an `img.Image`, mapping both a null return and any decoder
/// exception (the `image` package throws on some malformed inputs rather than
/// returning null) to [ImageDecodeFailed].
img.Image _decodeOrThrow(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const ImageDecodeFailed();
    return decoded;
  } on ImageDecodeFailed {
    rethrow;
  } catch (_) {
    throw const ImageDecodeFailed();
  }
}

/// Minimum crop side (px) below which we treat the framing as degenerate (the
/// user panned the image entirely out of the frame) and send the whole image.
const int _minCropSide = 8;

/// Maps an [InteractiveViewer]'s transform to the source-image rectangle
/// currently visible in [viewport]. The viewer is configured `constrained:
/// false` with a child sized to the image's own pixels, so the controller
/// matrix maps image-pixel coordinates → viewport coordinates directly;
/// inverting it maps the viewport's corners back into image pixels.
///
/// Returns null when the visible region is degenerate (barely any image in
/// frame) — the caller then sends the whole image rather than a sliver.
PixelRect? cropRectFromTransform({
  required Matrix4 transform,
  required Size viewport,
  required Size imageSize,
}) {
  final inverse = Matrix4.inverted(transform);
  final inImageSpace =
      MatrixUtils.transformRect(inverse, Offset.zero & viewport);
  final clamped = inImageSpace.intersect(Offset.zero & imageSize);

  if (clamped.width < _minCropSide || clamped.height < _minCropSide) {
    return null;
  }
  return PixelRect(
    left: clamped.left.round(),
    top: clamped.top.round(),
    width: clamped.width.round(),
    height: clamped.height.round(),
  );
}

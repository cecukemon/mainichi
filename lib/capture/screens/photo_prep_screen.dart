/// Frame-and-confirm step of the live import (D57): the user pans/zooms the
/// auto-oriented, downscaled photo under a fixed frame, and what's visible in
/// the frame is what gets sent to the extractor. Always shown after picking so
/// the sent bytes are never a surprise (and orientation can be eyeballed).
///
/// Deliberately dumb: takes a [NormalizedImage], returns the cropped JPEG via
/// `Navigator.pop` (or null on cancel). No extraction, saving, or providers —
/// the import screen owns that, and its error handling stays put.
library;

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';

import '../image_prep.dart';

class PhotoPrepScreen extends StatefulWidget {
  const PhotoPrepScreen(
      {super.key, required this.image, this.controller, this.cropper});

  final NormalizedImage image;

  /// Injectable for tests (mirrors `PhotoImportScreen`'s injected picker) so a
  /// test can set a known transform and assert the resulting crop.
  final TransformationController? controller;

  /// How the crop is executed. Defaults to a background isolate via
  /// `compute` (the encode can jank the UI thread); tests inject a direct
  /// call because isolate messaging deadlocks under the fake test clock (same
  /// reason the listening layer fakes its file IO, D51).
  final Future<Uint8List> Function(CropRequest)? cropper;

  @override
  State<PhotoPrepScreen> createState() => _PhotoPrepScreenState();
}

class _PhotoPrepScreenState extends State<PhotoPrepScreen> {
  late final TransformationController _controller =
      widget.controller ?? TransformationController();
  bool _initialized = false;
  bool _cropping = false;

  /// The frame's pixel size, captured from the image area's LayoutBuilder so
  /// the Send handler (in a sibling subtree) can compute the crop against it.
  Size _viewport = Size.zero;

  @override
  void dispose() {
    // Only dispose a controller we created; an injected one is the caller's.
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  /// Center the image in the viewport at fit-scale, so the user starts seeing
  /// the whole photo. Runs once, when the real viewport size is known — and
  /// never clobbers a controller a test injected on purpose.
  void _initTransform(Size viewport) {
    if (_initialized || widget.controller != null) return;
    _initialized = true;
    final imgSize = widget.image.size;
    final fit = _fitScale(viewport);
    final dx = (viewport.width - imgSize.width * fit) / 2;
    final dy = (viewport.height - imgSize.height * fit) / 2;
    _controller.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(fit, fit, 1, 1);
  }

  double _fitScale(Size viewport) {
    final imgSize = widget.image.size;
    final byWidth = viewport.width / imgSize.width;
    final byHeight = viewport.height / imgSize.height;
    return byWidth < byHeight ? byWidth : byHeight;
  }

  Future<void> _send() async {
    setState(() => _cropping = true);
    final rect = cropRectFromTransform(
      transform: _controller.value,
      viewport: _viewport,
      imageSize: widget.image.size,
    );
    // Degenerate framing (image panned out of frame) → send the whole image.
    final full = PixelRect(
        left: 0, top: 0, width: widget.image.width, height: widget.image.height);
    final crop = widget.cropper ?? (r) => compute(cropAndEncode, r);
    final bytes = await crop(CropRequest(widget.image.jpegBytes, rect ?? full));
    if (!mounted) return;
    Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final imgSize = widget.image.size;
    return Scaffold(
      appBar: AppBar(title: const Text('Frame the worksheet')),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _viewport = Size(constraints.maxWidth, constraints.maxHeight);
                _initTransform(_viewport);
                final fit = _fitScale(_viewport);
                final minScale = fit > 0 ? fit : 0.01;
                // Always allow zooming in past fit; for a small image whose
                // fit-scale already exceeds 6× (e.g. tiny test images), keep
                // max ≥ min so InteractiveViewer's invariant holds.
                final maxScale = minScale > 6 ? minScale : 6.0;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).dividerColor, width: 1),
                  ),
                  child: ClipRect(
                    child: InteractiveViewer(
                      transformationController: _controller,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      minScale: minScale,
                      maxScale: maxScale,
                      child: SizedBox(
                        width: imgSize.width,
                        height: imgSize.height,
                        child: Image.memory(widget.image.jpegBytes,
                            fit: BoxFit.fill),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pinch and drag so only the worksheet fills the frame.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _cropping ? null : _send,
                  icon: _cropping
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: const Text('Send to extractor'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

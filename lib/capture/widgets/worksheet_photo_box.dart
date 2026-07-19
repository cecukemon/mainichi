/// Worksheet photo box (triage's full sheet, the vocab card's source crop,
/// the picture-word card's drawing): shows the current import's real photo
/// when the draft has one (`CaptureDraft.sourceImage`, set on a live import),
/// with a zoomable full-screen preview.
///
/// When the caller passes a [region] (the extractor's per-item crop box, D58)
/// the box shows just that snippet of the photo — a real crop, no longer only
/// a framing promise. Without a region it shows the whole photo. The demo
/// fixture has no photo at all; it (and a stale/unreadable path) falls back to
/// the old labeled placeholder box. The zoom preview always shows the whole
/// photo (surrounding context is its point; regions are best-effort).
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capture_providers.dart';
import '../models.dart';

class WorksheetPhotoBox extends ConsumerWidget {
  const WorksheetPhotoBox(
      {super.key, required this.label, this.height = 112, this.region});

  final String label;
  final double height;

  /// The item's location on the photo (D58); when set, the box crops to it.
  final CropRegion? region;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(
      captureQueueProvider.select((s) => s.draft?.sourceImage),
    );
    final file = path == null ? null : File(path);
    final photo = (file != null && file.existsSync()) ? file : null;

    return Stack(
      children: [
        if (photo != null && region != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _RegionImage(
              file: photo,
              region: region!,
              height: height,
              placeholder: _Placeholder(label: label, height: height),
            ),
          )
        else if (photo != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              photo,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, _, _) => _Placeholder(label: label, height: height),
            ),
          )
        else
          _Placeholder(label: label, height: height),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _showZoom(context, photo),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.zoom_in, size: 18, color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showZoom(BuildContext context, File? photo) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: photo != null
            ? InteractiveViewer(
                maxScale: 6,
                child: Image.file(photo, fit: BoxFit.contain),
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: _Placeholder(label: label, height: 320),
              ),
      ),
    );
  }
}

/// Renders just [region] of [file], cover-fit into a full-width box of
/// [height]. Resolves the file to a `ui.Image` and paints a single
/// `drawImageRect` (source = the region in image pixels) — cropping in source
/// space, not layout space, so it composes correctly regardless of the box's
/// aspect ratio. Shows [placeholder] while the image resolves or if it fails.
class _RegionImage extends StatefulWidget {
  const _RegionImage({
    required this.file,
    required this.region,
    required this.height,
    required this.placeholder,
  });

  final File file;
  final CropRegion region;
  final double height;
  final Widget placeholder;

  @override
  State<_RegionImage> createState() => _RegionImageState();
}

class _RegionImageState extends State<_RegionImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_RegionImage old) {
    super.didUpdateWidget(old);
    if (old.file.path != widget.file.path) _resolve();
  }

  void _resolve() {
    final stream = FileImage(widget.file).resolve(ImageConfiguration.empty);
    if (stream.key == _stream?.key) return;
    _detach();
    _stream = stream;
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() {
          _image = info.image;
          _failed = false;
        });
      },
      onError: (_, _) {
        if (!mounted) return;
        setState(() => _failed = true);
      },
    );
    stream.addListener(_listener!);
  }

  void _detach() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.placeholder;
    final image = _image;
    if (image == null) return widget.placeholder;
    return SizedBox(
      key: const Key('region-crop'),
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(
        painter: _RegionPainter(image, widget.region),
      ),
    );
  }
}

class _RegionPainter extends CustomPainter {
  _RegionPainter(this.image, this.region);

  final ui.Image image;
  final CropRegion region;

  @override
  void paint(Canvas canvas, Size size) {
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    // The region in source pixels.
    final srcRegion = Rect.fromLTRB(
      region.left * iw,
      region.top * ih,
      region.right * iw,
      region.bottom * ih,
    );
    // Cover-fit: scale so the region fills the box, then center-crop the
    // overflow by shrinking the source rect to the box's aspect ratio.
    final scale = (size.width / srcRegion.width)
        .clamp(size.height / srcRegion.height, double.infinity);
    final visibleW = size.width / scale;
    final visibleH = size.height / scale;
    final src = Rect.fromCenter(
      center: srcRegion.center,
      width: visibleW.clamp(0.0, srcRegion.width),
      height: visibleH.clamp(0.0, srcRegion.height),
    );
    canvas.drawImageRect(
      image,
      src,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_RegionPainter old) =>
      old.image != image || old.region != region;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label, required this.height});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}

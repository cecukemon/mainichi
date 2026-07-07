/// Worksheet photo box (triage's full sheet, the vocab card's source crop,
/// the picture-word card's drawing): shows the current import's real photo
/// when the draft has one (`CaptureDraft.sourceImage`, set on a live import),
/// with a zoomable full-screen preview.
///
/// The extractor doesn't return per-item crop regions yet (capture-loop.md
/// §4), so every box shows the whole photo — the review cards' "crop" is a
/// framing promise, not yet a real crop. The demo fixture has no photo at
/// all; it (and a stale/unreadable path) falls back to the old labeled
/// placeholder box.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capture_providers.dart';

class WorksheetPhotoBox extends ConsumerWidget {
  const WorksheetPhotoBox({super.key, required this.label, this.height = 112});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(
      captureQueueProvider.select((s) => s.draft?.sourceImage),
    );
    final file = path == null ? null : File(path);
    final photo = (file != null && file.existsSync()) ? file : null;

    return Stack(
      children: [
        if (photo != null)
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

/// Shared placeholder for worksheet photo/crop images (triage's full sheet,
/// the vocab card's source crop, the picture-word card's drawing). The
/// extractor doesn't return crop regions yet (capture-loop.md §4), so this
/// stays decorative — a diagonal-stripe box with a zoom affordance that
/// previews a larger placeholder, standing in for a real photo/crop.
library;

import 'package:flutter/material.dart';

class WorksheetCropPlaceholder extends StatelessWidget {
  const WorksheetCropPlaceholder({super.key, required this.label, this.height = 112});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _showZoom(context),
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

  void _showZoom(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: WorksheetCropPlaceholder(label: label, height: 320),
        ),
      ),
    );
  }
}

/// Entry point for a live worksheet import: pick a photo, prepare it (bake
/// orientation, downscale, and let the user crop — D57), then send it to the
/// extractor and land on the same triage/review screens the fixture demo flow
/// uses (project-status.md "live extractor call from the app").
///
/// The prepared JPEG — exactly the bytes sent to the extractor — is persisted
/// under the app documents directory and recorded as the import's
/// `sourceImage`, so it survives the picker's temp-dir cleanup and so the
/// extractor's per-item crop regions (D58) index into an image that still
/// exists on disk.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../config/model_config.dart';
import '../../extraction/extraction_client.dart';
import '../../extraction/extraction_providers.dart';
import '../../extraction/worksheet_extractor.dart';
import '../capture_providers.dart';
import '../draft_from_extraction.dart';
import '../image_prep.dart';
import 'photo_prep_screen.dart';
import 'triage_screen.dart';

enum _Status { pickingSource, loading, error }

class PhotoImportScreen extends ConsumerStatefulWidget {
  PhotoImportScreen({
    super.key,
    ImagePicker? picker,
    this.imageNormalizer,
    this.cropper,
    this.documentsDirectory,
  }) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Injectable seams for tests (isolate `compute` and platform-channel
  /// path_provider both misbehave under the fake test clock — same reason the
  /// listening layer fakes its IO, D51). Production defaults use the real
  /// implementations.
  final Future<NormalizedImage> Function(Uint8List)? imageNormalizer;
  final Future<Uint8List> Function(CropRequest)? cropper;
  final Future<Directory> Function()? documentsDirectory;

  @override
  ConsumerState<PhotoImportScreen> createState() => _PhotoImportScreenState();
}

class _PhotoImportScreenState extends ConsumerState<PhotoImportScreen> {
  var _status = _Status.pickingSource;
  String? _error;
  String _loadingLabel = 'Extracting worksheet…';

  Future<NormalizedImage> _normalize(Uint8List bytes) =>
      (widget.imageNormalizer ?? (b) => compute(normalizeImage, b))(bytes);

  Future<void> _pickAndExtract(ImageSource source) async {
    final XFile? picked;
    try {
      picked = await widget._picker.pickImage(source: source, maxWidth: 2000, imageQuality: 90);
    } on Object catch (e) {
      _setError('Could not open camera/photos: $e');
      return;
    }
    if (picked == null) return; // user cancelled — stay on the source picker

    setState(() {
      _status = _Status.loading;
      _loadingLabel = 'Preparing photo…';
      _error = null;
    });

    // Prepare: bake orientation + downscale, off the UI thread.
    final NormalizedImage normalized;
    try {
      normalized = await _normalize(await picked.readAsBytes());
    } on ImageDecodeFailed {
      _setError("That image couldn't be read. Try another photo.");
      return;
    } on Object catch (e) {
      _setError('Could not prepare the photo: $e');
      return;
    }

    // Frame: the user crops under a fixed frame; back-out returns to source.
    if (!mounted) return;
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) =>
            PhotoPrepScreen(image: normalized, cropper: widget.cropper),
      ),
    );
    if (cropped == null) {
      if (mounted) setState(() => _status = _Status.pickingSource);
      return;
    }

    setState(() {
      _status = _Status.loading;
      _loadingLabel = 'Extracting worksheet…';
    });

    try {
      final savedPath = await _saveWorksheet(cropped);
      final json = await ref.read(extractionServiceProvider).extract(
            imageBytes: cropped,
            mediaType: 'image/jpeg',
          );
      final draft = draftFromExtraction(
        json,
        sourceImage: savedPath,
        model: ModelConfig.extraction,
      );
      await ref.read(captureQueueProvider.notifier).loadFromExtraction(draft);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TriageScreen()),
      );
    } on ApiKeyMissing {
      _setError('No API key set yet — add one in Settings first.');
    } on ExtractionRefused catch (e) {
      _setError('The model declined this image: ${e.details}');
    } on ExtractionTruncated {
      _setError('That worksheet was too long to read in one pass. '
          'Try a photo of just part of it, or a less dense page.');
    } on Object catch (e) {
      _setError('Extraction failed: $e');
    }
  }

  /// Persists the prepared JPEG under `<documents>/worksheets/` and returns
  /// its path — the import's `sourceImage`. Synchronous writes: it's a
  /// one-shot on a user tap (a single ~1MB JPEG), and async file IO deadlocks
  /// under the widget-test fake clock (D51's lesson).
  Future<String> _saveWorksheet(Uint8List bytes) async {
    final docs = await (widget.documentsDirectory ??
        getApplicationDocumentsDirectory)();
    final dir = Directory(p.join(docs.path, 'worksheets'))
      ..createSync(recursive: true);
    final file = File(
        p.join(dir.path, 'import_${DateTime.now().millisecondsSinceEpoch}.jpg'))
      ..writeAsBytesSync(bytes);
    return file.path;
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _status = _Status.error;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New import from photo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _status == _Status.loading
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_loadingLabel),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null) ...[
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 20),
                    ],
                    FilledButton.icon(
                      onPressed: () => _pickAndExtract(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take photo'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _pickAndExtract(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose from library'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

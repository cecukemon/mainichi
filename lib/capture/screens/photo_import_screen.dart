/// Entry point for a live worksheet import: pick a photo, send it to the
/// extractor, then land on the same triage/review screens the fixture demo
/// flow uses (project-status.md "live extractor call from the app").
///
/// In-app resize/auto-orient before send is a separate, not-yet-built item
/// (project-status.md §1) — this screen sends the picked photo as-is, aside
/// from `image_picker`'s own `maxWidth` downscale.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/model_config.dart';
import '../../extraction/extraction_client.dart';
import '../../extraction/extraction_providers.dart';
import '../../extraction/worksheet_extractor.dart';
import '../capture_providers.dart';
import '../draft_from_extraction.dart';
import 'triage_screen.dart';

enum _Status { pickingSource, loading, error }

class PhotoImportScreen extends ConsumerStatefulWidget {
  PhotoImportScreen({super.key, ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  ConsumerState<PhotoImportScreen> createState() => _PhotoImportScreenState();
}

class _PhotoImportScreenState extends ConsumerState<PhotoImportScreen> {
  var _status = _Status.pickingSource;
  String? _error;

  Future<void> _pickAndExtract(ImageSource source) async {
    final XFile? picked;
    try {
      picked = await widget._picker.pickImage(source: source, maxWidth: 2000, imageQuality: 90);
    } on Object catch (e) {
      setState(() {
        _status = _Status.error;
        _error = 'Could not open camera/photos: $e';
      });
      return;
    }
    if (picked == null) return; // user cancelled — stay on the source picker

    setState(() {
      _status = _Status.loading;
      _error = null;
    });

    try {
      final bytes = await picked.readAsBytes();
      final json = await ref.read(extractionServiceProvider).extract(
            imageBytes: bytes,
            mediaType: mediaTypeForPath(picked.path),
          );
      final draft = draftFromExtraction(
        json,
        sourceImage: picked.path,
        model: ModelConfig.extraction,
      );
      await ref.read(captureQueueProvider.notifier).loadFromExtraction(draft);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TriageScreen()),
      );
    } on ApiKeyMissing {
      setState(() {
        _status = _Status.error;
        _error = 'No API key set yet — add one in Settings first.';
      });
    } on ExtractionRefused catch (e) {
      setState(() {
        _status = _Status.error;
        _error = 'The model declined this image: ${e.details}';
      });
    } on Object catch (e) {
      setState(() {
        _status = _Status.error;
        _error = 'Extraction failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New import from photo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _status == _Status.loading
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Extracting worksheet…'),
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

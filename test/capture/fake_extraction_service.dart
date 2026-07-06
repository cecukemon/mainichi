import 'package:mainichi/extraction/extraction_client.dart';

/// In-memory [ExtractionService] for tests — the real one hits
/// api.anthropic.com, which automated tests never do (costs real money,
/// needs a real key).
class FakeExtractionService implements ExtractionService {
  FakeExtractionService.returning(Map<String, dynamic> json) : _result = json;
  FakeExtractionService.throwing(Object error)
      : _result = null,
        _error = error;

  final Map<String, dynamic>? _result;
  Object? _error;

  /// The bytes/mediaType from the most recent call, so tests can assert the
  /// picked photo actually reached the service.
  List<int>? lastImageBytes;
  String? lastMediaType;

  @override
  Future<Map<String, dynamic>> extract({
    required List<int> imageBytes,
    required String mediaType,
  }) async {
    lastImageBytes = imageBytes;
    lastMediaType = mediaType;
    if (_error != null) throw _error!;
    return _result!;
  }
}

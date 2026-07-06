import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A minimal [HttpClientAdapter] fake so `LiveExtractionService` can be
/// tested against a canned response without a real network call — this app
/// never hits the real Anthropic API from automated tests (it costs real
/// money and needs a real key).
class FakeDioAdapter implements HttpClientAdapter {
  FakeDioAdapter({required this.statusCode, required Map<String, dynamic> body})
      : _body = jsonEncode(body);

  final int statusCode;
  final String _body;

  /// The most recent request this adapter saw, so tests can assert on
  /// headers/body without a real transport in the way.
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      _body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

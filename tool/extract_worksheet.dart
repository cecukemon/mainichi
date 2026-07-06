/// Prototype CLI for the worksheet extraction step (spec §3 / §10.2).
///
/// Sends one or more worksheet photos to Claude and prints the structured
/// review draft. This is the throwaway transport around the real module in
/// `lib/extraction/worksheet_extractor.dart`; the app will swap `dart:io`'s
/// HttpClient for `dio` but keep the module.
///
/// Usage:
///   export ANTHROPIC_API_KEY=sk-ant-...
///   dart run tool/extract_worksheet.dart path/to/worksheet.jpg [more.jpg ...]
///
/// Pre-resize photos to ~2000px on the long edge first (the app will do this
/// in-process); on macOS: `sips -Z 2000 in.JPG --out out.jpg`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:mainichi/extraction/worksheet_extractor.dart';

const String _endpoint = 'https://api.anthropic.com/v1/messages';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/extract_worksheet.dart <image.jpg> [more.jpg ...]',
    );
    exitCode = 64; // EX_USAGE
    return;
  }

  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln(
      'ANTHROPIC_API_KEY is not set. export it, then re-run.',
    );
    exitCode = 78; // EX_CONFIG
    return;
  }

  final client = HttpClient();
  try {
    for (final path in args) {
      final file = File(path);
      if (!file.existsSync()) {
        stderr.writeln('skip (not found): $path');
        continue;
      }
      stdout.writeln('\n=== $path ===');
      try {
        final draft = await _extract(client, file, apiKey);
        stdout.writeln(const JsonEncoder.withIndent('  ').convert(draft));
      } on Object catch (e) {
        stderr.writeln('  extraction failed: $e');
      }
    }
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> _extract(
  HttpClient client,
  File image,
  String apiKey,
) async {
  final bytes = await image.readAsBytes();
  final body = buildExtractionRequest(
    base64Image: base64Encode(bytes),
    mediaType: mediaTypeForPath(image.path),
  );

  final req = await client.postUrl(Uri.parse(_endpoint));
  req.headers
    ..set('content-type', 'application/json')
    ..set('x-api-key', apiKey)
    ..set('anthropic-version', '2023-06-01');
  req.add(utf8.encode(jsonEncode(body)));

  final resp = await req.close();
  final text = await resp.transform(utf8.decoder).join();
  if (resp.statusCode != 200) {
    throw 'HTTP ${resp.statusCode}: $text';
  }
  return parseExtractionResponse(jsonDecode(text) as Map<String, dynamic>);
}

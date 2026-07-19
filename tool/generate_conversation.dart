/// Prototype CLI for the generation engine (spec §2 / §10.3).
///
/// Generates a constrained Q/A conversation from a seed vocab+structure set,
/// prints it with store-rendered furigana, and reports any scope violations.
/// Throwaway transport around `lib/generation/conversation_generator.dart`.
///
/// Usage:
///   ANTHROPIC_API_KEY=$(cat ~/.config/anthropic/key) \
///     dart run tool/generate_conversation.dart [seed.json] [lineCount] [model] [focus]
///
/// Defaults: tool/seed_demo.json, 6 lines, ModelConfig.generation, no focus.
/// [focus] is an optional steer, e.g. "eating and drinking" — useful to exercise
/// specific vocabulary/structures during validation rather than whatever the
/// model reaches for by default.
library;

import 'dart:convert';
import 'dart:io';

import 'package:mainichi/config/model_config.dart';
import 'package:mainichi/generation/conversation_generator.dart';

const String _endpoint = 'https://api.anthropic.com/v1/messages';

Future<void> main(List<String> args) async {
  final seedPath = args.isNotEmpty ? args[0] : 'tool/seed_demo.json';
  final lineCount = args.length > 1 ? int.parse(args[1]) : 6;
  final model = args.length > 2 ? args[2] : ModelConfig.generation;
  final focus = args.length > 3 ? args[3] : null;

  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('ANTHROPIC_API_KEY is not set. export it, then re-run.');
    exitCode = 78;
    return;
  }

  final seedFile = File(seedPath);
  if (!seedFile.existsSync()) {
    stderr.writeln('seed not found: $seedPath');
    exitCode = 66;
    return;
  }
  final seed = GenerationSeed.fromJson(
    jsonDecode(await seedFile.readAsString()) as Map<String, dynamic>,
  );

  stdout.writeln('model: $model   lines: $lineCount   '
      'vocab: ${seed.vocab.length}   structures: ${seed.structures.length}\n');

  final client = HttpClient();
  try {
    final response =
        await _generate(client, seed, lineCount, model, apiKey, focus);
    if (Platform.environment['DEBUG_RAW'] == '1') {
      stderr.writeln(const JsonEncoder.withIndent('  ').convert(response));
    }
    final convo = parseGenerationResponse(response);

    if (convo.topic.isNotEmpty) stdout.writeln('topic: ${convo.topic}\n');
    stdout.writeln(renderConversation(convo, seed));

    final report = validateScope(convo, seed);
    if (report.ok) {
      stdout.writeln('scope: OK (all in vocabulary/structures)');
    } else {
      stdout.writeln('scope: ${report.violations.length} VIOLATION(S):');
      for (final v in report.violations) {
        stdout.writeln('  - $v');
      }
    }

    final usage = response['usage'] as Map<String, dynamic>?;
    if (usage != null) {
      stdout.writeln('\nusage: in=${usage['input_tokens']} '
          'out=${usage['output_tokens']} '
          'cache_write=${usage['cache_creation_input_tokens']} '
          'cache_read=${usage['cache_read_input_tokens']}');
    }
  } on Object catch (e) {
    stderr.writeln('generation failed: $e');
    exitCode = 1;
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> _generate(
  HttpClient client,
  GenerationSeed seed,
  int lineCount,
  String model,
  String apiKey,
  String? focus,
) async {
  final body = buildGenerationRequest(
    seed: seed,
    lineCount: lineCount,
    model: model,
    focus: focus,
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
  return jsonDecode(text) as Map<String, dynamic>;
}

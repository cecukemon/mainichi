/// Initial contents of the GrammarGlue table — the hand-curated allowlist the
/// table was promoted from (decision D56). Applied by `AppDatabase` on create
/// and on the v1→v2 upgrade, idempotently (`insertOrIgnore` on the unique
/// surface).
///
/// Lives in data/ so the generation layer never imports the data layer; a pin
/// test keeps this list in sync with `seedGrammarGlue`
/// (`conversation_generator.dart`), which remains the const default for seeds
/// built without a database.
library;

import 'enums.dart';

const List<(String, GlueKind)> grammarGlueSeedRows = [
  ('は', GlueKind.particle),
  ('を', GlueKind.particle),
  ('に', GlueKind.particle),
  ('か', GlueKind.particle),
  ('も', GlueKind.particle),
  ('の', GlueKind.particle),
  ('と', GlueKind.particle),
  ('へ', GlueKind.particle),
  ('や', GlueKind.particle),
  ('です', GlueKind.copula),
  ('では', GlueKind.copula),
  ('ありません', GlueKind.copula),
  ('はい', GlueKind.interjection),
  ('いいえ', GlueKind.interjection),
  ('この', GlueKind.adnominal),
];

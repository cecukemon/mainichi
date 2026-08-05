/// Display labels for [WordRole] and [GlueKind], used as tab-filter chip
/// labels and detail-sheet role chips on the Bunko browser
/// (features/bunko-browser.md). Presentation only — capture's review cards
/// still show the raw wire strings (`lib/capture/widgets/vocab_review_card.dart`
/// etc.); this is the first place the app puts human wording on these enums.
library;

import '../data/enums.dart';

const Map<WordRole, String> _roleLabels = {
  WordRole.noun: 'Noun',
  WordRole.verb: 'Verb',
  WordRole.iAdjective: 'i-adjective',
  WordRole.naAdjective: 'na-adjective',
  WordRole.pronoun: 'Pronoun',
  WordRole.demonstrative: 'Demonstrative',
  WordRole.particle: 'Particle',
  WordRole.questionWord: 'Question word',
  WordRole.suffix: 'Suffix',
  WordRole.number: 'Number',
  WordRole.name: 'Name',
  WordRole.other: 'Other',
};

const Map<GlueKind, String> _glueKindLabels = {
  GlueKind.particle: 'Particle',
  GlueKind.copula: 'Copula',
  GlueKind.interjection: 'Interjection',
  GlueKind.adnominal: 'Adnominal',
  GlueKind.other: 'Other',
};

String roleLabel(WordRole role) => _roleLabels[role]!;

String glueKindLabel(GlueKind kind) => _glueKindLabels[kind]!;

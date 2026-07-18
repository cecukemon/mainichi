/// Central place for which Anthropic model each API-calling feature uses.
///
/// Kept deliberately separate per feature: worksheet extraction and
/// conversation generation sit at opposite ends of the accuracy/latency/cost
/// trade-off (spec §10.4 / decision D3), so they are tuned independently and
/// must never collapse into a single shared id.
///
/// Model ids rotate; verify against https://docs.claude.com before shipping.
library;

class ModelConfig {
  ModelConfig._();

  /// Vision worksheet extraction — most capable model, since accuracy matters
  /// and volume is low (spec §10.4).
  static const String extraction = 'claude-opus-4-8';

  /// Conversation generation — fast mid-tier model for frequent,
  /// latency-sensitive generation (decision D3). Validate quality on
  /// [extraction]'s ceiling model first, then confirm this holds.
  static const String generation = 'claude-sonnet-5';
}

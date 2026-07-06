/// Riverpod wiring for live extraction.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_providers.dart';
import 'extraction_client.dart';

/// Derives from [apiKeyStoreProvider] (already overridden at the app root
/// with the real Keychain store) rather than needing its own override —
/// tests override this provider directly with a fake [ExtractionService].
final extractionServiceProvider = Provider<ExtractionService>((ref) {
  final store = ref.watch(apiKeyStoreProvider);
  return LiveExtractionService(apiKeyProvider: store.read);
});

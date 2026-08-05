/// Riverpod wiring for the Bunko browser (features/bunko-browser.md): a
/// read-only, tabbed view of every word, sentence structure, and grammar-glue
/// entry in the store.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../capture/capture_providers.dart' show databaseProvider;
import '../data/bunko_store.dart';
import '../data/enums.dart';

final bunkoStoreProvider = Provider<BunkoStore>(
  (ref) => DriftBunkoStore(ref.watch(databaseProvider)),
);

@immutable
class BunkoState {
  const BunkoState({
    required this.words,
    required this.structures,
    required this.glue,
    this.roleFilter,
    this.loading = false,
    this.error = false,
  });
  const BunkoState.loading()
      : words = const [],
        structures = const [],
        glue = const [],
        roleFilter = null,
        loading = true,
        error = false;

  final List<BunkoWordRow> words;
  final List<BunkoStructureRow> structures;
  final List<BunkoGlueRow> glue;

  /// null means "All".
  final WordRole? roleFilter;
  final bool loading;
  final bool error;

  List<BunkoWordRow> get filteredWords => roleFilter == null
      ? words
      : [for (final w in words) if (w.role == roleFilter) w];

  /// Word count per role, for chip labels ("Noun (12)"). Only roles present
  /// in the Bunko appear.
  Map<WordRole, int> get roleCounts {
    final counts = <WordRole, int>{};
    for (final w in words) {
      counts[w.role] = (counts[w.role] ?? 0) + 1;
    }
    return counts;
  }

  BunkoState copyWith({
    List<BunkoWordRow>? words,
    List<BunkoStructureRow>? structures,
    List<BunkoGlueRow>? glue,
    WordRole? roleFilter,
    bool clearRoleFilter = false,
    bool? loading,
    bool? error,
  }) {
    return BunkoState(
      words: words ?? this.words,
      structures: structures ?? this.structures,
      glue: glue ?? this.glue,
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

class BunkoNotifier extends StateNotifier<BunkoState> {
  BunkoNotifier(this._store) : super(const BunkoState.loading());

  final BunkoStore _store;

  Future<void> load() async {
    state = const BunkoState.loading();
    try {
      final results = await Future.wait([
        _store.listWords(),
        _store.listStructures(),
        _store.listGlue(),
      ]);
      state = BunkoState(
        words: results[0] as List<BunkoWordRow>,
        structures: results[1] as List<BunkoStructureRow>,
        glue: results[2] as List<BunkoGlueRow>,
      );
    } catch (_) {
      state = const BunkoState(words: [], structures: [], glue: [], error: true);
    }
  }

  /// null selects "All".
  void setRoleFilter(WordRole? role) {
    if (role == null) {
      state = state.copyWith(clearRoleFilter: true);
    } else {
      state = state.copyWith(roleFilter: role);
    }
  }
}

/// autoDispose + `..load()`: the browser reloads fresh every time it's
/// opened, so it reflects captures added since the last visit.
final bunkoProvider = StateNotifierProvider.autoDispose<BunkoNotifier, BunkoState>(
  (ref) => BunkoNotifier(ref.watch(bunkoStoreProvider))..load(),
);

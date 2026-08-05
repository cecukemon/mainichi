import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/bunko/role_label.dart';
import 'package:mainichi/data/enums.dart';

void main() {
  test('every WordRole has a non-empty label', () {
    for (final role in WordRole.values) {
      expect(roleLabel(role), isNotEmpty, reason: 'missing label for $role');
    }
  });

  test('every GlueKind has a non-empty label', () {
    for (final kind in GlueKind.values) {
      expect(glueKindLabel(kind), isNotEmpty, reason: 'missing label for $kind');
    }
  });

  test('i-adjective and na-adjective are spelled out', () {
    expect(roleLabel(WordRole.iAdjective), 'i-adjective');
    expect(roleLabel(WordRole.naAdjective), 'na-adjective');
  });
}

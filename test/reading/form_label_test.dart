import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/reading/form_label.dart';

void main() {
  test('maps wire forms to the mockup wording', () {
    expect(formAnnotation('polite'), 'polite');
    expect(formAnnotation('polite_negative'), 'negative, polite');
    expect(formAnnotation('past'), 'past, polite');
    expect(formAnnotation('negative'), 'negative');
  });

  test('null and unknown forms produce no annotation, never a wire value', () {
    expect(formAnnotation(null), isNull);
    expect(formAnnotation('te'), isNull);
  });
}

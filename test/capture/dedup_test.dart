import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/capture/dedup.dart';
import 'package:mainichi/capture/models.dart';
import 'package:mainichi/data/database.dart';
import 'package:mainichi/data/enums.dart';

VocabDraftItem _vocab({
  required String kana,
  String kanji = '',
  WordRole role = WordRole.verb,
}) =>
    VocabDraftItem(
      kana: kana,
      kanji: kanji,
      romaji: '',
      meaning: 'to eat',
      role: role,
      kanaOnly: false,
      meaningSource: MeaningSource.printedGloss,
      confidence: ConfidenceTier.high,
    );

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('no candidate when kana is unseen', () async {
    final match = await findDedupCandidate(db, _vocab(kana: 'たべる', kanji: '食べる'));
    expect(match, isNull);
  });

  test('same kana, exact (kanji, role) match still proposes a merge', () async {
    final id = await db.into(db.words).insert(
          WordsCompanion.insert(kana: 'たべる', kanji: const Value('食べる'), role: WordRole.verb),
        );
    final match = await findDedupCandidate(db, _vocab(kana: 'たべる', kanji: '食べる'));
    expect(match, isNotNull);
    expect(match!.wordId, id);
  });

  test('same kana, different kanji still proposes a candidate (false-match risk)', () async {
    await db.into(db.words).insert(
          WordsCompanion.insert(kana: 'はし', kanji: const Value('橋'), role: WordRole.noun),
        );
    final match = await findDedupCandidate(db, _vocab(kana: 'はし', kanji: '箸', role: WordRole.noun));
    expect(match, isNotNull);
    expect(match!.kanji, '橋');
  });

  test('attachDedupCandidates only annotates matching vocab items', () async {
    await db.into(db.words).insert(
          WordsCompanion.insert(kana: 'たべる', kanji: const Value('食べる'), role: WordRole.verb),
        );
    final draft = CaptureDraft(
      worksheetTitle: '',
      worksheetTopic: '',
      vocabulary: [_vocab(kana: 'たべる', kanji: '食べる'), _vocab(kana: 'のむ', kanji: '飲む')],
      templates: const [],
    );

    final updated = await attachDedupCandidates(db, draft);
    expect(updated.vocabulary[0].existingMatch, isNotNull);
    expect(updated.vocabulary[1].existingMatch, isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/conversation_cache.dart';
import 'package:mainichi/reading/conversation_list.dart';

ConversationSummary _summary({
  required DateTime createdAt,
  DateTime? lastPracticedAt,
}) =>
    ConversationSummary(
      id: 1,
      title: 'Ordering at a restaurant',
      createdAt: createdAt,
      lastPracticedAt: lastPracticedAt,
      lineCount: 6,
    );

void main() {
  final now = DateTime(2026, 7, 19, 9, 41);

  group('practicedPhrase', () {
    test('null reads as not yet practiced', () {
      expect(practicedPhrase(null, now), 'not yet practiced');
    });

    test('same calendar day reads as today, ignoring the clock time', () {
      expect(practicedPhrase(DateTime(2026, 7, 19, 6), now), 'practiced today');
    });

    test('one day back reads as yesterday', () {
      expect(practicedPhrase(DateTime(2026, 7, 18, 23), now),
          'practiced yesterday');
    });

    test('a few days back reads in days', () {
      expect(practicedPhrase(DateTime(2026, 7, 16), now),
          'practiced 3 days ago');
    });

    test('a week-ish reads as one week', () {
      expect(practicedPhrase(DateTime(2026, 7, 12), now),
          'practiced 1 week ago');
    });

    test('two weeks back reads in weeks', () {
      expect(practicedPhrase(DateTime(2026, 7, 5), now),
          'practiced 2 weeks ago');
    });

    test('over a month back reads in months', () {
      // 39 days back → 1 month; 140 days back → 4 months.
      expect(practicedPhrase(DateTime(2026, 6, 10), now),
          'practiced 1 month ago');
      expect(practicedPhrase(DateTime(2026, 3, 1), now),
          'practiced 4 months ago');
    });
  });

  group('conversationMetaLine', () {
    test('joins the created date and the practiced phrase', () {
      final line = conversationMetaLine(
        _summary(
            createdAt: DateTime(2026, 7, 18),
            lastPracticedAt: DateTime(2026, 7, 18, 20)),
        now: now,
      );
      expect(line, 'Jul 18 · practiced yesterday');
    });

    test('a never-practiced conversation still shows its created date', () {
      final line = conversationMetaLine(
        _summary(createdAt: DateTime(2026, 7, 12)),
        now: now,
      );
      expect(line, 'Jul 12 · not yet practiced');
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mainichi/capture/capture_providers.dart';
import 'package:mainichi/data/database.dart';
import 'package:mainichi/main.dart';

void main() {
  testWidgets('home screen launches the capture flow', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MainichiApp(),
      ),
    );

    expect(find.text('New import from photo'), findsOneWidget);
  });
}

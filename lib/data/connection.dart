/// On-device DB connection (spec §0): opens the app's SQLite file in the
/// platform's app-support directory. Tests use `NativeDatabase.memory()`
/// directly instead (see `database.dart`); this file is only exercised by the
/// real app.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _dbFileName = 'mainichi.sqlite';

/// Pure path composition, kept separate from the platform lookup below so it
/// can be unit-tested without mocking a platform channel.
File dbFileIn(Directory supportDir) =>
    File(p.join(supportDir.path, _dbFileName));

/// Lazily resolves the app-support directory and opens the DB file there on
/// a background isolate, so DB I/O doesn't block the UI isolate.
LazyDatabase connectDb() {
  return LazyDatabase(() async {
    final supportDir = await getApplicationSupportDirectory();
    return NativeDatabase.createInBackground(dbFileIn(supportDir));
  });
}

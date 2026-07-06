import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/data/connection.dart';
import 'package:path/path.dart' as p;

void main() {
  test('dbFileIn joins the DB filename onto the given directory', () {
    final dir = Directory(p.join('some', 'support', 'dir'));
    final file = dbFileIn(dir);
    expect(file.path, p.join('some', 'support', 'dir', 'mainichi.sqlite'));
  });
}

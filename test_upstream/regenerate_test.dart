// Needs network and git: regenerates the catalog from the pinned upstream tag
// and checks it matches the committed file.
//
//   flutter test test_upstream
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tool/generate.dart reproduces lib/src/proicons.g.dart', () async {
    final file = File('lib/src/proicons.g.dart');
    final before = file.readAsStringSync();
    final res = await Process.run('dart', ['run', 'tool/generate.dart']);
    final after = file.readAsStringSync();
    file.writeAsStringSync(before); // never leave the working tree changed
    expect(res.exitCode, 0, reason: '${res.stdout}${res.stderr}');
    expect(after, before);
  }, timeout: const Timeout(Duration(minutes: 3)));
}

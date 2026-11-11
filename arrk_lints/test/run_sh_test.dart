// Tests for run.sh's setup step when arrk_core_flutter is a git dependency.
// Its arrk_lints/ then lives in the pub cache, where `dart pub get` refuses
// to run ("Cannot operate on packages inside the cache"). Products reach it
// through tools/link-lints' `.arrk-lints` symlink, so these tests do too.
// The target project has no lib/ files, so run.sh stops right after setup
// and no analysis or plugin load is needed.
@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late Directory project;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('arrk_run_sh_test');
    project = Directory('${tmp.path}/product')..createSync();
    Process.runSync('git', ['init', '-q'], workingDirectory: project.path);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  // Copies run.sh's package into [dir] and links product/.arrk-lints to it.
  void installAt(String dir) {
    final lints = Directory(dir)..createSync(recursive: true);
    for (final f in ['run.sh', 'baseline.py', 'pubspec.yaml']) {
      File(f).copySync('${lints.path}/$f');
    }
    Link('${project.path}/.arrk-lints').createSync(lints.path);
  }

  ProcessResult runGate(String pubCache) => Process.runSync(
        'bash',
        ['.arrk-lints/run.sh'],
        workingDirectory: project.path,
        environment: {'PUB_CACHE': pubCache},
      );

  test('runs from a git dependency checkout in the pub cache', () {
    final cache = '${tmp.path}/pub-cache';
    installAt('$cache/git/arrk_core_flutter-0123abc/arrk_lints');

    final r = runGate(cache);

    expect(r.stderr, isNot(contains('Cannot operate on packages')));
    expect(r.stderr, contains('No Dart files found'));
    expect(r.exitCode, 0);
  });

  test('runs from a read-only checkout', () {
    final dir = '${tmp.path}/readonly/arrk_lints';
    installAt(dir);
    Process.runSync('chmod', ['a-w', dir]);
    addTearDown(() => Process.runSync('chmod', ['u+w', dir]));

    final r = runGate('${tmp.path}/unused-cache');

    expect(r.stderr, contains('No Dart files found'));
    expect(r.exitCode, 0);
  });
}

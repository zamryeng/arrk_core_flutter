// Tests for baseline.py, the gate behind `run.sh`. Feeds it synthetic
// `dart analyze` output, so no project or plugin load is needed.
@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

const _a = '  warning - lib/features/a/domain/use_cases/a_use_case.dart:9:7 - '
    "Capability field '_n' holds state. Fix - it. - capability_stateless";
const _b = '  warning - lib/features/b/ui/b_vm.dart:3:8 - '
    'View model depends on a repository. - vm_uses_capabilities_only';
const _foreign = '   info - lib/x.dart:1:1 - Unused import. - unused_import';

void main() {
  late Directory dir;
  late String baseline;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('arrk_baseline_test');
    baseline = '${dir.path}/arrk_baseline.txt';
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('with no baseline, any violation fails', () {
    final r = _run('check', baseline, [_a, _foreign]);
    expect(r.exitCode, 1);
    expect(r.stdout, contains('NEW violations'));
    expect(r.stdout, contains('capability_stateless'));
  });

  test('a clean run passes and ignores non-arrk diagnostics', () {
    final r = _run('check', baseline, [_foreign]);
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
  });

  test('a violation already in the baseline passes', () {
    expect(_run('update', baseline, [_a]).exitCode, 0);
    final lines = File(baseline).readAsLinesSync().where((l) => !l.startsWith('#'));
    // rule|file|message, no line numbers; " - " inside the message survives.
    expect(lines.single,
        "capability_stateless|lib/features/a/domain/use_cases/a_use_case.dart|"
        "Capability field '_n' holds state. Fix - it.");

    // Same violation on a different line still matches.
    final moved = _a.replaceFirst(':9:7', ':42:7');
    final r = _run('check', baseline, [moved]);
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
  });

  test('a new violation fails even when others are baselined', () {
    _run('update', baseline, [_a]);
    final r = _run('check', baseline, [_a, _b]);
    expect(r.exitCode, 1);
    expect(r.stdout, contains('vm_uses_capabilities_only'));
    expect(r.stdout, isNot(contains('NEW violations (not in the baseline):\n  capability')));
  });

  test('a second copy of a baselined violation is new', () {
    _run('update', baseline, [_a]);
    final r = _run('check', baseline, [_a, _a.replaceFirst(':9:7', ':12:7')]);
    expect(r.exitCode, 1);
  });

  test('a fixed violation is reported and does not fail', () {
    _run('update', baseline, [_a, _b]);
    final r = _run('check', baseline, [_b]);
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
    expect(r.stdout, contains('fixed'));
    expect(r.stdout, contains('run.sh --update'));
    expect(r.stdout, contains('capability_stateless'));
  });

  test('analysis errors fail the run', () {
    final r = _run('check', baseline, [
      "  error - lib/x.dart:1:8 - Target of URI doesn't exist. - uri_does_not_exist",
    ]);
    expect(r.exitCode, 2);
  });

  test('report prints the count for each rule', () {
    final r = _run('report', baseline, [_a, _a, _b]);
    expect(r.exitCode, 0);
    expect(r.stdout, matches(RegExp(r'2\s+capability_stateless')));
    expect(r.stdout, matches(RegExp(r'1\s+vm_uses_capabilities_only')));
    expect(r.stdout, matches(RegExp(r'3\s+total')));
  });

  test('RULES in baseline.py matches every rule the plugin declares', () {
    final registered = Directory('${_root()}/lib/src/rules')
        .listSync()
        .whereType<File>()
        .map((f) => RegExp(r"static const _name = '([a-z_]+)';").firstMatch(f.readAsStringSync()))
        .whereType<RegExpMatch>()
        .map((m) => m.group(1)!)
        .toSet();
    expect(registered, hasLength(18));
    final script = File('${_root()}/baseline.py').readAsStringSync();
    final block = RegExp(r'RULES = \{([^}]*)\}').firstMatch(script)!.group(1)!;
    final listed = RegExp(r"'([a-z_]+)'").allMatches(block).map((m) => m.group(1)!).toSet();
    expect(listed, registered);
  });
}

ProcessResult _run(String mode, String baseline, List<String> analyzeLines) {
  final process = Process.runSync('sh', [
    '-c',
    'printf "%s\\n" "\$1" | python3 "\$2" "\$3" "\$4"',
    'sh',
    analyzeLines.join('\n'),
    '${_root()}/baseline.py',
    mode,
    baseline,
  ]);
  return process;
}

String _root() {
  var dir = Directory.current;
  while (!File('${dir.path}/baseline.py').existsSync()) {
    if (dir.parent.path == dir.path) return Directory.current.path;
    dir = dir.parent;
  }
  return dir.path;
}

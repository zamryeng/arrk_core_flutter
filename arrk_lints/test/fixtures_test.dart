// Golden test suite for the arrk_lints architecture rules.
//
// Strategy (mirrors how CI runs the gate): drive `dart analyze` over the
// fixture files under `test/fixtures/lib/` — which have their own
// `analysis_options.yaml` enabling the plugin — and assert the diagnostics.
//
// Fixtures are self-describing: every line that should raise a diagnostic
// carries a `// expect_lint: <rule>` marker (the count of markers for a rule
// in a file is the expected number of that diagnostic). Files named `*_bad.dart`
// must produce exactly their marked diagnostics; files named `*_ok.dart` must
// produce none of our rules' diagnostics.
//
// Run with: `dart test` (or `fvm dart test`) from the package root.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// The set of rule names owned by this plugin.
const _ourRules = {
  'avoid_data_models_in_domain',
  'event_bus_publisher_restriction',
  'event_naming_past_tense',
  'no_build_context_in_domain_or_data_or_services',
  'no_change_notifier_outside_vm',
  'no_cross_repo_calls',
  'no_event_bus_in_repo',
  'no_event_fire_in_handler',
  'no_manager_in_features',
  'no_repo_interfaces',
  'no_service_locator_in_features',
  'no_singleton_viewmodel',
  'no_try_catch_in_domain',
  'subscription_cancelled_in_dispose',
};

/// `expect_lint: <rule>` (the rest of the line is a human note).
final _expectMarker = RegExp(r'//\s*expect_lint:\s*([a-z_]+)');

/// A `dart analyze` machine-readable-ish line:
///   `  warning - path:line:col - message - rule_name`
final _diagnosticLine = RegExp(r'-\s+(\S+\.dart):(\d+):\d+\s+-\s+.*-\s+([a-z_]+)\s*$');

void main() {
  // Resolve paths relative to the package root regardless of cwd.
  final pkgRoot = _packageRoot();
  final fixturesDir = Directory('${pkgRoot.path}/test/fixtures');

  final fixtureFiles =
      fixturesDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('_stubs.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  // One `dart analyze` run over all fixtures; share the parsed result.
  late final _AnalysisResult analysis;

  setUpAll(() {
    expect(
      fixtureFiles,
      isNotEmpty,
      reason: 'no fixtures found under ${fixturesDir.path}',
    );
    analysis = _runAnalyze(fixtureFiles.map((f) => f.path).toList());
    // Guard against a silent vacuous pass (e.g. the plugin failed to load):
    // the suite is only meaningful if SOME of our diagnostics were produced.
    expect(
      analysis.diagnostics.where((d) => _ourRules.contains(d.rule)),
      isNotEmpty,
      reason:
          'no arrk_lints diagnostics at all — did the plugin load? '
          'Run `dart pub get` in the package root and check '
          'test/fixtures/analysis_options.yaml.',
    );
  });

  group('positive fixtures (*_bad.dart) flag exactly their marked rules', () {
    for (final file in fixtureFiles.where(
      (f) => f.path.endsWith('_bad.dart'),
    )) {
      test(_rel(pkgRoot, file), () {
        final expected = _markersIn(file);
        expect(
          expected,
          isNotEmpty,
          reason:
              '${file.path} is a _bad fixture but has no expect_lint '
              'markers — add them or rename the file.',
        );
        final actual = analysis.byFileRule(file.path);
        for (final entry in expected.entries) {
          expect(
            actual[entry.key] ?? 0,
            entry.value,
            reason: 'rule ${entry.key} in ${file.path}',
          );
        }
      });
    }
  });

  group('negative fixtures (*_ok.dart) raise none of our rules', () {
    for (final file in fixtureFiles.where(
      (f) => f.path.endsWith('_ok.dart'),
    )) {
      test(_rel(pkgRoot, file), () {
        final ours = analysis.forFile(file.path).where((d) => _ourRules.contains(d.rule)).toList();
        expect(
          ours,
          isEmpty,
          reason:
              'unexpected arrk_lints diagnostics in OK fixture: '
              '${ours.map((d) => '${d.rule}@${d.line}').join(', ')}',
        );
      });
    }
  });

  // Targeted regressions.
  group('regressions', () {
    test(
      'subscription: helper-delegated cancel is OK, '
      'unrelated cancel does not satisfy a different field',
      () {
        final okFile = _fixtureEndingWith(
          fixtureFiles,
          'subscription_cancelled_in_dispose_ok.dart',
        );
        final badFile = _fixtureEndingWith(
          fixtureFiles,
          'subscription_cancelled_in_dispose_bad.dart',
        );
        // Helper delegation + this-qualified + direct cancel => no diagnostics.
        expect(
          analysis.forFile(okFile.path).where((d) => d.rule == 'subscription_cancelled_in_dispose'),
          isEmpty,
          reason: 'a cancel reached through a helper must satisfy the field',
        );
        // Uncancelled field AND a field only "cancelled" by an unrelated
        // sibling => both flagged (2).
        expect(
          analysis.byFileRule(badFile.path)['subscription_cancelled_in_dispose'],
          2,
        );
      },
    );

    test(
      'avoid_data_models_in_domain: cross-feature data/models import is '
      'flagged; data<->data within a feature is allowed',
      () {
        final badFile = _fixtureEndingWith(
          fixtureFiles,
          'avoid_data_models_in_domain_bad.dart',
        );
        final dataOkFile = _fixtureEndingWith(
          fixtureFiles,
          'data/avoid_data_models_in_domain_ok.dart',
        );
        expect(
          analysis.byFileRule(badFile.path)['avoid_data_models_in_domain'],
          1,
          reason: 'domain importing another feature data/models must flag',
        );
        expect(
          analysis.forFile(dataOkFile.path).where((d) => d.rule == 'avoid_data_models_in_domain'),
          isEmpty,
          reason: 'a file inside data/ may import its own data internals',
        );
      },
    );

    test(
      'service locator: VM method bodies fire wherever the VM lives; '
      'constructor-fallback injection and route builders stay exempt',
      () {
        final vmBad = _fixtureEndingWith(
          fixtureFiles,
          'ui/no_service_locator_vm_bad.dart',
        );
        expect(
          analysis.byFileRule(vmBad.path)['no_service_locator_in_features'],
          3,
          reason: 'lookups in VM method bodies (incl. transitive VMs) must flag',
        );
        final vmOk = _fixtureEndingWith(
          fixtureFiles,
          'ui/no_service_locator_vm_ok.dart',
        );
        expect(
          analysis.forFile(vmOk.path).where((d) => d.rule == 'no_service_locator_in_features'),
          isEmpty,
          reason: 'constructor-fallback injection and widget model: are exempt',
        );
      },
    );

    test('no_cross_repo_calls: field, ctor param, and body reference all flag', () {
      final badFile = _fixtureEndingWith(fixtureFiles, 'no_cross_repo_calls_bad.dart');
      expect(analysis.byFileRule(badFile.path)['no_cross_repo_calls'], 3);
      final okFile = _fixtureEndingWith(fixtureFiles, 'no_cross_repo_calls_ok.dart');
      expect(
        analysis.forFile(okFile.path).where((d) => d.rule == 'no_cross_repo_calls'),
        isEmpty,
        reason: 'self-references, ArrkRepository, and non-repo coordinators are exempt',
      );
    });
  });
}

/// Expected `rule -> count` markers in [file].
Map<String, int> _markersIn(File file) {
  final counts = <String, int>{};
  for (final line in file.readAsLinesSync()) {
    final m = _expectMarker.firstMatch(line);
    if (m != null) {
      counts.update(m.group(1)!, (v) => v + 1, ifAbsent: () => 1);
    }
  }
  return counts;
}

class _Diagnostic {
  _Diagnostic(this.path, this.line, this.rule);
  final String path;
  final int line;
  final String rule;
}

class _AnalysisResult {
  _AnalysisResult(this.diagnostics);
  final List<_Diagnostic> diagnostics;

  Iterable<_Diagnostic> forFile(String path) {
    final normalized = _normalize(path);
    return diagnostics.where((d) => _normalize(d.path) == normalized);
  }

  /// `rule -> count` for the given file (our rules only).
  Map<String, int> byFileRule(String path) {
    final counts = <String, int>{};
    for (final d in forFile(path)) {
      if (_ourRules.contains(d.rule)) {
        counts.update(d.rule, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return counts;
  }
}

_AnalysisResult _runAnalyze(List<String> files) {
  // Reuse the SDK that is running this test — same Dart that powers the plugin.
  final dart = Platform.resolvedExecutable;
  final result = Process.runSync(dart, ['analyze', ...files]);
  final out = '${result.stdout}\n${result.stderr}';
  final diagnostics = <_Diagnostic>[];
  for (final line in const LineSplitter().convert(out)) {
    final m = _diagnosticLine.firstMatch(line);
    if (m == null) continue;
    diagnostics.add(_Diagnostic(m.group(1)!, int.parse(m.group(2)!), m.group(3)!));
  }
  return _AnalysisResult(diagnostics);
}

/// Finds the fixture whose forward-slash-normalized path ends with [suffix]
/// (separator-safe: `listSync` yields backslashes on Windows).
File _fixtureEndingWith(List<File> files, String suffix) =>
    files.firstWhere((f) => f.path.replaceAll(r'\', '/').endsWith(suffix));

/// Compare paths by their `test/fixtures/...` tail so the relative paths
/// `dart analyze` prints match the absolute fixture paths we discover.
String _normalize(String path) => path.replaceAll(r'\', '/').split('test/fixtures/').last;

String _rel(Directory pkgRoot, File file) => file.path
    .replaceAll(r'\', '/')
    .replaceFirst('${pkgRoot.path.replaceAll(r'\', '/')}/', '');

/// The package root, found by walking up to the pubspec.
Directory _packageRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync() &&
        Directory('${dir.path}/test/fixtures').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      // Fallback: assume cwd is the package root.
      return Directory.current;
    }
    dir = parent;
  }
}

#!/usr/bin/env python3
"""Baseline gate for the arrk_lints architecture rules.

The analyzer plugin system does not honor `// ignore` comments for plugin
lints, so an app that adopts arrk partway through its life can't suppress
its existing violations inline. Instead they are grandfathered in a
committed baseline file, `arrk_baseline.txt`, at the project root.

Format: one line per violation, `rule|file|message`. No line numbers, so the
baseline survives edits that move code around. The same violation appearing
twice in a file is two identical lines.

Modes (reads `dart analyze` output on stdin):

- `check` (default): fail on any violation not in the baseline. Baseline
  lines that no longer match are reported as fixed, with a reminder to
  update the baseline; they do not fail the run.
- `update`: rewrite the baseline from the current violations.
- `report`: print the number of violations for each rule.

Usage: baseline.py [check|update|report] <baseline_path>

Ported from zamry_wallet's tools/lints/baseline.py.
"""
import collections
import sys

# Keep in sync with lib/main.dart (test/baseline_test.dart checks it).
RULES = {
    'avoid_data_models_in_domain',
    'capability_stateless',
    'event_bus_publisher_restriction',
    'event_naming_past_tense',
    'event_subscribe_restriction',
    'message_stream_restriction',
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
    'vm_uses_capabilities_only',
}

HEADER = [
    '# arrk_lints baseline: architecture violations that predate the gate.',
    '# One line per violation: rule|file|message. Regenerate with run.sh --update.',
    '# Drive it to empty as code migrates.',
]

# If the live total drops below this fraction of the baseline, sources most
# likely failed to resolve (missing generated files) and the plugin went
# quiet. Fail instead of passing vacuously.
COLLAPSE_FRACTION = 0.5
# Below this many baselined violations the guard is off: on a small baseline,
# a big relative drop is just someone fixing things.
COLLAPSE_MIN_BASELINE = 10


def parse_line(line):
    """`  warning - lib/x.dart:12:3 - message - rule` -> (rule, file, message).

    The message may itself contain ' - ', so split the location off the
    front and the rule off the back.
    """
    line = line.strip()
    parts = line.split(' - ')
    if len(parts) < 4:
        return None
    rule = parts[-1].strip()
    if rule not in RULES:
        return None
    location = parts[1].strip()
    path = location.rsplit(':', 2)[0]
    if not path.endswith('.dart'):
        return None
    message = ' - '.join(parts[2:-1]).strip()
    return rule, path, message


def is_error(line):
    return line.lstrip().lower().startswith('error - ')


def parse(lines):
    found = collections.Counter()
    for line in lines:
        entry = parse_line(line)
        if entry:
            found[entry] += 1
    return found


def load(path):
    baseline = collections.Counter()
    try:
        with open(path) as fh:
            for raw in fh:
                raw = raw.rstrip('\n')
                if not raw.strip() or raw.startswith('#'):
                    continue
                rule, file, message = raw.split('|', 2)
                baseline[(rule, file, message)] += 1
    except FileNotFoundError:
        pass
    return baseline


def write(path, found):
    lines = list(HEADER)
    for (rule, file, message), count in sorted(found.items()):
        lines.extend([f'{rule}|{file}|{message}'] * count)
    with open(path, 'w') as fh:
        fh.write('\n'.join(lines) + '\n')


def fmt(entry):
    rule, file, message = entry
    return f'{rule}  {file}  {message}'


def main(argv):
    mode = argv[1] if len(argv) > 1 else 'check'
    path = argv[2] if len(argv) > 2 else 'arrk_baseline.txt'
    lines = sys.stdin.readlines()
    found = parse(lines)

    if mode == 'update':
        write(path, found)
        print(f'arrk_lints: baseline written to {path}: '
              f'{sum(found.values())} violations.')
        return 0

    if mode == 'report':
        per_rule = collections.Counter()
        for (rule, _, _), count in found.items():
            per_rule[rule] += count
        for rule in sorted(per_rule):
            print(f'{per_rule[rule]:5d}  {rule}')
        print(f'{sum(per_rule.values()):5d}  total')
        return 0

    if mode != 'check':
        print(f'arrk_lints: unknown mode {mode!r}', file=sys.stderr)
        return 2

    errors = [line.rstrip() for line in lines if is_error(line)]
    if errors:
        print(f'arrk_lints: {len(errors)} analysis error(s). Plugin diagnostics '
              'are unreliable when sources do not resolve (run build_runner?). '
              'Fix these first:', file=sys.stderr)
        for line in errors[:20]:
            print(f'  {line.strip()}', file=sys.stderr)
        return 2

    baseline = load(path)
    baseline_total = sum(baseline.values())
    found_total = sum(found.values())
    if (baseline_total >= COLLAPSE_MIN_BASELINE
            and found_total < baseline_total * COLLAPSE_FRACTION):
        print(f'arrk_lints: SUSPICIOUS: {found_total} violations now vs '
              f'{baseline_total} in the baseline. Generated files are probably '
              'missing. If the drop is real, run run.sh --update.',
              file=sys.stderr)
        return 2

    new = found - baseline
    fixed = baseline - found

    if fixed:
        print('arrk_lints: fixed (in the baseline, no longer found). '
              'Run run.sh --update to drop them:')
        for entry, count in sorted(fixed.items()):
            for _ in range(count):
                print(f'  {fmt(entry)}')
        print()

    if new:
        print('arrk_lints: NEW violations (not in the baseline):')
        for entry, count in sorted(new.items()):
            for _ in range(count):
                print(f'  {fmt(entry)}')
        print()
        print('Fix them. Accept them into the baseline (run.sh --update) only '
              'with reviewer sign-off.')
        return 1

    print(f'arrk_lints: OK. {found_total} known violations, none new.')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))

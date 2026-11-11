#!/usr/bin/env bash
#
# Runs the arrk_lints architecture rules over a target project.
#
# Why this wrapper exists: plugin diagnostics only surface for explicitly-
# listed file arguments; directory-mode analysis (`dart analyze <dir>` and a
# bare `flutter analyze` scanning the project) shows none of them. So we
# enumerate the project's Dart files (tracked + untracked-not-ignored) and
# pass them explicitly to `dart analyze`. (Per-file args work under both
# `dart analyze` and `flutter analyze`; we use `dart analyze` here.)
#
# The output goes through baseline.py: the run fails only on violations
# that are not in the project's arrk_baseline.txt (one `rule|file|message`
# line per violation, no line numbers). With no baseline file, every
# violation fails.
#
# Usage:
#   arrk_lints/run.sh [project_dir]            # gate; defaults to cwd
#   arrk_lints/run.sh --update [project_dir]   # rewrite arrk_baseline.txt
#   arrk_lints/run.sh --report [project_dir]   # violation count per rule
set -euo pipefail

MODE=check
case "${1:-}" in
  --update) MODE=update; shift ;;
  --report) MODE=report; shift ;;
  --*) echo "Unknown option: $1" >&2; exit 2 ;;
esac

LINTS_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${1:-$PWD}"
cd "$TARGET_DIR"

if ! command -v python3 >/dev/null 2>&1; then
  echo "run.sh needs python3 for the baseline gate." >&2
  exit 1
fi

# Resolve the Dart command. Prefer fvm when the project is fvm-managed.
if [ -d .fvm ] && command -v fvm >/dev/null 2>&1; then
  DART=(fvm dart)
elif command -v dart >/dev/null 2>&1; then
  DART=(dart)
else
  echo "Could not find 'dart' (or 'fvm dart'). Install the Dart/Flutter SDK." >&2
  exit 1
fi

# Resolve the plugin package in a local checkout. Skip it when arrk_lints sits
# in the pub cache (arrk_core_flutter as a git or hosted dependency, reached
# through tools/link-lints' .arrk-lints symlink): pub refuses to run there
# ("Cannot operate on packages inside the cache"), and the analysis server
# resolves the plugin on its own, so the step isn't needed.
LINTS_REAL="$(cd "$LINTS_DIR" && pwd -P)"
PUB_CACHE_REAL="$(cd "${PUB_CACHE:-$HOME/.pub-cache}" 2>/dev/null && pwd -P || true)"
if [ -n "$PUB_CACHE_REAL" ] && [ "${LINTS_REAL#"$PUB_CACHE_REAL"/}" != "$LINTS_REAL" ]; then
  : # inside the pub cache: nothing to resolve
elif [ ! -w "$LINTS_REAL" ]; then
  : # read-only checkout: pub get can't write .dart_tool, and isn't needed
else
  ( cd "$LINTS_REAL" && "${DART[@]}" pub get >/dev/null )
fi

# Dart sources under lib/, excluding generated outputs. Includes tracked
# files plus untracked-but-not-ignored ones, so a brand-new file is gated
# even before it's committed (portable: no mapfile -> works on bash 3.2).
files=()
while IFS= read -r f; do
  # A tracked file deleted from the working tree would make `dart analyze`
  # exit with a usage error and analyze nothing — skip it.
  [ -e "$f" ] && files+=("$f")
done < <(
  {
    git ls-files 'lib/**/*.dart' 'lib/*.dart'
    git ls-files --others --exclude-standard 'lib/**/*.dart' 'lib/*.dart'
  } | grep -vE '\.(config|g|mapper|freezed)\.dart$' | sort -u
)

if [ "${#files[@]}" -eq 0 ]; then
  echo "No Dart files found under lib/ in $TARGET_DIR." >&2
  exit 0
fi

echo "Analyzing ${#files[@]} files with arrk_lints..." >&2
# dart analyze exits non-zero whenever it finds anything; the gate decides.
output="$("${DART[@]}" analyze "${files[@]}" 2>&1 || true)"
# A gate that analyzed nothing must not pass. `dart analyze` prints
# "Analyzing ..." when it runs; a usage error or a missing SDK prints none.
if ! printf '%s\n' "$output" | grep -q '^Analyzing'; then
  echo "arrk_lints: dart analyze did not run — refusing to report OK. Output:" >&2
  printf '%s\n' "$output" >&2
  exit 1
fi
printf '%s\n' "$output" | python3 "$LINTS_DIR/baseline.py" "$MODE" "$PWD/arrk_baseline.txt"

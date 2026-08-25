#!/usr/bin/env bash
set -euo pipefail

plugin_dir="$(cd -- "$(dirname -- "$0")/.." && pwd)"
quickshell_bin="${QUICKSHELL_BIN:-quickshell}"
command -v "$quickshell_bin" >/dev/null 2>&1 || {
  printf 'Quickshell executable not found: %s\n' "$quickshell_bin" >&2
  exit 127
}
set +e
output="$(timeout 4 "$quickshell_bin" --no-color --path "$plugin_dir/RuntimeModelTest.qml" 2>&1)"
status=$?
set -e
if [[ $status -ne 0 && $status -ne 124 ]]; then
  printf '%s\n' "$output" >&2
  exit "$status"
fi
grep -q 'PRIVACY_QML_RUNTIME_OK' <<<"$output"

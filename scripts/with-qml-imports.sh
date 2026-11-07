#!/usr/bin/env bash
# Keep installed Omarchy and Qt files unchanged; all preparation is private.
set -euo pipefail
plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
[[ $# -ge 2 ]] || { printf 'Usage: with-qml-imports.sh <source-shell> <command> [args...]\n' >&2; exit 2; }
source_shell=$1
shift
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
python3 "$plugin_dir/scripts/prepare-qml-imports.py" --source-shell "$source_shell" --output "$scratch/shell"
python3 "$plugin_dir/scripts/prepare-qml-tooling.py" --output "$scratch/tooling"
export OMARCHY_SHELL_ROOT="$scratch/shell" QML_TOOLING_IMPORT_ROOT="$scratch/tooling"
"$@"

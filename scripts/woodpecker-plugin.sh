#!/usr/bin/env bash
# The same plugin checks as GitHub CI, inside its pinned toolchain image.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export RUNNER_TEMP="$scratch"
omarchy_dir="$scratch/omarchy"
git init --quiet "$omarchy_dir"
git -C "$omarchy_dir" fetch --quiet --depth 1 https://github.com/basecamp/omarchy.git 13f18b2cb7286fb54f87daf571a031aa6af3d8f0
git -C "$omarchy_dir" checkout --quiet --detach FETCH_HEAD
[[ $(git -C "$omarchy_dir" rev-parse HEAD) == 13f18b2cb7286fb54f87daf571a031aa6af3d8f0 ]]
export OMARCHY_PATH="$omarchy_dir" OMARCHY_SHELL_ROOT="$omarchy_dir/shell"
export OMARCHY_PLUGIN_VALIDATE="$omarchy_dir/bin/omarchy-plugin-validate"
export QMLLINT=/usr/lib/qt6/bin/qmllint
export OMABAR_QML_TESTS=never OMABAR_LIVE_TESTS=never MMW_QML_TESTS=never
export P2P_RUNTIME_TESTS=never PRIVACY_RUNTIME_TESTS=never

shellcheck scripts/build-site.sh scripts/capture-environment-guard scripts/capture-plugin-fingerprint scripts/capture-screenshots scripts/deploy-shell-runtime scripts/lint-qml scripts/prune-capture-recovery scripts/publish-screenshot-assets scripts/restart-shell-safely scripts/restore-capture-state scripts/select-capture-monitor scripts/verify-capture-postconditions tests/run_all.sh tests/run_qml_runtime.sh

mkdir "$RUNNER_TEMP/plugin"
git archive HEAD | tar -x -C "$RUNNER_TEMP/plugin"
"$OMARCHY_PLUGIN_VALIDATE" "$RUNNER_TEMP/plugin"

archive_files=$(git archive HEAD | tar -t)
if grep -E '(^|/)(__pycache__|node_modules|\.pytest_cache)(/|$)|\.py[co]$|\.tar\.gz(\.sha256)?$' <<<"$archive_files"; then
  echo "Release archive contains generated or forbidden files" >&2
  exit 1
fi
if grep -E '^(\.github|\.githooks|\.woodpecker|scripts|tests)/|^Runtime.*Test\.qml$|^package(-lock)?\.json$' <<<"$archive_files"; then
  echo "Release archive contains maintainer-only files" >&2
  exit 1
fi
if git grep -IlE -- 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|gh[pousr]_[A-Za-z0-9_]{20,}' -- .; then
  echo "Tracked files contain credential-like material" >&2
  exit 1
fi

npm ci --ignore-scripts --no-audit

tests/run_all.sh

scripts/lint-qml

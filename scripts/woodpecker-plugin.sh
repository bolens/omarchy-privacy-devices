#!/usr/bin/env bash
# Public preparation followed by mandatory offline plugin/QML validation.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
input_dir="$PWD/.woodpecker-qml-input"
omarchy_dir="$input_dir/omarchy"
omarchy_revision=13f18b2cb7286fb54f87daf571a031aa6af3d8f0
case "${1:-}" in
  --prepare)
    [[ $# == 1 ]] || exit 2
    if [[ -e "$input_dir" || -L "$input_dir" ]]; then
      echo "Refusing an existing QML input path" >&2
      exit 2
    fi
    umask 022
    mkdir -m 755 -- "$input_dir"
    git init --quiet "$omarchy_dir"
    GIT_TERMINAL_PROMPT=0 git -C "$omarchy_dir" fetch --quiet --depth 1 https://github.com/omacom/omarchy.git "$omarchy_revision"
    git -C "$omarchy_dir" checkout --quiet --detach FETCH_HEAD
    [[ $(git -C "$omarchy_dir" rev-parse HEAD) == "$omarchy_revision" ]]
    # Install exact public locked site-test dependencies before the offline step.
    NPM_CONFIG_USERCONFIG=/dev/null NPM_CONFIG_GLOBALCONFIG=/dev/null npm ci --ignore-scripts
    exit 0
    ;;
  --offline)
    [[ $# == 1 && $(id -u) == 10042 ]] || { echo "Offline QML checks require container user 10042" >&2; exit 2; }
    [[ -d "$input_dir" && ! -L "$input_dir" && -d "$omarchy_dir/.git" && ! -L "$omarchy_dir" ]] || exit 2
    ;;
  *) echo "Usage: woodpecker-plugin.sh --prepare|--offline" >&2; exit 2 ;;
esac
# The public clone/workspace belong to the previous container step. Trust only
# these exact paths, for this process tree; never alter host/global Git policy.
export GIT_CONFIG_COUNT=2
export GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0="$PWD"
export GIT_CONFIG_KEY_1=safe.directory GIT_CONFIG_VALUE_1="$omarchy_dir"
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export RUNNER_TEMP="$scratch" HOME="$scratch/home"
export XDG_CONFIG_HOME="$scratch/config" XDG_CACHE_HOME="$scratch/cache" XDG_STATE_HOME="$scratch/state"
export PYTHONPYCACHEPREFIX="$scratch/pycache"
mkdir -m 700 -- "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
[[ $(git -C "$omarchy_dir" rev-parse HEAD) == "$omarchy_revision" ]]
python3 scripts/prepare-qml-imports.py --source-shell "$omarchy_dir/shell" --output "$scratch/qml-shell"
python3 scripts/prepare-qml-tooling.py --output "$scratch/qml-tooling"
export OMARCHY_PATH="$omarchy_dir" OMARCHY_SHELL_ROOT="$scratch/qml-shell"
export QML_TOOLING_IMPORT_ROOT="$scratch/qml-tooling"
export OMARCHY_PLUGIN_VALIDATE="$omarchy_dir/bin/omarchy-plugin-validate"
export QMLLINT=/usr/lib/qt6/bin/qmllint
# Portable tests avoid an accidental desktop run. The owned runtime below is
# mandatory and never consults these optional-desktop selection variables.
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

python3 scripts/qml-runtime-fixture.py --execute --repository privacy \
  --checkout "$PWD" --prepared-shell "$OMARCHY_SHELL_ROOT" --output "$scratch/runtime-results" \
  --quickshell /usr/bin/quickshell --labwc /usr/bin/labwc --python /usr/bin/python3 \
  --pw-dump /usr/bin/pw-dump --pipewire /usr/bin/pipewire --fc-match /usr/bin/fc-match \
  --negative-catalog scripts/qml-runtime-warnings.json

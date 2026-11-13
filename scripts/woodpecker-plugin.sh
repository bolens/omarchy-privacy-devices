#!/usr/bin/env bash
# Public preparation followed by mandatory offline plugin/QML validation.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
input_dir="$PWD/.woodpecker-qml-input"
omarchy_dir="$input_dir/omarchy"
omarchy_revision=13f18b2cb7286fb54f87daf571a031aa6af3d8f0
# NPM 11 loads user/global files separately. Give each invocation distinct,
# empty private configs and no ambient authentication or configuration variables.
run_public_npm() (
  npm_config_dir=$(mktemp -d)
  trap 'rm -rf -- "$npm_config_dir"' EXIT
  mkdir -m 700 -- "$npm_config_dir/home" "$npm_config_dir/cache" "$npm_config_dir/tmp"
  install -m 600 /dev/null "$npm_config_dir/user.npmrc"
  install -m 600 /dev/null "$npm_config_dir/global.npmrc"
  env -i PATH="$PATH" LANG="${LANG:-C.UTF-8}" \
    HOME="$npm_config_dir/home" TMPDIR="$npm_config_dir/tmp" \
    NPM_CONFIG_CACHE="$npm_config_dir/cache" \
    NPM_CONFIG_USERCONFIG="$npm_config_dir/user.npmrc" \
    NPM_CONFIG_GLOBALCONFIG="$npm_config_dir/global.npmrc" npm "$@"
)

# Require the complete immutable import/validator closure before going offline.
# Disabling lazy fetch makes missing promised objects fail instead of using CI's
# network accidentally. The offline container enforces the network boundary too.
verify_omarchy_input() {
  [[ $(git -C "$omarchy_dir" rev-parse HEAD) == "$omarchy_revision" ]]
  [[ -d "$omarchy_dir/shell" && -x "$omarchy_dir/bin/omarchy-plugin-validate" ]]
  local object_types
  object_types=$(GIT_NO_LAZY_FETCH=1 git -C "$omarchy_dir" ls-tree -r --format='%(objectname)' HEAD -- shell bin |
    GIT_NO_LAZY_FETCH=1 git -C "$omarchy_dir" cat-file --batch-check='%(objecttype)' | sort -u)
  [[ "$object_types" == blob ]]
  GIT_NO_LAZY_FETCH=1 python3 - "$omarchy_dir" <<'PYTHON'
import hashlib
import pathlib
import stat
import subprocess
import sys

root = pathlib.Path(sys.argv[1])
entries = subprocess.check_output([
    "git", "-C", str(root), "ls-tree", "-rz", "HEAD", "--", "shell", "bin"
])
for entry in entries.split(b"\0"):
    if not entry:
        continue
    metadata, name = entry.split(b"\t", 1)
    mode, kind, expected = metadata.split()
    path = root / name.decode()
    info = path.lstat()
    if kind != b"blob" or mode not in (b"100644", b"100755") or not stat.S_ISREG(info.st_mode):
        raise SystemExit(f"Invalid prepared Omarchy file: {name.decode()}")
    content = path.read_bytes()
    actual = hashlib.sha1(b"blob " + str(len(content)).encode() + b"\0" + content).hexdigest().encode()
    if actual != expected or bool(info.st_mode & 0o111) != (mode == b"100755"):
        raise SystemExit(f"Prepared Omarchy bytes or mode differ: {name.decode()}")
PYTHON
}
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
    git -C "$omarchy_dir" remote add origin https://github.com/omacom/omarchy.git
    git -C "$omarchy_dir" config remote.origin.promisor true
    git -C "$omarchy_dir" config remote.origin.partialclonefilter blob:none
    git -C "$omarchy_dir" sparse-checkout set --cone shell bin
    GIT_TERMINAL_PROMPT=0 git -C "$omarchy_dir" fetch --quiet --no-tags --filter=blob:none --depth 1 origin "$omarchy_revision"
    git -C "$omarchy_dir" checkout --quiet --detach FETCH_HEAD
    verify_omarchy_input
    # Install exact public locked site-test dependencies before the offline step.
    run_public_npm ci --ignore-scripts
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
export GIT_NO_LAZY_FETCH=1
verify_omarchy_input
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

# The networked preparation owns installation; this step only checks the locked tree.
run_public_npm ls --all --offline

tests/run_all.sh

scripts/lint-qml

python3 scripts/qml-runtime-fixture.py --execute --repository privacy \
  --checkout "$PWD" --prepared-shell "$OMARCHY_SHELL_ROOT" --output "$scratch/runtime-results" \
  --quickshell /usr/bin/quickshell --labwc /usr/bin/labwc --python /usr/bin/python3 \
  --pw-dump /usr/bin/pw-dump --pipewire /usr/bin/pipewire --fc-match /usr/bin/fc-match \
  --negative-catalog scripts/qml-runtime-warnings.json

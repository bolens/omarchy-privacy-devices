#!/usr/bin/env bash
set -euo pipefail

plugin_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$plugin_dir"

for test_file in tests/*.test.js; do
  node "$test_file"
done

python3 -m py_compile privacy-history privacy-location privacy-observe privacy-diagnostics privacy-settings privacy-audio-devices privacy-menu-entry
python3 -m unittest discover -s tests -p 'test_*.py'

shellcheck \
  privacy-action privacy-control privacy-deps privacy-recording privacy-screenshot \
  scripts/build-site.sh \
  scripts/capture-environment-guard scripts/capture-plugin-fingerprint scripts/capture-screenshots \
  scripts/deploy-shell-runtime \
  scripts/prune-capture-recovery scripts/verify-capture-postconditions \
  scripts/publish-screenshot-assets scripts/restart-shell-safely scripts/restore-capture-state \
  tests/run_all.sh tests/run_qml_runtime.sh \
  tests/fixtures/*

runtime_mode=${PRIVACY_RUNTIME_TESTS:-auto}
case "$runtime_mode" in
  always)
    tests/run_qml_runtime.sh
    ;;
  never)
    printf 'Runtime QML tests skipped (PRIVACY_RUNTIME_TESTS=never).\n'
    ;;
  auto)
    wayland_socket=${XDG_RUNTIME_DIR:-}/${WAYLAND_DISPLAY:-}
    if [[ -n ${WAYLAND_DISPLAY:-} && -S $wayland_socket ]] \
      && { command -v quickshell >/dev/null || [[ -x $HOME/.local/opt/quickshell-git/usr/bin/quickshell ]]; }; then
      tests/run_qml_runtime.sh
    else
      printf 'Runtime QML tests skipped (no usable Wayland session; set PRIVACY_RUNTIME_TESTS=always to require them).\n'
    fi
    ;;
  *)
    printf 'PRIVACY_RUNTIME_TESTS must be auto, always, or never.\n' >&2
    exit 2
    ;;
esac

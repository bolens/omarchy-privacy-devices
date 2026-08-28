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

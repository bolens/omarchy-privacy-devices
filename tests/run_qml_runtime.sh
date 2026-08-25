#!/usr/bin/env bash
set -euo pipefail

plugin_dir="$(cd -- "$(dirname -- "$0")/.." && pwd)"
quickshell_bin="${QUICKSHELL_BIN:-quickshell}"
shell_root="${OMARCHY_SHELL_ROOT:-}"
command -v "$quickshell_bin" >/dev/null 2>&1 || {
  printf 'Quickshell executable not found: %s\n' "$quickshell_bin" >&2
  exit 127
}
if [[ -z $shell_root ]]; then
  for candidate in /usr/share/omarchy/shell "${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-overlay/shell"; do
    if [[ -d "$candidate/Commons" && -d "$candidate/Ui" ]]; then shell_root=$candidate; break; fi
  done
fi
runtime_parent="$(mktemp -d)"
runtime_dir="$runtime_parent/runtime tree"
mkdir "$runtime_dir"
trap 'rm -rf -- "$runtime_parent"' EXIT

[[ -d "$shell_root/Commons" && -d "$shell_root/Ui" ]] || {
  printf 'Omarchy Shell modules not found under %s\n' "$shell_root" >&2
  exit 1
}
find "$plugin_dir" -maxdepth 1 -type f -exec ln -s -- '{}' "$runtime_dir/" \;
ln -s -- "$plugin_dir/tests" "$runtime_dir/tests"
ln -s -- "$shell_root/Commons" "$runtime_dir/Commons"
ln -s -- "$shell_root/Ui" "$runtime_dir/Ui"

run_harness() {
  local file=$1 marker=$2 output status
  set +e
  output="$(timeout 4 "$quickshell_bin" --no-color --path "$runtime_dir/$file" 2>&1)"
  status=$?
  set -e
  if [[ $status -ne 0 && $status -ne 124 ]]; then
    printf '%s\n' "$output" >&2
    exit "$status"
  fi
  grep -q "$marker" <<<"$output" || {
    printf 'QML runtime harness %s did not emit %s\n%s\n' "$file" "$marker" "$output" >&2
    return 1
  }
}

run_harness RuntimeModelTest.qml PRIVACY_QML_RUNTIME_OK
run_harness RuntimeSettingsNavigationTest.qml PRIVACY_QML_SETTINGS_NAVIGATION_OK
run_harness RuntimeConfirmationTest.qml PRIVACY_QML_CONFIRMATION_OK
run_harness RuntimeObserverLifecycleTest.qml PRIVACY_QML_OBSERVER_LIFECYCLE_OK
run_harness RuntimeSettingsTransferTest.qml PRIVACY_QML_SETTINGS_TRANSFER_OK
run_harness RuntimeSettingsMutationTest.qml PRIVACY_QML_SETTINGS_MUTATION_OK
run_harness RuntimeSettingsTransferFailureTest.qml PRIVACY_QML_SETTINGS_TRANSFER_FAILURE_OK
run_harness RuntimeObserverRecoveryTest.qml PRIVACY_QML_OBSERVER_RECOVERY_OK
run_harness RuntimePluginSmokeTest.qml PRIVACY_QML_PLUGIN_SMOKE_OK
run_harness RuntimeSettingToggleTest.qml PRIVACY_QML_SETTING_TOGGLE_OK
run_harness RuntimeSettingsTransferResultTest.qml PRIVACY_QML_SETTINGS_TRANSFER_RESULT_OK

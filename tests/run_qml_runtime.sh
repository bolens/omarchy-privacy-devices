#!/usr/bin/env bash
set -euo pipefail

plugin_dir="$(cd -- "$(dirname -- "$0")/.." && pwd)"
quickshell_bin="${QUICKSHELL_BIN:-quickshell}"
shell_root="${OMARCHY_SHELL_ROOT:-}"
requested_harness="${QML_RUNTIME_HARNESS:-}"
ran_harness=0
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
active_harness=""
cleanup_runtime() {
  if [[ -n $active_harness ]]; then
    "$quickshell_bin" kill --path "$active_harness" --any-display >/dev/null 2>&1 || true
  fi
  rm -rf -- "$runtime_parent"
}
trap cleanup_runtime EXIT INT TERM

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
  if [[ -n $requested_harness && $file != "$requested_harness" ]]; then return 0; fi
  ran_harness=1
  active_harness="$runtime_dir/$file"
  set +e
  output="$(timeout 4 "$quickshell_bin" --no-color --path "$active_harness" 2>&1)"
  status=$?
  set -e
  "$quickshell_bin" kill --path "$active_harness" --any-display >/dev/null 2>&1 || true
  active_harness=""
  if [[ $status -ne 0 && $status -ne 124 ]]; then
    printf '%s\n' "$output" >&2
    exit "$status"
  fi
  if grep -Eq 'WARN scene:|CRITICAL:|FATAL:' <<<"$output"; then
    printf 'QML runtime harness %s emitted runtime errors\n%s\n' "$file" "$output" >&2
    return 1
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
run_harness RuntimeAppearanceSettingsTest.qml PRIVACY_QML_APPEARANCE_SETTINGS_OK
run_harness RuntimeDeepLinkTest.qml PRIVACY_QML_DEEP_LINK_OK
run_harness RuntimeAudioEndpointSettingsTest.qml PRIVACY_QML_AUDIO_ENDPOINT_SETTINGS_OK
run_harness RuntimeBarSemanticColorTest.qml PRIVACY_QML_BAR_SEMANTIC_COLOR_OK
run_harness RuntimeActivityCardStateTest.qml PRIVACY_QML_ACTIVITY_CARD_STATE_OK
run_harness RuntimeLockdownButtonTest.qml PRIVACY_QML_LOCKDOWN_BUTTON_OK
run_harness RuntimeDeviceSettingsNavigationTest.qml PRIVACY_QML_DEVICE_SETTINGS_NAVIGATION_OK
run_harness RuntimeSettingsRollbackTest.qml PRIVACY_QML_SETTINGS_ROLLBACK_OK
run_harness RuntimeDeviceDiagnosticsTest.qml PRIVACY_QML_DEVICE_DIAGNOSTICS_OK
run_harness RuntimeMonitoringActionsTest.qml PRIVACY_QML_MONITORING_ACTIONS_OK
run_harness RuntimeActivityPolicyActionsTest.qml PRIVACY_QML_ACTIVITY_POLICY_ACTIONS_OK
run_harness RuntimePrivateDataActionsTest.qml PRIVACY_QML_PRIVATE_DATA_ACTIONS_OK
run_harness RuntimeHistoryViewTest.qml PRIVACY_QML_HISTORY_VIEW_OK
run_harness RuntimeDeviceAppearanceMutationTest.qml PRIVACY_QML_DEVICE_APPEARANCE_MUTATION_OK
run_harness RuntimeGeneralSettingsTest.qml PRIVACY_QML_GENERAL_SETTINGS_OK
run_harness RuntimeAlertsSettingsTest.qml PRIVACY_QML_ALERTS_SETTINGS_OK
run_harness RuntimeIntegerSettingTest.qml PRIVACY_QML_INTEGER_SETTING_OK
run_harness RuntimeMarkerGlyphEditorTest.qml PRIVACY_QML_MARKER_GLYPH_EDITOR_OK
run_harness RuntimeMessageSurfaceTest.qml PRIVACY_QML_MESSAGE_SURFACE_OK
run_harness RuntimeMonitoringConfigurationTest.qml PRIVACY_QML_MONITORING_CONFIGURATION_OK
run_harness RuntimeAppearancePresentationTest.qml PRIVACY_QML_APPEARANCE_PRESENTATION_OK
run_harness RuntimeActivityCardInteractionTest.qml PRIVACY_QML_ACTIVITY_CARD_INTERACTION_OK
run_harness RuntimeActivitySessionSummaryTest.qml PRIVACY_QML_ACTIVITY_SESSION_SUMMARY_OK
run_harness RuntimeCapturePreviewLifecycleTest.qml PRIVACY_QML_CAPTURE_PREVIEW_LIFECYCLE_OK
run_harness RuntimeAudioEndpointFeedbackTest.qml PRIVACY_QML_AUDIO_ENDPOINT_FEEDBACK_OK
run_harness RuntimeDeviceMetadataMutationTest.qml PRIVACY_QML_DEVICE_METADATA_MUTATION_OK
run_harness RuntimeDeviceBackendResetTest.qml PRIVACY_QML_DEVICE_BACKEND_RESET_OK
run_harness RuntimeServicePayloadBoundaryTest.qml PRIVACY_QML_SERVICE_PAYLOAD_BOUNDARY_OK
run_harness RuntimeServiceProjectionTest.qml PRIVACY_QML_SERVICE_PROJECTION_OK
run_harness RuntimeControlTransactionLifecycleTest.qml PRIVACY_QML_CONTROL_TRANSACTION_LIFECYCLE_OK
run_harness RuntimeSessionRefreshReactivityTest.qml PRIVACY_QML_SESSION_REFRESH_REACTIVITY_OK
run_harness RuntimeCapturePreviewExpiryTest.qml PRIVACY_QML_CAPTURE_PREVIEW_EXPIRY_OK
run_harness RuntimeNotificationActionRoutingTest.qml PRIVACY_QML_NOTIFICATION_ACTION_ROUTING_OK
run_harness RuntimeControlVerificationTimeoutTest.qml PRIVACY_QML_CONTROL_VERIFICATION_TIMEOUT_OK
run_harness RuntimePrivacyPresetOrchestrationTest.qml PRIVACY_QML_PRIVACY_PRESET_ORCHESTRATION_OK
run_harness RuntimeSelfTestAggregationTest.qml PRIVACY_QML_SELF_TEST_AGGREGATION_OK
run_harness RuntimeKeyboardNavigationTest.qml PRIVACY_QML_KEYBOARD_NAVIGATION_OK
run_harness RuntimeControlRequestGatingTest.qml PRIVACY_QML_CONTROL_REQUEST_GATING_OK
run_harness RuntimeObserverHealthStateTest.qml PRIVACY_QML_OBSERVER_HEALTH_STATE_OK
run_harness RuntimeDeviceHealthAggregationTest.qml PRIVACY_QML_DEVICE_HEALTH_AGGREGATION_OK

if [[ -n $requested_harness && $ran_harness -eq 0 ]]; then
  printf 'Requested QML runtime harness not found: %s\n' "$requested_harness" >&2
  exit 2
fi

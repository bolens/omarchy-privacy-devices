const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")

const service = fs.readFileSync(path.join(__dirname, "..", "Service.qml"), "utf8")
const screenshotWorkflow = fs.readFileSync(path.join(__dirname, "..", "scripts/capture-screenshots"), "utf8")
const captureGuard = fs.readFileSync(path.join(__dirname, "..", "scripts/capture-environment-guard"), "utf8")
const capturePostconditions = fs.readFileSync(path.join(__dirname, "..", "scripts/verify-capture-postconditions"), "utf8")
const bar = fs.readFileSync(path.join(__dirname, "..", "BarWidget.qml"), "utf8")
const ci = fs.readFileSync(path.join(__dirname, "..", ".github", "workflows", "ci.yml"), "utf8")
const qmlRuntime = fs.readFileSync(path.join(__dirname, "run_qml_runtime.sh"), "utf8")
const serviceEntryPoint = service.trimStart()
const barEntryPoint = bar.trimStart()

assert.match(serviceEntryPoint, /^import[\s\S]*?\nItem\s*\{/, "the service entry point must remain an embeddable Item")
assert.doesNotMatch(serviceEntryPoint, /\nShellRoot\s*\{/, "the service entry point must not create a second shell root")
assert.doesNotMatch(barEntryPoint, /\nShellRoot\s*\{/, "the bar entry point must not create a second shell root")
assert.doesNotMatch(service, /Quickshell\.execDetached\(\s*["']/, "detached runtime commands must use argument arrays")
assert.doesNotMatch(service, /locationProc\.command\s*=\s*\["sh",\s*"-c"/, "GeoClue probing must not cross an inline shell boundary")
assert.match(service, /locationProc\.command = \[String\(Qt\.resolvedUrl\("privacy-location"\)\)/,
  "GeoClue probing must resolve its helper relative to the installed plugin")

assert.doesNotMatch(qmlRuntime, /\/home\/[^/]+\//,
  "the QML runtime test must not contain a developer-specific executable path")
assert.match(qmlRuntime, /QUICKSHELL_BIN:-quickshell/,
  "the QML runtime test should use PATH discovery while retaining an explicit override")
assert.match(qmlRuntime, /runtime_dir="\$runtime_parent\/runtime tree"/,
  "the QML runtime suite must exercise relocatable plugin paths containing spaces")

assert.match(service, /function monitoringTelemetry\(\)[\s\S]*?lastSessionRefreshAgeSeconds: Model\.freshnessAgeSeconds\(lastSessionRefreshAt, now\)[\s\S]*?lastFallbackRefreshAgeSeconds: Model\.freshnessAgeSeconds\(lastFallbackRefreshAt, now\)[\s\S]*?fallbackObserverHeartbeatAgeSeconds: Model\.freshnessAgeSeconds\(fallbackObserverLastSeen, now\)[\s\S]*?directHeartbeatAgeSeconds: Model\.freshnessAgeSeconds\(directObserverLastSeen, now\)/,
  "every exported telemetry timestamp must use the behavior-tested freshness policy")
assert.match(service, /requestedSettingsPage = Model\.settingsPage\(page\)/, "settings IPC pages must pass through the shared allowlist")
assert.match(service, /!historyWasEnabled && settings\.historyEnabled === true\) historyLoaded = false[\s\S]*?loadHistory\(\)/,
  "re-enabling history must invalidate the disabled-state load sentinel")
assert.match(service, /function protocol\(\): string \{ return "2" \}[\s\S]*?function beginCapture\(payloadB64: string\)[\s\S]*?capturePreviewOwner[\s\S]*?function renew\(owner: string\)[\s\S]*?function endCapture\(owner: string\)/,
  "capture previews must be controlled through bounded in-memory IPC")
assert.match(service, /capturePreviewExpiresAt = Date\.now\(\) \+ 180000/,
  "capture preview leases must have a bounded duration")
assert.match(service, /Date\.now\(\) >= root\.capturePreviewExpiresAt[\s\S]*?root\.clearCapturePreview\(\)/,
  "abandoned capture previews must expire automatically")
assert.match(screenshotWorkflow, /capture_owner=.*secrets\.token_urlsafe[\s\S]*?call privacy-devices-capture-v2 protocol/,
  "capture must negotiate the owner-based protocol")
assert.match(captureGuard, /privacy-devices-capture-v2 renew "\$owner"/,
  "capture must maintain its owner lease")
assert.match(service, /settings\.historyEnabled === true && !capturePreviewActive/,
  "capture-generated sessions must never enter the user's history")
assert.match(bar, /effectiveSettings: privacyService && privacyService\.capturePreviewActive[\s\S]*?capturePreviewSettings/,
  "capture preview settings must override presentation without replacing persisted settings")
assert.match(bar, /filteredHistory: Model\.filterHistory\(privacyService \? privacyService\.displayHistory/,
  "capture preview history must feed the visible history model")
assert.match(screenshotWorkflow, /trap cleanup_capture EXIT INT TERM/, "screenshot capture must restore user and repository state on failure")
assert.match(screenshotWorkflow, /--verify\) verify_only=true/,
  "capture must expose a repository-safe live verification mode")
assert.match(screenshotWorkflow, /if \[\[ \$verify_only == false \]\]; then[\s\S]*?optimize_png[\s\S]*?social-card\.png[\s\S]*?fi[\s\S]*?restore_desktop/,
  "verification must skip publication-only image processing")
assert.match(screenshotWorkflow, /if \[\[ \$verify_only == false \]\]; then[\s\S]*?command -v pngquant/,
  "verification must not require publication-only image tooling")
assert.match(screenshotWorkflow, /root=.*BASH_SOURCE[\s\S]*?cd "\$root"/,
  "capture must resolve repository helpers independently of the caller's working directory")
assert.match(screenshotWorkflow, /plugin_fingerprint=.*capture-plugin-fingerprint[\s\S]*?check_capture_environment\(\)[\s\S]*?capture-environment-guard/,
  "capture must abort when another agent changes the live plugin tree")
assert.match(screenshotWorkflow, /plugin_root="\$\{XDG_CONFIG_HOME[^\n]+\/\$plugin_id"/,
  "capture mutation detection must ignore unrelated installed plugins")
assert.match(screenshotWorkflow, /printf '\{\"pid\":%s,\"monitor\":\"%s\",\"workspace\":%s/,
  "the capture lock must identify its workspace owner")
assert.match(screenshotWorkflow, /write_report\(\)[\s\S]*?result:\"passed\"[\s\S]*?settings:\"untouched\"[\s\S]*?history:\"untouched\"/,
  "successful captures must emit a machine-readable state report")
assert.match(screenshotWorkflow, /on_capture_error\(\)[\s\S]*?failure_line[\s\S]*?current_checkpoint[\s\S]*?trap 'on_capture_error "\$LINENO"' ERR/,
  "screenshot failures should identify their source line and checkpoint without tracing private state")
assert.match(screenshotWorkflow, /write_failure_report\(\)[\s\S]*?result:"failed"[\s\S]*?checkpoint[\s\S]*?recoveryPath/,
  "failed captures must leave a machine-readable recovery report")
assert.ok(screenshotWorkflow.indexOf("write_failure_report()") < screenshotWorkflow.indexOf("trap cleanup_capture EXIT"),
  "failure reporting must be defined before capture cleanup can run")
assert.match(screenshotWorkflow, /prune-capture-recovery "\$recovery_root" 7/,
  "capture startup must prune only expired recovery transactions")
assert.match(screenshotWorkflow, /flock -n 9/,
  "screenshot capture must prevent concurrent runs from racing over user state")
assert.match(screenshotWorkflow, /set_capture_preview\(\) \{[\s\S]*?beginCapture[\s\S]*?history_samples/,
  "sample history and showcase settings must enter through in-memory preview IPC")
assert.doesNotMatch(screenshotWorkflow, /privacy-history (clear|append)|reloadConfig|mv -- .*settings_file/,
  "capture must never mutate user history, replace settings, or reload shell config")
assert.match(screenshotWorkflow, /window_count == 0/, "screenshot capture must reject workspaces containing user windows")
assert.match(screenshotWorkflow, /restore_original_workspace\(\) \{[\s\S]*?for attempt in \{1\.\.20\}[\s\S]*?workspace == \"\$original_workspace\"/,
  "workspace restoration must wait until the compositor confirms the original workspace")
assert.match(screenshotWorkflow, /restore_dnd\(\) \{[\s\S]*?dnd_changed == true[\s\S]*?call notifications setDnd[\s\S]*?call notifications isDnd[\s\S]*?actual == \"\$dnd_state\"/,
  "DND restoration must read back the requested state")
assert.match(screenshotWorkflow, /Restoration: settings=%s history=%s dnd=%s workspace=%s shell=%s/,
  "capture must report every restored desktop-state category")
assert.match(screenshotWorkflow, /notification_x=.*[\s\S]*?for attempt in \{1\.\.4\}[\s\S]*?notification send[\s\S]*?capture_has_content \"\$capture_dir\/notification\.png\"/,
  "notification capture must retry transiently missing toasts")
assert.match(screenshotWorkflow, /debugBarGeometry/, "bar screenshots must use measured live widget geometry")
assert.match(screenshotWorkflow, /panel_capture_x=\$\(\(widget_x \+ widget_width \/ 2 - panel_width \/ 2 - panel_side_padding\)\)/,
  "panel captures must center on live widget geometry instead of using a stale offset")
assert.match(screenshotWorkflow, /panel_width \+ panel_side_padding \* 2/,
  "panel captures must retain desktop context on both horizontal edges")
assert.ok(fs.statSync(path.join(__dirname, "..", "scripts/capture-screenshots")).mode & 0o111,
  "screenshot workflow must remain executable")
for (const qml of [
  "DeviceSettingsEditor.qml", "DeviceDiagnostics.qml", "RuntimeModelTest.qml",
  "PrivacySettingsNavigation.qml", "PrivacyConfirmationController.qml",
  "PrivacySettingsTransferController.qml", "PrivacySettingsMutationController.qml",
  "PrivacySettingsTransferResult.qml", "PrivacySettingToggle.qml",
  "PrivacyMessageSurface.qml", "RuntimeSettingsNavigationTest.qml",
  "RuntimeConfirmationTest.qml", "RuntimeObserverLifecycleTest.qml",
  "RuntimeSettingsTransferTest.qml", "RuntimeSettingsMutationTest.qml",
  "RuntimeSettingsTransferFailureTest.qml", "RuntimeObserverRecoveryTest.qml",
  "RuntimePluginSmokeTest.qml", "RuntimeSettingToggleTest.qml",
  "RuntimeSettingsTransferResultTest.qml"
])
  assert.match(ci, new RegExp(`qmllint[^']*${qml}`), `CI must lint ${qml}`)
for (const [harness, marker] of [
  ["RuntimeSettingsNavigationTest.qml", "PRIVACY_QML_SETTINGS_NAVIGATION_OK"],
  ["RuntimeConfirmationTest.qml", "PRIVACY_QML_CONFIRMATION_OK"],
  ["RuntimeObserverLifecycleTest.qml", "PRIVACY_QML_OBSERVER_LIFECYCLE_OK"],
  ["RuntimeSettingsTransferTest.qml", "PRIVACY_QML_SETTINGS_TRANSFER_OK"],
  ["RuntimeSettingsMutationTest.qml", "PRIVACY_QML_SETTINGS_MUTATION_OK"],
  ["RuntimeSettingsTransferFailureTest.qml", "PRIVACY_QML_SETTINGS_TRANSFER_FAILURE_OK"],
  ["RuntimeObserverRecoveryTest.qml", "PRIVACY_QML_OBSERVER_RECOVERY_OK"],
  ["RuntimePluginSmokeTest.qml", "PRIVACY_QML_PLUGIN_SMOKE_OK"],
  ["RuntimeSettingToggleTest.qml", "PRIVACY_QML_SETTING_TOGGLE_OK"],
  ["RuntimeSettingsTransferResultTest.qml", "PRIVACY_QML_SETTINGS_TRANSFER_RESULT_OK"]
])
  assert.match(qmlRuntime, new RegExp(`run_harness ${harness} ${marker}`), `${harness} must run in the real QML suite`)
assert.match(screenshotWorkflow, /capture_panel device device/, "screenshot workflow must capture an individual device settings page")
assert.match(screenshotWorkflow, /docs\/device\.png/, "screenshot workflow must publish the device settings capture")
assert.match(screenshotWorkflow, /privacy-devices-settings openHistory[\s\S]*capture_panel history history/,
  "screenshot workflow must open and capture the dedicated history view through focused-monitor IPC")
assert.match(screenshotWorkflow, /capture_panel history history[\s\S]*set_capture_preview false[\s\S]*capture_panel history-disabled history[\s\S]*set_capture_preview true/,
  "screenshot workflow must switch history presentation entirely in memory")
assert.match(screenshotWorkflow, /set_capture_preview\(\)[\s\S]*showBarActiveMarker:true[\s\S]*showBarDisabledMarker:true[\s\S]*statusMarkerMode:"symbols"/,
  "published captures should consistently showcase the default bar status markers")
assert.match(screenshotWorkflow, /capture_panel history-disabled history "" 240/,
  "the compact disabled-history view should not publish a mostly empty tall crop")
assert.match(screenshotWorkflow, /capture_panel monitoring-private settings-section monitoring 330 private-data 115/,
  "capture must showcase private history and settings transfer at its deep link")
assert.match(screenshotWorkflow, /capture_panel monitoring-health settings-section monitoring 290 observer-health 390/,
  "capture must showcase observer health at its deep link")
assert.match(screenshotWorkflow, /docs\/history\.png/,
  "screenshot workflow must publish the history capture")
assert.match(screenshotWorkflow, /docs\/history-disabled\.png/,
  "screenshot workflow must publish the disabled history capture")
assert.match(screenshotWorkflow, /update-screenshot-metadata \"\$publish_dir\/docs\/index\.html\" \"\$publish_dir\/docs\" \"\$publish_dir\/README\.md\"/,
  "capture must synchronize Pages dimensions and content-addressed README images")
assert.match(screenshotWorkflow, /restore_desktop[\s\S]*?publish-screenshot-assets \"\$publish_dir\"/,
  "repository assets must publish only after desktop restoration succeeds")
assert.match(screenshotWorkflow, /optimize_png \"\$capture_dir\/activity\.png\" \"\$publish_dir\/preview\.png\"/,
  "optimized screenshots must remain staged until publication")
assert.match(screenshotWorkflow, /verify_postconditions\(\) \{[\s\S]*?verify-capture-postconditions[\s\S]*?initial_shell_pid[\s\S]*?original_dnd_state/,
  "verification mode must check untouched settings/history, DND, workspace, and shell identity")
for (const checkpoint of ["preview-enabled", "history-disabled"])
  assert.match(screenshotWorkflow, new RegExp(`capture_checkpoint [\"']?${checkpoint.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`),
    `capture must expose the ${checkpoint} interruption checkpoint`)
assert.match(capturePostconditions, /cmp -s "\$settings_snapshot" "\$settings_file"/,
  "successful capture must verify the original shell settings were restored byte-for-byte")
assert.match(screenshotWorkflow, /restore_desktop\(\) \{[\s\S]*?end_capture_preview[\s\S]*?restore_original_workspace/,
  "cleanup must clear in-memory preview state before restoring workspace")
assert.match(screenshotWorkflow, /cleanup_capture\(\) \{[\s\S]*?capture_failed == true \|\| \$cleanup_failed == true[\s\S]*?Preserved recovery snapshot[\s\S]*?rm -rf/,
  "capture or cleanup failures must preserve their private recovery snapshot")
assert.doesNotMatch(screenshotWorkflow, /omarchy restart shell|quickshell kill|omarchy-launch-shell/,
  "settings capture must not restart or replace the Quickshell process")
assert.match(screenshotWorkflow, /omarchy notification send[\s\S]*--app-name[\s\S]*Privacy Devices[\s\S]*--icon[\s\S]*firefox/,
  "screenshot workflow must trigger an app-icon notification")
assert.match(screenshotWorkflow, /notifications isDnd[\s\S]*notifications setDnd/,
  "screenshot workflow must preserve and temporarily normalize DND state")
assert.match(screenshotWorkflow, /notification_summary=.*Screenshot example[\s\S]*call notifications dismiss "\$notification_summary"/,
  "screenshot cleanup must dismiss its uniquely labeled toast through Omarchy IPC")
assert.match(screenshotWorkflow, /dismiss_result[\s\S]*!= ok[\s\S]*expire automatically/,
  "unsupported sample-toast dismissal must degrade to bounded automatic expiry")
assert.doesNotMatch(screenshotWorkflow, /dismiss_result[\s\S]{0,160}exit 1/,
  "notification cleanup limitations must not discard otherwise valid screenshots")
assert.match(screenshotWorkflow, /docs\/notification\.png/,
  "screenshot workflow must publish the notification capture")
assert.match(screenshotWorkflow, /wtype -k Return/, "device capture must use wtype's portable Enter key name")
assert.match(screenshotWorkflow, /call shell summon "\$plugin_id" ""/, "activity capture must explicitly summon the main widget view")
assert.match(screenshotWorkflow, /capture_panel\(\)[\s\S]*?call shell hide "\$plugin_id"[\s\S]*?settings\) qs ipc --pid "\$shell_pid" call privacy-devices-settings open "\$page"/,
  "settings capture must normalize popup state before opening each page")
assert.match(screenshotWorkflow, /function validate_capture|validate_capture\(\)/, "screenshot workflow must reject blank captures")
assert.match(screenshotWorkflow, /colors >= 8/, "capture validation must reject low-content images")
assert.match(screenshotWorkflow, /wait_for_shell\(\)[\s\S]*?for attempt in \{1\.\.40\}/,
  "capture must wait conditionally for a restarted shell instead of assuming startup duration")
assert.doesNotMatch(screenshotWorkflow, /omarchy-overlay\/shell\/shell\.qml/,
  "capture must not depend on a machine-specific shell config path")
assert.match(screenshotWorkflow, /shell_reply=.*call shell ping[\s\S]*?history_reply=.*call privacy-devices historyEnabled[\s\S]*?shell_reply == ok[\s\S]*?history_reply =~/,
  "capture must identify the target shell through its IPC capabilities")
assert.match(screenshotWorkflow, /qs list --all[\s\S]*sort -rn/,
  "capture must prefer the newest IPC-ready shell while an old instance retires")
assert.doesNotMatch(screenshotWorkflow, /sleep 6/,
  "capture must not rely on a fixed shell-startup delay")
assert.doesNotMatch(screenshotWorkflow, /date \+%s%3N/,
  "capture must not require GNU date millisecond extensions")
assert.match(screenshotWorkflow, /python3 -c 'import time; print\(time\.time_ns\(\) \/\/ 1_000_000\)'/,
  "capture must derive portable millisecond timestamps from Python")
assert.match(screenshotWorkflow, /capture_panel\(\)[\s\S]*?for attempt in \{1\.\.4\}[\s\S]*?capture_has_content/,
  "each popup capture must retry until its target crop contains real content")
assert.doesNotMatch(screenshotWorkflow.match(/capture_panel\(\) \{[\s\S]*?^\}/m)[0], /wait_for_shell/,
  "capture retries must remain pinned to the shell that owns the preview lease")
assert.ok(screenshotWorkflow.lastIndexOf("resolve_geometry", screenshotWorkflow.indexOf("capture_panel history history")) >= 0,
  "bar geometry must be resolved before long-running capture operations")
assert.match(service, /id:\s*fallbackObserverProc/, "process fallbacks must share one persistent structured observer")
assert.match(service, /Model\.classifyNode\(node, settings, pipewireClassificationPolicy\)/,
  "PipeWire classification must reuse normalized settings across stream nodes")
assert.match(service, /function handleFallbackSnapshot\(line\) \{[\s\S]*?fallbackObserverRetiring[\s\S]*?return/,
  "retired fallback observers must reject buffered output")
assert.match(service, /function handleDirectDeviceSnapshot\(text\) \{[\s\S]*?directObserverRetiring[\s\S]*?return/,
  "retired direct observers must reject buffered output")
assert.match(service, /"watch-fallbacks"/, "fallback observer must use the structured watch protocol")
assert.match(service, /settings\.recordingPollSeconds/, "the persistent fallback observer must honor the configured scan interval")
assert.doesNotMatch(service, /id:\s*(?:recordingProc|screenshotProc)/, "recording and screenshot detection must not spawn periodic QML processes")
assert.doesNotMatch(service, /id:\s*(?:recordingTimer|screenshotTimer)/, "persistent observation must replace recording and screenshot polling timers")
assert.match(service, /target:\s*"privacy-devices-settings"[\s\S]*?shell\.summon/, "singleton service must route settings to the focused monitor")
assert.match(service, /function openSection\(page: string, section: string\): string[\s\S]*?Model\.settingsDeepLink\(page, section\)[\s\S]*?requestedSettingsSection = target\.section[\s\S]*?shell\.summon/,
  "settings IPC must expose validated section deep links through focused-monitor routing")
assert.match(service, /function open\(page: string\): string[\s\S]*?requestedSettingsSection = ""/,
  "page-only IPC navigation must clear stale section targets")
assert.match(service, /function openHistory\(\): string[\s\S]*?requestedView = "history"[\s\S]*?shell\.summon/,
  "history IPC must use the singleton service's focused-monitor routing")
assert.doesNotMatch(bar, /target:\s*"privacy-devices-settings"/, "per-monitor widgets must not compete for settings IPC ownership")
assert.match(service, /id:\s*notificationFlush[\s\S]*?interval:\s*400/, "activity notifications must use a bounded coalescing window")
assert.match(service, /id:\s*activityBaseline[\s\S]*?interval:\s*5000[\s\S]*?activityInitialized = true/,
  "startup observations must settle into a silent baseline before notifications begin")
assert.doesNotMatch(service, /function refreshSessions\(\)[\s\S]*?activityInitialized = true[\s\S]*?function scheduleSessionRefresh/,
  "individual startup refreshes must not prematurely enable notifications")
assert.match(service, /Model\.publishableSessionTransitions\([^;]+activityInitialized\)/,
  "history and notifications must share the behavior-tested startup publication policy")
assert.match(service, /function beginControlTransaction\(kind, expectedEnabled\)[\s\S]*?Model\.controlTransactionTransition\(null, \{type: "begin", expectedEnabled: expectedEnabled\}/,
  "control requests must enter the behavior-tested reducer with their requested state")
assert.match(service, /function beginControlVerification\(kind, exitCode\)[\s\S]*?Model\.controlTransactionTransition\(current, \{type: "command", exitCode: exitCode\}/,
  "command results must enter the behavior-tested reducer")
assert.match(service, /function verifyControlTransaction\(kind, observedEnabled, probeValid\)[\s\S]*?transitionControlTransaction\(kind, \{type: "observation", enabled: observedEnabled, valid: probeValid\}\)/,
  "observations must verify controls through the behavior-tested reducer")
assert.match(service, /function requestPrivacyLockdown\(\)[\s\S]*?Model\.privacyPresetPlan\([\s\S]*?runNextPrivacyPreset\(\)/,
  "privacy lockdown must use the behavior-tested serial preset plan")
assert.match(service, /function restorePrivacyLockdown\(\)[\s\S]*?Model\.privacyPresetPlan\(privacyPresetEntries\(\), privacyPresetPrevious\)/,
  "privacy lockdown undo must derive restoration from observed prior state")
assert.match(service, /onControlTransactionsChanged:[\s\S]*?advancePrivacyPreset\(\)/,
  "preset orchestration must advance only after control transactions settle")
assert.match(service, /function policies\(\)[\s\S]*?sessionPolicies/,
  "runtime session consumers must share normalized app and device policy")
assert.match(service, /transitionControlTransaction\(kind, \{type: "timeout"\}, now\)/, "verification must delegate bounded timeout handling to the tested reducer")
assert.doesNotMatch(service, /fallbackMicrophoneMuted\s*=\s*!fallbackMicrophoneMuted/, "controls must preserve the last observed microphone state while verification is pending")
assert.doesNotMatch(service, /fallbackOutputMuted\s*=\s*!fallbackOutputMuted/, "controls must preserve the last observed output state while verification is pending")
assert.match(bar, /pixelAligned:\s*true/, "popup scrolling should remain pixel aligned")
assert.match(bar, /onMovementEnded:\s*root\.flushDeferredItems\(\)/, "deferred row updates must flush when scrolling ends")
assert.match(bar, /function syncDisplayedItems\(\)[\s\S]*?contentFlick\.moving && Model\.activityCriticalStateEquivalent\(displayedActivityItems, next\)/,
  "scroll deferral must use the behavior-tested critical-state policy")
assert.doesNotMatch(bar, /function activityStateChanged\(/,
  "QML must not retain a second untested presentation-state policy")
assert.match(bar, /onCloseRequested:\s*root\.closeCurrentLayer\(\)/, "Escape must invoke layered popup dismissal")
assert.match(bar, /function closeCurrentLayer\(\)[\s\S]*?Model\.popupDismissalAction\(editingKind, showingGlobalSettings, showingHistory\)/,
  "layered dismissal must use the behavior-tested priority policy")
assert.match(bar, /text: "Keyboard: ↑\/↓ select · Enter open · H history · S settings · R refresh · Esc close"/,
  "the activity footer must advertise every main-view keyboard command")
assert.match(bar, /tooltipText: "Activity history"[\s\S]*?tooltipText: "Global settings"/,
  "the history action must sit immediately left of global settings")
assert.match(bar, /function showHistory\(\)[\s\S]*?privacyService\.loadHistory\(\)/,
  "opening history must request persisted entries without polling")
assert.match(bar, /id:\s*historyView[\s\S]*?History is off[\s\S]*?Loading history[\s\S]*?No completed activity yet/,
  "history view must distinguish disabled, loading, and empty states")
assert.match(bar, /filteredHistory:\s*Model\.filterHistory\(privacyService \? privacyService\.displayHistory : \[\], historyQuery\)/,
  "history view must derive from the full service-bounded history")
assert.equal((bar.match(/"Clear history"/g) || []).length, 1,
  "history clearing must have one explicit home")
assert.match(bar, /id:\s*historySearch[\s\S]*?placeholderText:\s*"Search history"/,
  "history view must expose a local search field")
assert.match(bar, /id:\s*historyCountPill[\s\S]*?radius:\s*implicitHeight \/ 2[\s\S]*?Model\.historyCountLabel\(/,
  "history result counts must render as a labeled status pill")
assert.match(bar, /readonly property var filteredHistory:\s*Model\.filterHistory\(/,
  "history filtering must use the behavior-tested bounded model policy")
assert.match(bar, /model:\s*root\.filteredHistory/,
  "history delegates must render only filtered entries")
assert.match(bar, /No history matches your search\./,
  "history must distinguish a filtered-empty result from an empty store")
assert.match(bar, /Model\.historyPeriodLabel\(modelData\.endedAt, root\.durationNow\)/,
  "history entries must expose behavior-tested relative period groups")
assert.match(bar, /function requestHistoryClear\(\)[\s\S]*?confirmationState\.request\("history"\)[\s\S]*?privacyService\.clearHistory\(\)/,
  "destructive history clearing must use the runtime-tested confirmation controller")
assert.doesNotMatch(bar, /Activity details distinguish observation source/,
  "the activity footer must not retain displaced implementation guidance")
assert.match(bar, /onMoveRequested:[\s\S]*?dy !== 0[\s\S]*?moveActivitySelection\(dy\)/,
  "advertised vertical navigation must select activity rows")
assert.match(bar, /function moveActivitySelection\(delta\)[\s\S]*?Model\.nextNavigationKind\(kinds, selectedKind, delta\)/,
  "activity selection must use behavior-tested boundary handling")
assert.match(bar, /onActivateRequested:[\s\S]*?activateActivitySelection\(\)/,
  "the advertised Enter command must open the selected activity row")
assert.match(bar, /function activateActivitySelection\(\)[\s\S]*?Model\.activationKind\(kinds, selectedKind\)/,
  "activity activation must reject stale selections through the tested policy")
assert.match(bar, /text === "s" \|\| text === "S"[\s\S]*?showGlobalSettings\("general"\)/,
  "the advertised S command must open settings")
assert.match(bar, /text === "r" \|\| text === "R"[\s\S]*?refreshFallbacks\(\)/,
  "the advertised R command must request an observer refresh")
assert.match(bar, /readonly property var activitySourceItems:\s*orderedKinds\(\)\.map/, "bar device state must be built once per reactive update")
assert.match(bar, /readonly property var visibleItems:\s*activitySourceItems\.filter/, "visible bar state must derive from the shared device snapshot")
assert.match(bar, /readonly property var activeItemList:\s*visibleItems\.filter/, "active bar state must be cached for all consumers")
assert.match(bar, /readonly property int activeCount:\s*activeItemList\.length/, "active count must not allocate another filtered list")
assert.doesNotMatch(bar, /function buildVisibleItems\(/, "bar rendering must not independently rebuild device state")

assert.match(service, /readonly property var enabledKindList:\s*Model\.arraySetting\(settings\.enabledKinds, Model\.KINDS\)/,
  "enabled kinds must be normalized once per settings update")
assert.match(service, /function enabledKinds\(\)\s*{\s*return enabledKindList\s*}/,
  "hot service paths must reuse normalized enabled kinds")
assert.match(service, /id:\s*preventativeControlTimer[\s\S]*?running:\s*root\.preventativeProbeKinds\.length > 0/,
  "preventative control polling must sleep when no enabled kind supports it")
assert.match(service, /id:\s*muteRefreshTimer[\s\S]*?running:\s*root\.audioMonitoringEnabled/,
  "mute polling must sleep when audio devices are disabled")
assert.match(service, /readonly property var notificationKindList:\s*Model\.arraySetting\(/,
  "notification filtering must reuse normalized settings")
assert.match(service, /readonly property var sessionPolicies:\s*\(\{/,
  "session policy arrays must be normalized once per settings update")
assert.match(service, /id:\s*sessionSafetyTimer[\s\S]*?running:\s*root\.enabledKindList\.length > 0/,
  "safety reconciliation must sleep when monitoring is disabled")
assert.match(service, /id:\s*dependencyRefreshTimer[\s\S]*?running:\s*root\.enabledKindList\.length > 0/,
  "dependency polling must sleep when no devices are enabled")
assert.match(service, /function refreshDependencies\(\)[\s\S]*?Model\.scheduleProbeRefresh\(dependencyCheckProc\.running, enabledKinds\(\)\)/,
  "dependency refreshes must use the behavior-tested supersession policy")
assert.match(service, /function runNextDependencyCheck\(\)[\s\S]*?Model\.nextProbeAction\(dependencyQueue, dependencyRefreshPending, dependencyCheckProc\.running\)/,
  "dependency workers must use the behavior-tested FIFO policy")

for (const signal of [
  "onObservedPipewireSessionsChanged", "onLocationAppsChanged", "onLocationActiveChanged",
  "onRecordingAppsChanged", "onRecordingActiveChanged", "onScreenshotActiveChanged",
  "onDirectObservationsChanged"
]) {
  assert.match(service, new RegExp(`${signal}:\\s*scheduleSessionRefresh\\(\\)`), `${signal} must schedule reconciliation`)
}

assert.match(service, /id:\s*sessionRefreshDebounce[\s\S]*?interval:\s*150[\s\S]*?onTriggered:\s*root\.refreshSessions\(\)/)
assert.match(service, /interval:\s*15000[\s\S]*?onTriggered:\s*root\.refreshSessions\(\)/,
  "a slow safety reconciliation must cover backends with incomplete change signals")
assert.doesNotMatch(service, /interval:\s*1000[\s\S]{0,100}?onTriggered:\s*root\.refreshSessions\(\)/,
  "session discovery must not continuously rebuild from a one-second poll")
assert.match(service, /"omarchy",\s*"notification",\s*"send"/,
  "notifications must use Omarchy's DND-aware notification path")
assert.match(service, /Quickshell\.iconPath\([^,]+,\s*true\)/,
  "notification icons must be verified against the active icon theme")
assert.match(service, /resolvedNotificationIcon\([^,]+,\s*[^)]+\)[\s\S]*?candidates/,
  "an unavailable application icon must retry a device or service fallback")
assert.match(service, /--icon/,
  "resolved application or service icons must be sent with notifications")
assert.match(service, /props\["application\.icon-name"\]/,
  "PipeWire application icon metadata must reach the notification pipeline")
assert.match(service, /"watch",\s*"--heartbeat"/, "direct-device monitoring must use one persistent observer")
assert.match(service, /directObserverRetryMilliseconds[\s\S]*?Math\.min\([^\n]*60000\)/,
  "observer restart backoff must be bounded at 60 seconds")
assert.match(service, /Model\.observerHeartbeatState\(root\.directObserverLastSeen, root\.directObserverStartedAt, Date\.now\(\), heartbeat\)\.stale/,
  "direct observation must apply startup grace and last-seen state through the tested heartbeat policy")
assert.match(service, /Model\.observerHeartbeatState\(root\.fallbackObserverLastSeen, root\.fallbackObserverStartedAt, Date\.now\(\), heartbeat\)\.stale/,
  "fallback observation must apply startup grace and last-seen state through the tested heartbeat policy")
assert.match(service, /function setObserverHealth\(source, status, code, reason\)[\s\S]*?Model\.updateObserverHealth\(/,
  "observer health mutation must use the behavior-tested idempotent policy")
assert.doesNotMatch(service, /directDeviceTimer/, "removed polling timer must not remain referenced")
assert.match(service, /function clearDirectObserverState\(\)[\s\S]*?directObservations = \[\]/,
  "direct observer failure must discard stale active-device observations")
assert.match(service, /function clearDirectObserverState\(\)[\s\S]*?discardObserverSessions\("direct-device"\)/,
  "direct observer loss must invalidate sessions outside normal stop transitions")
assert.match(service, /function clearDirectObserverState\(\)[\s\S]*?if \(directObservations\.length\) directObservations = \[\]/,
  "repeated direct-observer degradation must not emit empty-array churn")
assert.match(service, /function clearFallbackObserverState\(\)[\s\S]*?recordingActive = false[\s\S]*?screenshotActive = false/,
  "fallback observer failure must discard stale capture observations")
assert.match(service, /function clearFallbackObserverState\(\)[\s\S]*?discardObserverSessions\("process-probe"\)/,
  "fallback observer loss must invalidate sessions outside normal stop transitions")
assert.match(service, /function clearFallbackObserverState\(\)[\s\S]*?if \(recordingApps\.length\) recordingApps = \[\]/,
  "repeated fallback degradation must not emit empty-array churn")
assert.match(service, /id:\s*fallbackObserverHeartbeat[\s\S]*?fallback observer heartbeat is stale/,
  "fallback process observation must have heartbeat health coverage")
assert.match(service, /payload\.type !== "fallback-snapshot"[\s\S]*?throw new Error/,
  "structurally invalid fallback payloads must degrade observer health")
assert.match(service, /result\.type !== "snapshot"[\s\S]*?throw new Error/,
  "structurally invalid direct payloads must degrade observer health")
assert.match(service, /id:\s*directDeviceProc[\s\S]*?clearDirectObserverState\(\)[\s\S]*?observer_exited/,
  "unexpected direct observer exit must clear observations before reporting failure")
assert.match(service, /id:\s*fallbackObserverProc[\s\S]*?clearFallbackObserverState\(\)[\s\S]*?observer_exited/,
  "unexpected fallback observer exit must clear observations before reporting failure")
assert.match(service, /kind === "screen-recording" \|\| kind === "screenshot"[\s\S]*?observerHealth\["fallback-observer"\]/,
  "capture health must include its observer state")
assert.match(service, /function discardObserverSessions\(source\)[\s\S]*?Model\.invalidateObserverSessions\(activeSessions, source, suppressedObserverStarts\)/,
  "observer invalidation must remember uncertain sessions across recovery")
assert.match(service, /function handleSessionTransitions\(transition\)[\s\S]*?Model\.partitionObserverRecoveryStarts\(transition\.started, suppressedObserverStarts\)/,
  "observer recovery must not announce uncertain sessions as new activity")
assert.match(service, /function serviceControllable\(kind\)[\s\S]*?\["microphone", "audio-output", "camera", "screen-share", "location"\]/,
  "headless control must be limited to actions owned by the singleton service")
assert.match(service, /function toggleControl\(kind\)[\s\S]*?if \(controlRequestStatus\(kind\) !== "ok"\) return false/,
  "control requests must reject disabled, unsupported, and pending devices")
assert.match(service, /function controlRequestStatus\(kind\)[\s\S]*?Model\.controlRequestStatus\(/,
  "runtime control state must use the behavior-tested request policy")
assert.match(service, /function toggle\(kind: string\): string[\s\S]*?root\.controlRequestStatus\(kind\)/,
  "control IPC must report why an action was not accepted")
assert.match(bar, /function toggleEntry\(entry\)[\s\S]*?if \(!privacyService \|\| !entry\.controllable \|\| entry\.pending\) return/,
  "bar controls must ignore repeated input while verification is pending")
assert.match(bar, /function itemTooltip\(entry\)[\s\S]*?var action = Model\.itemTooltipAction\(entry\)/,
  "bar action guidance must use the behavior-tested device policy")
assert.doesNotMatch(bar, /function controlDescription\(/, "unused duplicate control guidance must not return")
assert.match(bar, /if \(!privacyService\.beginExternalControl\("screen-recording", !entry\.controlEnabled\)\) return/,
  "recording commands must not run unless their transaction is accepted")
assert.match(service, /function refreshPreventativeControls\(\)[\s\S]*?Model\.scheduleProbeRefresh\(busy, preventativeProbeKinds\)/,
  "preventative refreshes must use the behavior-tested supersession policy")
assert.match(service, /function runNextPrivacyState\(\)[\s\S]*?Model\.nextProbeAction\(privacyStateQueue, privacyStateRefreshPending, privacyStateProc\.running\)/,
  "preventative workers must use the behavior-tested FIFO policy")
assert.match(service, /readonly property bool audioMonitoringEnabled:[\s\S]*?controlPending\("microphone"\)[\s\S]*?controlPending\("audio-output"\)/,
  "audio verification probes must survive device monitoring changes")
assert.match(service, /readonly property var preventativeProbeKinds:[\s\S]*?controlPending\(kind\)/,
  "preventative verification probes must survive device monitoring changes")
assert.match(service, /id:\s*preventativeControlTimer[\s\S]*?running:\s*root\.preventativeProbeKinds\.length > 0/,
  "preventative polling must remain active only for enabled or verifying kinds")
assert.match(service, /property int historyGeneration:\s*0[\s\S]*?property int historyLoadGeneration:\s*0/,
  "history loads must be tied to the privacy configuration that requested them")
assert.match(service, /function clearHistory\(\)[\s\S]*?historyGeneration\+\+/,
  "clearing history must invalidate an in-flight load")
assert.match(service, /id:\s*historyLoadProc[\s\S]*?Model\.historyLoadAccepted\(root\.historyLoadGeneration, root\.historyGeneration, root\.settings\.historyEnabled\)[\s\S]*?recentHistory = \[\]/,
  "stale history output must not repopulate private data after history is disabled or cleared")
assert.match(service, /id:\s*historyLoadOutput[\s\S]*?onStreamFinished:\s*\{[\s\S]*?JSON\.parse\(String\(historyLoadOutput\.text \|\| "\[\]"\)\)/,
  "history loading must parse the collector property exposed by Quickshell")
assert.doesNotMatch(service, /id:\s*historyLoadProc[\s\S]*?onStreamFinished:\s*function\(text\)/,
  "history loading must not assume the completion signal passes collected text")
assert.match(service, /id:\s*dependencyCheckProc[\s\S]*?if \(!root\.dependencyRefreshPending\)[\s\S]*?dependencyReadyMap = ready/,
  "superseded dependency results must not be published")

console.log("runtime behavior contract tests passed")

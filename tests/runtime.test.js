const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")

const service = fs.readFileSync(path.join(__dirname, "..", "Service.qml"), "utf8")
const screenshotWorkflow = fs.readFileSync(path.join(__dirname, "..", "scripts/capture-screenshots"), "utf8")
const bar = fs.readFileSync(path.join(__dirname, "..", "BarWidget.qml"), "utf8")

assert.match(service, /function monitoringTelemetry\(\)[\s\S]*?Model\.freshnessAgeSeconds\(/,
  "monitoring telemetry must use the behavior-tested freshness policy")
assert.match(service, /requestedSettingsPage = Model\.settingsPage\(page\)/, "settings IPC pages must pass through the shared allowlist")
assert.match(screenshotWorkflow, /trap restore_desktop EXIT INT TERM/, "screenshot capture must restore the user's workspace on failure")
assert.match(screenshotWorkflow, /window_count == 0/, "screenshot capture must reject workspaces containing user windows")
assert.match(screenshotWorkflow, /debugBarGeometry/, "bar screenshots must use measured live widget geometry")
assert.ok(fs.statSync(path.join(__dirname, "..", "scripts/capture-screenshots")).mode & 0o111,
  "screenshot workflow must remain executable")
assert.match(service, /id:\s*fallbackObserverProc/, "process fallbacks must share one persistent structured observer")
assert.match(service, /"watch-fallbacks"/, "fallback observer must use the structured watch protocol")
assert.match(service, /settings\.recordingPollSeconds/, "the persistent fallback observer must honor the configured scan interval")
assert.doesNotMatch(service, /id:\s*(?:recordingProc|screenshotProc)/, "recording and screenshot detection must not spawn periodic QML processes")
assert.doesNotMatch(service, /id:\s*(?:recordingTimer|screenshotTimer)/, "persistent observation must replace recording and screenshot polling timers")
assert.match(service, /target:\s*"privacy-devices-settings"[\s\S]*?shell\.summon/, "singleton service must route settings to the focused monitor")
assert.doesNotMatch(bar, /target:\s*"privacy-devices-settings"/, "per-monitor widgets must not compete for settings IPC ownership")
assert.match(service, /id:\s*notificationFlush[\s\S]*?interval:\s*400/, "activity notifications must use a bounded coalescing window")
assert.match(service, /function beginControlTransaction\(kind, expectedEnabled\)[\s\S]*?Model\.controlTransactionTransition\(null, \{type: "begin", expectedEnabled: expectedEnabled\}/,
  "control requests must enter the behavior-tested reducer with their requested state")
assert.match(service, /function beginControlVerification\(kind, exitCode\)[\s\S]*?Model\.controlTransactionTransition\(current, \{type: "command", exitCode: exitCode\}/,
  "command results must enter the behavior-tested reducer")
assert.match(service, /function verifyControlTransaction\(kind, observedEnabled, probeValid\)[\s\S]*?transitionControlTransaction\(kind, \{type: "observation", enabled: observedEnabled, valid: probeValid\}\)/,
  "observations must verify controls through the behavior-tested reducer")
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
assert.match(bar, /function closeCurrentLayer\(\)[\s\S]*?Model\.popupDismissalAction\(editingKind, showingGlobalSettings\)/,
  "layered dismissal must use the behavior-tested priority policy")
assert.match(bar, /text: "Keyboard: ↑\/↓ select · Enter open · S settings · R refresh · Esc close"/,
  "the activity footer must advertise every main-view keyboard command")
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
assert.match(service, /id:\s*dependencyCheckProc[\s\S]*?if \(!root\.dependencyRefreshPending\)[\s\S]*?dependencyReadyMap = ready/,
  "superseded dependency results must not be published")

console.log("runtime behavior contract tests passed")

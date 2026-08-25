const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")

const service = fs.readFileSync(path.join(__dirname, "..", "Service.qml"), "utf8")
const bar = fs.readFileSync(path.join(__dirname, "..", "BarWidget.qml"), "utf8")

assert.match(service, /function monitoringTelemetry\(\)/, "service must expose monitoring telemetry")
assert.match(service, /id:\s*fallbackObserverProc/, "process fallbacks must share one persistent structured observer")
assert.match(service, /"watch-fallbacks"/, "fallback observer must use the structured watch protocol")
assert.match(service, /settings\.recordingPollSeconds/, "the persistent fallback observer must honor the configured scan interval")
assert.doesNotMatch(service, /id:\s*(?:recordingProc|screenshotProc)/, "recording and screenshot detection must not spawn periodic QML processes")
assert.doesNotMatch(service, /id:\s*(?:recordingTimer|screenshotTimer)/, "persistent observation must replace recording and screenshot polling timers")
assert.match(service, /target:\s*"privacy-devices-settings"[\s\S]*?shell\.summon/, "singleton service must route settings to the focused monitor")
assert.doesNotMatch(bar, /target:\s*"privacy-devices-settings"/, "per-monitor widgets must not compete for settings IPC ownership")
assert.match(service, /id:\s*notificationFlush[\s\S]*?interval:\s*400/, "activity notifications must use a bounded coalescing window")
assert.match(service, /function beginControlTransaction\(kind, expectedEnabled\)[\s\S]*?function beginControlVerification\(kind, exitCode\)[\s\S]*?function verifyControlTransaction\(kind, observedEnabled, probeValid\)/, "controls must apply, probe, and verify explicit requested states")
assert.match(service, /transitionControlTransaction\(kind, \{type: "timeout"\}, now\)/, "verification must delegate bounded timeout handling to the tested reducer")
assert.match(service, /lastFallbackRefreshAt/, "fallback refresh freshness must be observable")
assert.match(bar, /pixelAligned:\s*true/, "popup scrolling should remain pixel aligned")
assert.match(bar, /onMovementEnded:\s*root\.flushDeferredItems\(\)/, "deferred row updates must flush when scrolling ends")
assert.match(bar, /function closeCurrentLayer\(\)/, "Escape must close the current UI layer")
assert.match(bar, /onMoveRequested:[\s\S]*?moveActivitySelection/, "activity rows must support keyboard navigation")
assert.match(bar, /onTextKey:[\s\S]*?globalSettingsPage/, "settings tabs must support keyboard shortcuts")

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
assert.match(service, /observer heartbeat is stale/, "missing observer heartbeats must degrade health")
assert.doesNotMatch(service, /directDeviceTimer/, "removed polling timer must not remain referenced")

console.log("runtime behavior contract tests passed")

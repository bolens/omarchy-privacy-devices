const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const source = fs.readFileSync(path.join(__dirname, "..", "Model.js"), "utf8").replace(/^\.pragma library\s*/, "")
const model = {}
vm.createContext(model)
vm.runInContext(source, model)

assert.deepEqual(JSON.parse(JSON.stringify(model.observerHeartbeatState(0, 0, 20_000, 2))), {
  stale: true, ageSeconds: -1, thresholdMilliseconds: 15_000
})

const withinStartupGrace = model.observerHeartbeatState(0, 1_000, 16_000, 2)
assert.equal(withinStartupGrace.stale, false, "the exact grace boundary remains healthy")
assert.equal(withinStartupGrace.ageSeconds, 15)

assert.equal(model.observerHeartbeatState(0, 1_000, 16_001, 2).stale, true,
  "startup becomes stale immediately after the grace boundary")
assert.equal(model.observerHeartbeatState(19_000, 1_000, 20_000, 2).stale, false,
  "a heartbeat supersedes the older process start time")
assert.equal(model.observerHeartbeatState(1_000, 1_000, 180_999, 60).stale, false,
  "configured slow heartbeats receive three intervals of grace")
assert.equal(model.observerHeartbeatState(1_000, 1_000, 181_001, 60).stale, true)
assert.equal(model.observerHeartbeatState(25_000, 1_000, 20_000, 2).ageSeconds, 0,
  "backward clock movement cannot produce a negative age")

assert.equal(model.freshnessAgeSeconds(0, 20_000), -1)
assert.equal(model.freshnessAgeSeconds(18_501, 20_000), 1)
assert.equal(model.freshnessAgeSeconds(25_000, 20_000), 0)

const initialHealth = {
  pipewire: {status: "healthy", source: "pipewire", code: "ok", reason: ""},
  watcher: {status: "healthy", source: "watcher", code: "ok", reason: ""}
}
const unchangedHealth = model.updateObserverHealth(initialHealth, "watcher", "healthy", "ok", "")
assert.equal(unchangedHealth, initialHealth, "identical health does not churn reactive consumers")
const degradedHealth = model.updateObserverHealth(initialHealth, "watcher", "degraded", "late", "heartbeat missed")
assert.notEqual(degradedHealth, initialHealth)
assert.equal(degradedHealth.pipewire, initialHealth.pipewire, "unrelated source state retains identity")
assert.deepEqual(JSON.parse(JSON.stringify(degradedHealth.watcher)), {
  status: "degraded", source: "watcher", code: "late", reason: "heartbeat missed"
})

assert.equal(model.monitoringTelemetryText(null), "Monitoring telemetry unavailable")
assert.equal(model.monitoringTelemetryText({
  pipewireReactive: true,
  lastSessionRefreshAgeSeconds: 3,
  lastFallbackRefreshAgeSeconds: 2,
  fallbackObserverRunning: true,
  fallbackObserverHeartbeatAgeSeconds: 1,
  fallbackObserverRetryMilliseconds: 1000,
  directDeviceEnabled: true,
  directObserverRunning: false,
  directHeartbeatAgeSeconds: -1,
  directObserverRetryMilliseconds: 4000
}), [
  "PipeWire: reactive",
  "Session state: 3s ago",
  "Fallback probes: 2s ago · observer running · heartbeat 1s ago · retry 1000ms",
  "Direct-device observer: retrying · heartbeat waiting · retry 4000ms"
].join("\n"))

assert.equal(model.monitoringTelemetryText({
  pipewireReactive: false,
  lastSessionRefreshAgeSeconds: NaN,
  lastFallbackRefreshAgeSeconds: undefined,
  fallbackObserverRunning: false,
  fallbackObserverHeartbeatAgeSeconds: -1,
  fallbackObserverRetryMilliseconds: undefined,
  directDeviceEnabled: false
}), [
  "PipeWire: unavailable",
  "Session state: waiting",
  "Fallback probes: waiting · observer retrying · heartbeat waiting · retry unknown",
  "Direct-device observer: disabled"
].join("\n"), "missing telemetry must produce stable human-readable fallbacks")

console.log("monitoring policy tests passed")

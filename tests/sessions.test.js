const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const source = fs.readFileSync(path.join(__dirname, "..", "Model.js"), "utf8").replace(/^\.pragma library\s*/, "")
const model = {}
vm.createContext(model)
vm.runInContext(source, model)

const observation = (overrides = {}) => Object.assign({
  kind: "microphone",
  application: "Firefox",
  device: "Built-in Audio",
  source: "pipewire",
  confidence: "confirmed"
}, overrides)

{
  const first = model.reconcileSessions([], [observation()], 1_000)
  assert.equal(first.active.length, 1)
  assert.equal(first.started.length, 1)
  assert.equal(first.stopped.length, 0)
  assert.equal(first.active[0].startedAt, 1_000)
  assert.equal(first.active[0].id, '["microphone","firefox","built-in audio","pipewire"]')

  const continued = model.reconcileSessions(first.active, [observation()], 9_000)
  assert.equal(continued.started.length, 0)
  assert.equal(continued.stopped.length, 0)
  assert.equal(continued.active[0].startedAt, 1_000, "ongoing sessions retain their real start time")

  const stopped = model.reconcileSessions(continued.active, [], 12_000)
  assert.equal(stopped.active.length, 0)
  assert.equal(stopped.stopped.length, 1)
  assert.equal(stopped.stopped[0].endedAt, 12_000)
  assert.equal(stopped.stopped[0].durationMs, 11_000)
}

{
  const stopped = model.reconcileSessions([{id: "zero", kind: "camera", application: "OBS", startedAt: 0}], [], 5_000).stopped
  assert.equal(stopped[0].durationMs, 5_000, "a zero timestamp is not mistaken for missing data")
}

{
  const sessions = model.reconcileSessions([], [
    observation(),
    observation({device: "USB Headset"}),
    observation({application: "OBS", kind: "camera", device: "USB Camera"})
  ], 20_000).active
  assert.equal(sessions.length, 3, "simultaneous devices and applications remain distinct")
  assert.deepEqual(Array.from(model.applicationsForSessions(sessions, "microphone")), ["Firefox"])
  assert.deepEqual(Array.from(model.applicationsForSessions(sessions, "microphone", false)), ["Firefox", "Firefox"])
}

{
  const sessions = [
    observation({application: "Noise Suppression"}),
    observation({application: "Firefox"})
  ]
  const policies = {
    hiddenApps: ["noise suppression"],
    notificationSuppressedApps: ["firefox"]
  }
  assert.deepEqual(Array.from(model.visibleSessions(sessions, policies).map(x => x.application)), ["Firefox"])
  assert.equal(model.shouldNotifyForSession(sessions[0], policies), true, "hiding does not silently suppress alerts")
  assert.equal(model.shouldNotifyForSession(sessions[1], policies), false)
  assert.deepEqual(Array.from(model.filterAttribution([
    observation({application: "Confirmed", confidence: "confirmed"}),
    observation({application: "Heuristic", confidence: "inferred"})
  ], false).map(x => x.application)), ["Confirmed"], "attribution can be hidden without removing the underlying activity session")
}

{
  const hostile = model.reconcileSessions([], [observation({
    application: "A\u0000B" + "x".repeat(400),
    device: "D\n" + "y".repeat(700),
    detail: "z".repeat(700),
    icon: "/home/user/private.png"
  })], 1_000).active[0]
  assert.equal(hostile.application.includes("\u0000"), false, "session application text strips controls")
  assert.ok(Array.from(hostile.application).length <= 256, "session application text is bounded")
  assert.ok(Array.from(hostile.device).length <= 512, "session device text is bounded")
  assert.ok(Array.from(hostile.detail).length <= 512, "session detail text is bounded")
  assert.equal(hostile.icon, "", "session icon metadata cannot select arbitrary files")
  assert.equal(hostile.id, model.sessionId(hostile), "session identity uses the bounded representation")
  assert.equal(model.reconcileSessions([], [observation({icon: "org.mozilla.firefox"})], 1_000).active[0].icon,
    "org.mozilla.firefox", "safe themed icon identifiers survive normalization")
}

{
  assert.equal(model.aggregateHealth([{status: "healthy"}, {status: "healthy"}]).status, "healthy")
  const partial = model.aggregateHealth([
    {status: "healthy", source: "pipewire"},
    {status: "degraded", source: "direct-device", reason: "helper exited"}
  ])
  assert.equal(partial.status, "degraded")
  assert.match(partial.summary, /direct-device.*helper exited/)
  assert.equal(model.aggregateHealth([{status: "unavailable", source: "pipewire", reason: "not running"}]).status, "unavailable")
}

{
  let history = []
  for (let index = 0; index < 105; index++) {
    history = model.appendHistory(history, Object.assign(observation({application: `App ${index}`}), {
      startedAt: index * 1_000,
      endedAt: index * 1_000 + 500
    }), 200_000, {maxEntries: 100, maxAgeMs: 170_000})
  }
  assert.equal(history.length, 75, "both count and age limits are enforced")
  assert.equal(history[0].application, "App 104", "newest history appears first")
  assert.equal(history.at(-1).application, "App 30")
  assert.equal(model.formatDuration(3_723_000), "1h 2m")
  assert.equal(model.formatDuration(12_000), "12s")
}

{
  const observations = Array.from({length: 5_000}, (_, index) => observation({
    application: `Application ${index}`,
    device: `Device ${index % 8}`
  }))
  const before = process.hrtime.bigint()
  const first = model.reconcileSessions([], observations, 1_000)
  const continued = model.reconcileSessions(first.active, observations, 2_000)
  const elapsedMs = Number(process.hrtime.bigint() - before) / 1_000_000
  assert.equal(continued.active.length, 5_000)
  assert.equal(continued.started.length, 0)
  assert.ok(elapsedMs < 500, `5,000-session reconciliation took ${elapsedMs.toFixed(1)}ms`)
}

{
  const grouped = model.coalesceNotificationEvents([
    {phase: "started", kind: "camera", application: "Firefox", icon: "firefox"},
    {phase: "started", kind: "microphone", application: "Firefox", icon: "firefox"},
    {phase: "started", kind: "camera", application: "Firefox", icon: "firefox"}
  ])
  assert.equal(grouped.title, "Privacy activity started")
  assert.equal(grouped.body, "Firefox: Camera, Microphone")
  assert.equal(grouped.count, 2, "duplicate transitions are collapsed")
  assert.equal(grouped.icon, "firefox", "a single application's themed icon is retained")
  assert.equal(grouped.fallbackIcon, "security-high-symbolic",
    "multi-device activity retains a resolvable privacy fallback")

  const mixed = model.coalesceNotificationEvents([
    {phase: "started", kind: "camera", application: "Firefox", icon: "firefox"},
    {phase: "started", kind: "microphone", application: "Calls", icon: "calls"}
  ])
  assert.equal(mixed.icon, "security-high-symbolic", "multi-app bursts use a neutral privacy icon")
  assert.equal(mixed.fallbackIcon, "security-high-symbolic")
  assert.equal(model.notificationIconName("../../private/icon"), "", "icon metadata cannot select paths")
  assert.equal(model.notificationIconName("org.mozilla.firefox"), "org.mozilla.firefox")
}

{
  const sessions = [
    Object.assign(observation({source: "pipewire"}), {id: "pipewire"}),
    Object.assign(observation({source: "direct-device"}), {id: "direct"})
  ]
  const invalidated = model.invalidateObserverSessions(sessions, "direct-device", {})
  assert.deepEqual(Array.from(invalidated.active.map(session => session.id)), ["pipewire"])
  assert.equal(invalidated.changed, true)
  assert.equal(invalidated.suppressedSources["direct-device"], true)

  const recovery = model.partitionObserverRecoveryStarts([
    observation({source: "direct-device", application: "Recovered one"}),
    observation({source: "direct-device", application: "Recovered two"}),
    observation({source: "pipewire", application: "New stream"})
  ], invalidated.suppressedSources)
  assert.deepEqual(Array.from(recovery.notifyable.map(session => session.application)), ["New stream"])
  assert.deepEqual(JSON.parse(JSON.stringify(recovery.suppressedSources)), {})

  const unchanged = model.invalidateObserverSessions(invalidated.active, "direct-device", recovery.suppressedSources)
  assert.equal(unchanged.changed, false, "repeated observer invalidation is allocation-free")
  assert.equal(unchanged.active, invalidated.active)
}

console.log("session model tests passed")

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
  const duplicate = Object.assign({}, history[0])
  assert.equal(model.appendHistory(history, duplicate, 200_000, {maxEntries: 100, maxAgeMs: 170_000}).length, history.length,
    "replayed history entries must not create duplicates")
  assert.equal(model.formatDuration(3_723_000), "1h 2m")
  assert.equal(model.formatDuration(12_000), "12s")
  assert.equal(model.historyAgeLabel(199_000, 200_000), "Just now")
  assert.equal(model.historyAgeLabel(80_000, 200_000), "2m ago")
  assert.equal(model.historyAgeLabel(20_000, 7_220_000), "2h ago")
  assert.equal(model.historyAgeLabel(20_000, 180_020_000), "2d ago")
  assert.equal(model.historyAgeLabel(210_000, 200_000), "Just now", "clock skew must not produce a negative age")

  const searchable = [
    {kind: "microphone", application: "Firefox", device: "USB Mic", source: "pipewire", confidence: "confirmed", endedAt: 300_000},
    {kind: "screen-share", application: "Chromium", device: "Desktop portal", source: "portal", confidence: "inferred", endedAt: 200_000},
    {kind: "camera", application: "OBS Studio", device: "Webcam", source: "pipewire", confidence: "confirmed", endedAt: 100_000}
  ]
  assert.equal(model.filterHistory(searchable, " FIREfox ").length, 1, "search is normalized and case-insensitive")
  assert.equal(model.filterHistory(searchable, "usb mic")[0].application, "Firefox", "search includes devices")
  assert.equal(model.filterHistory(searchable, "screen sharing")[0].application, "Chromium", "search includes friendly activity labels")
  assert.equal(model.filterHistory(searchable, "confirmed").length, 2, "search includes confidence provenance")
  assert.equal(model.filterHistory(searchable, "").length, 3, "an empty query preserves all bounded entries")
  assert.doesNotThrow(() => model.filterHistory([null, {}], "camera"), "partial stored rows cannot break filtering")

  const day = 24 * 60 * 60 * 1000
  assert.equal(model.historyPeriodLabel(10 * day - 1000, 10 * day), "Today")
  assert.equal(model.historyPeriodLabel(10 * day - day - 1000, 10 * day), "Yesterday")
  assert.equal(model.historyPeriodLabel(10 * day - 3 * day, 10 * day), "Earlier this week")
  assert.equal(model.historyClearAction(false), "confirm")
  assert.equal(model.historyClearAction(true), "clear")
  assert.equal(model.historyCountLabel(1, 1), "1 entry")
  assert.equal(model.historyCountLabel(3, 3), "3 entries")
  assert.equal(model.historyCountLabel(2, 8), "2 of 8")
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
  const transition = {started: [{id: "existing"}], stopped: [{id: "ended"}]}
  assert.equal(JSON.stringify(model.publishableSessionTransitions(transition, false)), JSON.stringify({started: [], stopped: []}),
    "sessions discovered during startup must establish a silent baseline")
  assert.equal(JSON.stringify(model.publishableSessionTransitions(transition, true)), JSON.stringify(transition),
    "transitions after startup must remain publishable")
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

const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const source = fs.readFileSync(path.join(__dirname, "..", "Model.js"), "utf8").replace(/^\.pragma library\s*/, "")
const model = {}
vm.createContext(model)
vm.runInContext(source, model)

function item(kind, overrides = {}) {
  return Object.assign({
    kind,
    active: false,
    controlEnabled: true,
    pending: false,
    health: {status: "healthy"},
    apps: [],
    sessions: []
  }, overrides)
}

assert.equal(model.activityCriticalStateEquivalent([], []), true)
assert.equal(model.activityCriticalStateEquivalent([item("camera")], [
  item("camera", {apps: ["Browser"], sessions: [{lastSeenAt: 99}], durationMs: 5_000})
]), true, "text, session, and duration churn may be deferred while scrolling")

for (const changed of [
  item("camera", {active: true}),
  item("camera", {controlEnabled: false}),
  item("camera", {pending: true}),
  item("camera", {health: {status: "degraded"}})
]) {
  assert.equal(model.activityCriticalStateEquivalent([item("camera")], [changed]), false,
    "privacy state changes must render immediately")
}

assert.equal(model.activityCriticalStateEquivalent(
  [item("camera"), item("location")],
  [item("location"), item("camera")]
), false, "order changes must render immediately")
assert.equal(model.activityCriticalStateEquivalent([item("camera")], []), false)
assert.equal(model.activityCriticalStateEquivalent(null, []), true, "invalid snapshots normalize to an empty view")
assert.equal(model.activityCriticalStateEquivalent([item("camera")], [{kind: "camera"}]), false,
  "incomplete state cannot be mistaken for a stable privacy state")

const diagnostics = model.deviceDiagnosticPresentation({
  backend: "GeoClue",
  dependenciesReady: false,
  dependencyDescription: "Polkit missing",
  health: {status: "degraded", summary: "observer late"},
  active: true,
  apps: ["Maps"],
  controlState: "Allowed",
  controlTransaction: {status: "verifying", code: "command_ok"},
  probeExitCode: -1,
  controlExitCode: 7
})
assert.equal(diagnostics.healthStatus, "degraded")
assert.equal(diagnostics.dependenciesReady, false)
assert.deepEqual(JSON.parse(JSON.stringify(diagnostics.rows)), [
  {label: "Backend", value: "GeoClue", urgent: false},
  {label: "Dependencies", value: "Polkit missing", urgent: true},
  {label: "Monitoring", value: "degraded · observer late", urgent: true},
  {label: "Activity", value: "Active", urgent: false},
  {label: "Applications", value: "Maps", urgent: false},
  {label: "Control", value: "Allowed · Transaction: verifying (command_ok)", urgent: false},
  {label: "Exit codes", value: "Probe not run · Control 7", urgent: false}
])

const emptyDiagnostics = model.deviceDiagnosticPresentation({})
assert.equal(emptyDiagnostics.healthStatus, "unavailable")
assert.equal(emptyDiagnostics.dependenciesReady, false)
assert.equal(emptyDiagnostics.rows[4].value, "None detected")
assert.equal(emptyDiagnostics.rows[5].value, "Unavailable · Transaction: None")
assert.equal(emptyDiagnostics.rows[6].value, "Probe not run · Control not used")

console.log("presentation policy tests passed")

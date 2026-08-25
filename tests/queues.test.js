const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const source = fs.readFileSync(path.join(__dirname, "..", "Model.js"), "utf8").replace(/^\.pragma library\s*/, "")
const model = {}
vm.createContext(model)
vm.runInContext(source, model)

function plain(value) {
  return JSON.parse(JSON.stringify(value))
}

const requested = ["camera", "location"]
const scheduled = model.scheduleProbeRefresh(false, requested)
assert.deepEqual(plain(scheduled), {
  queue: ["camera", "location"],
  refreshPending: false
})
assert.notEqual(scheduled.queue, requested, "the runtime queue must not mutate its reactive source array")

assert.deepEqual(plain(model.scheduleProbeRefresh(true, requested)), {
  queue: [],
  refreshPending: true
}, "a refresh during an active probe supersedes stale queued work")

assert.deepEqual(plain(model.nextProbeAction(["camera", "location"], true, true)), {
  action: "wait",
  kind: "",
  queue: ["camera", "location"],
  refreshPending: true
}, "an active process preserves both queued work and a pending refresh")

assert.deepEqual(plain(model.nextProbeAction(["camera", "location"], true, false)), {
  action: "probe",
  kind: "camera",
  queue: ["location"],
  refreshPending: true
}, "idle workers consume probe kinds in FIFO order without losing a newer refresh")

assert.deepEqual(plain(model.nextProbeAction([], true, false)), {
  action: "refresh",
  kind: "",
  queue: [],
  refreshPending: true
}, "an empty stale queue requests one coalesced refresh")

assert.deepEqual(plain(model.nextProbeAction([], false, false)), {
  action: "idle",
  kind: "",
  queue: [],
  refreshPending: false
})

assert.deepEqual(plain(model.nextProbeAction(null, false, false)), {
  action: "idle",
  kind: "",
  queue: [],
  refreshPending: false
}, "invalid queue state fails closed instead of starting an undefined probe")

console.log("probe queue policy tests passed")

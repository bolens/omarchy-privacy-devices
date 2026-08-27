const assert = require("node:assert/strict")
const {spawnSync} = require("node:child_process")
const path = require("node:path")

const helper = path.join(__dirname, "..", "scripts", "select-capture-monitor")
const monitors = [
  {id: 0, name: "DP-3", focused: false, x: 0, y: 0, width: 2560, height: 1440},
  {id: 1, name: "DP-1", focused: true, x: -3440, y: 0, width: 3440, height: 1440}
]

function select(active, cursor, rows = monitors) {
  return spawnSync(helper, [JSON.stringify({active, monitors: rows, cursor})], {encoding: "utf8"})
}

let result = select({monitor: 0}, {x: -1000, y: 700})
assert.equal(result.status, 0)
assert.equal(result.stdout.trim(), "DP-3", "launching window must take precedence over the pointer")

result = select({}, {x: -1000, y: 700})
assert.equal(result.status, 0)
assert.equal(result.stdout.trim(), "DP-1", "pointer output must cover launchers without an active window")

result = select({}, {x: 9000, y: 9000})
assert.equal(result.status, 0)
assert.equal(result.stdout.trim(), "DP-1", "focused output must be the final bounded fallback")

for (const name of ["HDMI-A-1", "eDP-1", "DVI-D-1", "DP-2"]) {
  result = select({monitor: 7}, {x: 1, y: 1}, [{id: 7, name, focused: true, x: 0, y: 0, width: 1920, height: 1080}])
  assert.equal(result.status, 0, `${name} must be accepted as a standard connector name`)
  assert.equal(result.stdout.trim(), name)
}

result = select({}, {x: 0, y: 0}, [])
assert.notEqual(result.status, 0, "missing monitor evidence must fail closed")

result = select({monitor: 3}, {x: 0, y: 0}, [{id: 3, name: "unsafe output", focused: true, x: 0, y: 0, width: 10, height: 10}])
assert.notEqual(result.status, 0, "unsafe monitor names must fail closed")

console.log("capture monitor selection tests passed")

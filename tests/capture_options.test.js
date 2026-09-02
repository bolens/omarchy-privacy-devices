const assert = require("node:assert/strict")
const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")
const { spawnSync } = require("node:child_process")

const root = path.join(__dirname, "..")
const capture = path.join(root, "scripts", "capture-screenshots")

function run(...args) {
  return spawnSync(capture, args, { cwd: root, encoding: "utf8" })
}

for (const width of ["399", "801", "not-a-number"]) {
  const result = run("--panel-width", width)
  assert.equal(result.status, 2, `invalid panel width accepted: ${width}`)
  assert.match(result.stderr, /Panel width must be an integer from 400 through 800/)
}

const outsideTmp = path.join(path.parse(os.tmpdir()).root, "var", "tmp", "privacy-audit-options")
let result = run("--audit-dir", outsideTmp)
assert.equal(result.status, 2, "audit evidence escaped the temporary filesystem")
assert.match(result.stderr, /Audit output must be below \/tmp/)

const occupied = fs.mkdtempSync(path.join(os.tmpdir(), "privacy-audit-options-"))
fs.writeFileSync(path.join(occupied, "stale.png"), "stale")
result = run("--audit-dir", occupied)
assert.equal(result.status, 2, "an occupied audit directory was accepted")
assert.match(result.stderr, /Audit output directory must be empty/)
fs.rmSync(occupied, { recursive: true })

console.log("capture option tests passed")

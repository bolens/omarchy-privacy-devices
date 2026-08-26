const assert = require("node:assert/strict")
const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")
const { spawnSync } = require("node:child_process")

const root = path.join(__dirname, "..")
const publisher = path.join(root, "scripts", "publish-screenshot-assets")

function fixture() {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "privacy-capture-transaction-"))
  fs.mkdirSync(path.join(directory, "stage"))
  fs.writeFileSync(path.join(directory, "one"), "old-one")
  fs.writeFileSync(path.join(directory, "two"), "old-two")
  fs.writeFileSync(path.join(directory, "stage", "one"), "new-one")
  fs.writeFileSync(path.join(directory, "stage", "two"), "new-two")
  return directory
}

let directory = fixture()
let result = spawnSync(publisher, ["stage", "one", "two"], { cwd: directory, encoding: "utf8" })
assert.equal(result.status, 0, result.stderr)
assert.equal(fs.readFileSync(path.join(directory, "one"), "utf8"), "new-one")
assert.equal(fs.readFileSync(path.join(directory, "two"), "utf8"), "new-two")
fs.rmSync(directory, { recursive: true })

directory = fixture()
result = spawnSync(publisher, ["stage", "one", "two"], {
  cwd: directory,
  encoding: "utf8",
  env: { ...process.env, PRIVACY_CAPTURE_TESTING: "1", PRIVACY_CAPTURE_FAIL_AT: "published:one" },
})
assert.notEqual(result.status, 0)
assert.match(result.stderr, /Rolled back incomplete screenshot publication/)
assert.equal(fs.readFileSync(path.join(directory, "one"), "utf8"), "old-one")
assert.equal(fs.readFileSync(path.join(directory, "two"), "utf8"), "old-two")
fs.rmSync(directory, { recursive: true })

console.log("capture publication transaction tests passed")

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

directory = fixture()
fs.writeFileSync(path.join(directory, "stage", "new-asset"), "new")
result = spawnSync(publisher, ["stage", "new-asset"], { cwd: directory, encoding: "utf8" })
assert.equal(result.status, 0, result.stderr)
assert.equal(fs.readFileSync(path.join(directory, "new-asset"), "utf8"), "new")
fs.rmSync(path.join(directory, "new-asset"))
result = spawnSync(publisher, ["stage", "new-asset", "one"], {
  cwd: directory,
  encoding: "utf8",
  env: { ...process.env, PRIVACY_CAPTURE_TESTING: "1", PRIVACY_CAPTURE_FAIL_AT: "published:one" },
})
assert.notEqual(result.status, 0)
assert.match(result.stderr, /Injected capture failure/, "failure must occur after publishing the new asset")
assert.equal(fs.existsSync(path.join(directory, "new-asset")), false, "rollback must remove a newly published asset")
assert.equal(fs.readFileSync(path.join(directory, "one"), "utf8"), "old-one")
fs.rmSync(directory, { recursive: true })

directory = fixture()
for (const unsafe of ["../outside", path.join(directory, "one")]) {
  result = spawnSync(publisher, ["stage", unsafe], { cwd: directory, encoding: "utf8" })
  assert.equal(result.status, 2, `unsafe publication path accepted: ${unsafe}`)
  assert.match(result.stderr, /Unsafe screenshot publication path/)
}
assert.equal(fs.readFileSync(path.join(directory, "one"), "utf8"), "old-one")
fs.rmSync(directory, { recursive: true })

console.log("capture publication transaction tests passed")

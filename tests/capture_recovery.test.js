const assert = require("node:assert/strict")
const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")
const { spawnSync } = require("node:child_process")

const root = path.join(__dirname, "..")
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), "privacy-capture-recovery-"))
const config = path.join(temporary, "config", "omarchy")
const recovery = path.join(temporary, "recovery")
fs.mkdirSync(config, { recursive: true })
fs.mkdirSync(recovery)
fs.writeFileSync(path.join(config, "shell.json"), '{"current":true}')
fs.writeFileSync(path.join(recovery, "shell.json"), '{"restored":true}')
fs.writeFileSync(path.join(recovery, "history.json"), "[]")

const result = spawnSync(path.join(root, "scripts", "restore-capture-state"), [recovery], {
  cwd: root,
  encoding: "utf8",
  env: {...process.env, XDG_CONFIG_HOME: path.join(temporary, "config"), XDG_STATE_HOME: path.join(temporary, "state")},
})
assert.equal(result.status, 0, result.stderr)
assert.equal(fs.readFileSync(path.join(config, "shell.json"), "utf8"), '{"restored":true}')
assert.match(result.stdout, /Reload shell config when safe/)
fs.rmSync(temporary, {recursive: true})
console.log("capture recovery tests passed")

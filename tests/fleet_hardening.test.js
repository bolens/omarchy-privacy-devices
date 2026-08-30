const assert = require("node:assert/strict")
const fs = require("node:fs")

const read = path => fs.readFileSync(path, "utf8")
const ci = read(".github/workflows/ci.yml")
const release = read(".github/workflows/release.yml")
const compatibility = fs.existsSync(".github/workflows/compatibility.yml")
  ? read(".github/workflows/compatibility.yml")
  : ""
const capture = fs.existsSync("scripts/capture-screenshots")
  ? read("scripts/capture-screenshots")
  : ""

assert.match(ci, /reviewdog\/action-actionlint@dbe5299849118fd6f099ba563d263d770955a64a/)
assert.match(ci, /actions\/setup-node@820762786026740c76f36085b0efc47a31fe5020/)
assert.match(ci, /shellcheck/)
assert.match(ci, /lycheeverse\/lychee-action@e7477775783ea5526144ba13e8db5eec57747ce8/)
assert.match(ci, /--exclude-path '[^']*node_modules/)
assert.match(ci, /accessibility\.score\s*===\s*1|score\s*===\s*1/)
assert.match(ci, /13f18b2cb7286fb54f87daf571a031aa6af3d8f0/)

assert.match(compatibility, /schedule:/)
assert.match(compatibility, /13f18b2cb7286fb54f87daf571a031aa6af3d8f0/)
assert.match(compatibility, /omarchy-ref:\s*quattro/)
assert.match(compatibility, /workflow_dispatch:/)

assert.match(release, /actions\/attest-build-provenance@977bb373ede98d70efdf65b84cb5f73e068dcc2a/)
assert.match(release, /id-token:\s*write/)
assert.match(release, /attestations:\s*write/)

assert.ok(fs.statSync("scripts/capture-screenshots").mode & 0o100)
assert.match(capture, /trap .*?(cleanup|restore)/)
assert.match(capture, /restore/)
assert.match(capture, /--verify/)
assert.match(capture, /--report/)
assert.doesNotMatch(capture, /quickshell\s+(kill|--kill)|qs\s+kill/)

console.log("Fleet hardening contracts passed")

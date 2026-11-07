const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const source = fs.readFileSync(path.join(__dirname, "..", "Service.qml"), "utf8")
const location = source.slice(source.indexOf("id: locationProc"), source.indexOf("PrivacyHistoryController {"))
const match = location.match(/onStreamFinished:\s*(function\([^)]*\)\s*\{[^}]*\}|[^\n}]+)/)
assert.ok(match, "location output must retain its stream-completion handler")
const handler = match[1].trim()
const script = new vm.Script(handler.startsWith("function") ? `(${handler})` : `(function() { ${handler} })`)
for (const payload of [
  '{"type":"location-snapshot","active":true,"applications":["Maps"]}',
  '{"type":"location-snapshot","active":false,"applications":[]}',
  "not-json",
  "",
]) {
  const observed = []
  const context = { locationOutput: { text: payload }, root: { parseLocation(value) { observed.push(value) } } }
  // StdioCollector.streamFinished has no signal parameters. Its text property is
  // the authoritative completed output, including empty or malformed responses.
  script.runInNewContext(context)()
  assert.deepEqual(observed, [payload])
}
console.log("location collector completion preserves actual output (4 cases)")

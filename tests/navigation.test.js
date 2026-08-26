const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const source = fs.readFileSync(path.join(__dirname, "..", "Model.js"), "utf8").replace(/^\.pragma library\s*/, "")
const model = {}
vm.createContext(model)
vm.runInContext(source, model)

const kinds = ["microphone", "camera", "location"]

assert.equal(model.nextNavigationKind([], "camera", 1), "", "empty views clear stale selection")
assert.equal(model.nextNavigationKind(kinds, "", 1), "microphone", "Down initially selects the first row")
assert.equal(model.nextNavigationKind(kinds, "stale", -1), "microphone", "stale selection recovers to the first row")
assert.equal(model.nextNavigationKind(kinds, "microphone", 1), "camera")
assert.equal(model.nextNavigationKind(kinds, "camera", -1), "microphone")
assert.equal(model.nextNavigationKind(kinds, "microphone", -1), "microphone", "navigation clamps at the first row")
assert.equal(model.nextNavigationKind(kinds, "location", 1), "location", "navigation clamps at the last row")
assert.equal(model.nextNavigationKind(kinds, "camera", 0), "camera", "non-directional input preserves selection")

assert.equal(model.activationKind([], "camera"), "")
assert.equal(model.activationKind(kinds, "camera"), "camera")
assert.equal(model.activationKind(kinds, "stale"), "microphone", "activation cannot open a row absent from the view")

assert.equal(model.popupDismissalAction("camera", false, false), "device")
assert.equal(model.popupDismissalAction("", true, false), "settings")
assert.equal(model.popupDismissalAction("", false, true), "history")
assert.equal(model.popupDismissalAction("", false, false), "popup")

assert.deepEqual(
  JSON.parse(JSON.stringify(model.settingsDeepLink("monitoring", "private-data"))),
  {page: "monitoring", section: "private-data"},
  "history recovery must target the private-data settings section"
)
assert.deepEqual(
  JSON.parse(JSON.stringify(model.settingsDeepLink("appearance", "status-presentation"))),
  {page: "appearance", section: "status-presentation"},
  "device marker guidance must target the global marker section"
)
assert.deepEqual(
  JSON.parse(JSON.stringify(model.settingsDeepLink("appearance", "private-data"))),
  {page: "appearance", section: ""},
  "sections from another page must not produce a misleading scroll target"
)
assert.deepEqual(
  JSON.parse(JSON.stringify(model.settingsDeepLink("unknown", "private-data"))),
  {page: "general", section: ""},
  "invalid deep links must fall back to the safe default page"
)
assert.equal(model.settingsScrollPosition(420, 1200, 600), 420)
assert.equal(model.settingsScrollPosition(900, 1200, 600), 600, "deep links clamp at the scroll extent")
assert.equal(model.settingsScrollPosition(-20, 1200, 600), 0, "deep links never overscroll above content")
assert.equal(model.settingsScrollPosition(100, 400, 600), 0, "short settings pages remain at the top")
assert.equal(model.deviceDeepLink("microphone"), "microphone")
assert.equal(model.deviceDeepLink("audio-output"), "audio-output")
assert.equal(model.deviceDeepLink("unknown"), "", "unknown device routes must not open a misleading detail page")

console.log("popup navigation policy tests passed")

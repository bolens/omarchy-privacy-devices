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

assert.equal(model.popupDismissalAction("camera", false), "device")
assert.equal(model.popupDismissalAction("", true), "settings")
assert.equal(model.popupDismissalAction("", false), "popup")

console.log("popup navigation policy tests passed")

const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const source = fs.readFileSync(path.join(__dirname, "..", "Model.js"), "utf8").replace(/^\.pragma library\s*/, "")
const model = {}
vm.createContext(model)
vm.runInContext(source, model)

const applying = model.controlTransactionTransition(null, {type: "begin", expectedEnabled: false}, 1_000)
assert.deepEqual(JSON.parse(JSON.stringify(applying)), {
  status: "applying", expectedEnabled: false, startedAt: 1_000,
  finishedAt: 0, exitCode: -1, code: "applying",
})

const commandFailed = model.controlTransactionTransition(applying, {type: "command", exitCode: 7}, 1_100)
assert.equal(commandFailed.status, "failed")
assert.equal(commandFailed.code, "command_failed")
assert.equal(commandFailed.exitCode, 7)
assert.equal(commandFailed.finishedAt, 1_100)

const verifying = model.controlTransactionTransition(applying, {type: "command", exitCode: 0}, 1_100)
assert.equal(verifying.status, "verifying")
assert.equal(verifying.deadline, 6_100)
assert.equal(verifying.finishedAt, 0)

const mismatch = model.controlTransactionTransition(verifying, {type: "observation", valid: true, enabled: true}, 1_200)
assert.equal(mismatch, verifying, "a stale observation must not fail an asynchronous action early")

const verified = model.controlTransactionTransition(verifying, {type: "observation", valid: true, enabled: false}, 1_300)
assert.equal(verified.status, "succeeded")
assert.equal(verified.code, "verified")
assert.equal(verified.finishedAt, 1_300)

const invalidProbe = model.controlTransactionTransition(verifying, {type: "observation", valid: false}, 1_300)
assert.equal(invalidProbe.status, "failed")
assert.equal(invalidProbe.code, "verification_probe_failed")
assert.equal(invalidProbe.exitCode, 12)

assert.equal(model.controlTransactionTransition(verifying, {type: "timeout"}, 6_099), verifying)
const timedOut = model.controlTransactionTransition(verifying, {type: "timeout"}, 6_100)
assert.equal(timedOut.status, "failed")
assert.equal(timedOut.code, "verification_timeout")
assert.equal(timedOut.exitCode, 14)

const request = (overrides = {}) => Object.assign({
  known: true, enabled: true, serviceOwned: true, dependenciesReady: true,
  pending: false, processBusy: false
}, overrides)
assert.equal(model.controlRequestStatus(request()), "ok")
assert.equal(model.controlRequestStatus(request({known: false})), "unsupported")
assert.equal(model.controlRequestStatus(request({enabled: false})), "disabled")
assert.equal(model.controlRequestStatus(request({serviceOwned: false})), "unsupported")
assert.equal(model.controlRequestStatus(request({dependenciesReady: false})), "unavailable")
assert.equal(model.controlRequestStatus(request({pending: true})), "busy")
assert.equal(model.controlRequestStatus(request({processBusy: true})), "busy")

console.log("control transaction tests passed")

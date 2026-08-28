import QtQuick
import "Model.js" as Model

Item {
  id: controller

  required property var host
  property string state: "idle"
  property var queue: []
  property string activeKind: ""
  property var previous: ({})
  property var results: []
  property bool undoAvailable: false
  property bool restoring: false
  property string presetName: ""

  function entries() {
    return ["microphone", "audio-output", "camera", "screen-share", "location"].map(function(kind) {
      return {
        kind: kind,
        enabled: host.controlEnabled(kind),
        controllable: host.kindEnabled(kind) && host.serviceControllable(kind),
        dependenciesReady: host.dependenciesReady(kind),
        pending: host.controlPending(kind) || host.controlProcessBusy(kind)
      }
    })
  }

  function start(plan, isRestoring) {
    if (state === "applying" || state === "restoring") return false
    restoring = isRestoring === true
    state = restoring ? "restoring" : "applying"
    queue = plan.actions.slice()
    results = plan.skipped.slice()
    activeKind = ""
    runNext()
    return true
  }

  function observedState(values) {
    var observed = {}
    for (var index = 0; index < values.length; index++) observed[values[index].kind] = values[index].enabled === true
    return observed
  }

  function requestLockdown() {
    if (state === "applying" || state === "restoring") return false
    var values = entries()
    previous = observedState(values)
    presetName = "Lockdown"
    undoAvailable = false
    undoTimer.stop()
    return start(Model.privacyPresetPlan(values, false), false)
  }

  function requestMode(mode) {
    if (state === "applying" || state === "restoring") return false
    var clean = Model.sanitizePrivacyModes([mode])
    if (!clean.length) return false
    var values = entries()
    previous = observedState(values)
    presetName = clean[0].name
    undoAvailable = false
    undoTimer.stop()
    values = values.filter(function(entry) { return Object.prototype.hasOwnProperty.call(clean[0].controls, entry.kind) })
    return start(Model.privacyPresetPlan(values, clean[0].controls), false)
  }

  function restore() {
    if (!undoAvailable) return false
    var plan = Model.privacyPresetPlan(entries(), previous)
    undoAvailable = false
    undoTimer.stop()
    return start(plan, true)
  }

  function runNext() {
    var next = Model.nextPrivacyPresetAction(queue, activeKind)
    if (next.action === "wait") return
    if (next.action === "complete") {
      var outcome = Model.privacyPresetOutcome(results)
      state = outcome.state
      if (!restoring && outcome.changed) {
        undoAvailable = true
        undoTimer.restart()
      } else feedbackTimer.restart()
      restoring = false
      return
    }
    var action = next.current
    queue = next.queue
    if ((host.controlEnabled(action.kind) === true) === action.expectedEnabled) {
      results = results.concat([{kind: action.kind, reason: "already-set"}])
      Qt.callLater(controller.runNext)
      return
    }
    activeKind = action.kind
    if (!host.toggleControl(action.kind)) {
      results = results.concat([{kind: action.kind, reason: "request-failed"}])
      activeKind = ""
      Qt.callLater(controller.runNext)
    }
  }

  function advance() {
    if (!activeKind) return
    var transaction = host.controlTransactions[activeKind]
    if (!transaction || (transaction.status !== "succeeded" && transaction.status !== "failed")) return
    results = results.concat([{
      kind: activeKind,
      status: transaction.status,
      reason: transaction.status === "failed" ? String(transaction.code || "failed") : ""
    }])
    activeKind = ""
    runNext()
  }

  function message() {
    if (state === "applying") return "Applying " + (presetName || "privacy mode") + "…"
    if (state === "restoring") return "Restoring previous privacy state…"
    if (state === "partial") return "Privacy preset finished with unavailable or failed controls."
    if (state === "succeeded") return undoAvailable ? (presetName || "Privacy mode") + " verified. Undo is available for 30 seconds." : "Privacy mode verified."
    return ""
  }

  Timer {
    id: undoTimer
    interval: 30000
    onTriggered: {
      controller.undoAvailable = false
      if (controller.state === "succeeded" || controller.state === "partial") controller.state = "idle"
    }
  }

  Timer {
    id: feedbackTimer
    interval: 8000
    onTriggered: if (controller.state !== "applying" && controller.state !== "restoring") controller.state = "idle"
  }
}

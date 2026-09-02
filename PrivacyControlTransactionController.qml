pragma ComponentBehavior: Bound
import QtQuick
import "Model.js" as Model

Item {
  id: controller
  required property var host

  property var transactions: ({})

  function pending(kind) {
    var transaction = transactions[kind]
    return !!transaction && ["requested", "applying", "verifying"].indexOf(transaction.status) >= 0
  }

  function begin(kind, expectedEnabled) {
    var next = Object.assign({}, transactions)
    next[kind] = Model.controlTransactionTransition(null, {type: "begin", expectedEnabled: expectedEnabled}, Date.now())
    transactions = next
  }

  function beginVerification(kind, exitCode) {
    var next = Object.assign({}, transactions)
    var current = next[kind]
    next[kind] = Model.controlTransactionTransition(current, {type: "command", exitCode: exitCode}, Date.now())
    transactions = next
    if (next[kind] && next[kind].status === "failed") host.notifyControlResult(kind, next[kind].expectedEnabled, false)
  }

  function transition(kind, event, now) {
    var next = Object.assign({}, transactions)
    var current = next[kind]
    var updated = Model.controlTransactionTransition(current, event, now === undefined ? Date.now() : now)
    if (updated === current) return
    next[kind] = updated
    transactions = next
    if (updated && (updated.status === "succeeded" || updated.status === "failed"))
      host.notifyControlResult(kind, updated.expectedEnabled, updated.status === "succeeded")
  }

  function observe(kind, observedEnabled, probeValid) {
    transition(kind, {type: "observation", enabled: observedEnabled, valid: probeValid})
  }

  function beginExternal(kind, expectedEnabled) {
    if (kind !== "screen-recording" || !host.kindEnabled(kind) || pending(kind)) return false
    begin(kind, expectedEnabled)
    beginVerification(kind, 0)
    return true
  }

  Timer {
    interval: 500
    repeat: true
    running: {
      for (var kind in controller.transactions)
        if (controller.transactions[kind].status === "verifying") return true
      return false
    }
    onTriggered: {
      var now = Date.now()
      for (var kind in controller.transactions) {
        var transaction = controller.transactions[kind]
        if (transaction.status === "verifying" && now >= transaction.deadline)
          controller.transition(kind, {type: "timeout"}, now)
      }
    }
  }
}

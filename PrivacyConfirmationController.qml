import QtQuick

QtObject {
  id: controller
  property string pending: ""
  property int guardMilliseconds: 5000
  property var allowedActions: ["history", "backend", "all", "lockdown"]

  function request(action) {
    var selected = String(action || "")
    if (allowedActions.indexOf(selected) < 0) return false
    if (pending === selected) { clear(); return true }
    pending = selected
    guard.restart()
    return false
  }

  function clear() { pending = ""; guard.stop() }

  property Timer guard: Timer {
    interval: Math.max(1, controller.guardMilliseconds)
    onTriggered: controller.pending = ""
  }
}

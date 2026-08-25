import QtQuick

QtObject {
  id: controller
  property int interval: 75
  property int feedbackDuration: 1800
  property var pending: null
  property string status: ""
  property string detail: ""
  readonly property bool running: commitTimer.running

  signal commitRequested(var settings)

  function submit(current, patch) {
    var next = JSON.parse(JSON.stringify(pending || current || {}))
    var values = patch || {}
    for (var key in values) next[key] = values[key]
    pending = next
    status = "saving"
    detail = ""
    feedbackTimer.stop()
    commitTimer.restart()
  }

  function flush() {
    if (!pending) return false
    commitTimer.stop()
    var next = pending
    pending = null
    commitRequested(next)
    return true
  }

  function complete(success, message) {
    status = success === true ? "saved" : "failed"
    detail = String(message || "")
    feedbackTimer.restart()
  }

  property Timer commitTimer: Timer { interval: controller.interval; onTriggered: controller.flush() }
  property Timer feedbackTimer: Timer {
    interval: controller.feedbackDuration
    onTriggered: { controller.status = ""; controller.detail = "" }
  }
}

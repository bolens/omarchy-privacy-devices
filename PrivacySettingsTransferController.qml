import QtQuick
import Quickshell.Io

QtObject {
  id: controller
  required property string helper
  property bool busy: false
  property bool undoAvailable: false
  readonly property bool running: busy

  signal succeeded(string mode, string payload)
  signal failed(string mode, string detail)

  function request(mode, currentSettings) {
    var selected = String(mode || "")
    if (busy || ["export", "import", "undo", "checkpoint"].indexOf(selected) < 0) return false
    busy = true
    process.mode = selected
    process.command = selected === "export" ? [helper, "export", JSON.stringify(currentSettings || {})]
      : (selected === "import" ? [helper, "import", JSON.stringify(currentSettings || {})]
      : (selected === "checkpoint" ? [helper, "checkpoint", JSON.stringify(currentSettings || {})] : [helper, "undo"]))
    process.running = true
    return true
  }

  function refreshUndoAvailability() {
    if (busy) return false
    busy = true
    process.mode = "check"
    process.command = [helper, "can-undo"]
    process.running = true
    return true
  }

  property Process process: Process {
    property string mode: ""
    stdout: StdioCollector { id: output; waitForEnd: true }
    stderr: StdioCollector { id: errorOutput; waitForEnd: true }
    onExited: function(exitCode) {
      var completedMode = process.mode
      var payload = String(output.text || "").trim()
      var detail = String(errorOutput.text || "").trim()
      controller.busy = false
      if (completedMode === "check") { controller.undoAvailable = exitCode === 0; return }
      if (exitCode !== 0) { controller.failed(completedMode, detail); return }
      if (completedMode === "import" || completedMode === "checkpoint") controller.undoAvailable = true
      else if (completedMode === "undo") controller.undoAvailable = false
      controller.succeeded(completedMode, payload)
    }
  }

  Component.onCompleted: refreshUndoAvailability()
}

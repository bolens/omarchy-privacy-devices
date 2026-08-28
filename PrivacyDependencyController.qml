import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

Item {
  id: controller
  required property var host

  property var readyMap: ({})
  property var checkedMap: ({})
  property var queue: []
  property string currentKind: ""
  property bool busy: false
  property bool refreshPending: false

  function ready(kind) {
    return checkedMap[kind] !== true || readyMap[kind] === true
  }

  function description(kind) {
    if (kind === "microphone" || kind === "audio-output") return "Audio controls require pactl (libpulse) or wpctl"
    if (kind === "camera") return "Camera blocking requires Polkit"
    if (kind === "location") return "Location blocking requires GeoClue and Polkit"
    if (kind === "screen-share") return "Screen sharing requires xdg-desktop-portal-hyprland"
    if (kind === "screenshot") return "Screenshots require grim and slurp"
    if (kind === "screen-recording") return "The selected recording backend is not installed"
    return "No additional dependencies"
  }

  function helperPath() {
    return String(Qt.resolvedUrl("privacy-deps")).replace(/^file:\/\//, "")
  }

  function refresh() {
    var scheduled = Model.scheduleProbeRefresh(busy, host.enabledKinds())
    queue = scheduled.queue
    refreshPending = scheduled.refreshPending
    if (!busy) runNext()
  }

  function runNext() {
    var next = Model.nextProbeAction(queue, refreshPending, busy)
    if (next.action === "wait" || next.action === "idle") return
    if (next.action === "refresh") { refresh(); return }
    queue = next.queue
    currentKind = next.kind
    busy = true
    checkProcess.command = [helperPath(), "check", currentKind, host.recordingBackend(), host.audioControlBackend(), host.screenshotBackend()]
    checkProcess.running = true
  }

  function install(kind) {
    if (ready(kind)) return
    Quickshell.execDetached(["omarchy-launch-terminal", helperPath(), "install", kind,
      host.recordingBackend(), host.audioControlBackend(), host.screenshotBackend()])
  }

  Timer {
    interval: 300000
    repeat: true
    running: host.enabledKindList.length > 0
    onTriggered: controller.refresh()
  }

  Process {
    id: checkProcess
    onExited: function(exitCode) {
      controller.busy = false
      if (!controller.refreshPending) {
        var ready = Object.assign({}, controller.readyMap)
        var checked = Object.assign({}, controller.checkedMap)
        ready[controller.currentKind] = exitCode === 0
        checked[controller.currentKind] = true
        controller.readyMap = ready
        controller.checkedMap = checked
      }
      controller.runNext()
    }
  }
}

import QtQuick
import Quickshell.Io
import "Model.js" as Model

Item {
  id: controller

  required property var host
  property var endpointMap: ({microphone: [], "audio-output": []})
  property var initializedKinds: ({})
  property string activeKind: ""
  property string operation: ""
  property string pendingRefreshKind: ""
  property string message: ""

  function helperPath() {
    return host.audioEndpointHelperOverride || String(Qt.resolvedUrl("privacy-audio-devices")).replace(/^file:\/\//, "")
  }

  function endpoints(kind) {
    var rows = endpointMap[kind]
    return Array.isArray(rows) ? rows : []
  }

  function accept(kind, text) {
    try {
      var rows = JSON.parse(String(text || "[]"))
      if (!Array.isArray(rows)) throw new Error("invalid endpoint list")
      rows = Model.sanitizeAudioEndpoints(rows, 64)
      var changes = initializedKinds[kind] === true
        ? Model.deviceInventoryChanges(kind, endpoints(kind), rows, Date.now()) : []
      if (changes.length) host.recentDeviceChanges = changes.concat(host.recentDeviceChanges).slice(0, 24)
      var initialized = Object.assign({}, initializedKinds)
      initialized[kind] = true
      initializedKinds = initialized
      var next = Object.assign({}, endpointMap)
      next[kind] = rows
      endpointMap = next
      message = rows.length ? "" : "No audio endpoints detected."
    } catch (error) {
      message = "Audio endpoints could not be read."
    }
  }

  function refresh(kind) {
    if (["microphone", "audio-output"].indexOf(kind) === -1) return false
    if (operation !== "") {
      pendingRefreshKind = kind
      return true
    }
    pendingRefreshKind = ""
    operation = "list"
    activeKind = kind
    message = "Loading audio endpoints…"
    listProcess.command = [helperPath(), "list", kind]
    listProcess.running = true
    return true
  }

  function runPendingRefresh() {
    var kind = pendingRefreshKind
    if (!kind || operation !== "") return false
    pendingRefreshKind = ""
    return refresh(kind)
  }

  function setMuted(kind, identifier, muted) {
    if (["microphone", "audio-output"].indexOf(kind) === -1 || operation !== "") return false
    operation = "set"
    activeKind = kind
    message = muted ? "Blocking selected endpoint…" : "Allowing selected endpoint…"
    setProcess.command = [helperPath(), "set", kind, String(identifier), muted === true ? "true" : "false"]
    setProcess.running = true
    return true
  }

  Process {
    id: listProcess
    onExited: function(exitCode) {
      if (exitCode !== 0) controller.message = "Audio endpoints could not be read."
      controller.operation = ""
      controller.runPendingRefresh()
    }
    stdout: StdioCollector {
      id: listOutput
      waitForEnd: true
      onStreamFinished: controller.accept(controller.activeKind, listOutput.text)
    }
  }

  Process {
    id: setProcess
    onExited: function(exitCode) {
      if (exitCode !== 0) controller.message = "Audio endpoint state was not changed."
      controller.operation = ""
      controller.runPendingRefresh()
    }
    stdout: StdioCollector {
      id: setOutput
      waitForEnd: true
      onStreamFinished: controller.accept(controller.activeKind, setOutput.text)
    }
  }
}

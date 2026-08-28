import QtQuick
import Quickshell.Io
import "Model.js" as Model

Item {
  id: controller

  required property var host

  function helperPath() {
    return host.historyHelperOverride || String(Qt.resolvedUrl("privacy-history")).replace(/^file:\/\//, "")
  }

  function clear() {
    host.historyGeneration++
    host.historyLoadPending = false
    host.recentHistory = []
    host.historyLoaded = host.settings.historyEnabled !== true
    enqueueMutation(["clear"])
  }

  function enqueueMutation(arguments) {
    var values = Array.isArray(arguments) ? arguments.slice() : []
    if (!values.length || ["append", "clear"].indexOf(values[0]) < 0) return false
    host.historyMutationQueue = host.historyMutationQueue.concat([values])
    runNextMutation()
    return true
  }

  function runNextMutation() {
    if (host.historyMutationBusy || !host.historyMutationQueue.length) return false
    var queue = host.historyMutationQueue.slice()
    var arguments = queue.shift()
    host.historyMutationQueue = queue
    host.historyMutationBusy = true
    historyMutationProc.command = [helperPath()].concat(arguments)
    historyMutationProc.running = true
    return true
  }

  function load() {
    if (host.historyLoaded || host.settings.historyEnabled !== true) return false
    if (host.historyLoadBusy) {
      host.historyLoadPending = true
      return true
    }
    host.historyLoadPending = false
    host.historyLoadBusy = true
    host.historyLoadGeneration = host.historyGeneration
    historyLoadProc.command = [helperPath(), "load"]
    historyLoadProc.running = true
    return true
  }

  function inspect() {
    if (historyInspectProc.running) return false
    historyInspectProc.command = [helperPath(), "inspect"]
    historyInspectProc.running = true
    return true
  }

  Process {
    id: historyInspectProc
    stdout: StdioCollector {
      onStreamFinished: {
        var status = "attention"
        try { status = String(JSON.parse(String(text || "{}")).status || "attention") } catch (error) {}
        controller.host.selfTestResult = Model.privacySelfTest(controller.host.selfTestInput(status))
      }
    }
  }

  Process {
    id: historyLoadProc
    onExited: function(exitCode) {
      controller.host.historyLoadBusy = false
      if (controller.host.historyLoadGeneration === controller.host.historyGeneration)
        controller.host.historyLoaded = controller.host.settings.historyEnabled !== true || exitCode === 0
      if (controller.host.historyLoadPending && controller.host.settings.historyEnabled === true) controller.load()
    }
    stdout: StdioCollector {
      id: historyLoadOutput
      waitForEnd: true
      onStreamFinished: {
        if (!Model.historyLoadAccepted(controller.host.historyLoadGeneration, controller.host.historyGeneration, controller.host.settings.historyEnabled)) {
          controller.host.recentHistory = []
          return
        }
        try {
          var value = JSON.parse(String(historyLoadOutput.text || "[]"))
          controller.host.recentHistory = Array.isArray(value) ? value : []
        } catch (error) {
          controller.host.recentHistory = []
        }
      }
    }
  }

  Process {
    id: historyMutationProc
    onExited: function(_exitCode) {
      controller.host.historyMutationBusy = false
      controller.runNextMutation()
    }
  }
}

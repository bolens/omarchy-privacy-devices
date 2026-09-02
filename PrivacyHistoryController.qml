import QtQuick
import Quickshell.Io
import "Model.js" as Model

Item {
  id: controller

  required property var host
  readonly property int maximumQueuedMutations: 100
  readonly property int maximumQueuedMutationBytes: 1048576

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
    if (queuedMutationBytes([values]) > maximumQueuedMutationBytes) return false
    var queue = values[0] === "clear" ? [] : host.historyMutationQueue.slice()
    queue = queue.concat([values])
    while (queue.length > maximumQueuedMutations || queuedMutationBytes(queue) > maximumQueuedMutationBytes)
      queue.shift()
    if (!queue.length) return false
    host.historyMutationQueue = queue
    runNextMutation()
    return true
  }

  function queuedMutationBytes(queue) {
    try { return unescape(encodeURIComponent(JSON.stringify(queue))).length }
    catch (error) { return Number.POSITIVE_INFINITY }
  }

  function runNextMutation() {
    if (host.historyMutationBusy || !host.historyMutationQueue.length) return false
    var queue = host.historyMutationQueue.slice()
    var arguments = queue.shift()
    host.historyMutationQueue = queue
    host.historyMutationBusy = true
    historyMutationProc.command = [helperPath()].concat(arguments)
    historyMutationProc.running = true; historyMutationWatchdog.start()
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
    historyLoadProc.running = true; historyLoadWatchdog.start()
    return true
  }

  function inspect() {
    if (historyInspectProc.running) return false
    historyInspectProc.command = [helperPath(), "inspect"]
    historyInspectProc.running = true; historyInspectWatchdog.start()
    return true
  }

  Process {
    id: historyInspectProc
    onExited: historyInspectWatchdog.stop()
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
      historyLoadWatchdog.stop()
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
      historyMutationWatchdog.stop()
      controller.host.historyMutationBusy = false
      controller.runNextMutation()
    }
  }
  PrivacyProcessWatchdog { id: historyLoadWatchdog; process: historyLoadProc; timeoutMilliseconds: 15000 }
  PrivacyProcessWatchdog { id: historyMutationWatchdog; process: historyMutationProc; timeoutMilliseconds: 15000 }
  PrivacyProcessWatchdog { id: historyInspectWatchdog; process: historyInspectProc; timeoutMilliseconds: 15000 }
}

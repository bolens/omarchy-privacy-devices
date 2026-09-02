pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
  id: root
  readonly property string configPath: Quickshell.shellPath("RuntimeIpcDispatchTest.qml")
  readonly property string ipcExecutable: String(Quickshell.env("QUICKSHELL_BIN") || "quickshell")
  readonly property string owner: "runtime_ipc_owner_1234567890"
  readonly property string otherOwner: "runtime_ipc_other_1234567890"
  readonly property string capturePayload: "eyJvd25lciI6InJ1bnRpbWVfaXBjX293bmVyXzEyMzQ1Njc4OTAiLCJzZXR0aW5ncyI6eyJzaG93QWN0aXZpdHlJbmRpY2F0b3JzIjpmYWxzZX0sImhpc3RvcnkiOlt7ImtpbmQiOiJjYW1lcmEiLCJhcHBsaWNhdGlvbiI6IlJ1bnRpbWUgQ2FtZXJhIn1dLCJzZXNzaW9ucyI6W3sia2luZCI6Im1pY3JvcGhvbmUiLCJhcHBsaWNhdGlvbiI6IlJ1bnRpbWUgVm9pY2UiLCJzb3VyY2UiOiJwaXBld2lyZSIsImNvbmZpZGVuY2UiOiJjb25maXJtZWQiLCJzdGFydGVkQXQiOjF9XX0="
  readonly property string otherCapturePayload: "eyJvd25lciI6InJ1bnRpbWVfaXBjX290aGVyXzEyMzQ1Njc4OTAiLCJzZXR0aW5ncyI6e30sImhpc3RvcnkiOltdLCJzZXNzaW9ucyI6W119"
  property int summons: 0
  property int step: 0
  property var steps: [
    {target:"privacy-devices-capture-v2", method:"protocol", args:[], expected:"2"},
    {target:"privacy-devices", method:"openDetails", args:["microphone"], expected:"activity"},
    {target:"privacy-devices", method:"openSettingsSection", args:["monitoring", "observer-health"], expected:"monitoring#observer-health"},
    {target:"privacy-devices", method:"status", args:[], expected:"[]"},
    {target:"privacy-devices", method:"health", args:[], expected:"{}"},
    {target:"privacy-devices", method:"action", args:["shell-command", "camera"], expected:"invalid"},
    {target:"privacy-devices-settings", method:"open", args:["appearance"], expected:"appearance"},
    {target:"privacy-devices-settings", method:"openSection", args:["monitoring", "private-data"], expected:"monitoring#private-data"},
    {target:"privacy-devices-capture-v2", method:"beginCapture", args:["not-base64"], expected:"invalid"},
    {target:"privacy-devices-capture-v2", method:"beginCapture", args:[capturePayload], expected:"ok"},
    {target:"privacy-devices-capture-v2", method:"openPanel", args:[owner, "DP-1", "device", "microphone", ""], expected:"activity"},
    {target:"privacy-devices-capture-v2", method:"closePanel", args:[owner, "DP-1"], expected:"ok"},
    {target:"privacy-devices-capture-v2", method:"openPanel", args:[otherOwner, "DP-1", "activity", "", ""], expected:"denied"},
    {target:"privacy-devices-capture-v2", method:"beginCapture", args:[otherCapturePayload], expected:"busy"},
    {target:"privacy-devices-capture-v2", method:"renew", args:[otherOwner], expected:"denied"},
    {target:"privacy-devices-capture-v2", method:"state", args:[owner], validator:"capture-state"},
    {target:"privacy-devices-capture-v2", method:"presentation", args:[owner, "DP-1"], validator:"capture-presentation"},
    {target:"privacy-devices-capture-v2", method:"presentation", args:[otherOwner, "DP-1"], expected:"denied"},
    {target:"privacy-devices-capture-v2", method:"renew", args:[owner], expected:"ok"},
    {target:"privacy-devices-capture-v2", method:"endCapture", args:[otherOwner], expected:"denied"},
    {target:"privacy-devices-capture-v2", method:"endCapture", args:[owner], expected:"ok"},
    {target:"privacy-devices-capture-v2", method:"state", args:[owner], expected:"denied"},
    {target:"privacy-devices-capture-v2", method:"endCapture", args:[owner], expected:"ok"}
  ]

  QtObject {
    id: shellMock
    function summon(pluginId, argument) {
      if (pluginId !== "io.github.bolens.privacy-devices" || argument !== "")
        throw new Error("IPC summoned the wrong plugin")
      root.summons++
      return true
    }
  }
  Service { id: service; shell: shellMock; settings: ({enabledKinds:[]}) }
  QtObject {
    id: barMock
    property bool opened: false
    property string editingKind: ""
    function open() { opened = true }
    function close() { opened = false }
    function showGlobalSettings(_page, _section) {}
    function showActivity() {}
    function showHistory() {}
  }

  function runNext() {
    if (step >= steps.length) {
      if (service.requestedView !== "settings" || service.requestedSettingsPage !== "monitoring"
          || service.requestedSettingsSection !== "private-data" || root.summons !== 4
          || service.capturePreviewActive)
        throw new Error("IPC calls did not preserve routed service state")
      console.log("PRIVACY_QML_IPC_DISPATCH_OK")
      Qt.quit()
      return
    }
    var current = steps[step]
    ipc.command = [ipcExecutable, "ipc", "--path", configPath, "call", current.target, current.method].concat(current.args)
    ipc.running = true
  }

  function responseAccepted(current, response) {
    if (current.validator === "capture-presentation") {
      try {
        var presentation = JSON.parse(response)
        return presentation.opened === true && presentation.view === "device"
          && presentation.argument === "microphone" && presentation.ready === true
      } catch (error) { return false }
    }
    if (current.validator !== "capture-state") return response === current.expected
    try {
      var state = JSON.parse(response)
      return state.settings.showActivityIndicators === false
        && state.sessions.length === 1 && state.sessions[0].application === "Runtime Voice"
        && Array.isArray(state.barSessions)
    } catch (error) { return false }
  }

  Process {
    id: ipc
    stdout: StdioCollector { id: ipcOutput; waitForEnd: true }
    stderr: StdioCollector { id: ipcError; waitForEnd: true }
    onExited: function(exitCode) {
      var current = root.steps[root.step]
      var response = String(ipcOutput.text || "").trim()
      if (exitCode !== 0 || !root.responseAccepted(current, response))
        throw new Error("IPC " + current.target + "." + current.method + " failed: " + response + " " + String(ipcError.text || "").trim())
      if (current.validator === "capture-state")
        service.updateBarPresentation("DP-1", {opened:true, view:"device", argument:"microphone", ready:true})
      root.step++
      Qt.callLater(root.runNext)
    }
  }

  Component.onCompleted: {
    service.registerBarInstance("DP-1", barMock)
    Qt.callLater(runNext)
  }
}

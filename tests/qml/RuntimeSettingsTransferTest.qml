import Quickshell
import QtQuick

ShellRoot {
  id: root
  readonly property string fixtureHelper: String(Qt.resolvedUrl("tests/fixtures/settings-transfer-helper")).replace(/^file:\/\//, "")
  property var completed: []
  property bool started: false

  function startWhenReady() {
    if (started || transfer.running) return
    started = true
    if (transfer.request("invalid", {}) || transfer.running) throw new Error("invalid transfer mode was accepted")
    if (!transfer.request("export", {_privacySettingsVersion:1})) throw new Error("export request rejected")
    if (transfer.request("checkpoint", {}) || transfer.refreshUndoAvailability())
      throw new Error("overlapping transfer request was accepted")
  }
  PrivacySettingsTransferController {
    id: transfer
    helper: fixtureHelper
    onSucceeded: function(mode, payload) {
      completed = completed.concat([mode])
      if (mode === "export") transfer.request("checkpoint", {_privacySettingsVersion:1,showIdle:true})
      else if (mode === "checkpoint") {
        if (!transfer.undoAvailable) throw new Error("checkpoint did not expose undo")
        transfer.request("import", {_privacySettingsVersion:1,showIdle:true})
      }
      else if (mode === "import") {
        if (!transfer.undoAvailable || JSON.parse(payload).showIdle !== false) throw new Error("import result not applied")
        transfer.request("undo", {})
      } else if (mode === "undo") {
        if (transfer.undoAvailable || JSON.parse(payload).showIdle !== true) throw new Error("undo result not applied")
        if (completed.join(",") !== "export,checkpoint,import,undo") throw new Error("transfer sequence lost")
        console.log("PRIVACY_QML_SETTINGS_TRANSFER_OK")
        Qt.quit()
      }
    }
    onFailed: function(mode, detail) { throw new Error("transfer failed: " + mode + " " + detail) }
  }
  Connections { target: transfer; function onRunningChanged() { Qt.callLater(root.startWhenReady) } }
  Component.onCompleted: Qt.callLater(root.startWhenReady)
}

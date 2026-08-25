import Quickshell
import QtQuick

ShellRoot {
  readonly property string fixtureHelper: String(Qt.resolvedUrl("tests/fixtures/settings-transfer-helper")).replace(/^file:\/\//, "")
  property var completed: []
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
  Timer {
    interval: 100
    running: true
    onTriggered: {
      if (transfer.running) return
      if (!transfer.request("export", {_privacySettingsVersion:1})) throw new Error("export request rejected")
      stop()
    }
  }
}

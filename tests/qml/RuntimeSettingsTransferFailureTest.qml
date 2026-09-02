pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  readonly property string helper: String(Qt.resolvedUrl("tests/fixtures/settings-transfer-failing-helper")).replace(/^file:\/\//, "")
  property bool started: false

  function startWhenReady() {
    if (started || transfer.running) return
    started = true
    if (!transfer.undoAvailable) throw new Error("initial undo probe was not applied")
    if (!transfer.request("import", {_privacySettingsVersion:1})) throw new Error("failure request was rejected")
  }
  PrivacySettingsTransferController {
    id: transfer
    helper: root.helper
    onFailed: function(mode, detail) {
      if (mode !== "import" || detail !== "fixture import failed") throw new Error("failure payload was not preserved")
      if (transfer.running) throw new Error("failed transfer remained busy")
      if (!transfer.undoAvailable) throw new Error("failed import discarded existing undo")
      console.log("PRIVACY_QML_SETTINGS_TRANSFER_FAILURE_OK")
      Qt.quit()
    }
  }
  Connections { target: transfer; function onRunningChanged() { Qt.callLater(root.startWhenReady) } }
  Component.onCompleted: Qt.callLater(root.startWhenReady)
}

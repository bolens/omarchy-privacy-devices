import Quickshell
import QtQuick

ShellRoot {
  id: root
  readonly property string helper: String(Qt.resolvedUrl("tests/fixtures/settings-transfer-failing-helper")).replace(/^file:\/\//, "")
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
  Timer {
    interval: 100; running: true
    onTriggered: {
      if (transfer.running) return
      if (!transfer.undoAvailable) throw new Error("initial undo probe was not applied")
      if (!transfer.request("import", {_privacySettingsVersion:1})) throw new Error("failure request was rejected")
      stop()
    }
  }
}

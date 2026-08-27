import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    service.settings = {notifyOnControlChanges:false}
    service.controlTransactions = {
      camera:{status:"verifying", expectedEnabled:false, startedAt:10, finishedAt:0, exitCode:0, deadline:Date.now() - 1, code:"verifying"},
      microphone:{status:"succeeded", expectedEnabled:false, startedAt:1, finishedAt:2, exitCode:0, code:"verified"}
    }
  }

  Timer {
    interval: 650
    running: true
    onTriggered: {
      var expired = service.controlTransactions.camera
      var preserved = service.controlTransactions.microphone
      if (!expired || expired.status !== "failed" || expired.code !== "verification_timeout"
          || expired.exitCode !== 14 || expired.finishedAt <= 0 || service.controlPending("camera"))
        throw new Error("verification watchdog did not terminate the expired transaction")
      if (!preserved || preserved.status !== "succeeded" || preserved.code !== "verified")
        throw new Error("verification watchdog mutated an unrelated transaction")
      console.log("PRIVACY_QML_CONTROL_VERIFICATION_TIMEOUT_OK")
      Qt.quit()
    }
  }
}

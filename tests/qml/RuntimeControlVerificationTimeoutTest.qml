pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  Service { id: service }
  property bool completed: false

  function verifyTimeout() {
    if (completed) return
    var expired = service.controlTransactions.camera
    if (!expired || expired.status !== "failed") return
    completed = true
    var preserved = service.controlTransactions.microphone
    if (expired.code !== "verification_timeout" || expired.exitCode !== 14
        || expired.finishedAt <= 0 || service.controlPending("camera"))
      throw new Error("verification watchdog did not terminate the expired transaction")
    if (!preserved || preserved.status !== "succeeded" || preserved.code !== "verified")
      throw new Error("verification watchdog mutated an unrelated transaction")
    console.log("PRIVACY_QML_CONTROL_VERIFICATION_TIMEOUT_OK")
    Qt.quit()
  }

  Component.onCompleted: {
    service.settings = {notifyOnControlChanges:false}
    service.controlTransactions = {
      camera:{status:"verifying", expectedEnabled:false, startedAt:10, finishedAt:0, exitCode:0, deadline:Date.now() - 1, code:"verifying"},
      microphone:{status:"succeeded", expectedEnabled:false, startedAt:1, finishedAt:2, exitCode:0, code:"verified"}
    }
  }

  Connections { target: service; function onControlTransactionsChanged() { root.verifyTimeout() } }
  Timer { interval: 1500; running: true; onTriggered: { throw new Error("verification watchdog did not complete") } }
}

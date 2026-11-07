pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  Service { id: service }
  property bool completed: false
  QtObject {
    id: watchdogHost
    property var results: []
    function notifyControlResult(kind, expectedEnabled, succeeded) {
      results = results.concat([{kind: kind, expectedEnabled: expectedEnabled, succeeded: succeeded}])
      root.verifyTimeout()
    }
  }
  // No observers feed this real controller: only its production watchdog can finish it.
  PrivacyControlTransactionController { id: watchdog; host: watchdogHost }

  function verifyTimeout() {
    if (completed) return
    var expired = service.controlTransactions.camera
    var watched = watchdog.transactions.camera
    if (!expired || expired.status !== "failed" || !watched || watched.status !== "failed"
        || watchdogHost.results.length !== 1) return
    var preserved = service.controlTransactions.microphone
    if (expired.code !== "verification_timeout" || expired.exitCode !== 14
        || expired.finishedAt <= 0 || service.controlPending("camera"))
      throw new Error("verification watchdog did not terminate the expired transaction")
    if (!preserved || preserved.status !== "succeeded" || preserved.code !== "verified")
      throw new Error("verification watchdog mutated an unrelated transaction")
    if (watched.code !== "verification_timeout" || watched.exitCode !== 14
        || watched.finishedAt <= 0 || watchdog.pending("camera"))
      throw new Error("isolated production watchdog did not terminate the expired transaction")
    var notification = watchdogHost.results[0]
    if (notification.kind !== "camera" || notification.expectedEnabled !== false || notification.succeeded !== false)
      throw new Error("verification watchdog did not report exactly one failed control result")
    completed = true
    console.log("PRIVACY_QML_CONTROL_VERIFICATION_TIMEOUT_OK")
    Qt.quit()
  }

  Component.onCompleted: {
    service.settings = {notifyOnControlChanges:false}
    watchdog.transactions = {
      camera:{status:"verifying", expectedEnabled:false, startedAt:10, finishedAt:0, exitCode:0, deadline:Date.now() - 1, code:"verifying"}
    }
    service.controlTransactions = {
      camera:{status:"verifying", expectedEnabled:false, startedAt:10, finishedAt:0, exitCode:0, deadline:Date.now() - 1, code:"verifying"},
      microphone:{status:"succeeded", expectedEnabled:false, startedAt:1, finishedAt:2, exitCode:0, code:"verified"}
    }
  }

  Connections { target: watchdog; function onTransactionsChanged() { root.verifyTimeout() } }
  Connections { target: service; function onControlTransactionsChanged() { root.verifyTimeout() } }
  Timer { interval: 1500; running: true; onTriggered: { throw new Error("verification watchdog did not complete") } }
}

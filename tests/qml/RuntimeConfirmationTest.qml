pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  property bool awaitingExpiry: false
  property bool completed: false
  PrivacyConfirmationController { id: confirmation; guardMilliseconds: 40 }
  Component.onCompleted: {
    if (confirmation.request("unknown") || confirmation.pending !== "") throw new Error("unknown confirmation action accepted")
    if (confirmation.request("history") || confirmation.pending !== "history") throw new Error("first request must arm")
    if (confirmation.request("backend") || confirmation.pending !== "backend") throw new Error("new action must replace stale confirmation")
    if (!confirmation.request("backend") || confirmation.pending !== "") throw new Error("second matching request must confirm and clear")
    if (confirmation.request("lockdown") || confirmation.pending !== "lockdown") throw new Error("lockdown confirmation action was not allowlisted")
    confirmation.clear()
    confirmation.request("all")
    awaitingExpiry = true
  }

  Connections {
    target: confirmation
    function onPendingChanged() {
      if (!root.awaitingExpiry || root.completed || confirmation.pending !== "") return
      root.completed = true
      confirmation.request("history")
      confirmation.clear()
      if (confirmation.pending !== "") throw new Error("explicit clear failed")
      console.log("PRIVACY_QML_CONFIRMATION_OK")
      Qt.quit()
    }
  }
  Timer { interval: 1000; running: true; onTriggered: { throw new Error("confirmation guard did not expire") } }
}

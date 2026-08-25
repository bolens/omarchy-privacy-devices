import Quickshell
import QtQuick

ShellRoot {
  PrivacyConfirmationController { id: confirmation; guardMilliseconds: 40 }
  Component.onCompleted: {
    if (confirmation.request("unknown") || confirmation.pending !== "") throw new Error("unknown confirmation action accepted")
    if (confirmation.request("history") || confirmation.pending !== "history") throw new Error("first request must arm")
    if (confirmation.request("backend") || confirmation.pending !== "backend") throw new Error("new action must replace stale confirmation")
    if (!confirmation.request("backend") || confirmation.pending !== "") throw new Error("second matching request must confirm and clear")
    confirmation.request("all")
  }
  Timer {
    interval: 100
    running: true
    onTriggered: {
      if (confirmation.pending !== "") throw new Error("confirmation guard did not expire")
      confirmation.request("history")
      confirmation.clear()
      if (confirmation.pending !== "") throw new Error("explicit clear failed")
      console.log("PRIVACY_QML_CONFIRMATION_OK")
      Qt.quit()
    }
  }
}

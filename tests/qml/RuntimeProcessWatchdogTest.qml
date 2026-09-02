pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../.."

ShellRoot {
  id: root
  property int timeouts: 0
  Process { id: process; command: ["sleep", "30"]; running: true }
  PrivacyProcessWatchdog {
    id: watchdog
    process: process
    timeoutMilliseconds: 100
    onTimedOut: root.timeouts++
  }
  Component.onCompleted: watchdog.start()
  Timer {
    interval: 300; running: true
    onTriggered: {
      if (root.timeouts !== 1 || process.running || watchdog.armed)
        throw new Error("process watchdog did not terminate exactly once")
      console.info("PRIVACY_QML_PROCESS_WATCHDOG_OK")
      Qt.quit()
    }
  }
}

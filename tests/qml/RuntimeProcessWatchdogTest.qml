pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
  id: root
  property int timeouts: 0
  Process { id: observedProcess; command: ["sleep", "30"]; running: true }
  PrivacyProcessWatchdog {
    id: watchdog
    process: observedProcess
    timeoutMilliseconds: 100
    onTimedOut: root.timeouts++
  }
  Component.onCompleted: watchdog.start()
  Timer {
    interval: 300; running: true
    onTriggered: {
      if (root.timeouts !== 1 || observedProcess.running || watchdog.armed)
        throw new Error("process watchdog did not terminate exactly once")
      console.info("PRIVACY_QML_PROCESS_WATCHDOG_OK")
      Qt.quit()
    }
  }
}

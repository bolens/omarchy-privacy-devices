import Quickshell
import QtQuick

ShellRoot {
  id: root
  property int retries: 0

  PrivacyObserverWatchdog {
    id: watchdog
    enabled: true
    interval: 100
    onRetryRequested: root.retries++
  }

  Timer {
    interval: 180
    running: true
    onTriggered: {
      if (root.retries !== 1 || watchdog.running) throw new Error("watchdog retry did not fire exactly once")
      watchdog.enabled = false
      watchdog.restart()
      disabledCheck.start()
    }
  }

  Timer {
    id: disabledCheck
    interval: 180
    onTriggered: {
      if (root.retries !== 1) throw new Error("disabled watchdog emitted a retry")
      console.log("PRIVACY_QML_OBSERVER_WATCHDOG_OK")
      Qt.quit()
    }
  }

  Component.onCompleted: watchdog.restart()
}

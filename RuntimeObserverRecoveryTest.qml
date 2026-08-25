import Quickshell
import QtQuick

ShellRoot {
  id: root
  readonly property string healthyHelper: String(Qt.resolvedUrl("tests/fixtures/privacy-observer-helper")).replace(/^file:\/\//, "")
  Service { id: service; observerHelperOverride: "/usr/bin/false" }
  Component.onCompleted: service.configure({enabledKinds:["screen-recording"],directDeviceMonitoring:false,recordingPollSeconds:1})
  Timer {
    interval: 250; running: true
    onTriggered: {
      if (!service.fallbackObserverRetryRunning || service.observerHealth["fallback-observer"].status !== "degraded") throw new Error("observer failure did not enter bounded retry")
      service.observerHelperOverride = root.healthyHelper
      service.refreshFallbackObserver()
    }
  }
  Timer {
    interval: 750; running: true
    onTriggered: {
      if (!service.fallbackObserverRunning || service.fallbackObserverRetryRunning) throw new Error("observer did not recover from retry")
      if (service.observerHealth["fallback-observer"].status !== "healthy" || service.fallbackObserverLastSeen <= 0) throw new Error("recovered observer health was not published")
      console.log("PRIVACY_QML_OBSERVER_RECOVERY_OK")
      Qt.quit()
    }
  }
}

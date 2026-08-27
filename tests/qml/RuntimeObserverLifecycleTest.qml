import Quickshell
import QtQuick

ShellRoot {
  readonly property string fixtureHelper: String(Qt.resolvedUrl("tests/fixtures/privacy-observer-helper")).replace(/^file:\/\//, "")
  Service { id: service; observerHelperOverride: fixtureHelper }

  Component.onCompleted: service.configure({
    enabledKinds:["screen-recording", "screenshot", "camera", "microphone"],
    directDeviceMonitoring:true,
    recordingPollSeconds:1,
    directDevicePollSeconds:2
  })

  Timer {
    interval: 500
    running: true
    onTriggered: {
      if (!service.fallbackObserverRunning || !service.directObserverRunning) throw new Error("observers did not start")
      if (service.fallbackObserverLastSeen <= 0 || service.directObserverLastSeen <= 0) throw new Error("observer heartbeat missing")
      service.configure({enabledKinds:[],directDeviceMonitoring:false})
    }
  }

  Timer {
    interval: 1000
    running: true
    onTriggered: {
      if (service.fallbackObserverRunning || service.directObserverRunning) throw new Error("disabled observers still running")
      if (service.fallbackObserverRetryRunning || service.directObserverRetryRunning) throw new Error("disabled observer retry survived")
      if (service.fallbackObserverLastSeen !== 0 || service.directObserverLastSeen !== 0) throw new Error("disabled observer state survived")
      console.log("PRIVACY_QML_OBSERVER_LIFECYCLE_OK")
      Qt.quit()
    }
  }
}

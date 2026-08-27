import Quickshell
import QtQuick

ShellRoot {
  id: root
  property int stage: 0
  readonly property string fixtureHelper: String(Qt.resolvedUrl("tests/fixtures/privacy-observer-helper")).replace(/^file:\/\//, "")
  Service { id: service; observerHelperOverride: fixtureHelper }

  Component.onCompleted: service.configure({
    enabledKinds:["screen-recording", "screenshot", "camera", "microphone"],
    directDeviceMonitoring:true,
    recordingPollSeconds:1,
    directDevicePollSeconds:2
  })

  function advance() {
    if (stage === 0) {
      if (!service.fallbackObserverRunning || !service.directObserverRunning
          || service.fallbackObserverLastSeen <= 0 || service.directObserverLastSeen <= 0) return
      stage = 1
      service.configure({enabledKinds:[],directDeviceMonitoring:false})
      return
    }
    if (stage === 1) {
      if (service.fallbackObserverRunning || service.directObserverRunning) return
      if (service.fallbackObserverRetryRunning || service.directObserverRetryRunning) throw new Error("disabled observer retry survived")
      if (service.fallbackObserverLastSeen !== 0 || service.directObserverLastSeen !== 0) throw new Error("disabled observer state survived")
      stage = 2
      service.configure({enabledKinds:["screen-recording"],directDeviceMonitoring:true,recordingPollSeconds:1,directDevicePollSeconds:2})
      return
    }
    if (!service.fallbackObserverRunning || !service.directObserverRunning
        || service.fallbackObserverLastSeen <= 0 || service.directObserverLastSeen <= 0) return
    if (service.fallbackObserverRetiring || service.directObserverRetiring) throw new Error("retirement state blocked observer re-enable")
    console.log("PRIVACY_QML_OBSERVER_LIFECYCLE_OK")
    Qt.quit()
  }

  Connections {
    target: service
    function onFallbackObserverRunningChanged() { root.advance() }
    function onDirectObserverRunningChanged() { root.advance() }
    function onFallbackObserverLastSeenChanged() { root.advance() }
    function onDirectObserverLastSeenChanged() { root.advance() }
  }

  Timer { interval: 2500; running: true; onTriggered: { throw new Error("observer lifecycle did not settle") } }
}

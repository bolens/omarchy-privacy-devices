pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  property bool recovering: false
  readonly property string healthyHelper: String(Qt.resolvedUrl("tests/fixtures/privacy-observer-helper")).replace(/^file:\/\//, "")
  Service { id: service; observerHelperOverride: "/usr/bin/false" }
  Component.onCompleted: service.configure({enabledKinds:["screen-recording"],directDeviceMonitoring:false,recordingPollSeconds:1})
  function advance() {
    if (!recovering) {
      if (!service.fallbackObserverRetryRunning) return
      if (service.observerHealth["fallback-observer"].status !== "degraded") throw new Error("observer failure did not publish degraded health")
      recovering = true
      Qt.callLater(function() {
        service.observerHelperOverride = root.healthyHelper
        service.refreshFallbackObserver()
      })
      return
    }
    if (!service.fallbackObserverRunning || service.fallbackObserverRetryRunning || service.fallbackObserverLastSeen <= 0) return
    if (service.observerHealth["fallback-observer"].status !== "healthy") return
    console.log("PRIVACY_QML_OBSERVER_RECOVERY_OK")
    Qt.quit()
  }

  Connections {
    target: service
    function onFallbackObserverRetryRunningChanged() { root.advance() }
    function onFallbackObserverRunningChanged() { root.advance() }
    function onFallbackObserverLastSeenChanged() { root.advance() }
    function onObserverHealthChanged() { root.advance() }
  }

  Timer { interval: 2500; running: true; onTriggered: { throw new Error("observer recovery did not settle") } }
}

import Quickshell
import QtQuick

ShellRoot {
  id: root
  readonly property string helper: String(Qt.resolvedUrl("tests/fixtures/privacy-observer-helper")).replace(/^file:\/\//, "")
  property bool reconfiguring: false
  property bool completed: false
  Service { id: service; observerHelperOverride: root.helper }

  function heartbeatArgument(command) {
    var index = command.indexOf("--heartbeat")
    return index >= 0 ? command[index + 1] : ""
  }

  function advance() {
    if (completed || service.directObserverLastSeen <= 0 || service.fallbackObserverLastSeen <= 0) return
    if (!reconfiguring) {
      reconfiguring = true
      service.configure({enabledKinds:["screen-recording"],directDeviceMonitoring:true,recordingPollSeconds:3,directDevicePollSeconds:4})
      return
    }
    if (!service.directObserverRunning || !service.fallbackObserverRunning
        || heartbeatArgument(service.directObserverActiveCommand) !== "4"
        || heartbeatArgument(service.fallbackObserverActiveCommand) !== "3") return
    if (service.directObserverRestartPending || service.fallbackObserverRestartPending
        || service.directObserverRetiring || service.fallbackObserverRetiring)
      throw new Error("observer restart state survived successful reconfiguration")
    completed = true
    console.log("PRIVACY_QML_OBSERVER_RECONFIGURATION_OK")
    Qt.quit()
  }

  Connections {
    target: service
    function onDirectObserverLastSeenChanged() { root.advance() }
    function onFallbackObserverLastSeenChanged() { root.advance() }
    function onDirectObserverRunningChanged() { root.advance() }
    function onFallbackObserverRunningChanged() { root.advance() }
  }

  Timer {
    interval: 3000
    running: true
    onTriggered: { throw new Error("observer reconfiguration did not settle") }
  }

  Component.onCompleted: service.configure({enabledKinds:["screen-recording"],directDeviceMonitoring:true,recordingPollSeconds:1,directDevicePollSeconds:2})
}

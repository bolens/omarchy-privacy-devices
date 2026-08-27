import Quickshell
import QtQuick

ShellRoot {
  id: root
  readonly property string helper: String(Qt.resolvedUrl("tests/fixtures/privacy-observer-helper")).replace(/^file:\/\//, "")
  property bool completed: false
  Service { id: service; observerHelperOverride: root.helper }

  function heartbeatArgument(command) {
    var index = command.indexOf("--heartbeat")
    return index >= 0 ? command[index + 1] : ""
  }

  function verifyFinalObservers() {
    if (completed || service.directObserverLastSeen <= 0 || service.fallbackObserverLastSeen <= 0) return
    if (heartbeatArgument(service.directObserverActiveCommand) !== "4"
        || heartbeatArgument(service.fallbackObserverActiveCommand) !== "3") return
    if (!service.directObserverOwned || !service.fallbackObserverOwned
        || service.directObserverRetiring || service.fallbackObserverRetiring
        || service.directObserverRestartPending || service.fallbackObserverRestartPending)
      throw new Error("observer startup ownership did not settle")
    completed = true
    console.log("PRIVACY_QML_OBSERVER_STARTUP_OWNERSHIP_OK")
    Qt.quit()
  }

  Component.onCompleted: {
    service.configure({enabledKinds:["screen-recording"],directDeviceMonitoring:true,recordingPollSeconds:1,directDevicePollSeconds:2})
    if (!service.directObserverOwned || !service.fallbackObserverOwned)
      throw new Error("observer launch did not claim synchronous ownership")
    service.configure({enabledKinds:["screen-recording"],directDeviceMonitoring:true,recordingPollSeconds:3,directDevicePollSeconds:4})
  }

  Connections {
    target: service
    function onDirectObserverLastSeenChanged() { root.verifyFinalObservers() }
    function onFallbackObserverLastSeenChanged() { root.verifyFinalObservers() }
  }
  Timer { interval: 3000; running: true; onTriggered: { throw new Error("observer startup reconfiguration did not settle: direct="
    + service.directObserverOwned + "/" + service.directObserverRetiring + "/" + service.directObserverRestartPending + "/" + service.directObserverRunning
    + " fallback=" + service.fallbackObserverOwned + "/" + service.fallbackObserverRetiring + "/" + service.fallbackObserverRestartPending + "/" + service.fallbackObserverRunning
    + " commands=" + JSON.stringify(service.directObserverActiveCommand) + "/" + JSON.stringify(service.fallbackObserverActiveCommand)) } }
}

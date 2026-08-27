import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    var direct = {id:"direct", kind:"camera", application:"Camera", device:"Camera 1", source:"direct-device", confidence:"confirmed", startedAt:1}
    var fallback = {id:"fallback", kind:"screen-recording", application:"Recorder", device:"Desktop", source:"process-probe", confidence:"inferred", startedAt:2}
    var pipewire = {id:"pipewire", kind:"microphone", application:"Voice", device:"Mic", source:"pipewire", confidence:"confirmed", startedAt:3}
    service.settings = {enabledKinds:[], notifyOnActivity:false, notifyOnStop:false, historyEnabled:false}
    service.activeSessions = [direct, fallback, pipewire]
    service.directObservations = [direct]
    service.directObserverLastSeen = 100
    service.recordingApps = ["Recorder"]
    service.recordingActive = true
    service.screenshotActive = true
    service.fallbackObserverLastSeen = 200

    service.clearDirectObserverState()
    if (service.activeSessions.length !== 2 || service.activeSessions[0].id !== "fallback"
        || service.directObservations.length || service.directObserverLastSeen !== 0
        || service.suppressedObserverStarts["direct-device"] !== true)
      throw new Error("direct observer teardown did not isolate and suppress its sessions")
    service.clearFallbackObserverState()
    if (service.activeSessions.length !== 1 || service.activeSessions[0].id !== "pipewire"
        || service.recordingApps.length || service.recordingActive || service.screenshotActive
        || service.fallbackObserverLastSeen !== 0 || service.suppressedObserverStarts["process-probe"] !== true)
      throw new Error("fallback observer teardown did not isolate and clear its state")

    service.handleSessionTransitions({started:[direct, fallback], stopped:[]})
    if (Object.keys(service.suppressedObserverStarts).length !== 0 || service.notificationQueue.length)
      throw new Error("observer recovery did not consume suppression without notifications")
    if (service.activeSessions.length !== 1 || service.activeSessions[0].id !== "pipewire")
      throw new Error("recovery suppression unexpectedly mutated active sessions")

    console.log("PRIVACY_QML_OBSERVER_SESSION_TEARDOWN_OK")
    Qt.quit()
  }
}

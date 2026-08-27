import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    service.configure({enabledKinds:[], directDeviceMonitoring:false})

    service.settings = {enabledKinds:["location"]}
    service.locationProbeGeneration = service.locationGeneration
    service.parseLocation('{"type":"location-snapshot","active":true,"applications":["Maps","Maps","<unsafe>"]}')
    if (!service.locationActive || JSON.stringify(service.locationApps) !== JSON.stringify(["Maps", "＜unsafe＞"]))
      throw new Error("location payload was not normalized")
    service.parseLocation('{"type":"wrong","active":true,"applications":["Maps"]}')
    if (service.locationActive || service.locationApps.length)
      throw new Error("invalid location payload did not clear state")
    service.settings = {enabledKinds:[]}
    service.parseLocation('{"type":"location-snapshot","active":true,"applications":["Late Maps"]}')
    if (service.locationActive || service.locationApps.length)
      throw new Error("disabled location monitoring accepted a late payload")

    service.acceptAudioEndpoints("microphone", '[{"id":"source.1","label":"Desk mic","muted":false},{"id":"bad id","label":"Invalid","muted":true},{"id":"source.2","label":"","muted":true}]')
    var endpoints = service.audioEndpoints("microphone")
    if (endpoints.length !== 2 || endpoints[0].label !== "Desk mic" || endpoints[1].label !== "source.2"
        || endpoints[1].muted !== true || service.audioEndpointMessage !== "")
      throw new Error("audio endpoint payload was not sanitized")
    service.acceptAudioEndpoints("microphone", '{"not":"a list"}')
    if (service.audioEndpointMessage !== "Audio endpoints could not be read." || service.audioEndpoints("microphone").length !== 2)
      throw new Error("invalid endpoint payload corrupted the last good state")

    service.settings = {directDeviceMonitoring:true}
    service.directObserverRetiring = false
    service.handleDirectDeviceSnapshot('{"type":"snapshot","healthy":false,"code":"permission_denied","error":"denied","observations":[{"kind":"camera","application":"Browser"}]}')
    if (service.directObservations.length !== 1 || service.observerHealth["direct-device"].status !== "degraded"
        || service.observerHealth["direct-device"].code !== "permission_denied")
      throw new Error("unhealthy direct observer payload was not retained and surfaced")
    service.handleDirectDeviceSnapshot('{"type":"invalid"}')
    if (service.directObservations.length || service.observerHealth["direct-device"].code !== "invalid_payload")
      throw new Error("invalid direct observer payload did not clear stale observations")

    service.settings = {enabledKinds:["screen-recording", "screenshot"]}
    service.fallbackObserverRetiring = false
    service.handleFallbackSnapshot('{"type":"fallback-snapshot","version":1,"activities":{"screen-recording":["Recorder"],"screenshot":["Shot"]}}')
    if (!service.recordingActive || service.recordingApps[0] !== "Recorder" || !service.screenshotActive
        || service.observerHealth["fallback-observer"].status !== "healthy")
      throw new Error("fallback observer payload was not applied")
    service.handleFallbackSnapshot('{"type":"fallback-snapshot","version":2,"activities":{}}')
    if (service.recordingActive || service.screenshotActive || service.observerHealth["fallback-observer"].code !== "invalid_payload")
      throw new Error("invalid fallback observer payload did not clear stale state")

    console.log("PRIVACY_QML_SERVICE_PAYLOAD_BOUNDARY_OK")
    Qt.quit()
  }
}

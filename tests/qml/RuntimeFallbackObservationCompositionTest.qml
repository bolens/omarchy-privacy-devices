pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    service.settings = {enabledKinds:["location", "screen-recording", "screenshot"]}
    service.parseLocation('{"type":"location-snapshot","active":true,"applications":["Maps","Maps"]}')
    service.handleFallbackSnapshot('{"type":"fallback-snapshot","version":1,"activities":{"screen-recording":["Recorder"],"screenshot":["Shot"]}}')
    var rows = service.fallbackObservations()
    if (rows.length !== 3 || rows[0].kind !== "location" || rows[0].application !== "Maps"
        || rows[0].source !== "geoclue" || rows[0].confidence !== "confirmed")
      throw new Error("location observation was not composed from normalized state")
    if (rows[1].kind !== "screen-recording" || rows[1].application !== "Recorder"
        || rows[1].source !== "process-probe" || rows[1].confidence !== "inferred")
      throw new Error("recording observation lost fallback attribution")
    if (rows[2].kind !== "screenshot" || rows[2].application !== "Screenshot tool"
        || rows[2].source !== "process-probe" || rows[2].confidence !== "inferred")
      throw new Error("screenshot observation lost fallback attribution")

    service.locationApps = []
    rows = service.fallbackObservations()
    if (rows[0].kind !== "location" || rows[0].application !== "Unknown application"
        || rows[0].confidence !== "inferred")
      throw new Error("active unattributed location did not retain an inferred observation")
    service.locationActive = false
    service.recordingApps = []
    service.recordingActive = false
    service.screenshotActive = false
    if (service.fallbackObservations().length !== 0)
      throw new Error("inactive fallback state still emitted observations")

    console.log("PRIVACY_QML_FALLBACK_OBSERVATION_COMPOSITION_OK")
    Qt.quit()
  }
}

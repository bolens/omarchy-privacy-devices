import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    service.settings = {enabledKinds:["screenshot", "location"], directDeviceMonitoring:false}
    service.observerHealth = Object.assign({}, service.observerHealth, {
      "fallback-observer":{status:"degraded", source:"fallback-observer", code:"invalid_payload", reason:"invalid observer response"}
    })
    service.dependencyCheckedMap = {location:true}
    service.dependencyReadyMap = {location:false}

    var screenshot = service.healthFor("screenshot")
    if (screenshot.status !== "degraded" || screenshot.codes.length !== 1
        || screenshot.codes[0] !== "invalid_payload" || screenshot.summary.indexOf("invalid observer response") < 0)
      throw new Error("fallback observer degradation was not projected to device health")
    var location = service.healthFor("location")
    if (location.status !== "unavailable" || location.codes.indexOf("dependency_unavailable") < 0
        || location.summary.indexOf("GeoClue") < 0)
      throw new Error("missing location dependency was not projected to device health")

    service.setObserverHealth("fallback-observer", "healthy", "ok", "")
    service.dependencyReadyMap = {location:true}
    if (service.healthFor("screenshot").status !== "healthy" || service.healthFor("location").status !== "healthy")
      throw new Error("device health did not recover with its sources")
    if (service.monitoringDegraded())
      throw new Error("aggregate monitoring health remained degraded after recovery")

    console.log("PRIVACY_QML_DEVICE_HEALTH_AGGREGATION_OK")
    Qt.quit()
  }
}

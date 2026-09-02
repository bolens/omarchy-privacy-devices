pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    if (service.boundedSeconds("bad", 5, 2, 60) !== 5
        || service.boundedSeconds(-10, 5, 2, 60) !== 2
        || service.boundedSeconds(100, 5, 2, 60) !== 60
        || service.boundedSeconds(4.6, 5, 2, 60) !== 5)
      throw new Error("service polling bounds were not normalized")
    if (service.regexEscape("shot.(x)+[1]?") !== "shot\\.\\(x\\)\\+\\[1\\]\\?")
      throw new Error("service regex escaping did not quote metacharacters")

    service.cameraAllowed = true
    service.locationAllowed = true
    service.screenShareAllowed = true
    service.setAllowed("camera", false)
    if (service.cameraAllowed || !service.locationAllowed || !service.screenShareAllowed)
      throw new Error("camera state mutation crossed device boundaries")
    service.setAllowed("location", false)
    service.setAllowed("screen-share", false)
    service.setAllowed("not-a-kind", true)
    if (service.locationAllowed || service.screenShareAllowed || service.cameraAllowed)
      throw new Error("allow-state mutation was incomplete or accepted an unknown kind")

    service.lastProbeExitCodes = {camera:1}
    service.lastControlExitCodes = {location:2}
    var priorProbe = service.lastProbeExitCodes
    var priorControl = service.lastControlExitCodes
    service.setResult("probe", "location", "7")
    service.setResult("control", "camera", "9")
    if (service.lastProbeExitCodes === priorProbe || service.lastControlExitCodes === priorControl
        || service.lastProbeExitCodes.camera !== 1 || service.lastProbeExitCodes.location !== 7
        || service.lastControlExitCodes.location !== 2 || service.lastControlExitCodes.camera !== 9)
      throw new Error("result maps were mutated in place, cross-wired, or not normalized")

    console.log("PRIVACY_QML_SERVICE_STATE_MUTATION_OK")
    Qt.quit()
  }
}

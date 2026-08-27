import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    service.settings = {
      enabledKinds:["microphone", "camera"],
      showInferredAttribution:false,
      deduplicateApps:true,
      hiddenApps:["Hidden app"],
      hiddenDevices:["Hidden device"]
    }
    service.activeSessions = [
      {id:"visible", kind:"microphone", application:"Recorder", device:"Desk mic", source:"pipewire", confidence:"confirmed", startedAt:10},
      {id:"duplicate", kind:"microphone", application:"Recorder", device:"USB mic", source:"pipewire", confidence:"confirmed", startedAt:20},
      {id:"inferred", kind:"microphone", application:"Browser", device:"Web mic", source:"pipewire", confidence:"inferred", startedAt:30},
      {id:"hidden-app", kind:"microphone", application:"Hidden app", device:"Other mic", source:"pipewire", confidence:"confirmed", startedAt:40},
      {id:"hidden-device", kind:"camera", application:"Camera app", device:"Hidden device", source:"pipewire", confidence:"confirmed", startedAt:50}
    ]
    service.lastProbeExitCodes = {camera:7}
    service.lastControlExitCodes = {microphone:0}
    service.controlTransactions = {camera:{phase:"verifying", expectedEnabled:false}}

    var status = service.snapshot()
    if (status.length !== 2 || status[0].kind !== "microphone" || status[1].kind !== "camera")
      throw new Error("snapshot did not preserve configured kind order")
    if (!status[0].active || status[0].apps.length !== 1 || status[0].apps[0] !== "Recorder"
        || status[0].sessions.length !== 4 || !status[1].active)
      throw new Error("snapshot attribution projection was inconsistent")

    var safe = service.diagnostics(true)
    if (!safe.redacted || safe.sessions.length !== 5 || safe.sessions[0].application !== "redacted"
        || safe.sessions[0].device !== "redacted" || safe.sessions[0].source !== "pipewire"
        || safe.probeExitCodes.camera !== 7 || safe.controlExitCodes.microphone !== 0
        || safe.controlTransactions.camera.phase !== "verifying")
      throw new Error("safe diagnostics lost metadata or exposed private fields")
    var unsafe = service.diagnostics(false)
    if (unsafe.redacted || unsafe.sessions[0].application !== "Recorder" || unsafe.sessions[0].device !== "Desk mic")
      throw new Error("explicit unsafe diagnostics did not retain troubleshooting fields")

    console.log("PRIVACY_QML_SERVICE_PROJECTION_OK")
    Qt.quit()
  }
}

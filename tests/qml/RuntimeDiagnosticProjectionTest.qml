pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    service.settings = {
      enabledKinds:["screenshot", "screen-recording", "microphone"],
      screenshotBackend:"grim",
      recordingBackend:"wf-recorder"
    }
    service.activeSessions = [{
      id:"shot", kind:"screenshot", application:"Screenshot tool", device:"Desktop",
      source:"process-probe", confidence:"inferred", startedAt:10
    }]
    service.controlTransactions = {screenshot:{status:"verifying", expectedEnabled:false, code:"verifying"}}
    service.lastProbeExitCodes = {screenshot:4}
    service.lastControlExitCodes = {screenshot:0}
    service.recordingActive = true
    service.fallbackMicrophoneMuted = true

    var screenshot = service.diagnostic("screenshot")
    if (screenshot.controlState !== "Pending authorization" || !screenshot.pending || !screenshot.active
        || screenshot.apps.length !== 1 || screenshot.apps[0] !== "Screenshot tool" || screenshot.sessions.length !== 1
        || screenshot.probeExitCode !== 4 || screenshot.controlExitCode !== 0
        || screenshot.backend !== "Screenshot capture (grim)" || screenshot.controlTransaction.status !== "verifying")
      throw new Error("screenshot diagnostic lost pending, session, backend, or exit-code state")

    var recording = service.diagnostic("screen-recording")
    if (recording.controlState !== "Recording" || !recording.enabled
        || recording.backend !== "Recorder process detection (wf-recorder)"
        || recording.probeExitCode !== -1 || recording.controlExitCode !== -1)
      throw new Error("recording diagnostic did not project active backend state")
    var microphone = service.diagnostic("microphone")
    if (microphone.controlState !== "Muted" || microphone.enabled
        || microphone.backend.indexOf("activity: PipeWire") < 0)
      throw new Error("microphone diagnostic did not project mute state")

    console.log("PRIVACY_QML_DIAGNOSTIC_PROJECTION_OK")
    Qt.quit()
  }
}

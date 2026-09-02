pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  function assertHelper(path, suffix) {
    if (path.indexOf("file:") === 0 || path.slice(-suffix.length) !== suffix || path.indexOf("runtime tree") < 0)
      throw new Error("helper path was not resolved inside the relocatable runtime tree: " + path)
  }

  Component.onCompleted: {
    assertHelper(service.helperPath(), "/privacy-control")
    assertHelper(service.historyHelperPath(), "/privacy-history")
    assertHelper(service.audioEndpointHelperPath(), "/privacy-audio-devices")
    assertHelper(service.dependencyHelperPath(), "/privacy-deps")
    assertHelper(service.actionHelperPath(), "/privacy-action")
    assertHelper(service.observerHelperPath(), "/privacy-observe")

    service.observerHelperOverride = "/tmp/fixture observer"
    service.settings = {
      recordingBackend:"custom",
      recordingProcessName:"recorder process",
      recordingPollSeconds:999,
      screenshotBackend:"custom",
      screenshotProcessName:"shot.(x)+"
    }
    var command = service.fallbackObserverCommand()
    if (command[0] !== "/tmp/fixture observer" || command[1] !== "watch-fallbacks"
        || command[2] !== "--heartbeat" || command[3] !== "60"
        || command[4] !== "--recording" || command[5] !== "recorder process"
        || command[6] !== "--screenshot-pattern" || command[7] !== "^(shot\\.\\(x\\)\\+)(\\s|$)")
      throw new Error("fallback observer command lost bounded or escaped arguments")

    service.settings = {recordingBackend:"wf-recorder", recordingPollSeconds:-10, screenshotBackend:"grim"}
    command = service.fallbackObserverCommand()
    if (command[3] !== "1" || command[5] !== "wf-recorder"
        || command[7].indexOf("grim") < 0 || command[7].indexOf("flameshot") < 0)
      throw new Error("built-in fallback observer command used invalid defaults")

    console.log("PRIVACY_QML_HELPER_COMMAND_BOUNDARY_OK")
    Qt.quit()
  }
}

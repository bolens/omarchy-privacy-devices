pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    service.settings = {
      enabledKinds:["microphone"],
      hiddenApps:["Hidden app"],
      hiddenDevices:["Hidden mic"],
      showInferredAttribution:false,
      deduplicateApps:true
    }
    service.activeSessions = [{
      id:"live", kind:"microphone", application:"Live recorder", device:"Live mic",
      source:"pipewire", confidence:"confirmed", startedAt:1
    }]
    service.capturePreviewBarSessions = [
      {id:"visible-1", kind:"microphone", application:"Recorder", device:"Desk mic", source:"pipewire", confidence:"confirmed", startedAt:2},
      {id:"visible-2", kind:"microphone", application:"Recorder", device:"USB mic", source:"pipewire", confidence:"confirmed", startedAt:3},
      {id:"hidden-app", kind:"microphone", application:"Hidden app", device:"Other mic", source:"pipewire", confidence:"confirmed", startedAt:4},
      {id:"hidden-device", kind:"microphone", application:"Camera app", device:"Hidden mic", source:"pipewire", confidence:"confirmed", startedAt:5},
      {id:"inferred", kind:"microphone", application:"Browser", device:"Web mic", source:"pipewire", confidence:"inferred", startedAt:6}
    ]
    service.capturePreviewActive = true

    if (service.barSessionsFor("microphone").length !== 5 || !service.barActive("microphone"))
      throw new Error("capture preview did not own raw bar activity")
    var visible = service.barAttributedSessionsFor("microphone")
    var apps = service.barAppsFor("microphone")
    if (visible.length !== 2 || apps.length !== 1 || apps[0] !== "Recorder")
      throw new Error("bar policies did not hide private/inferred sessions or deduplicate apps")

    service.capturePreviewActive = false
    if (service.barSessionsFor("microphone").length !== 1 || service.barAppsFor("microphone")[0] !== "Live recorder")
      throw new Error("ending capture preview did not restore live bar sessions")
    service.settings = Object.assign({}, service.settings, {enabledKinds:[]})
    if (service.barActive("microphone"))
      throw new Error("disabled kind remained active in the bar")

    console.log("PRIVACY_QML_BAR_SESSION_POLICY_OK")
    Qt.quit()
  }
}

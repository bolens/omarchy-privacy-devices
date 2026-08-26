import Quickshell
import QtQuick
import qs.Commons

ShellRoot {
  id: root
  property var patches: []

  QtObject {
    id: serviceMock
    property var selfTestResult: ({status:"idle",text:"Idle"})
    function clearHistory() {}
    function runSelfTest() {}
    function sendTestNotification() {}
    function copySelfTest() {}
    function copyDiagnostics(_safe) {}
  }
  QtObject {
    id: controllerMock
    property color activeThemeColor: Color.accent
    property bool monitoringDegraded: false
    property var privacyService: serviceMock
    property bool settingsTransferRunning: false
    property bool settingsUndoAvailable: false
    property string settingsTransferStatus: ""
    property var kindOptions: [
      {label:"Microphone",value:"microphone"}, {label:"Camera",value:"camera"},
      {label:"Screen share",value:"screen-share"}, {label:"Location",value:"location"}
    ]
    property var values: ({blockableKinds:["camera"],directDeviceMonitoring:true,showInferredAttribution:false,directDevicePollSeconds:9,locationPollSeconds:25,recordingPollSeconds:4})
    function setting(key, fallback) { return values[key] === undefined ? fallback : values[key] }
    function persistSettings(patch) { root.patches = root.patches.concat([patch]) }
    function monitoringTelemetryText() { return "Healthy" }
    function exportSettings() {}
    function importSettings() {}
    function undoSettingsChange() {}
  }

  PrivacyMonitoringSettings { id: page; width: 700; controller: controllerMock }

  function descendant(item, name) {
    if (!item) return null
    if (item.objectName === name) return item
    var children = item.children || []
    for (var index = 0; index < children.length; index++) {
      var found = descendant(children[index], name)
      if (found) return found
    }
    return null
  }

  Component.onCompleted: Qt.callLater(function() {
    var kinds = descendant(page, "monitoringBlockableKindsSetting")
    var direct = descendant(page, "monitoringDirectDeviceToggle")
    var inferred = descendant(page, "monitoringInferredAttributionToggle")
    var heartbeat = descendant(page, "monitoringDirectPollSetting")
    var location = descendant(page, "monitoringLocationPollSetting")
    var recording = descendant(page, "monitoringRecordingPollSetting")
    if (!kinds || !direct || !inferred || !heartbeat || !location || !recording)
      throw new Error("monitoring configuration controls are not addressable")
    if (kinds.values.join("|") !== "camera" || !direct.checked || inferred.checked
        || heartbeat.value !== 9 || location.value !== 25 || recording.value !== 4)
      throw new Error("monitoring configuration did not reflect settings")
    kinds.changed(["screen-share", "location"])
    direct.clicked()
    inferred.clicked()
    heartbeat.modified(12)
    location.modified(35)
    recording.modified(6)
    if (root.patches.length !== 6 || root.patches[0].blockableKinds.join("|") !== "screen-share|location"
        || root.patches[1].directDeviceMonitoring !== false || root.patches[2].showInferredAttribution !== true
        || root.patches[3].directDevicePollSeconds !== 12 || root.patches[4].locationPollSeconds !== 35
        || root.patches[5].recordingPollSeconds !== 6)
      throw new Error("monitoring configuration persisted incorrect values")
    console.log("PRIVACY_QML_MONITORING_CONFIGURATION_OK")
    Qt.quit()
  })
}

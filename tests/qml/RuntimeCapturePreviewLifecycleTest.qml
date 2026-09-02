pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  Service { id: service }
  QtObject {
    id: barMock
    property bool opened: false
    property string view: ""
    property string editingKind: ""
    property string scrollPosition: ""
    function open() { opened = true }
    function close() { opened = false }
    function showGlobalSettings(page, section) { view = "settings:" + page + ":" + section }
    function showActivity() { view = "activity" }
    function showHistory() { view = "history" }
    function applySettingsScroll(position) { scrollPosition = position; return view.indexOf("settings:") === 0 ? "ok" : "settings closed" }
  }

  Component.onCompleted: {
    service.configure({enabledKinds:[],historyEnabled:false,directDeviceMonitoring:false})
    service.recentHistory = [{kind:"location",application:"Maps",startedAt:1,endedAt:2}]
    service.activeSessions = [{kind:"microphone",application:"Recorder",startedAt:10}]
    service.updateBarPresentation("DP-1", {opened:false})
    service.updateBarPresentation("HDMI-A-1", {opened:true, view:"settings", settingsPage:"monitoring", ready:true})
    if (!service.anyBarOpen()) throw new Error("multi-monitor bar presentation lost its open panel")
    var presentation = service.barPresentation("HDMI-A-1")
    if (presentation.view !== "settings" || presentation.settingsPage !== "monitoring" || !presentation.ready
        || Object.keys(service.barPresentation("missing-output")).length !== 0)
      throw new Error("monitor-scoped bar presentation was not preserved")
    service.capturePreviewOwner = "fixture_owner_123456789012"
    service.capturePreviewActive = true
    if (!service.registerBarInstance("HDMI-A-1", barMock)
        || service.openCapturePanel("fixture_owner_123456789012", "HDMI-A-1", "device", "microphone", "") !== "activity"
        || !barMock.opened || barMock.view !== "activity" || barMock.editingKind !== "microphone")
      throw new Error("capture did not route directly to the selected monitor instance")
    if (service.scrollCaptureSettings("fixture_owner_123456789012", "HDMI-A-1", "bottom") !== "settings closed")
      throw new Error("capture scroll did not reject a non-settings view")
    barMock.showGlobalSettings("monitoring", "")
    if (service.scrollCaptureSettings("fixture_owner_123456789012", "HDMI-A-1", "bottom") !== "ok" || barMock.scrollPosition !== "bottom"
        || service.scrollCaptureSettings("fixture_owner_123456789012", "HDMI-A-1", "middle") !== "invalid position"
        || service.scrollCaptureSettings("wrong_owner_123456789012345", "HDMI-A-1", "top") !== "denied")
      throw new Error("capture settings scroll did not validate and route to the selected monitor")
    if (service.closeCapturePanel("fixture_owner_123456789012", "HDMI-A-1") !== "ok" || barMock.opened)
      throw new Error("capture did not close the selected monitor instance")
    service.unregisterBarInstance("HDMI-A-1", barMock)
    service.capturePreviewHistory = [{kind:"camera",application:"Preview",startedAt:3,endedAt:4}]
    service.capturePreviewSessions = [{kind:"camera",application:"Preview",startedAt:20}]
    service.capturePreviewBarSessions = [{kind:"screen-share",application:"Preview",startedAt:30}]
    service.capturePreviewSettings = ({showIdle:false})
    service.captureHistoryPresentationEnabled = false
    service.capturePreviewOwner = "fixture_owner_123456789012"
    service.capturePreviewExpiresAt = Date.now() + 60000
    service.capturePreviewActive = true
    if (service.displayHistory[0].application !== "Preview" || service.displaySessions[0].kind !== "camera"
        || service.barSessionsFor("screen-share").length !== 1)
      throw new Error("capture preview did not isolate documentation state")
    service.clearCapturePreview()
    if (service.capturePreviewActive || service.capturePreviewHistory.length || service.capturePreviewSessions.length
        || service.capturePreviewBarSessions.length || Object.keys(service.capturePreviewSettings).length
        || !service.captureHistoryPresentationEnabled || service.capturePreviewOwner !== "" || service.capturePreviewExpiresAt !== 0)
      throw new Error("capture preview cleanup left temporary state behind")
    if (service.displayHistory[0].application !== "Maps" || service.displaySessions[0].kind !== "microphone"
        || !service.anyBarOpen())
      throw new Error("capture cleanup did not restore live state or preserve bar presentation")
    service.updateBarPresentation("HDMI-A-1", {opened:false})
    if (service.anyBarOpen()) throw new Error("closed multi-monitor bar presentation remained open")
    console.log("PRIVACY_QML_CAPTURE_PREVIEW_LIFECYCLE_OK")
    Qt.quit()
  }
}

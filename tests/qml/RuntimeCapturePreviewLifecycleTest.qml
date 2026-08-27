import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

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

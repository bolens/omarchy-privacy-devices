pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  property int updates: 0
  property int stage: 0

  Service { id: sharedService }
  QtObject {
    id: shellMock
    function serviceFor(id) { return id === "io.github.bolens.privacy-devices" ? sharedService : null }
    function updateEntryInline(id, settings) {
      if (id !== "io.github.bolens.privacy-devices" || settings.id !== id) throw new Error("invalid settings commit")
      root.updates += 1
    }
  }
  QtObject {
    id: barMock
    property var shell: shellMock
    property color barForeground: "#ffffff"
    property color foreground: "#ffffff"
    property color urgent: "#ff5555"
    property string fontFamily: "sans-serif"
    property bool foregroundAnimationEnabled: false
    property var activePopout: ""
    property bool vertical: false
    property int barSize: 40
    property string position: "top"
    property var screen: null
    function switchPanelFrom(_owner, _direction) { return false }
    function requestPopout(key) { activePopout = key }
    function releasePopout(key) { if (activePopout === key) activePopout = "" }
    function registerClickTarget(_item) {}
    function unregisterClickTarget(_item) {}
    function showTooltip(_item, _text) {}
    function hideTooltip(_item) {}
  }
  BarWidget {
    id: widget
    bar: barMock
    settings: ({enabledKinds:[],historyEnabled:false,showIdle:true,showControls:true})
  }

  Component.onCompleted: {
    sharedService.configure({enabledKinds:[],historyEnabled:false,directDeviceMonitoring:false})
    sharedService.capturePreviewSettings = ({})
    sharedService.capturePreviewHistory = [{kind:"camera",application:"Capture",startedAt:1,endedAt:2}]
    sharedService.capturePreviewSessions = [{kind:"camera",application:"Capture",startedAt:1}]
    sharedService.capturePreviewBarSessions = []
    sharedService.capturePreviewActive = true
    if (!widget.showIdle || sharedService.displayHistory.length !== 1 || sharedService.sessionsFor("camera").length !== 1 || sharedService.barActive("camera")) throw new Error("capture preview did not preserve presentation settings")
    sharedService.requestedView = "activity"
    sharedService.captureHistoryPresentationEnabled = false
    if (widget.historyPresentationEnabled || !widget.showIdle || sharedService.sessionsFor("camera").length !== 1)
      throw new Error("disabled-history view changed the immutable bar preview")
    sharedService.requestedView = "activity"
    sharedService.captureHistoryPresentationEnabled = true
    sharedService.capturePreviewActive = false
    sharedService.configure({enabledKinds:[],historyEnabled:true,directDeviceMonitoring:false})
    if (sharedService.historyLoaded) throw new Error("re-enabled history did not start a fresh load")
    sharedService.configure({enabledKinds:[],historyEnabled:false,directDeviceMonitoring:false})
    widget.open()
    widget.showGlobalSettings("monitoring", "private-data")
  }
  Timer {
    id: smokeTimer
    interval: 200; running: true; repeat: true
    onTriggered: {
      if (root.stage === 0) {
        if (widget.privacyService !== sharedService || widget.globalSettingsPage !== "monitoring") throw new Error("plugin service or settings wiring failed")
        if (!widget.settingsPageLoaded) throw new Error("lazy monitoring settings page did not load")
        widget.persistSettings({showIdle:false})
        widget.persistSettings({showControls:false})
        root.stage = 1
      } else if (root.stage === 1) {
        if (root.updates !== 1 || widget.showIdle !== false || widget.showControls !== false) return
        widget.showGlobalSettings("general", "")
        root.stage = 2
      } else if (root.stage === 2) {
        if (widget.globalSettingsPage !== "general") throw new Error("general settings page route changed: " + widget.globalSettingsPage + ", opened=" + widget.opened)
        if (!widget.settingsPageLoaded) return
        widget.showGlobalSettings("appearance", "")
        root.stage = 3
      } else if (root.stage === 3) {
        if (widget.globalSettingsPage !== "appearance") throw new Error("appearance settings page route changed: " + widget.globalSettingsPage + ", opened=" + widget.opened)
        if (!widget.settingsPageLoaded) return
        widget.showGlobalSettings("alerts", "")
        root.stage = 4
      } else if (root.stage === 4) {
        if (widget.globalSettingsPage !== "alerts") throw new Error("alerts settings page route changed: " + widget.globalSettingsPage + ", opened=" + widget.opened)
        if (!widget.settingsPageLoaded) return
        widget.showGlobalSettings("monitoring", "")
        root.stage = 5
      } else if (root.stage === 5) {
        if (widget.globalSettingsPage !== "monitoring") throw new Error("monitoring settings page route changed: " + widget.globalSettingsPage + ", opened=" + widget.opened)
        if (!widget.settingsPageLoaded) return
        widget.showHistory()
        if (!widget.showingHistory || widget.showingGlobalSettings) throw new Error("history navigation failed")
        widget.showActivity()
        widget.editingKind = "camera"
        root.stage = 6
      } else {
        if (widget.editingKind !== "camera" || widget.showingHistory || widget.showingGlobalSettings) throw new Error("device editor integration failed")
        barMock.vertical = true
        root.stage = 7
      }
      if (root.stage === 7) Qt.callLater(function() {
        if (!widget.verticalBar || widget.barFlowColumns !== 1) throw new Error("vertical bar layout did not stack items")
        smokeTimer.stop()
        console.log("PRIVACY_QML_PLUGIN_SMOKE_OK")
        Qt.quit()
      })
    }
  }
}

import Quickshell
import QtQuick

ShellRoot {
  id: root

  Service { id: service }
  QtObject {
    id: shellMock
    function serviceFor(id) { return id === "io.github.bolens.privacy-devices" ? service : null }
    function updateEntryInline(_id, _settings) {}
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
    settings: ({enabledKinds:[],historyEnabled:false,showIdle:true})
  }

  Component.onCompleted: {
    service.configure({enabledKinds:[],historyEnabled:false,directDeviceMonitoring:false})
    var now = Date.now()
    service.capturePreviewSettings = ({historyEnabled:true})
    service.capturePreviewHistory = [
      {kind:"microphone",application:"Firefox",device:"Desk mic",startedAt:now-60000,endedAt:now-30000,durationMs:30000,confidence:"confirmed"},
      {kind:"camera",application:"Video Call",device:"Webcam",startedAt:now-120000,endedAt:now-90000,durationMs:30000,confidence:"confirmed"}
    ]
    service.capturePreviewActive = true
    service.requestedView = "history"
    widget.open()
    widget.showHistory()
    Qt.callLater(function() {
      var search = widget.historySearchControl
      var count = widget.historyCountLabel
      if (!search || !count) throw new Error("history search presentation is not addressable")
      if (widget.filteredHistory.length !== 2 || count.text !== "2 entries" || widget.historySummaryRows.length !== 2)
        throw new Error("history view did not render the in-memory retained activity: filtered=" + widget.filteredHistory.length
          + " count=" + count.text + " summaries=" + widget.historySummaryRows.length)
      search.text = "Firefox"
      Qt.callLater(function() {
        if (widget.historyQuery !== "Firefox" || widget.filteredHistory.length !== 1 || count.text !== "1 of 2")
          throw new Error("history search did not update filtered count feedback")
        search.text = "No match"
        Qt.callLater(function() {
          if (widget.filteredHistory.length !== 0 || count.text !== "0 of 2")
            throw new Error("empty history search result was not represented")
          widget.requestHistoryClear()
          if (widget.confirmationPending !== "history") throw new Error("history clear did not require confirmation")
          widget.showActivity()
          if (widget.confirmationPending !== "") throw new Error("leaving history did not cancel destructive confirmation")
          service.captureHistoryPresentationEnabled = false
          widget.showHistory()
          Qt.callLater(function() {
            var settingsAction = widget.historyDisabledSettingsControl
            if (!settingsAction || !settingsAction.visible) throw new Error("disabled-history settings action is not addressable")
            settingsAction.clicked()
            Qt.callLater(function() {
              if (!widget.showingGlobalSettings || widget.globalSettingsPage !== "monitoring")
                throw new Error("disabled-history action did not open monitoring settings")
              console.log("PRIVACY_QML_HISTORY_VIEW_OK")
              Qt.quit()
            })
          })
        })
      })
    })
  }
}

import Quickshell
import QtQuick

ShellRoot {
  id: root
  property int phase: 0
  property int successfulWrites: 0

  Service { id: service }
  QtObject {
    id: shellMock
    property bool rejectWrites: true
    function serviceFor(id) { return id === "io.github.bolens.privacy-devices" ? service : null }
    function updateEntryInline(_id, _settings) {
      if (rejectWrites) throw new Error("fixture persistence rejected")
      root.successfulWrites++
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
    service.configure({enabledKinds:[],historyEnabled:false,directDeviceMonitoring:false})
    widget.persistSettings({showIdle:false,showControls:false})
  }

  Timer {
    id: check
    interval: 180
    running: true
    onTriggered: {
      if (root.phase === 0) {
        if (!widget.showIdle || !widget.showControls) throw new Error("failed persistence did not restore prior widget settings")
        if (service.settings.showIdle !== true || service.settings.showControls !== true)
          throw new Error("failed persistence did not restore prior service configuration")
        if (widget.settingsMutationMessage.indexOf("Settings update failed") !== 0
            || widget.settingsMutationMessage.indexOf("fixture persistence rejected") < 0)
          throw new Error("failed persistence did not expose actionable feedback")
        shellMock.rejectWrites = false
        widget.persistSettings({showIdle:false})
        root.phase = 1
        restart()
        return
      }
      if (root.successfulWrites !== 1 || widget.showIdle || service.settings.showIdle !== false
          || widget.settingsMutationMessage !== "Changes applied")
        throw new Error("settings persistence did not recover after rollback")
      console.log("PRIVACY_QML_SETTINGS_ROLLBACK_OK")
      Qt.quit()
    }
  }
}

import Quickshell
import QtQuick

ShellRoot {
  id: root
  property var commits: []

  Service { id: service }
  QtObject {
    id: shellMock
    function serviceFor(id) { return id === "io.github.bolens.privacy-devices" ? service : null }
    function updateEntryInline(_id, settings) { root.commits = root.commits.concat([settings]) }
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
    settings: ({enabledKinds:[],historyEnabled:false,itemColorRoles:{},itemIdleOpacity:{}})
  }

  Component.onCompleted: {
    service.configure({enabledKinds:[],historyEnabled:false,directDeviceMonitoring:false})
    widget.persistItemColor("microphone", "active", "accent")
    widget.persistItemColor("microphone", "blocked", "urgent")
    widget.persistItemIdleOpacity("microphone", 55)
  }

  Timer {
    id: firstCheck
    interval: 180
    running: true
    onTriggered: {
      if (root.commits.length !== 1) throw new Error("rapid device appearance changes were not coalesced")
      var settings = root.commits[0]
      var roles = settings.itemColorRoles.microphone || {}
      if (roles.active !== "accent" || roles.blocked !== "urgent" || settings.itemIdleOpacity.microphone !== 0.55)
        throw new Error("coalesced device appearance changes lost an override")
      widget.persistItemColor("microphone", "active", "inherit")
      widget.persistItemIdleOpacity("microphone", null)
      secondCheck.start()
    }
  }

  Timer {
    id: secondCheck
    interval: 180
    onTriggered: {
      if (root.commits.length !== 2) throw new Error("inherited device appearance changes were not persisted")
      var settings = root.commits[1]
      var roles = settings.itemColorRoles.microphone || {}
      if (roles.active !== undefined || roles.blocked !== "urgent" || settings.itemIdleOpacity.microphone !== undefined)
        throw new Error("inherit did not remove only the selected device override")
      console.log("PRIVACY_QML_DEVICE_APPEARANCE_MUTATION_OK")
      Qt.quit()
    }
  }
}

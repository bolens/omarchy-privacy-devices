pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  property var commits: []

  Service { id: service }
  QtObject {
    id: shellMock
    function serviceFor(id) { return id === "io.github.bolens.privacy-devices" ? service : null }
    function updateEntryInline(_id, settings) { root.acceptCommit(settings) }
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

  function acceptCommit(settings) {
    root.commits = root.commits.concat([settings])
    var roles = settings.itemColorRoles.microphone || {}
    if (root.commits.length === 1) {
      if (roles.active !== "accent" || roles.blocked !== "urgent" || settings.itemIdleOpacity.microphone !== 0.55)
        throw new Error("coalesced device appearance changes lost an override")
      widget.persistItemColor("microphone", "active", "inherit")
      widget.persistItemIdleOpacity("microphone", null)
      return
    }
    if (root.commits.length === 2) {
      if (roles.active !== undefined || roles.blocked !== "urgent" || settings.itemIdleOpacity.microphone !== undefined)
        throw new Error("inherit did not remove only the selected device override")
      widget.persistItemColor("microphone", "active", "accent")
      widget.persistItemIdleVisibility("microphone", "hide")
      widget.persistLabel("microphone", "Primary microphone")
      widget.persistItemColor("camera", "active", "bar-active")
      widget.persistLabel("camera", "Webcam")
      widget.resetItemSettings("microphone")
      return
    }
    if (root.commits.length !== 3 || settings.itemColorRoles.microphone !== undefined
        || settings.itemIdleVisibility.microphone !== undefined || settings.itemLabels.microphone !== undefined)
      throw new Error("device reset retained pending overrides for its target")
    if (settings.itemColorRoles.camera.active !== "bar-active" || settings.itemLabels.camera !== "Webcam")
      throw new Error("device reset removed another device's pending overrides")
    console.log("PRIVACY_QML_DEVICE_APPEARANCE_MUTATION_OK")
    Qt.quit()
  }

  Component.onCompleted: {
    service.configure({enabledKinds:[],historyEnabled:false,directDeviceMonitoring:false})
    widget.persistItemColor("microphone", "active", "accent")
    widget.persistItemColor("microphone", "blocked", "urgent")
    widget.persistItemIdleOpacity("microphone", 55)
  }

  Timer { interval: 2000; running: true; onTriggered: { throw new Error("device appearance commits did not complete") } }
}
